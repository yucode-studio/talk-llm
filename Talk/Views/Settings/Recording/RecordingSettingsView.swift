//
//  RecordingSettingsView.swift
//  Talk
//
//  Created by Yu on 2025/4/9.
//

import SwiftData
import SwiftUI

struct RecordingSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPicker(
                    title: "Select Mode",
                    selection: Binding(
                        get: { viewModel.selectedRecordingMode },
                        set: { viewModel.selectedRecordingMode = $0 }
                    )
                )

                if viewModel.selectedRecordingMode == .manual {
                    Text("Tap once to start recording, tap again to stop and send the voice message.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ColorTheme.secondaryTextColor())
                } else if viewModel.selectedRecordingMode == .auto {
                    Text("Tap to start recording, system automatically detects speech pauses and sends message. Next conversation begins with voice recording.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ColorTheme.secondaryTextColor())
                }
            }
            .padding(20)
        }
        .navigationTitle("Recording Settings")
        .background(ColorTheme.backgroundColor())
    }
}

#Preview("RecordingSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)

    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }

    let viewModel = SettingsViewModel(modelContext: context)
    return NavigationStack {
        RecordingSettingsView(viewModel: viewModel)
    }
}
