import SwiftData
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(modelContext: ModelContext) {
        let viewModel = SettingsViewModel(modelContext: modelContext)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: RecordingSettingsView(viewModel: viewModel)) {
                        SettingRow(
                            title: "Recording Mode",
                            subtitle: viewModel.selectedRecordingMode.rawValue,
                            iconName: "waveform.badge.microphone"
                        )
                    }

                    NavigationLink(destination: LLMSettingsView(viewModel: viewModel)) {
                        SettingRow(
                            title: "Large Language Model",
                            subtitle: viewModel.selectedLLMService.rawValue,
                            iconName: "brain"
                        )
                    }

                    NavigationLink(destination: SpeechRecognitionSettingsView(viewModel: viewModel)) {
                        SettingRow(
                            title: "Speech Recognition",
                            subtitle: viewModel.selectedSpeechService.rawValue,
                            iconName: "waveform"
                        )
                    }

                    NavigationLink(destination: TTSSettingsView(viewModel: viewModel)) {
                        SettingRow(
                            title: "Text-to-Speech",
                            subtitle: viewModel.selectedTTSService.rawValue,
                            iconName: "speaker.wave.2"
                        )
                    }
                } header: {
                    Text("Service Settings")
                }

                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingRow(
                            title: "About",
                            subtitle: "Information, Privacy & Support",
                            iconName: "info.circle"
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(ColorTheme.backgroundColor())
        }
        .tint(ColorTheme.accentColor())
    }
}

#Preview("SettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    return SettingsView(modelContext: context)
}
