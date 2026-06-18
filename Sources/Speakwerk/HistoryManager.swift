import Foundation
import os

public struct TranscriptionEntry: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let text: String
    public let modelName: String

    public init(id: UUID = UUID(), timestamp: Date = Date(), text: String, modelName: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.modelName = modelName
    }
}

public actor HistoryManager {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "HistoryManager")
    private let storageURL: URL
    private let maxEntriesLimit: Int
    private var cachedEntries: [TranscriptionEntry]?

    public init(storageURL: URL? = nil, maxEntriesLimit: Int = 500) {
        self.maxEntriesLimit = maxEntriesLimit
        
        if let url = storageURL {
            self.storageURL = url
        } else {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("com.alex.Speakwerk", isDirectory: true)
            
            // Ensure directory exists
            if let dirURL = appSupportURL {
                try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
                self.storageURL = dirURL.appendingPathComponent("history.json")
            } else {
                // Fallback to temp if app support is unavailable
                self.storageURL = fileManager.temporaryDirectory.appendingPathComponent("history.json")
            }
        }
    }

    /// Adds a new entry to the transcription history and saves it.
    @discardableResult
    public func addEntry(text: String, modelName: String) throws -> TranscriptionEntry {
        var entries = try loadEntries()
        
        let newEntry = TranscriptionEntry(text: text, modelName: modelName)
        entries.append(newEntry)
        
        // Enforce limit: remove oldest items if count exceeds limit
        if entries.count > maxEntriesLimit {
            let itemsToRemove = entries.count - maxEntriesLimit
            entries.removeFirst(itemsToRemove)
            logger.info("History limit reached. Removed \(itemsToRemove) oldest entries.")
        }
        
        try saveEntries(entries)
        cachedEntries = entries
        return newEntry
    }

    /// Loads the transcription history.
    public func loadHistory() throws -> [TranscriptionEntry] {
        return try loadEntries()
    }

    /// Clears the transcription history.
    public func clearHistory() throws {
        try saveEntries([])
        cachedEntries = []
    }

    /// Deletes a specific entry from the transcription history by its ID.
    public func deleteEntry(id: UUID) throws {
        var entries = try loadEntries()
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries.remove(at: index)
            try saveEntries(entries)
            cachedEntries = entries
            logger.info("Deleted history entry with ID: \(id)")
        } else {
            logger.warning("History entry with ID: \(id) not found for deletion.")
        }
    }

    // MARK: - Private Helpers

    private func loadEntries() throws -> [TranscriptionEntry] {
        if let cached = cachedEntries {
            return cached
        }

        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            let entries = try decoder.decode([TranscriptionEntry].self, from: data)
            cachedEntries = entries
            return entries
        } catch {
            logger.error("Failed to load or decode history: \(error.localizedDescription)")
            throw error
        }
    }

    private func saveEntries(_ entries: [TranscriptionEntry]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(entries)
            
            let tempURL = storageURL.appendingPathExtension("tmp")
            
            // 1. Write to temporary file
            try data.write(to: tempURL)
            
            // 2. Atomically replace the destination file
            if FileManager.default.fileExists(atPath: storageURL.path) {
                _ = try FileManager.default.replaceItem(
                    at: storageURL,
                    withItemAt: tempURL,
                    backupItemName: nil,
                    options: [],
                    resultingItemURL: nil
                )
            } else {
                try FileManager.default.moveItem(at: tempURL, to: storageURL)
            }
            
            logger.info("History saved atomically to: \(self.storageURL.path)")
        } catch {
            logger.error("Failed to save history atomically: \(error.localizedDescription)")
            throw error
        }
    }
}
