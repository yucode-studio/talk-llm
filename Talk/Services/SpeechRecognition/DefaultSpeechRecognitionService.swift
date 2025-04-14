import Foundation
import WhisperKit

public class DefaultSpeechRecognitionService: SpeechRecognitionService {
    private let adapter: SpeechRecognitionAdapter

    public init(adapter: SpeechRecognitionAdapter) {
        self.adapter = adapter
    }

    public func recognizeSpeech(pcmData: [Int16]) async throws -> SpeechRecognitionResult {
        guard !pcmData.isEmpty else {
            throw SpeechRecognitionError.invalidInput
        }

        return try await adapter.recognize(pcmData: pcmData)
    }
}

public enum SpeechRecognitionServiceFactory {
    public static func createWhisperCppService(serverURL: URL) -> SpeechRecognitionService {
        let adapter = WhisperCppServerAdapter(serverURL: serverURL)
        return DefaultSpeechRecognitionService(adapter: adapter)
    }

    public static func createWhisperKitService(modelName: String, language: String? = nil) async throws -> SpeechRecognitionService {
        let config = try await WhisperKitModelManager.config(for: modelName)
        let adapter = try await WhisperKitAdapter(config: config, language: language)

        return DefaultSpeechRecognitionService(adapter: adapter)
    }
}
