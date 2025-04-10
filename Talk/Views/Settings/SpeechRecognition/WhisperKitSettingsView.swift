import SwiftUI
import WhisperKit
import SwiftData

struct WhisperKitSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isDownloading = false
    @State private var downloadProgress: Progress = Progress()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var downloadModels = WhisperKitModelManager.getDownloadedModelsNames()
    
    let availableModels = [
        ("tiny", "~73 MB"),
        ("tiny.en", "~145 MB"),
        ("base", "~139 MB"),
        ("base.en", "~139 MB"),
        ("small", "~463 MB"),
        ("small.en", "~463 MB"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {           
            VStack(alignment: .leading, spacing: 6) {
                Text("Select Model")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(availableModels, id: \.self.0) { (model, size) in
                        ModelSelectionCard(
                            modelName: model,
                            size: size,
                            downloaded: downloadModels.contains(model),
                            selected: viewModel.whisperKitSettings.modelName == model,
                            onTap: {
                                var settings = viewModel.whisperKitSettings
                                settings.modelName = model
                                viewModel.whisperKitSettings = settings
                            }
                        )
                    }
                }
            }

            Text("WhisperKit requires downloading a speech model on your device to enable transcription.")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(ColorTheme.secondaryTextColor())
            
            let downloaded = WhisperKitModelManager.getDownloadedModelsNames().contains(viewModel.whisperKitSettings.modelName)
            
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
                        Text(downloaded ? "Load Model" : "Download Model")
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
            
            if isDownloading {
                Text(
                    "The model is \(downloaded ? "loading" : "downloading"), please wait for the download to complete. This may take some time.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryTextColor())
                    .transition(.opacity)
            }
        }
        .background(ColorTheme.backgroundColor())
        .alert("Download Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear{
            print(downloadModels)
        }
    }
    
    @MainActor
    private func downloadModel() async {
        withAnimation{
            isDownloading = true
        }
        
        downloadProgress = Progress()
        
        do {
            let modelName = viewModel.whisperKitSettings.modelName
            let url = try await WhisperKitModelManager.downloadModel(modelName){ downloadProgress = $0 }
            print("Model \(modelName) downloaded: \(url)")
        } catch {
            errorMessage = "Failed to download model: \(error.localizedDescription)"
            showingError = true
        }
        
        withAnimation{
            isDownloading = false
            downloadModels = WhisperKitModelManager.getDownloadedModelsNames()
        }
    }
}

struct ModelSelectionCard: View {
    let modelName: String
    let size: String
    let downloaded: Bool
    let selected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack {
                    Text(modelName)
                        .font(.system(size: 14, weight: selected ? .semibold : .regular))
                    if downloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }
                Text(size)
                    .font(.system(size: 10))
            }
            .foregroundColor(selected ? ColorTheme.backgroundColor() : ColorTheme.textColor())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? ColorTheme.textColor() : ColorTheme.backgroundColor())
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? ColorTheme.textColor() : ColorTheme.borderColor(), lineWidth: 1)
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
            size: "~100Mb",
            downloaded: true,
            selected: true,
            onTap: {}
        )
        
        ModelSelectionCard(
            modelName: "base",
            size: "~100Mb",
            downloaded: false,
            selected: false,
            onTap: {}
        )
    }
    .padding()
}
