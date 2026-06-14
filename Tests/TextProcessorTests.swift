import XCTest
@testable import Speakwerk

final class TextProcessorTests: XCTestCase {
    
    // Test base dictation commands replacement
    func testBaseDictationCommands() {
        let rules = [
            DictationRule(trigger: "punkt", replacement: "."),
            DictationRule(trigger: "komma", replacement: ","),
            DictationRule(trigger: "fragezeichen", replacement: "?"),
            DictationRule(trigger: "ausrufezeichen", replacement: "!"),
            DictationRule(trigger: "neue zeile", replacement: "\n"),
            DictationRule(trigger: "neuer absatz", replacement: "\n\n")
        ]
        
        let rawText = "Das ist ein Test punkt Wie geht es dir fragezeichen Neue zeile Weiter im Text"
        let expectedText = "Das ist ein Test. Wie geht es dir?\nWeiter im Text"
        
        let result = TextProcessor.process(rawText, with: rules)
        XCTAssertEqual(result, expectedText)
    }
    
    // Test that subwords are not incorrectly replaced
    func testWordBoundaries() {
        let rules = [
            DictationRule(trigger: "punkt", replacement: ".")
        ]
        
        // "Punktlandung" contains "Punkt" but should NOT be replaced.
        // "Kommafehler" contains "Komma" but should NOT be replaced.
        let rawText = "Das war eine Punktlandung und kein Punkt"
        let expectedText = "Das war eine Punktlandung und kein."
        
        let result = TextProcessor.process(rawText, with: rules)
        XCTAssertEqual(result, expectedText)
    }
    
    // Test that longer trigger phrases are replaced before shorter ones
    func testTriggerLengthSorting() {
        let rules = [
            DictationRule(trigger: "zeile", replacement: "LINE"),
            DictationRule(trigger: "neue zeile", replacement: "\n")
        ]
        
        let rawText = "Das ist eine neue zeile"
        let expectedText = "Das ist eine\n"
        
        let result = TextProcessor.process(rawText, with: rules)
        XCTAssertEqual(result, expectedText)
    }
    
    // Test case insensitivity of triggers
    func testCaseInsensitivity() {
        let rules = [
            DictationRule(trigger: "PUNKT", replacement: ".")
        ]
        
        let rawText = "Hallo punkt Hallo PUNKT Hallo Punkt"
        let expectedText = "Hallo. Hallo. Hallo."
        
        let result = TextProcessor.process(rawText, with: rules)
        XCTAssertEqual(result, expectedText)
    }
    
    // Test whitespace cleanup around punctuation and parentheses
    func testWhitespaceCleanup() {
        let rules: [DictationRule] = [] // No replacement rules, just testing formatting
        
        // Spaces before punctuation should be stripped
        XCTAssertEqual(TextProcessor.process("Hallo .", with: rules), "Hallo.")
        XCTAssertEqual(TextProcessor.process("Test ,", with: rules), "Test,")
        XCTAssertEqual(TextProcessor.process("Was ? !", with: rules), "Was?!")
        XCTAssertEqual(TextProcessor.process("Text : weiter", with: rules), "Text: weiter")
        
        // Spaces inside parentheses should be stripped
        XCTAssertEqual(TextProcessor.process("( Hallo welt )", with: rules), "(Hallo welt)")
        XCTAssertEqual(TextProcessor.process("[ Hallo welt ]", with: rules), "[Hallo welt]")
        XCTAssertEqual(TextProcessor.process("{ Hallo welt }", with: rules), "{Hallo welt}")
        
        // Punctuation directly after opening or before closing parentheses should be stripped
        XCTAssertEqual(TextProcessor.process("(, wirklich sehr, )", with: rules), "(wirklich sehr)")
        XCTAssertEqual(TextProcessor.process("[; wirklich sehr; ]", with: rules), "[wirklich sehr]")
        
        // Spacing inside double quotes and smart quotes
        XCTAssertEqual(TextProcessor.process("Er sagte \" Hallo \" zu mir", with: rules), "Er sagte \"Hallo\" zu mir")
        XCTAssertEqual(TextProcessor.process("Sie sagte „ Hallo “ zu mir", with: rules), "Sie sagte „Hallo“ zu mir")
        XCTAssertEqual(TextProcessor.process("Oder auch « Hallo »", with: rules), "Oder auch «Hallo»")
        
        // Test comma before opening parenthesis (absorbing surrounding spaces)
        XCTAssertEqual(TextProcessor.process("Test, (", with: rules), "Test (")
        XCTAssertEqual(TextProcessor.process("Test ,(", with: rules), "Test (")
        XCTAssertEqual(TextProcessor.process("Test,(", with: rules), "Test (")
        XCTAssertEqual(TextProcessor.process("Test,  (", with: rules), "Test (")
        XCTAssertEqual(TextProcessor.process("Test, [", with: rules), "Test [")
        XCTAssertEqual(TextProcessor.process("Test ,{", with: rules), "Test {")
    }
    
    // Test DictationManager logic
    @MainActor
    func testDictationManagerRules() {
        let manager = DictationManager.shared
        
        // Reset to default rules
        manager.dictationRules = DictationManager.defaultRules
        XCTAssertEqual(manager.dictationRules.count, DictationManager.defaultRules.count)
        
        // Check uniqueness constraint
        let initialCount = manager.dictationRules.count
        let addedDuplicate = manager.addRule(trigger: "punkt", replacement: "X")
        XCTAssertFalse(addedDuplicate, "Duplicate trigger should not be added")
        XCTAssertEqual(manager.dictationRules.count, initialCount)
        
        // Add valid rule
        let addedNew = manager.addRule(trigger: "smiley", replacement: ":-)")
        XCTAssertTrue(addedNew, "Unique trigger should be added successfully")
        XCTAssertEqual(manager.dictationRules.count, initialCount + 1)
        
        // Verify whitespace normalization of trigger
        XCTAssertTrue(manager.dictationRules.contains(where: { $0.trigger == "smiley" }))
        
        // Test invalid empty triggers
        XCTAssertFalse(manager.addRule(trigger: "   ", replacement: "X"))
        XCTAssertFalse(manager.addRule(trigger: "", replacement: "X"))
        
        // Remove rule
        if let ruleToRemove = manager.dictationRules.first(where: { $0.trigger == "smiley" }) {
            manager.removeRule(id: ruleToRemove.id)
            XCTAssertFalse(manager.dictationRules.contains(where: { $0.trigger == "smiley" }))
        } else {
            XCTFail("Rule to remove not found")
        }
    }
}
