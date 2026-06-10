import Foundation
import AppKit
import Carbon
import os

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "AppDelegate")
    private let audioRecorder = AudioRecorder()
    private let transcriptionManager = TranscriptionManager()
    private let historyManager = HistoryManager()
    private var errorResetTimer: Timer?
    
    var statusItem: NSStatusItem?
    var state: AppState = .idle
    
    var statusLabelItem: NSMenuItem?
    var toggleItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy programmatically to run as an accessory app without a dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status item in the system menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Build the dropdown menu
        let menu = NSMenu()
        
        // 1. Status label (disabled menu item for information)
        let statusLabel = NSMenuItem(title: "Status: Bereit", action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        self.statusLabelItem = statusLabel
        menu.addItem(statusLabel)
        
        // 2. Toggle menu item for recording
        let toggle = NSMenuItem(title: "Aufnahme starten", action: #selector(toggleRecording), keyEquivalent: "r")
        toggle.target = self
        self.toggleItem = toggle
        menu.addItem(toggle)
        
        // 3. Separator
        menu.addItem(NSMenuItem.separator())
        
        // 4. Quit app
        let quit = NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        
        statusItem?.menu = menu
        
        // Set UI to initial state
        updateUI()
        
        // Register Command + Option + K (Keycode 40, Cmd=256, Option=2048)
        let success = HotkeyManager.shared.register(
            keyCode: 40,
            carbonModifiers: UInt32(cmdKey | optionKey)
        ) {
            self.toggleRecording()
        }
        
        if !success {
            let logger = Logger(subsystem: "com.alex.Speakwerk", category: "AppDelegate")
            logger.error("Could not register global hotkey (Cmd+Option+K)")
        }
        
        // Smoke test protection: exit successfully if argument is passed
        if CommandLine.arguments.contains("--smoke-test") {
            print("Smoke test check passed after full initialization.")
            exit(0)
        }
    }
    
    func updateUI() {
        // Safe unwrapping of system button without force-unwrapping
        guard let statusItem = self.statusItem,
              let button = statusItem.button else {
            return
        }
        
        switch state {
        case .idle:
            button.title = "🎙️"
            statusLabelItem?.title = "Status: Bereit"
            toggleItem?.title = "Aufnahme starten"
            toggleItem?.isEnabled = true
        case .recording:
            button.title = "🔴 [REC]"
            statusLabelItem?.title = "Status: Aufnahme läuft..."
            toggleItem?.title = "Aufnahme stoppen"
            toggleItem?.isEnabled = true
        case .transcribing:
            button.title = "⏳"
            statusLabelItem?.title = "Status: Transkribiere..."
            toggleItem?.title = "Transkription läuft..."
            toggleItem?.isEnabled = false
        case .error(let message):
            button.title = "⚠️"
            statusLabelItem?.title = "Fehler: \(message)"
            toggleItem?.title = "Aufnahme starten"
            toggleItem?.isEnabled = true
        }
    }
    
    private func startRecordingProcess() {
        errorResetTimer?.invalidate()
        errorResetTimer = nil
        
        do {
            let fileURL = try audioRecorder.startRecording()
            logger.info("Recording started and saving to: \(fileURL.path)")
            
            // Preload model on first record start
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
            
            // Perform asynchronous transcription
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
                        // History-first: Speichere in lokalem Verlauf
                        _ = try await historyManager.addEntry(text: result, modelName: "openai_whisper-base")
                        textToInsert = result
                    }
                } catch {
                    logger.error("Error during transcription process: \(error.localizedDescription)")
                    setErrorState(message: "Transkription fehlgeschlagen")
                }
                
                // Safe cleanup of temporary recording file
                audioRecorder.deleteRecording()
                
                // If we have text, insert it
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
                    // Falls kein Text transkribiert wurde und kein Fehler vorlag, gehe zurück zu idle
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
}

// Start the main event loop
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
