import Foundation
import Observation
import WhisperKit
import os

public enum ModelTier: String, CaseIterable, Sendable, Identifiable {
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case largeV3Turbo = "openai_whisper-large-v3_turbo"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .base: return "Schnell"
        case .small: return "Ausgewogen"
        case .largeV3Turbo: return "Genau"
        }
    }
    
    public var sizeDescription: String {
        switch self {
        case .base: return "~150 MB"
        case .small: return "~500 MB"
        case .largeV3Turbo: return "~1,5 GB"
        }
    }
}

public enum DownloadState: Equatable {
    case idle
    case downloading(progress: Double)
    case completed
    case failed(String)
}

@MainActor
@Observable
public class ModelManager {
    public static let shared = ModelManager()
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "ModelManager")
    
    public var downloadState: DownloadState = .idle
    public var onProgressUpdate: (@MainActor @Sendable (Double) -> Void)?
    
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard
    
    private let downloadedModelsKey = "downloadedModels"
    private let selectedModelKey = "selectedModel"
    private let selectedLanguageKey = "selectedLanguage"
    
    public var selectedModel: ModelTier = .base {
        didSet {
            defaults.set(selectedModel.rawValue, forKey: selectedModelKey)
            logger.info("Selected model changed to: \(self.selectedModel.rawValue)")
        }
    }
    
    public var selectedLanguage: TranscriptionLanguage = .auto {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: selectedLanguageKey)
            logger.info("Selected language changed to: \(self.selectedLanguage.rawValue)")
        }
    }
    
    private init() {
        let rawModel = UserDefaults.standard.string(forKey: "selectedModel") ?? ""
        if let tier = ModelTier(rawValue: rawModel) {
            self.selectedModel = tier
        }
        
        let rawLang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
        if let lang = TranscriptionLanguage(rawValue: rawLang) {
            self.selectedLanguage = lang
        }
        
        migrateLegacyPaths()
    }
    
    public var downloadedModels: [String: String] {
        get {
            return defaults.dictionary(forKey: downloadedModelsKey) as? [String: String] ?? [:]
        }
        set {
            defaults.set(newValue, forKey: downloadedModelsKey)
        }
    }
    
    /// The local folder where WhisperKit models are stored
    public var modelsDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let modelsDir = appSupport.appendingPathComponent("com.alex.Speakwerk/Models", isDirectory: true)
        try? fileManager.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }
    
    private func resolvedModelFolder(for tier: ModelTier) -> URL? {
        guard let storedValue = downloadedModels[tier.rawValue],
              storedValue.hasPrefix("/") else {
            return nil
        }
        
        let folderURL = URL(fileURLWithPath: storedValue, isDirectory: true)
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
            if let files = try? fileManager.contentsOfDirectory(atPath: folderURL.path), !files.isEmpty {
                return folderURL
            }
        }
        
        return nil
    }
    
    /// Migrates any legacy relative paths in downloadedModels to absolute paths by performing a one-time recursive search.
    public func migrateLegacyPaths() {
        var updated = false
        var currentDownloaded = downloadedModels
        
        for tier in ModelTier.allCases {
            guard let storedValue = currentDownloaded[tier.rawValue] else {
                continue
            }
            
            // If it is already an absolute path and exists, no migration needed
            if storedValue.hasPrefix("/") {
                let folderURL = URL(fileURLWithPath: storedValue, isDirectory: true)
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
                    if let files = try? fileManager.contentsOfDirectory(atPath: folderURL.path), !files.isEmpty {
                        continue
                    }
                }
            }
            
            // Otherwise (relative leaf name or invalid path), search recursively once
            logger.info("Migrating legacy path for tier: \(tier.rawValue) (stored: \(storedValue))")
            
            let keys: [URLResourceKey] = [.isDirectoryKey]
            guard let enumerator = fileManager.enumerator(
                at: modelsDirectoryURL,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else {
                continue
            }
            
            var found = false
            for case let url as URL in enumerator {
                guard let resourceValues = try? url.resourceValues(forKeys: Set(keys)),
                      let isDirectory = resourceValues.isDirectory,
                      isDirectory else {
                    continue
                }
                
                if url.lastPathComponent == tier.rawValue {
                    if let files = try? fileManager.contentsOfDirectory(atPath: url.path), !files.isEmpty {
                        currentDownloaded[tier.rawValue] = url.path
                        updated = true
                        found = true
                        logger.info("Successfully migrated \(tier.rawValue) to absolute path: \(url.path)")
                        break
                    }
                }
            }
            
            if !found {
                // If the folder was not found, clear the invalid legacy entry to prevent future tree walks
                currentDownloaded.removeValue(forKey: tier.rawValue)
                updated = true
                logger.warning("Cleared invalid legacy path for \(tier.rawValue) as no matching folder was found.")
            }
        }
        
        if updated {
            downloadedModels = currentDownloaded
        }
    }
    
    public func isModelDownloaded(tier: ModelTier) -> Bool {
        return resolvedModelFolder(for: tier) != nil
    }
    
    public func downloadModel(tier: ModelTier) async throws {
        if case .downloading = downloadState {
            logger.warning("Download already in progress.")
            return
        }
        
        downloadState = .downloading(progress: 0.0)
        logger.info("Starting download for model variant: \(tier.rawValue)")
        
        do {
            let modelsDir = modelsDirectoryURL
            
            // WhisperKit.download returns the URL of the downloaded model folder
            let downloadedFolderURL = try await WhisperKit.download(
                variant: tier.rawValue,
                downloadBase: modelsDir,
                useBackgroundSession: false,
                progressCallback: { progress in
                    Task { @MainActor in
                        let fraction = progress.fractionCompleted
                        ModelManager.shared.downloadState = .downloading(progress: fraction)
                        ModelManager.shared.logger.debug("Download progress: \(fraction * 100)%")
                        
                        ModelManager.shared.onProgressUpdate?(fraction)
                    }
                }
            )
            
            // Persist the association between the tier and the local folder absolute path
            let folderPath = downloadedFolderURL.path
            var currentDownloaded = downloadedModels
            currentDownloaded[tier.rawValue] = folderPath
            downloadedModels = currentDownloaded
            
            downloadState = .completed
            logger.info("Successfully downloaded \(tier.rawValue) to \(downloadedFolderURL.path)")
            
        } catch {
            let errorMsg = error.localizedDescription
            downloadState = .failed(errorMsg)
            logger.error("Failed to download model \(tier.rawValue): \(errorMsg)")
            throw error
        }
    }
    
    /// Returns the absolute local URL for the downloaded model folder, if it exists
    public func modelFolderURL(for tier: ModelTier) -> URL? {
        return resolvedModelFolder(for: tier)
    }
    
    /// Ensures selectedModel points to a model that is actually available on disk.
    /// Falls back to any downloaded model. Returns false if none is available.
    public func reconcileSelectedModel() -> Bool {
        // 1. If currently selected model is already downloaded, it's valid
        if isModelDownloaded(tier: selectedModel) {
            return true
        }
        
        // 2. Otherwise, check all cases and fall back to the first one available
        for tier in ModelTier.allCases {
            if isModelDownloaded(tier: tier) {
                selectedModel = tier
                logger.info("Reconciled selected model: fell back to \(tier.rawValue)")
                return true
            }
        }
        
        // 3. No downloaded model is available
        logger.warning("Reconcile failed: no models are downloaded on disk.")
        return false
    }
    
    public func resetDownloadState() {
        downloadState = .idle
    }
}
