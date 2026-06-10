import AppKit
@preconcurrency import KeyboardShortcuts
import os

extension KeyboardShortcuts.Name {
    @MainActor static let toggleRecording = Self("toggleRecording", default: .init(.k, modifiers: [.command, .option]))
}

@MainActor
class HotkeyManager {
    static let shared = HotkeyManager()
    
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "HotkeyManager")
    private var isSetUp = false
    
    func setup(onTrigger: @escaping @MainActor () -> Void) {
        guard !isSetUp else {
            logger.info("HotkeyManager setup already run. Skipping duplicate registration.")
            return
        }
        
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) {
            Task { @MainActor in
                onTrigger()
            }
        }
        isSetUp = true
        logger.info("HotkeyManager setup complete with KeyboardShortcuts (default: Cmd+Option+K).")
    }
}
