import Foundation
import SwiftData

@Model
final class SettingsModel {
    var selectedVADService: VADServiceType = VADServiceType.energy
    var selectedLLMService: LLMServiceType = LLMServiceType.openAI
    var selectedSpeechService: SpeechServiceType = SpeechServiceType.whisperKit
    var selectedTTSService: TTSServiceType = TTSServiceType.openAI
    
    @Attribute var cobraSettings: CobraSettings = CobraSettings()
    @Attribute var openAILLMSettings: OpenAILLMSettings = OpenAILLMSettings()
    @Attribute var difySettings: DifySettings = DifySettings()
    @Attribute var whisperCppSettings: WhisperCppSettings = WhisperCppSettings()
    @Attribute var whisperKitSettings: WhisperKitSettings = WhisperKitSettings()
    @Attribute var microsoftTTSSettings: MicrosoftTTSSettings = MicrosoftTTSSettings()
    @Attribute var openAITTSSettings: OpenAITTSSettings = OpenAITTSSettings()
    
    enum VADServiceType: String, Codable, CaseIterable, Identifiable {
        case energy = "Energy"
        case cobra = "Cobra"
        
        var id: String { self.rawValue }
    }
    
    enum LLMServiceType: String, Codable, CaseIterable, Identifiable {
        case openAI = "OpenAI"
        case dify = "Dify"
        
        var id: String { self.rawValue }
    }
    
    enum SpeechServiceType: String, Codable, CaseIterable, Identifiable {
        case whisperKit = "WhisperKit"
        case whisperCpp = "Whisper.cpp"
        
        var id: String { self.rawValue }
    }
    
    enum TTSServiceType: String, Codable, CaseIterable, Identifiable {
        case microsoft = "Microsoft"
        case openAI = "OpenAI"
        
        var id: String { self.rawValue }
    }
    
    init() {}
}

struct CobraSettings: Codable, Hashable {
    var accessKey: String = ""
}

struct OpenAILLMSettings: Codable, Hashable {
    var apiKey: String = ""
    var baseURL: String = ""
    var model: String = "gpt-3.5-turbo"
    var prompt: String = ""
    var temperature: Float = 1.0
    var top_p: Float = 1.0
}

struct DifySettings: Codable, Hashable {
    var apiKey: String = ""
    var baseURL: String = ""
}

struct WhisperCppSettings: Codable, Hashable {
    var serverURL: String = "http://localhost:8080/inference"
}

struct WhisperKitSettings: Codable, Hashable {
    var modelName: String = "tiny.en"
}

struct MicrosoftTTSSettings: Codable, Hashable {
    var subscriptionKey: String = ""
    var region: String = ""
    var voiceName: String = "en-US-AvaMultilingualNeural"
}

struct OpenAITTSSettings: Codable, Hashable {
    var apiKey: String = ""
    var model: String = "tts-1"
    var voice: String = "alloy"
    var speed: Float = 1.0
    var instructions: String = ""
    var baseURL: String = "https://api.openai.com"
}
