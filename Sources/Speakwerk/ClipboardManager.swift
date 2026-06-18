import Cocoa
import ApplicationServices
import Foundation
import os

/// Helper struct to backup and restore system pasteboard contents safely.
public struct PasteboardBackup {
    private static let logger = Logger(subsystem: "com.alex.Speakwerk", category: "PasteboardBackup")

    public struct BackupItem {
        public let dataMap: [NSPasteboard.PasteboardType: Data]
    }

    public let items: [BackupItem]

    /// Captures the current general pasteboard state.
    public static func capture() -> PasteboardBackup {
        let pasteboard = NSPasteboard.general
        guard let pbItems = pasteboard.pasteboardItems else {
            Self.logger.warning("No pasteboard items found to backup.")
            return PasteboardBackup(items: [])
        }

        var backupItems: [BackupItem] = []

        for (itemIndex, item) in pbItems.enumerated() {
            var dataMap: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dataMap[type] = data
                } else {
                    // Fallback only if there is exactly one item to avoid cross-item data pollution
                    if pbItems.count == 1, let pbData = pasteboard.data(forType: type) {
                        dataMap[type] = pbData
                        Self.logger.debug("Resolved lazy promise on pasteboard-level for single-item of type: \(type.rawValue)")
                    } else {
                        Self.logger.warning("Failed to resolve pasteboard data for item \(itemIndex + 1) type: \(type.rawValue)")
                    }
                }
            }
            if !dataMap.isEmpty {
                backupItems.append(BackupItem(dataMap: dataMap))
            }
        }

        Self.logger.info("Captured \(backupItems.count) pasteboard items for backup.")
        return PasteboardBackup(items: backupItems)
    }

    /// Restores the backed up items to the general pasteboard.
    public func restore() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let itemsToRestore = items.map { backupItem -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in backupItem.dataMap {
                item.setData(data, forType: type)
            }
            return item
        }

        pasteboard.writeObjects(itemsToRestore)
        Self.logger.info("Restored \(itemsToRestore.count) items to pasteboard.")
    }
}

/// Singleton manager responsible for simulating command+V keystroke and managing pasteboard manipulation.
@MainActor
public class ClipboardManager {
    public static let shared = ClipboardManager()
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "ClipboardManager")

    private init() {}

    /// Checks whether the application is trusted for Accessibility (required for CGEvent posting).
    public func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Inserts the specified text at the current cursor position by:
    /// 1. Backing up the current clipboard.
    /// 2. Overwriting the clipboard with the text.
    /// 3. Simulating Cmd+V.
    /// 4. Waiting for a short delay asynchronously.
    /// 5. Restoring the original clipboard.
    ///
    /// Throws an error if Accessibility permissions are missing or if CGEvent simulation fails.
    public func insert(_ text: String, delayMs: Int = 150) async throws {
        guard checkAccessibilityPermission() else {
            logger.error("Accessibility permission missing. Aborting clipboard insert.")
            throw NSError(
                domain: "ClipboardManager",
                code: 101,
                userInfo: [NSLocalizedDescriptionKey: "Zugriffsrechte für Bedienungshilfen fehlen. Bitte erteile Speakwerk diese Rechte in den macOS Systemeinstellungen unter Datenschutz & Sicherheit -> Bedienungshilfen."]
            )
        }

        logger.info("Starting text insertion of length \(text.count)...")

        // 1. Capture original clipboard
        let backup = PasteboardBackup.capture()
        defer {
            backup.restore()
        }

        // 2. Set new text on general pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)

        guard pasteboard.setString(text, forType: .string) else {
            logger.error("Failed to write text to general pasteboard.")
            throw NSError(
                domain: "ClipboardManager",
                code: 102,
                userInfo: [NSLocalizedDescriptionKey: "Text konnte nicht in die Zwischenablage geschrieben werden."]
            )
        }

        // 3. Simulate Command+V
        try simulateCmdV()

        // 4. Wait asynchronously without blocking the thread
        try await Task.sleep(for: .milliseconds(delayMs))

        logger.info("Text insertion and clipboard restoration completed.")
    }

    /// Sets the specified text to the general pasteboard without simulating keystrokes.
    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)

        if pasteboard.setString(text, forType: .string) {
            logger.info("Successfully copied text of length \(text.count) to clipboard.")
        } else {
            logger.error("Failed to copy text to general pasteboard.")
        }
    }

    /// Helper to simulate Cmd+V event using CoreGraphics events.
    private func simulateCmdV() throws {
        let source = CGEventSource(stateID: .combinedSessionState)

        // Keycode 0x09 represents the physical key 'V' on QWERTY/QWERTZ/AZERTY.
        // TODO: Dynamically translate the 'V' character to keycode using active input source for layout-independence.
        guard let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
            throw NSError(
                domain: "ClipboardManager",
                code: 103,
                userInfo: [NSLocalizedDescriptionKey: "CGEvent für keyDown konnte nicht erstellt werden."]
            )
        }
        vDown.flags = .maskCommand

        guard let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            throw NSError(
                domain: "ClipboardManager",
                code: 104,
                userInfo: [NSLocalizedDescriptionKey: "CGEvent für keyUp konnte nicht erstellt werden."]
            )
        }
        vUp.flags = .maskCommand

        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        logger.debug("Cmd+V events posted successfully.")
    }
}
