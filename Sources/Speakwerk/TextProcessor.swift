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
    
    /// Cleans up typical Whisper whitespace anomalies around punctuation, parentheses, and quotes.
    private static func cleanUpWhitespace(_ text: String) -> String {
        var result = text
        
        // 1. Remove space before punctuation: . , ? ! : ; )
        // Example: "Hello ." -> "Hello."
        do {
            let spaceBeforePunctuation = try Regex("\\s+([.,!?:;)])")
            result = result.replacing(spaceBeforePunctuation, with: { match in
                let punctuation = match.output[1].substring ?? ""
                return String(punctuation)
            })
        } catch {}
        
        // 2. Remove space after opening parenthesis: (
        // Example: "( Hello" -> "(Hello"
        do {
            let spaceAfterParen = try Regex("(\\()\\s+")
            result = result.replacing(spaceAfterParen, with: { match in
                let paren = match.output[1].substring ?? ""
                return String(paren)
            })
        } catch {}
        
        // 3. Remove spacing inside quotes: "
        // Remove space after opening quote: " Hello -> "Hello
        do {
            let spaceAfterQuote = try Regex("\"\\s+(\\w)")
            result = result.replacing(spaceAfterQuote, with: { match in
                let wordChar = match.output[1].substring ?? ""
                return "\"" + String(wordChar)
            })
        } catch {}
        
        // Remove space before closing quote: Hello " -> Hello"
        do {
            let spaceBeforeQuote = try Regex("(\\w)\\s+\"")
            result = result.replacing(spaceBeforeQuote, with: { match in
                let wordChar = match.output[1].substring ?? ""
                return String(wordChar) + "\""
            })
        } catch {}
        
        return result
    }
}
