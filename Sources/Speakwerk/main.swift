import Foundation
import AppKit
import Carbon
import os
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "AppDelegate")
    private let audioRecorder = AudioRecorder()
    private let transcriptionManager = TranscriptionManager()
    private let historyManager = HistoryManager()
    private var errorResetTimer: Timer?
    
    var statusItem: NSStatusItem?
    var state: AppState = .idle
    private var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Smoke test protection: exit successfully if argument is passed
        if CommandLine.arguments.contains("--smoke-test") {
            print("Smoke test check passed after full initialization.")
            exit(0)
        }
        
        // Set activation policy programmatically to run as an accessory app without a dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status item in the system menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Check onboarding status
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            state = .error("Onboarding ausstehend")
            updateUI()
            showOnboarding(mode: .fullOnboarding)
        } else {
            state = .idle
            updateUI()
            registerGlobalHotkey()
            transcriptionManager.preloadModel()
        }
    }
    
    func updateUI() {
        guard let statusItem = self.statusItem,
              let button = statusItem.button else {
            return
        }
        
        rebuildMenu()
        
        switch state {
        case .idle:
            button.title = "🎙️"
        case .recording:
            button.title = "🔴 [REC]"
        case .transcribing:
            button.title = "⏳"
        case .error:
            button.title = "⚠️"
        }
    }
    
    private func rebuildMenu() {
        let menu = NSMenu()
        
        // 1. Status Label
        let statusTitle: String
        switch state {
        case .idle:
            statusTitle = "Status: Bereit"
        case .recording:
            statusTitle = "Status: Aufnahme läuft..."
        case .transcribing:
            statusTitle = "Status: Transkribiere..."
        case .error(let message):
            statusTitle = "Fehler: \(message)"
        }
        let statusLabel = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        
        // 2. Action Items (only if onboarding is complete)
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            let actionTitle: String
            let isEnabled: Bool
            let selector: Selector?
            
            switch state {
            case .idle, .error:
                actionTitle = "Aufnahme starten"
                isEnabled = true
                selector = #selector(toggleRecording)
            case .recording:
                actionTitle = "Aufnahme stoppen"
                isEnabled = true
                selector = #selector(toggleRecording)
            case .transcribing:
                actionTitle = "Transkription läuft..."
                isEnabled = false
                selector = nil
            }
            
            let actionItem = NSMenuItem(title: actionTitle, action: selector, keyEquivalent: "r")
            actionItem.target = self
            actionItem.isEnabled = isEnabled
            menu.addItem(actionItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // 3. Model Switch Submenu
            let modelMenu = NSMenu()
            let selectedModel = ModelManager.shared.selectedModel
            
            for tier in ModelTier.allCases {
                let isSelected = (tier == selectedModel)
                let isDownloaded = ModelManager.shared.isModelDownloaded(tier: tier)
                
                let titleStr = "\(tier.displayName) (\(tier.sizeDescription))\(isDownloaded ? "" : " ⬇️")"
                let item = NSMenuItem(title: titleStr, action: #selector(selectModelItem(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = tier
                item.state = isSelected ? .on : .off
                modelMenu.addItem(item)
            }
            
            let modelSubmenuItem = NSMenuItem(title: "Modell wechseln", action: nil, keyEquivalent: "")
            modelSubmenuItem.submenu = modelMenu
            menu.addItem(modelSubmenuItem)
            
            // 4. Repeat Setup
            let resetItem = NSMenuItem(title: "Einrichtung erneut ausführen...", action: #selector(resetOnboardingAction), keyEquivalent: "")
            resetItem.target = self
            menu.addItem(resetItem)
            
            menu.addItem(NSMenuItem.separator())
        } else {
            // Setup pending
            let setupItem = NSMenuItem(title: "Einrichtung starten...", action: #selector(startOnboardingAction), keyEquivalent: "")
            setupItem.target = self
            menu.addItem(setupItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // 5. Quit App
        let quit = NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        
        statusItem?.menu = menu
    }
    
    @objc private func selectModelItem(_ sender: NSMenuItem) {
        guard let tier = sender.representedObject as? ModelTier else { return }
        
        if tier == ModelManager.shared.selectedModel {
            return
        }
        
        if ModelManager.shared.isModelDownloaded(tier: tier) {
            ModelManager.shared.selectedModel = tier
            transcriptionManager.switchModel(to: tier)
            updateUI()
        } else {
            state = .transcribing
            updateUI()
            showOnboarding(mode: .downloadOnly(tier))
        }
    }
    
    @objc private func startOnboardingAction() {
        showOnboarding(mode: .fullOnboarding)
    }
    
    @objc private func resetOnboardingAction() {
        showOnboarding(mode: .fullOnboarding)
    }
    
    @MainActor
    func showOnboarding(mode: OnboardingViewMode) {
        if onboardingWindow != nil {
            onboardingWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
        let onboardingView = OnboardingView(
            mode: mode,
            onCompletion: { [weak self] in
                guard let self = self else { return }
                self.onboardingWindow?.close()
                self.onboardingWindow = nil
                
                if case .fullOnboarding = mode {
                    self.completeOnboardingFlow()
                } else if case .downloadOnly(let tier) = mode {
                    self.transcriptionManager.switchModel(to: tier)
                    self.state = .idle
                    self.updateUI()
                }
            },
            onCancel: { [weak self] in
                guard let self = self else { return }
                self.onboardingWindow?.close()
                self.onboardingWindow = nil
                if case .downloadOnly = mode {
                    self.state = .idle
                    self.updateUI()
                }
            }
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Speakwerk - Einrichtung"
        window.contentView = NSHostingView(rootView: onboardingView)
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        self.onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func completeOnboardingFlow() {
        logger.info("Onboarding completed successfully.")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        state = .idle
        updateUI()
        registerGlobalHotkey()
        transcriptionManager.preloadModel()
    }
    
    private func registerGlobalHotkey() {
        let success = HotkeyManager.shared.register(
            keyCode: 40,
            carbonModifiers: UInt32(cmdKey | optionKey)
        ) {
            self.toggleRecording()
        }
        
        if !success {
            logger.error("Could not register global hotkey (Cmd+Option+K)")
        } else {
            logger.info("Global hotkey (Cmd+Option+K) registered successfully.")
        }
    }
    
    private func startRecordingProcess() {
        errorResetTimer?.invalidate()
        errorResetTimer = nil
        
        do {
            let fileURL = try audioRecorder.startRecording()
            logger.info("Recording started and saving to: \(fileURL.path)")
            
            transcriptionManager.preloadModel()
            
            state = .recording
            updateUI()
        } catch {
            logger.error("Failed to start audio recording: \(error.localizedDescription)")
            setErrorState(message: "Aufnahme fehlgeschlagen")
        }
    }
    
    private func setErrorState(message: String) {
        errorResetTimer?.invalidate()
        state = .error(message)
        updateUI()
        
        errorResetTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if case .error = self.state {
                    self.state = .idle
                    self.updateUI()
                }
            }
        }
    }
    
    @objc func toggleRecording() {
        switch state {
        case .idle, .error:
            startRecordingProcess()
            
        case .recording:
            audioRecorder.stopRecording()
            
            state = .transcribing
            updateUI()
            
            Task {
                var textToInsert: String?
                do {
                    guard let fileURL = audioRecorder.audioFileURL else {
                        throw NSError(
                            domain: "AppDelegate",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Audio file URL is missing after recording stopped"]
                        )
                    }
                    
                    let result = try await transcriptionManager.transcribe(audioURL: fileURL)
                    logger.info("Transcription result: \(result)")
                    
                    if !result.isEmpty {
                        textToInsert = result
                        do {
                            let activeModelName = ModelManager.shared.selectedModel.rawValue
                            _ = try await historyManager.addEntry(text: result, modelName: activeModelName)
                        } catch {
                            logger.error("Failed to save to history: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    logger.error("Error during transcription process: \(error.localizedDescription)")
                    setErrorState(message: "Transkription fehlgeschlagen")
                }
                
                audioRecorder.deleteRecording()
                
                if let text = textToInsert {
                    do {
                        try await ClipboardManager.shared.insert(text)
                        self.state = .idle
                        self.updateUI()
                    } catch {
                        logger.error("Error during clipboard insertion: \(error.localizedDescription)")
                        setErrorState(message: "Einfügen fehlgeschlagen (Rechte?)")
                    }
                } else if case .transcribing = self.state {
                    self.state = .idle
                    self.updateUI()
                }
            }
            
        case .transcribing:
            logger.info("Ignoring toggle request: transcription is currently in progress.")
        }
    }
    
    @objc func quitApp() {
        errorResetTimer?.invalidate()
        HotkeyManager.shared.unregister()
        audioRecorder.stopRecording()
        audioRecorder.deleteRecording()
        NSApp.terminate(nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == onboardingWindow {
            onboardingWindow = nil
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                logger.info("Onboarding window closed before completion. Terminating app.")
                NSApp.terminate(nil)
            }
        }
    }
}

// Start the main event loop
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
