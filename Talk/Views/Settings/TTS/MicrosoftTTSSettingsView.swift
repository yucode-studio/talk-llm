import SwiftData
import SwiftUI

struct MicrosoftTTSSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsTextField(
                title: "Subscription Key",
                text: Binding(
                    get: { viewModel.microsoftTTSSettings.subscriptionKey },
                    set: {
                        var settings = viewModel.microsoftTTSSettings
                        settings.subscriptionKey = $0
                        viewModel.microsoftTTSSettings = settings
                    }
                ),
                placeholder: "Enter Microsoft Speech Service subscription key",
                isSecure: true
            )

            SettingsTextField(
                title: "Region",
                text: Binding(
                    get: { viewModel.microsoftTTSSettings.region },
                    set: {
                        var settings = viewModel.microsoftTTSSettings
                        settings.region = $0
                        viewModel.microsoftTTSSettings = settings
                    }
                ),
                placeholder: "Enter region (e.g. eastasia)"
            )

            SettingsTextField(
                title: "Voice Name",
                text: Binding(
                    get: { viewModel.microsoftTTSSettings.voiceName },
                    set: {
                        var settings = viewModel.microsoftTTSSettings
                        settings.voiceName = $0
                        viewModel.microsoftTTSSettings = settings
                    }
                ),
                placeholder: "Enter voice identifier (e.g. en-US-JennyNeural)"
            )
        }
    }
}

#Preview("MicrosoftTTSSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    var settings = MicrosoftTTSSettings()
    settings.subscriptionKey = "12345..."
    settings.region = "eastasia"
    settings.voiceName = "zh-CN-XiaoxiaoNeural"
    viewModel.microsoftTTSSettings = settings

    return ScrollView {
        MicrosoftTTSSettingsView(viewModel: viewModel)
            .padding()
    }
}
