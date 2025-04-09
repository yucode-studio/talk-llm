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
                throw SettingsServiceError.invalidConfiguration("Cobra Access key is not configured")
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
                throw SettingsServiceError.invalidConfiguration("OpenAI API key is not configured")
            }
            if openAILLMSettings.model.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI model is not specified")
            }
            let baseURL: URL? = openAILLMSettings.baseURL.isEmpty ? nil : URL(string: openAILLMSettings.baseURL)
            return LLMServiceFactory.createOpenAIService(apiKey: openAILLMSettings.apiKey, baseURL: baseURL)
            
        case .dify:
            if difySettings.apiKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Dify API key is not configured")
            }
            if difySettings.baseURL.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Dify base URL is not configured")
            }
            let baseURL: URL? = difySettings.baseURL.isEmpty ? nil : URL(string: difySettings.baseURL)
            return LLMServiceFactory.createDifyService(apiKey: difySettings.apiKey, baseURL: baseURL)
        }
    }
    
    static func createSpeechRecognitionService(
        selectedSpeechService: SettingsModel.SpeechServiceType,
        whisperCppSettings: WhisperCppSettings,
        whisperKitSettings: WhisperKitSettings
    ) async throws -> SpeechRecognitionService {
        switch selectedSpeechService {
        case .whisperCpp:
            if whisperCppSettings.serverURL.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Whisper.cpp server URL is not configured")
            }
            let serverURL = URL(string: whisperCppSettings.serverURL) ?? URL(string: "http://localhost:8080/inference")!
            return SpeechRecognitionServiceFactory.createWhisperCppService(serverURL: serverURL)
        case .whisperKit:
            return try await SpeechRecognitionServiceFactory.createWhisperKitService(modelName: whisperKitSettings.modelName)
        }
    }
    
    static func createTTSService(
        selectedTTSService: SettingsModel.TTSServiceType,
        microsoftTTSSettings: MicrosoftTTSSettings,
        openAITTSSettings: OpenAITTSSettings
    ) throws -> TTSService {
        switch selectedTTSService {
        case .microsoft:
            if microsoftTTSSettings.subscriptionKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Microsoft subscription key is not configured")
            }
            if microsoftTTSSettings.region.isEmpty {
                throw SettingsServiceError.invalidConfiguration("Microsoft region is not configured")
            }
            return TTSServiceFactory.createMicrosoftCognitiveServicesService(
                subscriptionKey: microsoftTTSSettings.subscriptionKey,
                region: microsoftTTSSettings.region,
                voiceName: microsoftTTSSettings.voiceName
            )
        case .openAI:
            if openAITTSSettings.apiKey.isEmpty {
                throw SettingsServiceError.invalidConfiguration("OpenAI TTS API key is not configured")
            }
            return TTSServiceFactory.createOpenAIService(
                apiKey: openAITTSSettings.apiKey,
                model: openAITTSSettings.model,
                voice: openAITTSSettings.voice,
                speed: openAITTSSettings.speed,
                instructions: openAITTSSettings.instructions.isEmpty ? nil : openAITTSSettings.instructions,
                baseURL: openAITTSSettings.baseURL
            )
        }
    }
}
