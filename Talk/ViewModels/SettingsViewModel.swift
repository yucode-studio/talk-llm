import Combine
import Foundation
import SwiftData
import SwiftUI

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
                settings = firstSettings
            } else {
                settings = SettingsModel()
                modelContext.insert(settings)
                try modelContext.save()
            }
        } catch {
            print("Error fetching settings: \(error)")
            settings = SettingsModel()
            modelContext.insert(settings)
            try? modelContext.save()
        }

        selectedVADService = settings.selectedVADService
        cobraSettings = settings.cobraSettings
        selectedLLMService = settings.selectedLLMService
        openAILLMSettings = settings.openAILLMSettings
        difySettings = settings.difySettings
        selectedSpeechService = settings.selectedSpeechService
        whisperCppSettings = settings.whisperCppSettings
        whisperKitSettings = settings.whisperKitSettings
        selectedTTSService = settings.selectedTTSService
        microsoftTTSSettings = settings.microsoftTTSSettings
        openAITTSSettings = settings.openAITTSSettings
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
