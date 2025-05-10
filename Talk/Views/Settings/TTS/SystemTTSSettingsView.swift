import AVFoundation
import SwiftData
import SwiftUI

struct SystemTTSSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    @State private var selectedVoiceIdentifier: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Voice")
                    .font(.headline)

                Picker("Flavor", selection: $selectedVoiceIdentifier) {
                    ForEach(availableVoices, id: \.identifier) { voice in
                        Text("\(voice.name) - \(voice.language)").tag(voice.identifier)
                    }
                }
                .pickerStyle(.wheel)
                .onChange(of: selectedVoiceIdentifier) { _, newValue in
                    if let voice = availableVoices.first(where: { $0.identifier == newValue }) {
                        var settings = viewModel.systemTTSSettings
                        settings.voiceIdentifier = voice.identifier
                        settings.language = voice.language
                        viewModel.systemTTSSettings = settings
                    }
                }
                .frame(height: 120)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 16) {
                SettingsSlider(
                    title: "Speech Rate",
                    value: Binding(
                        get: { viewModel.systemTTSSettings.rate },
                        set: {
                            var settings = viewModel.systemTTSSettings
                            settings.rate = $0
                            viewModel.systemTTSSettings = settings
                        }
                    ),
                    range: 0.1 ... 1.0,
                    step: 0.05
                )

                SettingsSlider(
                    title: "Pitch",
                    value: Binding(
                        get: { viewModel.systemTTSSettings.pitch },
                        set: {
                            var settings = viewModel.systemTTSSettings
                            settings.pitch = $0
                            viewModel.systemTTSSettings = settings
                        }
                    ),
                    range: 0.5 ... 2.0,
                    step: 0.1
                )

                SettingsSlider(
                    title: "Volume",
                    value: Binding(
                        get: { viewModel.systemTTSSettings.volume },
                        set: {
                            var settings = viewModel.systemTTSSettings
                            settings.volume = $0
                            viewModel.systemTTSSettings = settings
                        }
                    ),
                    range: 0.0 ... 1.0,
                    step: 0.1
                )
            }
        }
        .task {
            await loadAvailableVoices()
        }
    }

    private func loadAvailableVoices() async {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        availableVoices = voices.sorted { $0.name < $1.name }
        selectedVoiceIdentifier = viewModel.systemTTSSettings.voiceIdentifier
    }
}
