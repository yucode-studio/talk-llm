import Foundation
import Combine

public class DefaultLLMService: LLMService {
    
    private let adapter: LLMAdapter
    
    public init(adapter: LLMAdapter) {
        self.adapter = adapter
    }
    
    public func sendMessage(_ request: LLMRequest) async throws -> LLMMessage {
        guard !request.messages.isEmpty else {
            throw LLMError.invalidInput
        }
        
        return try await adapter.sendMessage(request)
    }
    
    ///   let stream = llmService.streamMessage(request)
    ///   for try await chunk in stream {
    ///     text += chunk
    ///   }
    public func streamMessage(_ request: LLMRequest) -> AsyncThrowingStream<String,Error> {
        guard !request.messages.isEmpty else {
            return AsyncThrowingStream<String,Error>(bufferingPolicy: .unbounded) { continuation in
                continuation.finish(throwing: LLMError.invalidInput)
            }
        }
        
        return adapter.streamMessage(request)
    }
}

public enum LLMServiceFactory {
    
    public static func createOpenAIService(
        apiKey: String,
        baseURL: URL
    ) -> LLMService {
        let adapter =  OpenAIAdapter(baseURL: baseURL, apiKey: apiKey)

        return DefaultLLMService(adapter: adapter)
    }
    
    public static func createDifyService(
        apiKey: String,
        baseURL: URL?
    ) -> LLMService {
        let adapter: DifyAdapter
        
        if let baseURL = baseURL {
            adapter = DifyAdapter(baseURL: baseURL, apiKey: apiKey)
        } else {
            adapter = DifyAdapter(apiKey: apiKey)
        }
        
        return DefaultLLMService(adapter: adapter)
    }
} 
