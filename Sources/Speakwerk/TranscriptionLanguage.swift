import Foundation

public enum TranscriptionLanguage: String, CaseIterable, Identifiable, Sendable {
    case auto      // Auto-detect
    case de, en, es, fr, it, pt, nl   // kuratierte Auswahl, erweiterbar

    public var id: String { rawValue }

    /// WhisperKit language code, or nil for auto-detect.
    public var code: String? { self == .auto ? nil : rawValue }

    public var displayName: String {
        switch self {
        case .auto: return "Automatisch erkennen"
        case .de: return "Deutsch"
        case .en: return "Englisch"
        case .es: return "Spanisch"
        case .fr: return "Französisch"
        case .it: return "Italienisch"
        case .pt: return "Portugiesisch"
        case .nl: return "Niederländisch"
        }
    }
}
