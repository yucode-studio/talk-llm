//
//  AVSpeechAdapter.swift
//  Talk
//
//  Created by Yu on 2025/5/10.
//

import AVFoundation

@MainActor
final class AVSpeechPlayback: NSObject, TTSPlayback, AVSpeechSynthesizerDelegate {
    private let synthesizer: AVSpeechSynthesizer
    private var finishedContinuation: CheckedContinuation<Void, Never>?

    init(synthesizer: AVSpeechSynthesizer) {
        self.synthesizer = synthesizer
        super.init()
        synthesizer.delegate = self
    }

    var isPlaying: Bool {
        synthesizer.isSpeaking
    }

    func stop() throws {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func waitForCompletion() async {
        guard synthesizer.isSpeaking else { return }
        await withCheckedContinuation { continuation in
            self.finishedContinuation = continuation
        }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor in
            finishedContinuation?.resume()
            finishedContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        Task { @MainActor in
            finishedContinuation?.resume()
            finishedContinuation = nil
        }
    }
}

final class AVSpeechAdapter: TTSService, TTSAdapter {
    private let language: String
    private let voiceIdentifier: String
    private let rate: Float
    private let pitch: Float
    private let volume: Float
    private let synthesizer = AVSpeechSynthesizer()

    init(language: String, voiceIdentifier: String = "", rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 1.0) {
        self.language = language
        self.voiceIdentifier = voiceIdentifier
        self.rate = rate
        self.pitch = pitch
        self.volume = volume
    }

    @discardableResult
    func speak(_ text: String) async throws -> TTSPlayback {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TTSError.invalidInput
        }

        let utterance = AVSpeechUtterance(string: text)

        if !voiceIdentifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        }

        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch

        synthesizer.speak(utterance)

        let playback = await AVSpeechPlayback(synthesizer: synthesizer)

        return playback
    }
}
