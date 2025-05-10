import Foundation
import SwiftData

@Model
final class SettingsModel {
    var selectedVADService: VADServiceType = VADServiceType.energy
    var selectedLLMService: LLMServiceType = LLMServiceType.openAI
    var selectedSpeechService: SpeechServiceType = SpeechServiceType.system
    var selectedTTSService: TTSServiceType = TTSServiceType.system

    @Attribute var cobraSettings: CobraSettings = CobraSettings()
    @Attribute var openAILLMSettings: OpenAILLMSettings = OpenAILLMSettings()
    @Attribute var difySettings: DifySettings = DifySettings()
    @Attribute var whisperCppSettings: WhisperCppSettings = WhisperCppSettings()
    @Attribute var whisperKitSettings: WhisperKitSettings = WhisperKitSettings()
    @Attribute var microsoftTTSSettings: MicrosoftTTSSettings = MicrosoftTTSSettings()
    @Attribute var openAITTSSettings: OpenAITTSSettings = OpenAITTSSettings()
    @Attribute var appleSpeechSettings: AppleSpeechSettings = AppleSpeechSettings()
    @Attribute var systemTTSSettings: SystemTTSSettings = SystemTTSSettings()

    enum VADServiceType: String, Codable, CaseIterable, Identifiable {
        case energy = "Energy"
        case cobra = "Cobra"

        var id: String { rawValue }
    }

    enum LLMServiceType: String, Codable, CaseIterable, Identifiable {
        case openAI = "OpenAI compatible"
        case dify = "Dify"

        var id: String { rawValue }
    }

    enum SpeechServiceType: String, Codable, CaseIterable, Identifiable {
        case whisperKit = "WhisperKit"
        case whisperCpp = "Whisper.cpp"
        case system = "System"

        var id: String { rawValue }
    }

    enum TTSServiceType: String, Codable, CaseIterable, Identifiable {
        case microsoft = "Microsoft"
        case openAI = "OpenAI compatible"
        case system = "System"

        var id: String { rawValue }
    }

    init() {}
}

extension SettingsModel {
    var settingsHash: String {
        [
            selectedVADService.rawValue,
            selectedLLMService.rawValue,
            selectedSpeechService.rawValue,
            selectedTTSService.rawValue,

            cobraSettings.accessKey,

            openAILLMSettings.apiKey,
            openAILLMSettings.baseURL,
            openAILLMSettings.model,
            openAILLMSettings.prompt,
            String(openAILLMSettings.temperature),
            String(openAILLMSettings.top_p),

            difySettings.apiKey,
            difySettings.baseURL,

            whisperCppSettings.serverURL,

            whisperKitSettings.modelName,

            microsoftTTSSettings.subscriptionKey,
            microsoftTTSSettings.region,
            microsoftTTSSettings.voiceName,

            openAITTSSettings.apiKey,
            openAITTSSettings.model,
            openAITTSSettings.voice,
            String(openAITTSSettings.speed),
            openAITTSSettings.instructions,
            openAITTSSettings.baseURL,

            appleSpeechSettings.language,

            systemTTSSettings.voiceIdentifier,
            systemTTSSettings.language,
            String(systemTTSSettings.rate),
            String(systemTTSSettings.pitch),
            String(systemTTSSettings.volume),
        ].joined(separator: "-")
    }
}

struct CobraSettings: Codable, Hashable {
    var accessKey: String = ""
}

struct OpenAILLMSettings: Codable, Hashable {
    var apiKey: String = ""
    var baseURL: String = ""
    var model: String = ""
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
    var model: String = ""
    var voice: String = ""
    var speed: Float = 1.0
    var instructions: String = ""
    var baseURL: String = ""
}

struct AppleSpeechSettings: Codable, Hashable {
    var language: String = "en-US"
}

struct SystemTTSSettings: Codable, Hashable {
    var voiceIdentifier: String = ""
    var language: String = "en-US"
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
}
