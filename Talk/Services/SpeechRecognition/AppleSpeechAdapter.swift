import AVFoundation
import Foundation
import Speech

public class AppleSpeechAdapter: SpeechRecognitionAdapter {
    private let language: String
    private let speechRecognizer: SFSpeechRecognizer

    public init(language: String = "en-US") {
        self.language = language

        let locale = Locale(identifier: language)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            fatalError("Speech recognizer not available for locale: \(language)")
        }

        speechRecognizer = recognizer
    }

    public func recognize(pcmData: [Int16]) async throws -> SpeechRecognitionResult {
        if SFSpeechRecognizer.authorizationStatus() != .authorized {
            let authStatus = await requestSpeechAuthorization()
            guard authStatus == .authorized else {
                throw SpeechRecognitionError.adapterNotAvailable
            }
        }

        guard speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.adapterNotAvailable
        }

        // Convert PCM data to format compatible with Apple Speech framework
        let audioBuffer = convertPCMToAudioBuffer(pcmData)

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.append(audioBuffer)
            request.endAudio()

            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: SpeechRecognitionError.processingFailed(error.localizedDescription))
                    return
                }

                guard let result = result else {
                    continuation.resume(throwing: SpeechRecognitionError.processingFailed("No recognition result"))
                    return
                }

                if result.isFinal {
                    let text = result.bestTranscription.formattedString
                    let languageCode = self.language.components(separatedBy: "-").first ?? "en"

                    let additionalInfo: [String: Any] = [
                        "confidence": result.bestTranscription.segments.map { $0.confidence }.reduce(0, +) / Float(result.bestTranscription.segments.count),
                        "segments": result.bestTranscription.segments.map { segment -> [String: Any] in
                            return [
                                "text": segment.substring,
                                "confidence": segment.confidence,
                                "timestamp": segment.timestamp,
                                "duration": segment.duration,
                            ]
                        },
                    ]

                    continuation.resume(returning: SpeechRecognitionResult(
                        text: text,
                        language: languageCode,
                        additionalInfo: additionalInfo
                    ))
                }
            }
        }
    }

    private func convertPCMToAudioBuffer(_ pcmData: [Int16]) -> AVAudioPCMBuffer {
        // Create audio format: 16kHz, 16-bit, mono
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        // Create audio buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(pcmData.count))!
        buffer.frameLength = buffer.frameCapacity

        // Fill with data
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: Int(buffer.format.channelCount))
        for i in 0 ..< pcmData.count {
            channels[0][i] = pcmData[i]
        }

        return buffer
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

public struct AppleSpeechRequestOptions {
    public var language: String
    public var taskHint: SFSpeechRecognitionTaskHint
    public var contextualStrings: [String]?

    public init(
        language: String = "en-US",
        taskHint: SFSpeechRecognitionTaskHint = .unspecified,
        contextualStrings: [String]? = nil
    ) {
        self.language = language
        self.taskHint = taskHint
        self.contextualStrings = contextualStrings
    }
}
