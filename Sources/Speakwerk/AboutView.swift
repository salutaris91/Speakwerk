import SwiftUI

public struct AboutView: View {
    public init() {}
    
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // App Logo Header Area
            VStack {
                Spacer()
                if let appIcon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .padding(.bottom, 12)
                } else {
                    // Fallback Emoji if icon loading fails
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Text("🎙️")
                            .font(.system(size: 44))
                    }
                    .padding(.bottom, 12)
                }
                
                Text("Speakwerk")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(versionString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .frame(height: 180)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Info Content
            VStack(spacing: 16) {
                // Privacy Box
                VStack(spacing: 4) {
                    Text("🔒 Datenschutz garantiert")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("100% lokale Transkription auf deiner Apple Neural Engine. Keine Cloud, keine Telemetrie, kein Tracking.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                
                // Links Area
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: {
                            if let url = URL(string: "https://anderzlabs.de/speakwerk/") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Webseite")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            if let url = URL(string: "mailto:info@anderzlabs.de?subject=Speakwerk%20Feedback") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("Support")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if let url = URL(string: "https://github.com/salutaris91/Speakwerk") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("GitHub Repo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            if let url = URL(string: "https://github.com/salutaris91") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.2")
                                Text("Projekte")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(20)
            
            Spacer()
        }
        .frame(width: 380, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
