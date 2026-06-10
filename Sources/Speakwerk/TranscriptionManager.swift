import Foundation
import WhisperKit
import os

@MainActor
class TranscriptionManager {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "TranscriptionManager")
    private var whisperKit: WhisperKit?
    private var isDownloadingOrLoading = false
    private var loadingFailed = false
    
    /// Starts loading the WhisperKit model asynchronously in the background.
    func preloadModel() {
        guard whisperKit == nil else {
            return
        }
        guard !isDownloadingOrLoading else {
            return
        }
        
        isDownloadingOrLoading = true
        loadingFailed = false
        logger.info("Starting WhisperKit model preloading...")
        
        Task {
            do {
                let config = WhisperKitConfig(model: "openai_whisper-base")
                logger.info("Initializing WhisperKit with model: openai_whisper-base")
                
                let kit = try await WhisperKit(config)
                
                // Safe update on MainActor since Task inherits main actor isolation here
                self.whisperKit = kit
                self.isDownloadingOrLoading = false
                logger.info("WhisperKit initialization completed successfully.")
            } catch {
                self.isDownloadingOrLoading = false
                self.loadingFailed = true
                logger.error("Failed to initialize WhisperKit: \(error.localizedDescription)")
            }
        }
    }
    
    /// Transcribes the audio file at the specified URL.
    /// If the model is not yet loaded, it will wait (polling safely via Task.sleep) for the loading task to complete.
    func transcribe(audioURL: URL) async throws -> String {
        // If preloading already failed, abort immediately to avoid long timeout loops
        if loadingFailed {
            throw NSError(
                domain: "TranscriptionManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "WhisperKit model failed to load during preloading. Please start a new recording to retry."]
            )
        }
        
        // Trigger preloading if not already running
        preloadModel()
        
        // Wait for WhisperKit to finish loading
        var elapsedSeconds = 0
        let timeoutLimit = 300 // 5 minutes timeout (allows for slow initial model downloads)
        
        while whisperKit == nil {
            if loadingFailed {
                throw NSError(
                    domain: "TranscriptionManager",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "WhisperKit model failed to load. Check logs for details."]
                )
            }
            
            if elapsedSeconds >= timeoutLimit {
                throw NSError(
                    domain: "TranscriptionManager",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "WhisperKit model loading timed out after \(timeoutLimit) seconds."]
                )
            }
            
            // Log loading status every 5 seconds to reduce log spam
            if elapsedSeconds % 5 == 0 {
                logger.info("WhisperKit model is still loading... waiting (\(elapsedSeconds)/\(timeoutLimit)s)")
            }
            
            try await Task.sleep(for: .seconds(1))
            elapsedSeconds += 1
        }
        
        guard let kit = whisperKit else {
            throw NSError(
                domain: "TranscriptionManager",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "WhisperKit instance is nil after successful load check"]
            )
        }
        
        logger.info("Starting transcription for file: \(audioURL.path)")
        
        // WhisperKit v1.0.0+ transcribe returns [TranscriptionResult]
        let results = try await kit.transcribe(audioPath: audioURL.path)
        
        if results.isEmpty {
            logger.warning("Transcription completed, but returned no results.")
            return ""
        }
        
        // Join all transcribed segments to prevent loss of text in recordings longer than 30 seconds
        let transcribedText = results
            .map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        logger.info("Transcription completed. Length: \(transcribedText.count) characters.")
        
        return transcribedText
    }
}
