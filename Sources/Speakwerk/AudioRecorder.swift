import Foundation
import AVFoundation
import os

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private let logger = Logger(subsystem: "com.alex.Speakwerk", category: "AudioRecorder")
    private var audioRecorder: AVAudioRecorder?
    private(set) var isRecording = false
    private var audioFileURL: URL?
    
    /// Starts recording audio and returns the URL where the recording is saved.
    func startRecording() throws -> URL {
        guard !isRecording else {
            logger.warning("Already recording. Ignoring start request.")
            if let url = audioFileURL { return url }
            throw NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Already recording but URL is missing"])
        }
        
        let fileManager = FileManager.default
        
        // Retrieve and create the cache directory securely
        let cacheDirs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let systemCacheURL = cacheDirs.first else {
            throw NSError(domain: "AudioRecorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find system cache directory"])
        }
        
        let appCacheURL = systemCacheURL.appendingPathComponent("de.alex.speakwerk", isDirectory: true)
        
        // Ensure directory exists
        try fileManager.createDirectory(at: appCacheURL, withIntermediateDirectories: true, attributes: nil)
        
        let fileURL = appCacheURL.appendingPathComponent("recording.wav")
        self.audioFileURL = fileURL
        
        // Configure for WhisperKit: 16 kHz, Mono, 16-Bit Linear PCM WAV
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        logger.info("Initializing AVAudioRecorder at URL: \(fileURL.path)")
        
        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.delegate = self
        
        // Prepare and start recording
        guard recorder.prepareToRecord() else {
            throw NSError(domain: "AudioRecorder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare AVAudioRecorder"])
        }
        
        guard recorder.record() else {
            throw NSError(domain: "AudioRecorder", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to start AVAudioRecorder recording"])
        }
        
        self.audioRecorder = recorder
        self.isRecording = true
        logger.info("AVAudioRecorder started successfully.")
        
        return fileURL
    }
    
    /// Stops the current recording session.
    func stopRecording() {
        guard isRecording, let recorder = audioRecorder else {
            logger.warning("Stop recording requested, but not recording.")
            return
        }
        
        recorder.stop()
        self.audioRecorder = nil
        self.isRecording = false
        logger.info("AVAudioRecorder stopped.")
    }
    
    /// Safely deletes the temporary audio recording file if it exists.
    func deleteRecording() {
        guard let url = audioFileURL else { return }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                logger.info("Successfully deleted temporary audio file: \(url.path)")
            } catch {
                logger.error("Failed to delete temporary audio file at \(url.path): \(error.localizedDescription)")
            }
        }
        self.audioFileURL = nil
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        logger.info("AVAudioRecorder finished recording. Success status: \(flag)")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let err = error {
            logger.error("AVAudioRecorder encode error occurred: \(err.localizedDescription)")
        }
    }
}
