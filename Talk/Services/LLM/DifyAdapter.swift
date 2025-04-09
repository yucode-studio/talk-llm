import Foundation
import Combine
import Alamofire
import EventSource

public class DifyAdapter: LLMAdapter {
    
    private let baseURL: URL
    private let apiKey: String
    private let session: Session
    private let logger = DebugLogger(tag: "DifyAdapter")
    
    public init(
        baseURL: URL = URL(string: "https://api.dify.ai/v1")!,
        apiKey: String
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        self.session = Session(configuration: configuration)
        
        logger.info("DifyAdapter initialed")
    }
    
    public func sendMessage(_ request: LLMRequest) async throws -> LLMMessage {
        let url = baseURL.appendingPathComponent("chat-messages")
        
        let requestBody = createRequestBody(from: request, responseMode: "blocking")
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        do {
            let response = try await session.request(url, method: .post, parameters: requestBody, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .serializingData()
                .value
            
            return try handleBlockingResponse(data: response)
        } catch {
            logger.error("Request Error: \(error.localizedDescription)")
            if let afError = error as? AFError {
                throw LLMError.networkError(afError)
            } else {
                throw LLMError.processingFailed(error.localizedDescription)
            }
        }
    }
    
    public func streamMessage(_ request: LLMRequest) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                let url = baseURL.appendingPathComponent("chat-messages")
                
                let requestBody = createRequestBody(from: request, responseMode: "streaming")
                
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                } catch {
                    logger.error("Create Request body failed: \(error.localizedDescription)")
                    continuation.finish(throwing: LLMError.invalidInput)
                    return
                }
                
                let eventSource = EventSource(mode: .dataOnly)
                let dataTask = await eventSource.dataTask(for: urlRequest)
                
                for await event in await dataTask.events() {
                    switch event {
                    case .open:
                        logger.debug("SSE open")
                        
                    case .error(let error):
                        logger.error("SSE error: \(error.localizedDescription)")
                        continuation.finish(throwing: LLMError.networkError(error))
                        
                    case .event(let event):
                        if let data = event.data?.data(using: .utf8) {
                            do {
                                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                    continue
                                }
                                
                                guard let eventType = json["event"] as? String else {
                                    continue
                                }
                                
                                switch eventType {
                                case "message":
                                    if let answer = json["answer"] as? String {
                                        logger.debug("receive token: \(answer)")
                                        continuation.yield(answer)
                                    }
                                    
                                case "message_end":
                                    logger.debug("stream end")
                                    continuation.finish()
                                    
                                case "error":
                                    let message = json["message"] as? String ?? "未知错误"
                                    logger.error("Dify stream error: \(message)")
                                    continuation.finish(throwing: LLMError.serverError(message))
                                    
                                case "ping":
                                    break
                                    
                                default:
                                    break
                                }
                            } catch {
                                logger.error("parse JSON error: \(error.localizedDescription), data: \(String(data: data, encoding: .utf8) ?? "connot parse")")
                            }
                        }
                        
                    case .closed:
                        logger.debug("SSE closed")
                        continuation.finish()
                    }
                }
            }
        }
    }
    
    private func createRequestBody(from request: LLMRequest, responseMode: String) -> [String: Any] {
        var userQuery = ""
        for message in request.messages.reversed() {
            if message.role == "user" {
                userQuery = message.content
                break
            }
        }
        
        var body: [String: Any] = [
            "query": userQuery,
            "inputs": [:] as [String: Any],
            "response_mode": responseMode,
            "user": "app_user"
        ]
        
        if let conversationId = request.additionalParams?["conversation_id"] as? String ?? DifyAdapterUtils.getConversationId() {
            body["conversation_id"] = conversationId
        }
        
        if let files = request.additionalParams?["files"] as? [[String: Any]] {
            body["files"] = files
        }
        
        if let autoGenerateName = request.additionalParams?["auto_generate_name"] as? Bool {
            body["auto_generate_name"] = autoGenerateName
        }
        
        if let user = request.additionalParams?["user"] as? String {
            body["user"] = user
        }
        
        logger.debug("create API request, response mode: \(responseMode)")
        
        return body
    }
    
    private func handleBlockingResponse(data: Data) throws -> LLMMessage {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("connot parse server response")
            throw LLMError.processingFailed("connot parse server response")
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            logger.error("response error: \(message)")
            throw LLMError.serverError(message)
        }
        
        guard let answer = json["answer"] as? String else {
            logger.error("response invaild")
            throw LLMError.processingFailed("response invaild")
        }

        // save conversation_id
        if let conversationId = json["conversation_id"] as? String {
            DifyAdapterUtils.saveConversationId(conversationId: conversationId)
        }
        
        return LLMMessage(
            content: answer,
            role: "assistant",
            additionalInfo: json
        )
    }
} 

enum DifyAdapterUtils {
    static let conversationIdKey = "dify_conversation_id"

    static func saveConversationId(conversationId: String) {
        UserDefaults.standard.set(conversationId, forKey: conversationIdKey)
    }
    static func getConversationId() -> String? {
        return UserDefaults.standard.string(forKey: conversationIdKey)
    }
    static func clearConversationId() {
        UserDefaults.standard.removeObject(forKey: conversationIdKey)
    }
}
