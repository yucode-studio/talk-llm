import Foundation
import MicrosoftCognitiveServicesSpeech

public class MicrosoftCognitiveServicesSpeechAdapter: TTSAdapter {
    private enum PlaybackState {
        case idle
        case playing
        case stopped
    }

    @MainActor
    class MSTTSPlayback: TTSPlayback {
        private weak var synthesizer: SPXSpeechSynthesizer?
        private var playbackState: PlaybackState = .idle
        private var completionContinuation: CheckedContinuation<Void, Never>?

        init(synthesizer: SPXSpeechSynthesizer) {
            self.synthesizer = synthesizer
        }

        public func stop() throws {
            setStopped()
            try synthesizer?.stopSpeaking()
        }

        var isPlaying: Bool {
            return playbackState == .playing
        }

        func setPlaying() {
            playbackState = .playing
        }

        func setStopped() {
            if playbackState == .playing {
                playbackState = .stopped
                resumeContinuation()
            }
        }

        func resumeContinuation() {
            if let continuation = completionContinuation {
                continuation.resume()
                completionContinuation = nil
            }
        }

        public func waitForCompletion() async {
            if playbackState != .playing {
                return
            }

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.completionContinuation = continuation
            }
        }
    }

    private let subscriptionKey: String
    private let region: String
    private let voiceName: String

    private var activePlaybacks: [MSTTSPlayback] = []

    public init(subscriptionKey: String, region: String, voiceName: String) {
        self.subscriptionKey = subscriptionKey
        self.region = region
        self.voiceName = voiceName
    }

    @discardableResult
    public func speak(_ text: String) async throws -> TTSPlayback {
        do {
            let speechConfig = try SPXSpeechConfiguration(subscription: subscriptionKey, region: region)
            speechConfig.speechSynthesisVoiceName = voiceName

            let synthesizer = try SPXSpeechSynthesizer(speechConfig)

            let playback = await MSTTSPlayback(synthesizer: synthesizer)

            await playback.setPlaying()

            Task.detached {
                do {
                    let ttsResult = try await self.synthesizeTextAsync(text, synthesizer: synthesizer)

                    await playback.setStopped()

                    if ttsResult.reason == SPXResultReason.canceled {
                        if let details = try? SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: ttsResult) {
                            print("TTS cancel, error code：\(details.errorCode), info：\(details.errorDetails ?? "unkonw")")
                        }
                    }
                } catch {
                    print("TTS error: \(error.localizedDescription)")
                    await playback.setStopped()
                }
            }

            return playback
        } catch let error as TTSError {
            throw error
        } catch {
            throw TTSError.processingFailed("Microsoft TTS failed: \(error.localizedDescription)")
        }
    }

    private func synthesizeTextAsync(_ text: String, synthesizer: SPXSpeechSynthesizer) async throws -> SPXSpeechSynthesisResult {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try synthesizer.speakText(text)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
