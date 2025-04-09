import Foundation
import Combine

public struct LLMMessage {
    public let content: String
    public let role: String
    public let additionalInfo: [String: Any]?
    
    public init(content: String, role: String = "assistant", additionalInfo: [String: Any]? = nil) {
        self.content = content
        self.role = role
        self.additionalInfo = additionalInfo
    }
}

public struct LLMRequest {
    public let messages: [LLMMessage]
    public let model: String
    public let temperature: Float
    public let additionalParams: [String: Any]?
    
    public init(
        messages: [LLMMessage],
        model: String = "gpt-4o",
        temperature: Float = 0.7,
        additionalParams: [String: Any]? = nil
    ) {
        self.messages = messages
        self.model = model
        self.temperature = temperature
        self.additionalParams = additionalParams
    }
}

public enum LLMError: Error {
    case networkError(Error)
    case serverError(String)
    case invalidInput
    case processingFailed(String)
    case adapterNotAvailable
    case streamCancelled
}

public protocol LLMService {

    func sendMessage(_ request: LLMRequest) async throws -> LLMMessage
    
    func streamMessage(_ request: LLMRequest) -> AsyncThrowingStream<String, Error>
}

public protocol LLMAdapter {

    func sendMessage(_ request: LLMRequest) async throws -> LLMMessage
    
    func streamMessage(_ request: LLMRequest) -> AsyncThrowingStream<String, Error>
}
