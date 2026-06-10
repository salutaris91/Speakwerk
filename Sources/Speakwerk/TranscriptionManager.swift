import Foundation
import WhisperKit
import os

@MainActor
class TranscriptionManager {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "TranscriptionManager")
    private var whisperKit: WhisperKit?
    private var whisperKitTask: Task<WhisperKit, any Error>?
    
    /// Starts loading the WhisperKit model asynchronously in the background.
    func preloadModel() {
        guard whisperKit == nil && whisperKitTask == nil else {
            return
        }
        
        logger.info("Starting WhisperKit model preloading...")
        
        whisperKitTask = Task {
            // Configure WhisperKit to use the lightweight "openai_whisper-base" model.
            // Using a specific model name prevents automatic device-dependent downloading
            // of larger models (like small/large) during the initial load.
            let config = WhisperKitConfig(model: "openai_whisper-base")
            logger.info("Initializing WhisperKit with model: openai_whisper-base")
            
            let kit = try await WhisperKit(config)
            
            // Assign to local state upon successful load
            self.whisperKit = kit
            logger.info("WhisperKit initialization completed successfully.")
            return kit
        }
    }
    
    /// Transcribes the audio file at the specified URL.
    /// If the model is not yet loaded, it will wait for the loading task to complete.
    func transcribe(audioURL: URL) async throws -> String {
        let kit: WhisperKit
        
        if let existingKit = whisperKit {
            kit = existingKit
        } else {
            // Trigger preloading if not already running
            preloadModel()
            
            guard let task = whisperKitTask else {
                throw NSError(
                    domain: "TranscriptionManager",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Preload task could not be initialized"]
                )
            }
            
            logger.info("Waiting for WhisperKit model to finish loading...")
            kit = try await task.value
        }
        
        logger.info("Starting transcription for file: \(audioURL.path)")
        
        // WhisperKit v1.0.0+ transcribe returns [TranscriptionResult]
        let results = try await kit.transcribe(audioPath: audioURL.path)
        
        guard let firstResult = results.first else {
            logger.warning("Transcription completed, but returned no results.")
            return ""
        }
        
        let transcribedText = firstResult.text.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.info("Transcription completed. Length: \(transcribedText.count) characters.")
        
        return transcribedText
    }
}
