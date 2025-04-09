import SwiftUI
import SwiftData

struct WhisperCppSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {            
            SettingsTextField(
                title: "Server URL",
                text: Binding(
                    get: { viewModel.whisperCppSettings.serverURL },
                    set: { 
                        var settings = viewModel.whisperCppSettings
                        settings.serverURL = $0
                        viewModel.whisperCppSettings = settings 
                    }
                ),
                placeholder: "Enter server URL (e.g. http://localhost:8080/inference)"
            )
        }
    }
} 

#Preview("WhisperCppSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)
    
    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }
    
    let viewModel = SettingsViewModel(modelContext: context)
    
    var settings = WhisperCppSettings()
    settings.serverURL = "http://localhost:8080/inference"
    viewModel.whisperCppSettings = settings
    
    return ScrollView{
        WhisperCppSettingsView(viewModel: viewModel).padding()
    }
}
