import Foundation

public struct SpeechRecognitionResult {
    public let text: String
    public let language: String
    public let additionalInfo: [String: Any]?
    
    public init(text: String, language: String = "en", additionalInfo: [String: Any]? = nil) {
        self.text = text
        self.language = language
        self.additionalInfo = additionalInfo
    }
}

public enum SpeechRecognitionError: Error {
    case networkError(Error)
    case serverError(String)
    case invalidInput
    case processingFailed(String)
    case adapterNotAvailable
}

public protocol SpeechRecognitionService {
    func recognizeSpeech(pcmData: [Int16]) async throws -> SpeechRecognitionResult
}

public protocol SpeechRecognitionAdapter {
    func recognize(pcmData: [Int16]) async throws -> SpeechRecognitionResult
} 
