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
} 
