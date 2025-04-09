import SwiftUI
import SwiftData

struct SpeechRecognitionSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPicker(
                    title: "Select Speech Recognition Service",
                    selection: Binding(
                        get: { viewModel.selectedSpeechService },
                        set: { viewModel.selectedSpeechService = $0 }
                    )
                )
                
                if viewModel.selectedSpeechService == .whisperCpp {
                    WhisperCppSettingsView(viewModel: viewModel)
                } else if viewModel.selectedSpeechService == .whisperKit {
                    WhisperKitSettingsView(viewModel: viewModel)
                }
            }
            .padding(20)
        }
        .navigationTitle("Speech Recognition Settings")
        .background(ColorTheme.backgroundColor())
    }
} 

#Preview("SpeechRecognitionSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)
    
    let context = container.mainContext
    let settings = SettingsModel()
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(settings)
    }
    
    let viewModel = SettingsViewModel(modelContext: context)
    return ScrollView {
        SpeechRecognitionSettingsView(viewModel: viewModel)
    }
} 
