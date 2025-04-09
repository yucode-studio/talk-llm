import SwiftUI
import WhisperKit
import SwiftData

struct WhisperKitSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isDownloading = false
    @State private var downloadProgress: Progress = Progress()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let availableModels = ["tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium", "medium.en"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {           
            VStack(alignment: .leading, spacing: 6) {
                Text("Select Model")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(availableModels, id: \.self) { model in
                        ModelSelectionCard(
                            modelName: model,
                            isSelected: viewModel.whisperKitSettings.modelName == model,
                            onTap: {
                                var settings = viewModel.whisperKitSettings
                                settings.modelName = model
                                viewModel.whisperKitSettings = settings
                            }
                        )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Model Download")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())
                
                Button(action: {
                    Task {
                        await downloadModel()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Download Model")
                            .fontWeight(.medium)
                        Spacer()
                        if isDownloading {
                            ProgressView(downloadProgress)
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(12)
                    .background(
                        isDownloading ?
                        ColorTheme.textColor().opacity(0.7) :
                        ColorTheme.textColor())
                    .foregroundColor(ColorTheme.backgroundColor())
                    .cornerRadius(8)
                }
                .disabled(isDownloading)
            }
            .padding(.vertical, 3)
        }
        .background(ColorTheme.backgroundColor())
        .alert("Download Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @MainActor
    private func downloadModel() async {
        isDownloading = true
        downloadProgress = Progress()
        
        do {
            let modelName = viewModel.whisperKitSettings.modelName
            let url = try await WhisperKitModelManager.downloadModel(modelName){ downloadProgress = $0 }
            print("Model \(modelName) downloaded: \(url)")
            isDownloading = false
        } catch {
            isDownloading = false
            errorMessage = "Failed to download model: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct ModelSelectionCard: View {
    let modelName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(modelName)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ColorTheme.backgroundColor() : ColorTheme.textColor())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? ColorTheme.textColor() : ColorTheme.backgroundColor())
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? ColorTheme.textColor() : ColorTheme.borderColor(), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("WhisperKitSettingsView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SettingsModel.self, configurations: config)
    
    let context = container.mainContext
    if try! context.fetch(FetchDescriptor<SettingsModel>()).isEmpty {
        context.insert(SettingsModel())
    }
    
    let viewModel = SettingsViewModel(modelContext: context)
    
    var settings = WhisperKitSettings()
    settings.modelName = "small"
    viewModel.whisperKitSettings = settings
    
    return ScrollView {
        WhisperKitSettingsView(viewModel: viewModel)
            .padding()
    }
}

#Preview("ModelSelectionCard") {
    HStack(spacing: 12) {
        ModelSelectionCard(
            modelName: "tiny",
            isSelected: true,
            onTap: {}
        )
        
        ModelSelectionCard(
            modelName: "base",
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
