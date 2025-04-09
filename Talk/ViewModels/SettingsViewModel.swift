import Foundation
import SwiftUI
import SwiftData
import Combine


class SettingsViewModel: ObservableObject {
    private let modelContext: ModelContext
    private var settings: SettingsModel
    
    // MARK: - Properties
    
    @Published var selectedVADService: SettingsModel.VADServiceType {
        didSet {
            saveSettings()
        }
    }
    
    @Published var cobraSettings: CobraSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var selectedLLMService: SettingsModel.LLMServiceType {
        didSet {
            saveSettings()
        }
    }
    
    @Published var openAILLMSettings: OpenAILLMSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var difySettings: DifySettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var selectedSpeechService: SettingsModel.SpeechServiceType {
        didSet {
            saveSettings()
        }
    }
    
    @Published var whisperCppSettings: WhisperCppSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var whisperKitSettings: WhisperKitSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var selectedTTSService: SettingsModel.TTSServiceType {
        didSet {
            saveSettings()
        }
    }
    
    @Published var microsoftTTSSettings: MicrosoftTTSSettings {
        didSet {
            saveSettings()
        }
    }
    
    @Published var openAITTSSettings: OpenAITTSSettings {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        let descriptor = FetchDescriptor<SettingsModel>()
        
        do {
            let existingSettings = try modelContext.fetch(descriptor)
            if let firstSettings = existingSettings.first {
                self.settings = firstSettings
            } else {
                self.settings = SettingsModel()
                modelContext.insert(settings)
                try modelContext.save()
            }
        } catch {
            print("Error fetching settings: \(error)")
            self.settings = SettingsModel()
            modelContext.insert(settings)
            try? modelContext.save()
        }
        
        self.selectedVADService = settings.selectedVADService
        self.cobraSettings = settings.cobraSettings
        self.selectedLLMService = settings.selectedLLMService
        self.openAILLMSettings = settings.openAILLMSettings
        self.difySettings = settings.difySettings
        self.selectedSpeechService = settings.selectedSpeechService
        self.whisperCppSettings = settings.whisperCppSettings
        self.whisperKitSettings = settings.whisperKitSettings
        self.selectedTTSService = settings.selectedTTSService
        self.microsoftTTSSettings = settings.microsoftTTSSettings
        self.openAITTSSettings = settings.openAITTSSettings
    }
    
    // MARK: - Methods
    
    private func saveSettings() {
        settings.selectedVADService = selectedVADService
        settings.cobraSettings = cobraSettings
        settings.selectedLLMService = selectedLLMService
        settings.openAILLMSettings = openAILLMSettings
        settings.difySettings = difySettings
        settings.selectedSpeechService = selectedSpeechService
        settings.whisperCppSettings = whisperCppSettings
        settings.whisperKitSettings = whisperKitSettings
        settings.selectedTTSService = selectedTTSService
        settings.microsoftTTSSettings = microsoftTTSSettings
        settings.openAITTSSettings = openAITTSSettings
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving settings: \(error)")
        }
    }
}
