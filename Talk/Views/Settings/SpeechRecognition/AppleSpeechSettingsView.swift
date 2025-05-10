import Speech
import SwiftData
import SwiftUI

struct AppleSpeechSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    private var availableLocales: [String] = []

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        availableLocales = Self.loadAvailableLocales()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recognition Language")
                .font(.headline)
            Picker("Recognition Language", selection: Binding(
                get: { viewModel.appleSpeechSettings.language },
                set: { viewModel.appleSpeechSettings.language = $0 }
            )) {
                ForEach(availableLocales, id: \.self) { language in
                    Text(displayName(for: language))
                        .tag(language)
                }
            }
            .pickerStyle(.wheel)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }

    private static func loadAvailableLocales() -> [String] {
        return Array(SFSpeechRecognizer.supportedLocales()).map { $0.identifier }
    }

    /// Helper to display language names in a more readable format
    private func displayName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        let languageName = locale.localizedString(forIdentifier: languageCode) ?? languageCode
        return languageName
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    let settings = SettingsModel()
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(settings)
    }

    let viewModel = SettingsViewModel(modelContext: context)

    return ScrollView {
        AppleSpeechSettingsView(viewModel: viewModel)
    }
}
