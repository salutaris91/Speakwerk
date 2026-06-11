import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
    @State private var modelManager = ModelManager.shared

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
        .frame(width: 480, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
