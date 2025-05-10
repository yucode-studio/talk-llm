//
//  ServicesManager.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//
import Foundation

enum SettingsServiceError: Error {
    case invalidConfiguration(String)
}

enum ServicesManager {
    static func createVADEngin(selectedVADEngine: SettingsModel.VADServiceType, cobraSettings: CobraSettings) throws -> VADEngine {
        switch selectedVADEngine {
        case .cobra:
            if cobraSettings.accessKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("You choose Cobra VAD, but you haven't configured the access key, please check your settings")
            }
            return try CobraVADEngine(accessKey: cobraSettings.accessKey)
        case .energy:
            return EnergyVADEngine()
        }
    }

    static func createLLMService(selectedLLMService: SettingsModel.LLMServiceType, openAILLMSettings: OpenAILLMSettings, difySettings: DifySettings) throws -> LLMService {
        switch selectedLLMService {
        case .openAI:
            if openAILLMSettings.apiKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI compatible LLM API key is not configured, please check your settings")
            }
            if openAILLMSettings.model.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI compatible LLM model is not specified, please check your settings")
            }
            if openAILLMSettings.baseURL.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI compatible LLM API base url is not specified, please check your settings")
            }
            guard let baseURL = URL(string: openAILLMSettings.baseURL) else {
                throw SettingsServiceError.invalidConfiguration("OpenAI compatible LLM API base url is invalid, please check your settings")
            }
            return LLMServiceFactory.createOpenAIService(apiKey: openAILLMSettings.apiKey, baseURL: baseURL)

        case .dify:
            if difySettings.apiKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Dify API key is not configured, please check your settings")
            }
            if difySettings.baseURL.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Dify base URL is not configured, please check your settings")
            }
            let baseURL: URL? = difySettings.baseURL.isEmpty ? nil : URL(string: difySettings.baseURL)
            return LLMServiceFactory.createDifyService(apiKey: difySettings.apiKey, baseURL: baseURL)
        }
    }

    static func createSpeechRecognitionService(
        selectedSpeechService: SettingsModel.SpeechServiceType,
        whisperCppSettings: WhisperCppSettings,
        whisperKitSettings: WhisperKitSettings,
        appleSpeechSettings: AppleSpeechSettings
    ) async throws -> SpeechRecognitionService {
        switch selectedSpeechService {
        case .whisperCpp:
            if whisperCppSettings.serverURL.isEmpty {
                throw SettingsServiceError.invalidConfiguration("You choose Whisper.cpp, but you haven't configured the server URL, please check your settings")
            }
            let serverURL = URL(string: whisperCppSettings.serverURL) ?? URL(string: "http://localhost:8080/inference")!
            return SpeechRecognitionServiceFactory.createWhisperCppService(serverURL: serverURL)
        case .whisperKit:
            return try await SpeechRecognitionServiceFactory.createWhisperKitService(modelName: whisperKitSettings.modelName)
        case .system:
            return SpeechRecognitionServiceFactory.createAppleSpeechService(language: appleSpeechSettings.language)
        }
    }

    static func createTTSService(
        selectedTTSService: SettingsModel.TTSServiceType,
        microsoftTTSSettings: MicrosoftTTSSettings,
        openAITTSSettings: OpenAITTSSettings,
        systemTTSSettings: SystemTTSSettings
    ) throws -> TTSService {
        switch selectedTTSService {
        case .microsoft:
            if microsoftTTSSettings.subscriptionKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Text-to-Speech Microsoft subscription key is not configured, please check your settings")
            }
            if microsoftTTSSettings.region.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Text-to-Speech Microsoft region is not configured, please check your settings")
            }
            return TTSServiceFactory.createMicrosoftCognitiveServicesService(
                subscriptionKey: microsoftTTSSettings.subscriptionKey,
                region: microsoftTTSSettings.region,
                voiceName: microsoftTTSSettings.voiceName
            )
        case .openAI:
            if openAITTSSettings.apiKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI compatible Text-to-Speech API key is not configured, please check your settings")
            }
            return TTSServiceFactory.createOpenAIService(
                apiKey: openAITTSSettings.apiKey,
                model: openAITTSSettings.model,
                voice: openAITTSSettings.voice,
                speed: openAITTSSettings.speed,
                instructions: openAITTSSettings.instructions.isEmpty ? nil : openAITTSSettings.instructions,
                baseURL: openAITTSSettings.baseURL
            )
        case .system:
            return TTSServiceFactory.createAVSpeechService(
                language: systemTTSSettings.language,
                voiceIdentifier: systemTTSSettings.voiceIdentifier,
                rate: systemTTSSettings.rate,
                pitch: systemTTSSettings.pitch,
                volume: systemTTSSettings.volume
            )
        }
    }
}
