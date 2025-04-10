//
//  WhisperKitModelManager.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//
import Foundation
import WhisperKit

struct WhisperKitModelManager {
    static let downloadedModelsKey = "whisperKitDownloadedModels"
    static let modelURLKey = "whisperKitModelURL"

    static func getDownloadedModelsNames() -> [String] {
        let models = UserDefaults.standard.array(forKey: downloadedModelsKey) as? [String] ?? []
        return models
    }

    static func addDownloadedModel(_ model: String) {
        var models = getDownloadedModelsNames()
        models.append(model)
        UserDefaults.standard.set(models, forKey: downloadedModelsKey)
    }

    static func downloadModel(_ variant: String, progressCallback: @escaping ((Progress) -> Void)) async throws -> URL {
        let url = try await WhisperKit.download(
            variant: variant,
            progressCallback: progressCallback
        )
        
        Self.addDownloadedModel(variant)
        
        UserDefaults.standard.set(url.path(), forKey: modelURLKey)
        return url
    }
    
    static func config(for variant: String) async throws -> WhisperKitConfig {
        guard let modelFolder = UserDefaults.standard.string(forKey: modelURLKey) else {
            throw SettingsServiceError.invalidConfiguration("WhisperKit requires downloading a speech model on first launch to enable transcription, please check your settings.")
        }
        return WhisperKitConfig(
            model: variant,
            modelFolder: modelFolder,
            download: false,
            useBackgroundDownloadSession: false,
        )
    }
}
