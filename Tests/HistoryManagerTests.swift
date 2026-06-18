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
        _ = try await manager.addEntry(text: "Atomic Test Original", modelName: "model")

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

        // Remove write permissions from directory to simulate system/permission failure during write
        try? FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: tempDirectory.path)

        do {
            _ = try await manager.addEntry(text: "Atomic Test Failed Attempt", modelName: "model")
            XCTFail("Should have failed to write due to read-only directory")
        } catch {
            // Expected error
        }

        // Restore write permissions for cleanup
        try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: tempDirectory.path)

        // Verify original data is still intact and readable
        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.text, "Atomic Test Original")
    }

    func testDeleteEntry() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 5)

        let entry1 = try await manager.addEntry(text: "Entry 1", modelName: "model")
        let entry2 = try await manager.addEntry(text: "Entry 2", modelName: "model")
        let entry3 = try await manager.addEntry(text: "Entry 3", modelName: "model")

        // Delete the middle entry
        try await manager.deleteEntry(id: entry2.id)

        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].id, entry1.id)
        XCTAssertEqual(history[1].id, entry3.id)

        // Delete a non-existent UUID (should not throw, just warn)
        try await manager.deleteEntry(id: UUID())
        let historyAfterNonExistentDelete = try await manager.loadHistory()
        XCTAssertEqual(historyAfterNonExistentDelete.count, 2)
    }

    func testClearHistory() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 5)

        _ = try await manager.addEntry(text: "Entry 1", modelName: "model")
        _ = try await manager.addEntry(text: "Entry 2", modelName: "model")

        try await manager.clearHistory()

        let history = try await manager.loadHistory()
        XCTAssertTrue(history.isEmpty)
    }

    func testRecentEntriesSuffixAndOrdering() async throws {
        let manager = HistoryManager(storageURL: testFileURL, maxEntriesLimit: 10)

        for i in 1...6 {
            _ = try await manager.addEntry(text: "Entry \(i)", modelName: "model")
        }

        let history = try await manager.loadHistory()
        XCTAssertEqual(history.count, 6)

        // Mimic recentEntries fetch: suffix(5) reversed
        let recent = Array(history.suffix(5).reversed())
        XCTAssertEqual(recent.count, 5)
        XCTAssertEqual(recent[0].text, "Entry 6")
        XCTAssertEqual(recent[1].text, "Entry 5")
        XCTAssertEqual(recent[2].text, "Entry 4")
        XCTAssertEqual(recent[3].text, "Entry 3")
        XCTAssertEqual(recent[4].text, "Entry 2")
    }
}
