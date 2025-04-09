//
//  WhisperKitModelManager.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//
import Foundation
import WhisperKit

struct WhisperKitModelManager {
    static func downloadModel(_ variant: String, progressCallback: @escaping ((Progress) -> Void)) async throws -> URL {
        let url = try await WhisperKit.download(
            variant: variant,
            progressCallback: progressCallback
        )
        UserDefaults.standard.set(url.path(), forKey: "whisperKitModelURL")
        return url
    }
    
    static func config(for variant: String) async throws -> WhisperKitConfig {
        guard let modelFolder = UserDefaults.standard.string(forKey: "whisperKitModelURL") else {
            throw SettingsServiceError.invalidConfiguration("WhisperKit model is not downloaded")
        }
        return WhisperKitConfig(
            model: variant,
            modelFolder: modelFolder,
            download: false,
            useBackgroundDownloadSession: false,
        )
    }
}
