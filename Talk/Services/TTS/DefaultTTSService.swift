import AVFoundation
import Foundation

public class DefaultTTSService: TTSService {
    private let adapter: TTSAdapter

    public init(adapter: TTSAdapter) {
        self.adapter = adapter
    }

    @discardableResult
    public func speak(_ text: String) async throws -> TTSPlayback {
        guard !text.isEmpty else {
            throw TTSError.invalidInput
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            mode: .default,
                                                            options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession configuration error: \(error.localizedDescription)")
        }

        let nomralizedText = TextNormalizer.normalize(text)

        return try await adapter.speak(nomralizedText)
    }
}

public enum TTSServiceFactory {
    public static func createMicrosoftCognitiveServicesService(
        subscriptionKey: String,
        region: String,
        voiceName: String = "en-US-AvaMultilingualNeural"
    ) -> TTSService {
        let adapter = MicrosoftCognitiveServicesSpeechAdapter(
            subscriptionKey: subscriptionKey,
            region: region,
            voiceName: voiceName
        )
        return DefaultTTSService(adapter: adapter)
    }

    public static func createOpenAIService(
        apiKey: String,
        model: String = "tts-1",
        voice: String = "alloy",
        responseFormat: OpenAITTSAdapter.ResponseFormat = .mp3,
        speed: Float = 1.0,
        instructions: String? = nil,
        baseURL: String = "https://api.openai.com"
    ) -> TTSService {
        let adapter = OpenAITTSAdapter(
            apiKey: apiKey,
            model: model,
            voice: voice,
            responseFormat: responseFormat,
            speed: speed,
            instructions: instructions,
            baseURL: baseURL
        )
        return DefaultTTSService(adapter: adapter)
    }

    public static func createAVSpeechService(
        language: String = "en-US",
        voiceIdentifier: String = "",
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) -> TTSService {
        let adapter = AVSpeechAdapter(
            language: language,
            voiceIdentifier: voiceIdentifier,
            rate: rate,
            pitch: pitch,
            volume: volume
        )
        return DefaultTTSService(adapter: adapter)
    }
}
