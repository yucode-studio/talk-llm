//
//  VADSettingsView.swift
//  Talk
//
//  Created by Yu on 2025/4/9.
//

import SwiftData
import SwiftUI

struct VADSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPicker(
                    title: "Select VAD Service",
                    selection: Binding(
                        get: { viewModel.selectedVADService },
                        set: { viewModel.selectedVADService = $0 }
                    )
                )

                if viewModel.selectedVADService == .cobra {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsTextField(
                            title: "Access Key",
                            text: Binding(
                                get: { viewModel.cobraSettings.accessKey },
                                set: {
                                    var settings = viewModel.cobraSettings
                                    settings.accessKey = $0
                                    viewModel.cobraSettings = settings
                                }
                            ),
                            placeholder: "Enter Cobra VAD access key",
                            isSecure: true
                        )
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("VAD Settings")
        .background(ColorTheme.backgroundColor())
    }
}

#Preview("VADSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    return NavigationStack {
        VADSettingsView(viewModel: viewModel)
    }
}
