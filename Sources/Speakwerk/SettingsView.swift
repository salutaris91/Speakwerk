import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
    @State private var modelManager = ModelManager.shared
    @State private var dictationManager = DictationManager.shared
    @State private var newTrigger = ""
    @State private var newReplacement = ""
    @State private var errorMessage: String? = nil

    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Einstellungen")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                      )
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tastatur-Kurzbefehl")
                    .font(.headline)
                    .padding(.top, 15)
                
                Text("Lege ein globales Tastenkürzel fest, um die Aufnahme von Speakwerk von überall aus zu steuern.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        KeyboardShortcuts.Recorder("Aufnahme starten/stoppen:", name: .toggleRecording)
                        Spacer()
                    }
                    
                    Text("Hinweis: Wenn ein Tastenkürzel bereits vom System oder einer anderen App belegt ist (z. B. Spotlight oder Siri), wird es nicht ausgelöst. Wähle in diesem Fall eine andere Tastenkombination.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Transkriptionssprache")
                    .font(.headline)
                    .padding(.top, 15)
                
                Text("Wähle die Sprache aus, in der du diktierst, oder lass sie automatisch erkennen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sprache:")
                            .font(.body)
                        
                        Picker("", selection: $modelManager.selectedLanguage) {
                            ForEach(TranscriptionLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            // Diktierbefehle
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Diktierbefehle")
                        .font(.headline)
                    Spacer()
                    Toggle("Aktiviert", isOn: $dictationManager.dictationCommandsEnabled)
                        .toggleStyle(.switch)
                }
                .padding(.top, 10)
                
                Text("Ersetze gesprochene Wörter nach der Transkription deterministisch durch Satzzeichen oder Symbole.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                
                if dictationManager.dictationCommandsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        // Regel-Tabelle
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(dictationManager.dictationRules.sorted(by: { $0.trigger < $1.trigger })) { rule in
                                    HStack {
                                        Toggle("", isOn: Binding(
                                            get: { rule.isEnabled },
                                            set: { newValue in
                                                if let index = dictationManager.dictationRules.firstIndex(where: { $0.id == rule.id }) {
                                                    dictationManager.dictationRules[index].isEnabled = newValue
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                        .toggleStyle(.checkbox)
                                        
                                        Text(rule.trigger)
                                            .font(.system(.body, design: .monospaced))
                                            .frame(width: 150, alignment: .leading)
                                        
                                        Image(systemName: "arrow.right")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                        
                                        Text(rule.replacement.replacingOccurrences(of: "\n", with: "\\n"))
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            dictationManager.removeRule(id: rule.id)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Regel löschen")
                                    }
                                    .padding(.vertical, 4)
                                    
                                    Divider()
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        
                        // Regel hinzufügen
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                TextField("gesprochen (z.B. smiley)", text: $newTrigger)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 170)
                                
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Ersetzung (z.B. :-))", text: $newReplacement)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                
                                Button("Hinzufügen") {
                                    validateAndAddRule()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Support & Feedback Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Support & Feedback")
                    .font(.headline)
                    .padding(.top, 10)
                
                HStack(spacing: 12) {
                    Text("Hast du Fragen oder Feedback zu Speakwerk?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: "mailto:info@anderzlabs.de?subject=Speakwerk%20Support%20%26%20Feedback") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope")
                            Text("info@anderzlabs.de")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(width: 520, height: 620)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func validateAndAddRule() {
        errorMessage = nil
        let cleanTrigger = newTrigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanReplacement = newReplacement
        
        guard !cleanTrigger.isEmpty else {
            errorMessage = "Das gesprochene Wort darf nicht leer sein."
            return
        }
        
        guard !cleanReplacement.isEmpty else {
            errorMessage = "Der Ersetzungstext darf nicht leer sein."
            return
        }
        
        if dictationManager.dictationRules.contains(where: { $0.trigger == cleanTrigger }) {
            errorMessage = "Dieser Diktierbefehl existiert bereits."
            return
        }
        
        let success = dictationManager.addRule(trigger: cleanTrigger, replacement: cleanReplacement)
        if success {
            newTrigger = ""
            newReplacement = ""
        } else {
            errorMessage = "Fehler beim Hinzufügen der Regel."
        }
    }
}
