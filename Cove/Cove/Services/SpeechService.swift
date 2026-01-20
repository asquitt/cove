import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechService {
    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var transcribedText: String = ""
    var isRecording: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var error: SpeechError?

    // MARK: - Initialization
    init() {
        checkAuthorization()
    }

    // MARK: - Authorization
    func checkAuthorization() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    func requestMicrophonePermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Recording
    func startRecording() async throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        guard authorizationStatus == .authorized else {
            throw SpeechError.notAuthorized
        }

        // Cancel any ongoing task
        stopRecording()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        audioEngine = AVAudioEngine()
        guard let audioEngine else {
            throw SpeechError.audioEngineError
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        transcribedText = ""
        isRecording = true
        error = nil

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, taskError in
            Task { @MainActor in
                guard let self else { return }

                if let taskError {
                    self.error = SpeechError.recognitionFailed(taskError.localizedDescription)
                    self.stopRecording()
                    return
                }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    // MARK: - Status Helpers
    var canRecord: Bool {
        authorizationStatus == .authorized &&
        speechRecognizer?.isAvailable == true
    }

    var statusMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Tap to enable voice capture"
        case .denied:
            return "Speech recognition denied. Enable in Settings."
        case .restricted:
            return "Speech recognition restricted on this device."
        case .authorized:
            return speechRecognizer?.isAvailable == true
                ? "Ready to listen"
                : "Speech recognition unavailable"
        @unknown default:
            return "Unknown status"
        }
    }
}

// MARK: - Errors
enum SpeechError: LocalizedError {
    case recognizerNotAvailable
    case notAuthorized
    case audioEngineError
    case requestCreationFailed
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .audioEngineError:
            return "Audio engine failed to initialize"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .recognitionFailed(let reason):
            return "Recognition failed: \(reason)"
        }
    }
}
