//
//  VoiceChatView.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import SwiftUI
import Combine
import Alamofire
import SwiftData
import WhisperKit
import AVFoundation

struct VoiceChatView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechMonitor = SpeechMonitorViewModel()
    @Query private var settings: [SettingsModel]
    @State private var cancellables = Set<AnyCancellable>()
    @State private var playback: TTSPlayback?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var speechRecognitionService: SpeechRecognitionService?
    @State private var llmService: LLMService?
    @State private var ttsService: TTSService?
    
    @State private var servicesInitialed: Bool = false
    @State private var prepareForSpeak: Bool = false
    
    @State private var responding: Bool = false
    
    private var currentSettings: SettingsModel? {
        settings.first
    }
    
    var body: some View {
        ZStack {
            ColorCircle(
                listening: speechMonitor.listening,
                speaking: speechMonitor.speaking,
                responding: responding,
                audioLevel: speechMonitor.voiceVolume
            ) {
                // Validate service initialization when user taps
                verifyAndInitializeServices()
            }
            .onChange(of: speechMonitor.recordedAudioData) { _, newValue in
                onSpeakEnd(data: newValue)
            }
            .onChange(of: currentSettings?.settingsHash) { _, newSettings in
                debugPrint("Settings changed")
                if speechMonitor.listening {
                    speechMonitor.stopMonitoring()
                }
                servicesInitialed = false
            }
            .alert("Configuration Information", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            
            if prepareForSpeak {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .offset(y: 85)
            }
        }
    }
    
    private func verifyAndInitializeServices() {
        prepareForSpeak = true

        Task {
            if !servicesInitialed {
                servicesInitialed = await initializeServices()
                if !servicesInitialed {
                    prepareForSpeak = false
                    return
                }
            }
            speechMonitor.toggleMonitoring()

            prepareForSpeak = false
        }
    }
    
    @discardableResult
    private func initializeServices() async -> Bool {
        do {
            guard let currentSettings else {
                throw SettingsServiceError.invalidConfiguration("Please open the settings page to configure your preferences for the first time.")
            }
            let vadEngine = try ServicesManager.createVADEngin(
                selectedVADEngine: currentSettings.selectedVADService,
                cobraSettings: currentSettings.cobraSettings
            )
            
            speechMonitor.setVADEngine(vadEngine)
            
            speechRecognitionService = try await ServicesManager.createSpeechRecognitionService(
                selectedSpeechService: currentSettings.selectedSpeechService,
                whisperCppSettings: currentSettings.whisperCppSettings,
                whisperKitSettings: currentSettings.whisperKitSettings
            )
            
            llmService = try ServicesManager.createLLMService(
                selectedLLMService: currentSettings.selectedLLMService,
                openAILLMSettings: currentSettings.openAILLMSettings,
                difySettings: currentSettings.difySettings
            )
            
            ttsService = try ServicesManager.createTTSService(
                selectedTTSService: currentSettings.selectedTTSService,
                microsoftTTSSettings: currentSettings.microsoftTTSSettings,
                openAITTSSettings: currentSettings.openAITTSSettings
            )
            
            return true
        } catch SettingsServiceError.invalidConfiguration(let message) {
            showErrorAlert(message)
            return false
        } catch {
            showErrorAlert("Unknown error occurred: \(error.localizedDescription)")
            return false
        }
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
    
    func onSpeakEnd(data: [Int16]?) {
        guard let data else {
            print("No audio data")
            return
        }
        
        guard let currentSettings else {
            print("No Settings")
            return 
        }
        
        guard let speechRecognitionService = speechRecognitionService,
              let llmService = llmService,
              let ttsService = ttsService else {
            showErrorAlert("Services not properly initialized")
            return
        }
        
        speechMonitor.stopMonitoring()
        Task {
            do {
                responding = true
                
                let sttText = try await speechRecognitionService.recognizeSpeech(pcmData: data).text
                
                ChatHistory.addMessage(content: sttText, isUserMessage: true, in: modelContext)
                
                var chatHistoryMessages = ChatHistory.getLatestMessages(count: 5, in: modelContext)
                    .map {
                        LLMMessage(
                            content: $0.content,
                            role: $0.isUserMessage ? "user" : "assistant"
                        )
                    }
                
                let modelName: String
                switch currentSettings.selectedLLMService {
                case .openAI:
                    modelName = currentSettings.openAILLMSettings.model
                case .dify:
                    modelName = ""
                }
                
                var additionalParams: [String: Any] = [:]
                
                let useOpenAILLM = currentSettings.selectedLLMService == .openAI
                let openAILLMPromptEmpty = currentSettings.openAILLMSettings.prompt.isEmpty
                
                if useOpenAILLM {
                    if !openAILLMPromptEmpty {
                        chatHistoryMessages.insert(
                            LLMMessage(content: currentSettings.openAILLMSettings.prompt, role: "system"),
                            at: 0
                        )
                    }
                    additionalParams["temperature"] = currentSettings.openAILLMSettings.temperature
                    additionalParams["top_p"] = currentSettings.openAILLMSettings.top_p
                }
                
                let request = LLMRequest(
                    messages: chatHistoryMessages,
                    model: modelName,
                    additionalParams: additionalParams
                )
                
                let llmResponse = try await llmService.sendMessage(request)
                
                ChatHistory.addMessage(content: llmResponse.content, isUserMessage: false, in: modelContext)
                
                playback = try await ttsService.speak(llmResponse.content)
                await playback?.waitForCompletion()
                
                responding = false
                // Wait for the responding animation to end
                try await Task.sleep(nanoseconds: 500_000_000)
                speechMonitor.startMonitoring()
            } catch {
                responding = false
                showErrorAlert("Error during conversation: \(error.localizedDescription)")
            }
        }
    }
}

#Preview("VoiceChatView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, ChatMessage.self, configurations: config)
    
    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }
    
    return VoiceChatView()
        .modelContainer(container)
}
