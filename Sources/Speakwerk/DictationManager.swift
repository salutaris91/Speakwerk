import Foundation
import Observation
import os

/// Represents a single customizable dictation replacement rule.
public struct DictationRule: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var trigger: String       // The spoken word (e.g. "punkt")
    public var replacement: String   // The replacement character/string (e.g. ".")
    public var isEnabled: Bool       // Flag to toggle individual rule activation
    
    public init(id: UUID = UUID(), trigger: String, replacement: String, isEnabled: Bool = true) {
        self.id = id
        self.trigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.replacement = replacement
        self.isEnabled = isEnabled
    }
}

/// Manages dictation rules and settings persistence.
@MainActor
@Observable
public class DictationManager {
    public static let shared = DictationManager()
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "DictationManager")
    private let defaults = UserDefaults.standard
    
    private let dictationRulesKey = "dictationRules"
    private let dictationCommandsEnabledKey = "dictationCommandsEnabled"
    
    /// Global toggle to enable or disable all dictation replacements.
    public var dictationCommandsEnabled: Bool {
        didSet {
            defaults.set(dictationCommandsEnabled, forKey: dictationCommandsEnabledKey)
            logger.info("Dictation commands enabled changed to: \(self.dictationCommandsEnabled)")
        }
    }
    
    /// Persistent list of dictation replacement rules.
    public var dictationRules: [DictationRule] = [] {
        didSet {
            saveRules()
        }
    }
    
    private init() {
        self.dictationCommandsEnabled = UserDefaults.standard.object(forKey: dictationCommandsEnabledKey) as? Bool ?? true
        loadRules()
    }
    
    private func loadRules() {
        if let data = defaults.data(forKey: dictationRulesKey),
           let rules = try? JSONDecoder().decode([DictationRule].self, from: data) {
            self.dictationRules = rules
            logger.info("Loaded \(rules.count) dictation rules from UserDefaults.")
        } else {
            self.dictationRules = Self.defaultRules
            logger.info("No saved dictation rules found. Loaded default rules.")
        }
    }
    
    private func saveRules() {
        do {
            let data = try JSONEncoder().encode(dictationRules)
            defaults.set(data, forKey: dictationRulesKey)
            logger.info("Saved \(self.dictationRules.count) dictation rules to UserDefaults.")
        } catch {
            logger.error("Failed to encode dictation rules: \(error.localizedDescription)")
        }
    }
    
    /// Adds a new rule. Returns false if the trigger already exists (case-insensitive) or is empty.
    @discardableResult
    public func addRule(trigger: String, replacement: String) -> Bool {
        let cleanTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanTrigger.isEmpty else {
            logger.warning("Attempted to add an empty trigger.")
            return false
        }
        
        // Prevent duplicate trigger entries
        if dictationRules.contains(where: { $0.trigger == cleanTrigger }) {
            logger.warning("Attempted to add duplicate trigger: \(cleanTrigger)")
            return false
        }
        
        let newRule = DictationRule(trigger: cleanTrigger, replacement: replacement)
        dictationRules.append(newRule)
        return true
    }
    
    /// Removes a rule by its ID.
    public func removeRule(id: UUID) {
        dictationRules.removeAll(where: { $0.id == id })
    }
    
    /// Default dictation commands set.
    public static let defaultRules: [DictationRule] = [
        DictationRule(trigger: "punkt", replacement: "."),
        DictationRule(trigger: "komma", replacement: ","),
        DictationRule(trigger: "fragezeichen", replacement: "?"),
        DictationRule(trigger: "ausrufezeichen", replacement: "!"),
        DictationRule(trigger: "doppelpunkt", replacement: ":"),
        DictationRule(trigger: "semikolon", replacement: ";"),
        DictationRule(trigger: "bindestrich", replacement: "-"),
        DictationRule(trigger: "klammer auf", replacement: "("),
        DictationRule(trigger: "klammer zu", replacement: ")"),
        DictationRule(trigger: "anführungszeichen", replacement: "\""),
        DictationRule(trigger: "neue zeile", replacement: "\n"),
        DictationRule(trigger: "neuer absatz", replacement: "\n\n")
    ]
}
