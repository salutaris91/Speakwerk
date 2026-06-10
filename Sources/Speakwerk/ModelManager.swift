import Foundation
import AppKit
import Observation
import WhisperKit
import os

public enum ModelTier: String, CaseIterable, Sendable, Identifiable {
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case largeV3Turbo = "openai_whisper-large-v3-turbo"
    
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
    
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard
    
    private let downloadedModelsKey = "downloadedModels"
    private let selectedModelKey = "selectedModel"
    
    public var selectedModel: ModelTier {
        get {
            guard let raw = defaults.string(forKey: selectedModelKey),
                  let tier = ModelTier(rawValue: raw) else {
                return .base
            }
            return tier
        }
        set {
            defaults.set(newValue.rawValue, forKey: selectedModelKey)
            logger.info("Selected model changed to: \(newValue.rawValue)")
        }
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
    
    public func isModelDownloaded(tier: ModelTier) -> Bool {
        guard let folderName = downloadedModels[tier.rawValue] else {
            return false
        }
        let folderURL = modelsDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
        
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
            if let files = try? fileManager.contentsOfDirectory(atPath: folderURL.path), !files.isEmpty {
                return true
            }
        }
        return false
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
                        
                        if let delegate = NSApp.delegate as? AppDelegate,
                           case .downloadingModel = delegate.state {
                            delegate.state = .downloadingModel(fraction)
                            delegate.updateUI()
                        }
                    }
                }
            )
            
            // Persist the association between the tier and the local folder name
            let folderName = downloadedFolderURL.lastPathComponent
            var currentDownloaded = downloadedModels
            currentDownloaded[tier.rawValue] = folderName
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
        guard isModelDownloaded(tier: tier),
              let folderName = downloadedModels[tier.rawValue] else {
            return nil
        }
        return modelsDirectoryURL.appendingPathComponent(folderName, isDirectory: true)
    }
    
    public func resetDownloadState() {
        downloadState = .idle
    }
}
