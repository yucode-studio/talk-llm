import SwiftData
import SwiftUI

struct OpenAITTSSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsTextField(
                title: "API Key",
                text: Binding(
                    get: { viewModel.openAITTSSettings.apiKey },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.apiKey = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                placeholder: "Enter API Key",
                isSecure: true
            )

            SettingsTextField(
                title: "TTS Model",
                text: Binding(
                    get: { viewModel.openAITTSSettings.model },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.model = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                placeholder: "Enter model (e.g. tts-1, tts-1-hd)"
            )

            SettingsTextField(
                title: "Voice",
                text: Binding(
                    get: { viewModel.openAITTSSettings.voice },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.voice = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                placeholder: "Enter voice (e.g. alloy, echo)"
            )

            SettingsSlider(
                title: "Speed",
                value: Binding(
                    get: { viewModel.openAITTSSettings.speed },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.speed = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                range: 0.25 ... 4.0,
                step: 0.05
            )

            SettingsTextField(
                title: "Voice Instructions (Optional, only for specific models)",
                text: Binding(
                    get: { viewModel.openAITTSSettings.instructions },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.instructions = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                placeholder: "e.g. Speak with an upward inflection"
            )

            SettingsTextField(
                title: "API Base URL",
                text: Binding(
                    get: { viewModel.openAITTSSettings.baseURL },
                    set: {
                        var settings = viewModel.openAITTSSettings
                        settings.baseURL = $0
                        viewModel.openAITTSSettings = settings
                    }
                ),
                placeholder: "Enter custom API URL (e.g. https://example.com/v1)"
            )
        }
    }
}

#Preview("OpenAITTSSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    var settings = OpenAITTSSettings()
    settings.apiKey = "sk-..."
    settings.model = "tts-1-hd"
    settings.voice = "nova"
    settings.speed = 1.0
    settings.instructions = "Speak naturally with clear pronunciation"
    viewModel.openAITTSSettings = settings

    return ScrollView {
        OpenAITTSSettingsView(viewModel: viewModel)
            .padding()
    }
}
