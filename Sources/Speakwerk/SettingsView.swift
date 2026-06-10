import SwiftUI
import KeyboardShortcuts

public struct SettingsView: View {
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
                
                HStack {
                    KeyboardShortcuts.Recorder("Aufnahme starten/stoppen:", name: .toggleRecording)
                    Spacer()
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
        .frame(width: 480, height: 220)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
