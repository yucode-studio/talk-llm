import SwiftData
import SwiftUI

struct LLMSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPicker(
                    title: "Select LLM Service",
                    selection: Binding(
                        get: { viewModel.selectedLLMService },
                        set: { viewModel.selectedLLMService = $0 }
                    )
                )

                if viewModel.selectedLLMService == .openAI {
                    OpenAILLMSettingsView(viewModel: viewModel)
                } else if viewModel.selectedLLMService == .dify {
                    DifyLLMSettingsView(viewModel: viewModel)
                }
            }
            .padding(20)
        }
        .navigationTitle("LLM Settings")
        .background(ColorTheme.backgroundColor())
    }
}

#Preview("LLMSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    return NavigationStack {
        LLMSettingsView(viewModel: viewModel)
    }
}
