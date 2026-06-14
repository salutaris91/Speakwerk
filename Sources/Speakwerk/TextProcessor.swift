import Foundation

/// Utility to process transcription text and apply dictation rules.
public enum TextProcessor {
    
    /// Processes the input text by applying enabled dictation rules and cleaning up typography spacing.
    ///
    /// - Parameters:
    ///   - text: The raw transcribed text.
    ///   - rules: The list of dictation replacement rules.
    /// - Returns: The formatted text with replacements and spacing corrections applied.
    public static func process(_ text: String, with rules: [DictationRule]) -> String {
        var processedText = text
        
        // Filter active rules and sort by trigger length descending to process longer matches first
        let activeRules = rules
            .filter { $0.isEnabled }
            .sorted { $0.trigger.count > $1.trigger.count }
        
        for rule in activeRules {
            do {
                // Escape special characters in the trigger to ensure valid regex syntax
                let escapedTrigger = NSRegularExpression.escapedPattern(for: rule.trigger)
                
                // Use word boundary matches (\b) to avoid replacing partial words
                let pattern = "\\b\(escapedTrigger)\\b"
                let regex = try Regex(pattern).ignoresCase()
                
                processedText = processedText.replacing(regex, with: rule.replacement)
            } catch {
                // Fallback in case of regex initialization failure
                continue
            }
        }
        
        // Apply typographic spacing corrections
        processedText = cleanUpWhitespace(processedText)
        
        return processedText
    }
    
    /// Represents a declarative typography cleanup rule.
    private struct TypographyRule: Sendable {
        let name: String
        let pattern: String
        let replacement: @Sendable (Regex<AnyRegexOutput>.Match) -> String
    }
    
    private static let typographyRules: [TypographyRule] = [
        // 1. Remove space before punctuation: . , ? ! : ; ) ] }
        TypographyRule(name: "Remove space before punctuation", pattern: "\\s+([.,!?:;\\]\\}\\)])") { match in
            let punctuation = match.output[1].substring ?? ""
            return String(punctuation)
        },
        
        // 2. Remove space after opening parenthesis: ( [ {
        TypographyRule(name: "Remove space after opening parenthesis", pattern: "([\\(\\[\\{])\\s+") { match in
            let paren = match.output[1].substring ?? ""
            return String(paren)
        },
        
        // 3. Remove punctuation (comma, colon, semicolon) right after opening parenthesis
        TypographyRule(name: "Remove punctuation right after opening parenthesis", pattern: "([\\(\\[\\{])\\s*[,;:]\\s*") { match in
            let paren = match.output[1].substring ?? ""
            return String(paren)
        },
        
        // 4. Remove comma/colon/semicolon right before closing parenthesis
        TypographyRule(name: "Remove punctuation right before closing parenthesis", pattern: "\\s*[,;:]\\s*([\\)\\]\\}])") { match in
            let paren = match.output[1].substring ?? ""
            return String(paren)
        },
        
        // 5. Remove space after opening quote: " Hello -> "Hello
        TypographyRule(name: "Remove space after opening quote", pattern: "([\"“”„«»])\\s+(\\w)") { match in
            let quote = match.output[1].substring ?? ""
            let wordChar = match.output[2].substring ?? ""
            return String(quote) + String(wordChar)
        },
        
        // 6. Remove space before closing quote: Hello " -> Hello"
        TypographyRule(name: "Remove space before closing quote", pattern: "(\\w)\\s+([\"“”„«»])") { match in
            let wordChar = match.output[1].substring ?? ""
            let quote = match.output[2].substring ?? ""
            return String(wordChar) + String(quote)
        },
        
        // 7. Remove comma before opening parenthesis/bracket, absorbing surrounding spaces
        TypographyRule(name: "Remove comma before opening bracket", pattern: "\\s*,\\s*([\\(\\[\\{])") { match in
            let paren = match.output[1].substring ?? ""
            return " " + String(paren)
        }
    ]

    /// Cleans up typical Whisper whitespace anomalies around punctuation, parentheses, and quotes.
    private static func cleanUpWhitespace(_ text: String) -> String {
        var result = text
        
        for rule in typographyRules {
            do {
                let regex = try Regex(rule.pattern)
                result = result.replacing(regex, with: rule.replacement)
            } catch {
                continue
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
