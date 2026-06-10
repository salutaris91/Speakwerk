import SwiftUI
import AVFoundation
import ApplicationServices
import WhisperKit
import KeyboardShortcuts

public enum OnboardingStep {
    case welcome
    case downloading
    case permissions
    case hotkeyInfo
}

public enum OnboardingViewMode {
    case fullOnboarding
    case downloadOnly(ModelTier)
}

@MainActor
@Observable
class OnboardingState {
    var currentStep: OnboardingStep = .welcome
    var selectedTier: ModelTier = .small
    var micGranted: Bool = false
    var accessibilityGranted: Bool = false
    var micStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    var progressTimer: Timer?
    
    init() {
        checkPermissions()
        
        // Start polling for permissions changes while on the permissions screen
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.checkPermissions()
            }
        }
    }
    
    func invalidate() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func checkPermissions() {
        // Microphone check
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        micGranted = (status == .authorized)
        
        // Accessibility check
        accessibilityGranted = AXIsProcessTrusted()
    }
    
    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            Task { @MainActor in
                self.micGranted = granted
            }
        }
    }
    
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") ?? 
                  URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
        NSWorkspace.shared.open(url)
    }
    
    func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") ?? 
                  URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
        NSWorkspace.shared.open(url)
    }
}

public struct OnboardingView: View {
    let mode: OnboardingViewMode
    let onCompletion: () -> Void
    let onCancel: (() -> Void)?
    
    @State private var state = OnboardingState()
    @State private var modelManager = ModelManager.shared
    
