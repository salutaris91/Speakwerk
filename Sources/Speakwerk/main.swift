import Foundation
import AppKit
import AVFoundation
import os
import SwiftUI
import KeyboardShortcuts
import Sparkle

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUStandardUserDriverDelegate {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "AppDelegate")
    private let audioRecorder = AudioRecorder()
    private let transcriptionManager = TranscriptionManager()
    private let historyManager = HistoryManager()
    private var errorResetTimer: Timer?
    private var updaterController: SPUStandardUpdaterController?
    
    var statusItem: NSStatusItem?
    var state: AppState = .idle
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle Updater (verifies linking during smoke-test)
        updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: self)
        
        // Smoke test protection: exit successfully if argument is passed
        if CommandLine.arguments.contains("--smoke-test") {
            print("Smoke test check passed after full initialization.")
            exit(0)
        }
        
        // Start updater immediately after smoke-test validation
        updaterController?.startUpdater()
        
        // Set activation policy programmatically to run as an accessory app without a dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status item in the system menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.isVisible = true
        
        // Observe model downloader progress updates to update the menu bar status
        ModelManager.shared.onProgressUpdate = { [weak self] progress in
            guard let self = self else { return }
            if case .downloadingModel = self.state {
                self.state = .downloadingModel(progress)
                self.updateUI()
            }
        }
        
        // Check onboarding status
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            state = .error("Onboarding ausstehend")
            updateUI()
            showOnboarding(mode: .fullOnboarding)
        } else {
            if ModelManager.shared.reconcileSelectedModel() {
                state = .idle
                updateUI()
                setupGlobalHotkey()
                transcriptionManager.preloadModel()
            } else {
                state = .error("Kein Modell installiert")
                updateUI()
                showOnboarding(mode: .fullOnboarding)
            }
        }
    }
    
    func updateUI() {
        guard let statusItem = self.statusItem,
              let button = statusItem.button else {
            return
        }
        
        rebuildMenu()
        
        // Ensure no image is set, only use the robust emoji text-based title
        button.image = nil
        
        switch state {
        case .idle:
            button.title = "🎙️"
        case .recording:
            button.title = "🔴 [REC]"
        case .transcribing:
            button.title = "⏳"
        case .downloadingModel:
            button.title = "⬇️"
        case .error:
            button.title = "🎙️⚠️"
        }
    }
    
    private func rebuildMenu() {
        let menu = NSMenu()
        
        // 0. About
        let aboutItem = NSMenuItem(title: "Über Speakwerk...", action: #selector(showAboutAction), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        
        // 1. Status Label
        let statusTitle: String
        switch state {
        case .idle:
            statusTitle = "Status: Bereit"
        case .recording:
            statusTitle = "Status: Aufnahme läuft..."
        case .transcribing:
            statusTitle = "Status: Transkribiere..."
        case .downloadingModel(let progress):
            statusTitle = "Status: Lade Modell (\(Int(progress * 100))%)..."
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
            case .downloadingModel:
                actionTitle = "Download läuft..."
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
            
            var isBusy = false
            switch state {
            case .recording, .transcribing, .downloadingModel:
                isBusy = true
            default:
                break
            }
            
            modelSubmenuItem.isEnabled = !isBusy
            menu.addItem(modelSubmenuItem)
            
            // 4. Settings
            let settingsItem = NSMenuItem(title: "Einstellungen...", action: #selector(showSettingsAction), keyEquivalent: ",")
            settingsItem.target = self
            settingsItem.isEnabled = !isBusy
            menu.addItem(settingsItem)
            
            // 5. Repeat Setup
            let resetItem = NSMenuItem(title: "Einrichtung erneut ausführen...", action: #selector(resetOnboardingAction), keyEquivalent: "")
            resetItem.target = self
            resetItem.isEnabled = !isBusy
            menu.addItem(resetItem)
            
            menu.addItem(NSMenuItem.separator())
        } else {
            // Setup pending
            let setupItem = NSMenuItem(title: "Einrichtung starten...", action: #selector(startOnboardingAction), keyEquivalent: "")
            setupItem.target = self
            menu.addItem(setupItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // 6. Sparkle Update Check
        menu.addItem(NSMenuItem.separator())
        let updateItem = NSMenuItem(
            title: "Nach Updates suchen...",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updateItem.target = updaterController
        menu.addItem(updateItem)
        
        // 7. Quit App
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
            state = .downloadingModel(0.0)
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
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 580),
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
    
    @MainActor
    @objc private func showSettingsAction() {
        if settingsWindow != nil {
            settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Speakwerk - Einstellungen"
        window.contentView = NSHostingView(rootView: settingsView)
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @MainActor
    @objc private func showAboutAction() {
        if aboutWindow != nil {
            aboutWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let aboutView = AboutView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Über Speakwerk"
        window.contentView = NSHostingView(rootView: aboutView)
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        self.aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func completeOnboardingFlow() {
        logger.info("Onboarding completed successfully.")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        state = .idle
        updateUI()
        setupGlobalHotkey()
        transcriptionManager.preloadModel()
    }
    
    private func setupGlobalHotkey() {
        HotkeyManager.shared.setup {
            self.toggleRecording()
        }
        logger.info("Global hotkey setup configured.")
    }
    
    private func startRecordingProcess() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            beginRecording()
        case .notDetermined:
            logger.info("Microphone permission not determined yet. Requesting access...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                Task { @MainActor in
                    if granted {
                        self.beginRecording()
                    } else {
                        self.handleMicrophoneAccessDenied()
                    }
                }
            }
        case .denied, .restricted:
            handleMicrophoneAccessDenied()
        @unknown default:
            handleMicrophoneAccessDenied()
        }
    }

    /// Shows an error state and an alert guiding the user to System Settings.
    /// Without microphone permission, AVAudioRecorder silently records silence,
    /// which Whisper then hallucinates into tags like "[Musik]".
    private func handleMicrophoneAccessDenied() {
        logger.error("Microphone access is denied or restricted. Recording aborted.")
        setErrorState(message: "Kein Mikrofonzugriff")

        let alert = NSAlert()
        alert.messageText = "Speakwerk hat keinen Mikrofonzugriff"
        alert.informativeText = "Ohne Mikrofonberechtigung kann keine Sprache aufgenommen werden. Bitte aktiviere Speakwerk unter Systemeinstellungen → Datenschutz & Sicherheit → Mikrofon."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Abbrechen")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func beginRecording() {
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
                        var processedText = result
                        if DictationManager.shared.dictationCommandsEnabled {
                            processedText = TextProcessor.process(result, with: DictationManager.shared.dictationRules)
                            logger.info("Processed transcription result: \(processedText)")
                        }
                        
                        textToInsert = processedText
                        do {
                            let activeModelName = ModelManager.shared.selectedModel.rawValue
                            _ = try await historyManager.addEntry(text: processedText, modelName: activeModelName)
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
                    let finalInsertText = DictationManager.shared.appendTrailingSpace ? text + " " : text
                    do {
                        try await ClipboardManager.shared.insert(finalInsertText)
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
            
        case .transcribing, .downloadingModel:
            logger.info("Ignoring toggle request: busy with transcription or model download.")
        }
    }
    
    @objc func quitApp() {
        errorResetTimer?.invalidate()
        audioRecorder.stopRecording()
        audioRecorder.deleteRecording()
        NSApp.terminate(nil)
    }
    
    // MARK: - SPUStandardUserDriverDelegate
    
    nonisolated func standardUserDriverWillShowModalAlert() {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if handleShowingUpdate {
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        if window == onboardingWindow {
            onboardingWindow = nil
            
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                state = .error("Onboarding ausstehend")
                ModelManager.shared.resetDownloadState()
            } else if case .downloadingModel = state {
                state = .idle
                ModelManager.shared.resetDownloadState()
            }
            
            updateUI()
        } else if window == settingsWindow {
            settingsWindow = nil
        } else if window == aboutWindow {
            aboutWindow = nil
        }
    }
}

// Start the main event loop
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

withExtendedLifetime(delegate) {
    app.run()
}
