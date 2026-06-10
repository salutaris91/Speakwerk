import Foundation
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var state: AppState = .idle
    
    var statusLabelItem: NSMenuItem?
    var toggleItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hintergrundmodus ohne Dock-Icon programmatisch setzen
        NSApp.setActivationPolicy(.accessory)
        
        // StatusItem in der Menüleiste initialisieren
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Menü aufbauen
        let menu = NSMenu()
        
        // 1. Status-Anzeige (deaktiviertes Menüelement zur Information)
        let statusLabel = NSMenuItem(title: "Status: Bereit", action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        self.statusLabelItem = statusLabel
        menu.addItem(statusLabel)
        
        // 2. Toggle-Menüpunkt für Aufnahme
        let toggle = NSMenuItem(title: "Aufnahme starten", action: #selector(toggleRecording), keyEquivalent: "r")
        toggle.target = self
        self.toggleItem = toggle
        menu.addItem(toggle)
        
        // 3. Trennlinie
        menu.addItem(NSMenuItem.separator())
        
        // 4. Beenden
        let quit = NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        
        statusItem?.menu = menu
        
        // UI auf den initialen Zustand setzen
        updateUI()
        
        // Smoke-Test Schutz: Beende sofort erfolgreich, wenn Argument übergeben wurde
        if CommandLine.arguments.contains("--smoke-test") {
            print("Smoke test check passed after full initialization.")
            exit(0)
        }
    }
    
    func updateUI() {
        // Sicheres Entpacken des System-Buttons gemäß Hausregeln (keine Force-Unwraps)
        guard let statusItem = self.statusItem,
              let button = statusItem.button else {
            return
        }
        
        switch state {
        case .idle:
            button.title = "🎙️"
            statusLabelItem?.title = "Status: Bereit"
            toggleItem?.title = "Aufnahme starten"
        case .recording:
            button.title = "🔴 [REC]"
            statusLabelItem?.title = "Status: Aufnahme läuft..."
            toggleItem?.title = "Aufnahme stoppen"
        }
    }
    
    @objc func toggleRecording() {
        state = (state == .idle) ? .recording : .idle
        updateUI()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// Haupt-Event-Loop starten
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
