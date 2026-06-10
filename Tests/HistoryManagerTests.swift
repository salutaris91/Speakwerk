import XCTest
@testable import Speakwerk

final class HistoryManagerTests: XCTestCase {
    var tempDirectory: URL!
    var testFileURL: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        testFileURL = tempDirectory.appendingPathComponent("test_history.json")
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testAddAndLoadHistory() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 5)
        
        let entry1 = try await manager.addEntry(text: "Hello world", modelName: "test-model")
        XCTAssertEqual(entry1.text, "Hello world")
        XCTAssertEqual(entry1.modelName, "test-model")
        
        let entry2 = try await manager.addEntry(text: "Second transcription", modelName: "test-model-2")
        
        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].id, entry1.id)
        XCTAssertEqual(history[1].id, entry2.id)
    }
    
    func testMaxLimitEnforcement() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 3)
        
        _ = try await manager.addEntry(text: "Entry 1", modelName: "model")
        _ = try await manager.addEntry(text: "Entry 2", modelName: "model")
        _ = try await manager.addEntry(text: "Entry 3", modelName: "model")
        
        // This should push Entry 1 out
        _ = try await manager.addEntry(text: "Entry 4", modelName: "model")
        
        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].text, "Entry 2")
        XCTAssertEqual(history[1].text, "Entry 3")
        XCTAssertEqual(history[2].text, "Entry 4")
    }
    
    func testAtomicSaving() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 5)
        _ = try await manager.addEntry(text: "Atomic Test", modelName: "model")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
        
        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.text, "Atomic Test")
    }
}