    public init(mode: OnboardingViewMode, onCompletion: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.mode = mode
        self.onCompletion = onCompletion
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("Speakwerk")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Spacer()
                if case .downloadOnly = mode {
                    Button("Abbrechen") {
                        onCancel?()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            VStack {
                switch mode {
                case .fullOnboarding:
                    switch state.currentStep {
                    case .welcome:
                        welcomeStep
                    case .downloading:
                        downloadStep(tier: state.selectedTier)
                    case .permissions:
                        permissionsStep
                    case .hotkeyInfo:
                        hotkeyInfoStep
                    }
                case .downloadOnly(let tier):
                    downloadStep(tier: tier)
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 540)
        .onAppear {
            if case .downloadOnly(let tier) = mode {
                // Instantly trigger download
                triggerDownload(for: tier)
            }
        }
        .onDisappear {
            state.invalidate()
        }
    }
    
    // MARK: - Welcome / Selection Step
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("Willkommen bei Speakwerk")
                .font(.title)
                .bold()
            
            Text("Wähle das Whisper-Modell für deine Transkriptionen. Modelle laufen zu 100% lokal auf deiner Apple Neural Engine.")
                .font(.body)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(ModelTier.allCases) { tier in
                    Button(action: {
                        state.selectedTier = tier
                    }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(tier.displayName)
                                        .font(.headline)
                                    if tier == .small {
                                        Text("Empfohlen")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.3))
                                            .foregroundStyle(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(sizeDescription(for: tier))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if state.selectedTier == tier {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(state.selectedTier == tier ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(state.selectedTier == tier ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            Button(action: {
                triggerDownload(for: state.selectedTier)
            }) {
                Text("Modell herunterladen & Weiter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Download Step
    
    private func downloadStep(tier: ModelTier) -> some View {
        VStack(spacing: 25) {
            Spacer()
            
            Text("Lade Modell herunter...")
                .font(.title2)
                .bold()
            
            Text(tier.displayName)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            switch modelManager.downloadState {
            case .idle:
                ProgressView()
                    .progressViewStyle(.circular)
            case .downloading(let progress):
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                    
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.body)
                            .bold()
                        Spacer()
                        Text("Herunterladen von Hugging Face...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 40)
            case .completed:
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    Text("Download abgeschlossen!")
                        .font(.headline)
                }
                .onAppear {
                    // Automatically move forward after a delay in onboarding
                    if case .fullOnboarding = mode {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            modelManager.resetDownloadState()
                            state.currentStep = .permissions
                        }
                    } else {
                        // In download-only mode, complete immediately
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            modelManager.selectedModel = tier
                            modelManager.resetDownloadState()
                            onCompletion()
                        }
                    }
                }
            case .failed(let errorMsg):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    Text("Download fehlgeschlagen")
                        .font(.headline)
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Erneut versuchen") {
                        triggerDownload(for: tier)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Permissions Step
    
    private var permissionsStep: some View {
        VStack(spacing: 20) {
            Text("Systemberechtigungen")
                .font(.title)
                .bold()
            
            Text("Speakwerk benötigt folgende Berechtigungen, um Audio aufzunehmen und Text an der Cursorposition einzufügen.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Microphone row
                HStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundStyle(state.micGranted ? .green : .blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mikrofon-Zugriff")
                            .font(.headline)
                        Text("Wird benötigt, um Audio für die Transkription aufzunehmen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if state.micGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    } else {
                        if state.micStatus == .notDetermined {
                            Button("Freigeben") {
                                state.requestMicrophone()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Einstellungen öffnen") {
                                state.openMicrophoneSettings()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.05)))
                
                // Accessibility row
                HStack(spacing: 16) {
                    Image(systemName: "keyboard.fill")
                        .font(.title2)
                        .foregroundStyle(state.accessibilityGranted ? .green : .blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bedienungshilfen")
                            .font(.headline)
                        Text("Wird benötigt, um transkribierten Text per Tastatur-Simulation einzufügen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if state.accessibilityGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    } else {
                        Button("Einstellungen öffnen") {
                            state.openAccessibilitySettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.05)))
            }
            .padding(.vertical, 10)
            
            Spacer()
            
            Button(action: {
                if state.micGranted && state.accessibilityGranted {
                    state.currentStep = .hotkeyInfo
                }
            }) {
                Text("Weiter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(state.micGranted && state.accessibilityGranted ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(!state.micGranted || !state.accessibilityGranted)
        }
    }
    
    // MARK: - Hotkey / Info Step
    
    private var hotkeyInfoStep: some View {
        VStack(spacing: 25) {
            Text("Alles bereit!")
                .font(.title)
                .bold()
            
            Text("Lege dein Tastenkürzel fest, um die Aufnahme von überall zu starten und stoppen:")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Key recorder
            KeyboardShortcuts.Recorder("Tastatur-Kurzbefehl:", name: .toggleRecording)
                .padding(.vertical, 15)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "1.circle.fill").foregroundStyle(.blue)
                    Text("Drücke deinen definierten Shortcut zum Starten (Menüleiste wechselt auf 🔴 [REC]).")
                }
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "2.circle.fill").foregroundStyle(.blue)
                    Text("Sprich deinen Text ein (das Mikrofon zeichnet auf).")
                }
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "3.circle.fill").foregroundStyle(.blue)
                    Text("Drücke den Shortcut erneut. Der Text wird automatisch transkribiert und an deiner Cursorposition eingefügt.")
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                modelManager.selectedModel = state.selectedTier
                onCompletion()
            }) {
                Text("Onboarding abschließen")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func triggerDownload(for tier: ModelTier) {
        modelManager.resetDownloadState()
        if case .fullOnboarding = mode {
            state.currentStep = .downloading
        }
        
        Task {
            do {
                try await modelManager.downloadModel(tier: tier)
            } catch {
                // State is handled in ModelManager
            }
        }
    }
    
    private func sizeDescription(for tier: ModelTier) -> String {
        switch tier {
        case .base:
            return "Schnell (\(tier.sizeDescription)) - Geringe Latenz, ideal für schnelle Notizen"
        case .small:
            return "Ausgewogen (\(tier.sizeDescription)) - Gute Balance aus Geschwindigkeit und Genauigkeit"
        case .largeV3Turbo:
            return "Genau (\(tier.sizeDescription)) - Höchste Qualität, benötigt die meisten Ressourcen"
        }
    }
}
