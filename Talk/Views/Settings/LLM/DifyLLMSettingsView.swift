import SwiftData
import SwiftUI

struct DifyLLMSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsTextField(
                title: "API Key",
                text: Binding(
                    get: { viewModel.difySettings.apiKey },
                    set: {
                        var settings = viewModel.difySettings
                        settings.apiKey = $0
                        viewModel.difySettings = settings
                    }
                ),
                placeholder: "Enter Dify API Key",
                isSecure: true
            )

            SettingsTextField(
                title: "API Base URL",
                text: Binding(
                    get: { viewModel.difySettings.baseURL },
                    set: {
                        var settings = viewModel.difySettings
                        settings.baseURL = $0
                        viewModel.difySettings = settings
                    }
                ),
                placeholder: "Enter Dify API URL (e.g. http://localhost/v1)"
            )
        }
    }
}

#Preview("DifyLLMSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    var settings = DifySettings()
    settings.apiKey = "dify-..."
    settings.baseURL = "https://api.dify.ai/v1"
    viewModel.difySettings = settings

    return ScrollView {
        DifyLLMSettingsView(viewModel: viewModel)
            .padding()
    }
}
