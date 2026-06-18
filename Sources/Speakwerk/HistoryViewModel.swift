import Foundation
import Observation
import os

@MainActor
@Observable
public final class HistoryViewModel {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "HistoryViewModel")
    
    public var entries: [TranscriptionEntry] = []
    public var searchText: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let historyManager: HistoryManager
    private let onChanged: @MainActor @Sendable () -> Void
    
    public init(historyManager: HistoryManager, onChanged: @escaping @MainActor @Sendable () -> Void) {
        self.historyManager = historyManager
        self.onChanged = onChanged
    }
    
    /// Filters entries based on the searchText property.
    public var filteredEntries: [TranscriptionEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// Loads history from HistoryManager and updates the local state (newest first).
    public func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await historyManager.loadHistory()
            // Chronologically stored old-to-new -> reverse to show newest first
            self.entries = loaded.reversed()
        } catch {
            logger.error("Failed to load history: \(error.localizedDescription)")
            errorMessage = "Verlauf konnte nicht geladen werden."
        }
        isLoading = false
    }
    
    /// Deletes a specific entry by its ID and refreshes the view.
    public func delete(id: UUID) async {
        errorMessage = nil
        do {
            try await historyManager.deleteEntry(id: id)
            // Update local state directly
            entries.removeAll(where: { $0.id == id })
            onChanged()
        } catch {
            logger.error("Failed to delete entry \(id): \(error.localizedDescription)")
            errorMessage = "Eintrag konnte nicht gelöscht werden."
        }
    }
    
    /// Clears all entries and refreshes the view.
    public func clear() async {
        errorMessage = nil
        do {
            try await historyManager.clearHistory()
            entries = []
            onChanged()
        } catch {
            logger.error("Failed to clear history: \(error.localizedDescription)")
            errorMessage = "Verlauf konnte nicht geleert werden."
        }
    }
    
    /// Copies text to clipboard using ClipboardManager.
    public func copy(text: String) {
        ClipboardManager.shared.copyToClipboard(text)
    }
}
