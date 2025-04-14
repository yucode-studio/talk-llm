import SwiftData
import SwiftUI

struct OpenAILLMSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsTextField(
                title: "API Key",
                text: Binding(
                    get: { viewModel.openAILLMSettings.apiKey },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.apiKey = $0
                        viewModel.openAILLMSettings = settings
                    }
                ),
                placeholder: "Enter API Key",
                isSecure: true
            )

            SettingsTextField(
                title: "API Base URL",
                text: Binding(
                    get: { viewModel.openAILLMSettings.baseURL },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.baseURL = $0
                        viewModel.openAILLMSettings = settings
                    }
                ),
                placeholder: "Enter API Base URL (e.g. https://example.com/v1)"
            )

            SettingsTextField(
                title: "Model",
                text: Binding(
                    get: { viewModel.openAILLMSettings.model },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.model = $0
                        viewModel.openAILLMSettings = settings
                    }
                ),
                placeholder: "Enter model name"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("System (Optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())

                TextEditor(text: Binding(
                    get: { viewModel.openAILLMSettings.prompt },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.prompt = $0
                        viewModel.openAILLMSettings = settings
                    }
                ))
                .font(.system(size: 14))
                .padding(8)
                .frame(height: 100)
                .background(ColorTheme.backgroundColor())
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ColorTheme.borderColor(), lineWidth: 0.5)
                )
            }
            .padding(.vertical, 3)

            SettingsSlider(
                title: "Temperature",
                value: Binding(
                    get: { viewModel.openAILLMSettings.temperature },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.temperature = $0
                        viewModel.openAILLMSettings = settings
                    }
                ),
                range: 0.0 ... 2.0,
                step: 0.1
            )

            SettingsSlider(
                title: "Top P",
                value: Binding(
                    get: { viewModel.openAILLMSettings.top_p },
                    set: {
                        var settings = viewModel.openAILLMSettings
                        settings.top_p = $0
                        viewModel.openAILLMSettings = settings
                    }
                ),
                range: 0.0 ... 1.0,
                step: 0.1
            )
        }
    }
}

#Preview("OpenAILLMSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)

    var settings = OpenAILLMSettings()
    settings.apiKey = "sk-..."
    settings.model = "deepseek"
    settings.prompt = "你是一个有用的AI助手。"
    settings.temperature = 0.7
    settings.top_p = 1.0
    viewModel.openAILLMSettings = settings

    return ScrollView {
        OpenAILLMSettingsView(viewModel: viewModel)
            .padding()
    }
}
