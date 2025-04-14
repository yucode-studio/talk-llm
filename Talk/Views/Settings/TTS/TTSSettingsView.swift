import SwiftData
import SwiftUI

struct TTSSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPicker(
                    title: "Select TTS Service",
                    selection: Binding(
                        get: { viewModel.selectedTTSService },
                        set: { viewModel.selectedTTSService = $0 }
                    )
                )

                if viewModel.selectedTTSService == .microsoft {
                    MicrosoftTTSSettingsView(viewModel: viewModel)
                } else if viewModel.selectedTTSService == .openAI {
                    OpenAITTSSettingsView(viewModel: viewModel)
                }
            }
            .padding(20)
        }
        .navigationTitle("Text-to-Speech Settings")
        .background(ColorTheme.backgroundColor())
    }
}

#Preview("TTSSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    return NavigationStack {
        TTSSettingsView(viewModel: viewModel)
    }
}
