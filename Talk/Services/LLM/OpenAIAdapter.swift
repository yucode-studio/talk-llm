import Alamofire
import Combine
import EventSource
import Foundation

struct ChatCompletionChunk: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatCompletionChunkChoice]

    struct ChatCompletionChunkChoice: Decodable {
        let index: Int
        let delta: ChatCompletionChunkDelta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct ChatCompletionChunkDelta: Decodable {
        let role: String?
        let content: String?
    }
}

public class OpenAIAdapter: LLMAdapter {
    private let baseURL: URL
    private let apiKey: String
    private let session: Session
    private let logger = DebugLogger(tag: "OpenAIAdapter")

    public init(
        baseURL: URL,
        apiKey: String
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        session = Session(configuration: configuration)

        logger.info("OpenAIAdapter initialed")
    }

    public func sendMessage(_ request: LLMRequest) async throws -> LLMMessage {
        let url = baseURL.appendingPathComponent("chat/completions")

        let requestBody = createRequestBody(from: request, stream: false)

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)",
        ]

        do {
            logger.debug("Send request: \(requestBody)")
            logger.debug("URL: \(url)")
            logger.debug("Headers: \(headers)")
            let response = try await session.request(url, method: .post, parameters: requestBody, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .serializingData()
                .value

            return try handleResponse(data: response)
        } catch {
            logger.error("request failed: \(error.localizedDescription)")
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
                let url = baseURL.appendingPathComponent("chat/completions")

                let requestBody = createRequestBody(from: request, stream: true)

                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                } catch {
                    logger.error("create request body failed: \(error.localizedDescription)")
                    continuation.finish(throwing: LLMError.invalidInput)
                    return
                }

                let eventSource = EventSource(mode: .dataOnly)
                let dataTask = await eventSource.dataTask(for: urlRequest)

                for await event in await dataTask.events() {
                    switch event {
                    case .open:
                        logger.debug("SSE opened")

                    case let .error(error):
                        logger.error("SSE error: \(error.localizedDescription)")
                        continuation.finish(throwing: LLMError.networkError(error))

                    case let .event(event):
                        if event.data == "[DONE]" {
                            logger.debug("receive [DONE], stream end")
                            continuation.finish()
                            continue
                        }

                        if let data = event.data?.data(using: .utf8) {
                            do {
                                let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)

                                if let content = chunk.choices.first?.delta.content {
                                    logger.debug("receive token: \(content)")
                                    continuation.yield(content)
                                }

                                if let finishReason = chunk.choices.first?.finishReason,
                                   finishReason == "stop"
                                {
                                    logger.debug("end reason: stop")
                                    continuation.finish()
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

    private func createRequestBody(from request: LLMRequest, stream: Bool) -> [String: Any] {
        let openAIMessages = request.messages.map { message -> [String: Any] in
            let openAIMessage: [String: Any] = [
                "role": message.role,
                "content": message.content,
            ]
            return openAIMessage
        }

        var body: [String: Any] = [
            "model": request.model,
            "messages": openAIMessages,
            "temperature": request.temperature,
            "stream": stream,
        ]

        if let additionalParams = request.additionalParams {
            for (key, value) in additionalParams {
                body[key] = value
            }
        }

        logger.debug("create API request, stream: \(stream), model: \(request.model)")

        return body
    }

    private func handleResponse(data: Data) throws -> LLMMessage {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("connot parse server response")
            throw LLMError.processingFailed("connot parse server response")
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String
        {
            logger.error("server error: \(message)")
            throw LLMError.serverError(message)
        }

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let role = message["role"] as? String
        else {
            logger.error("response invailed")
            throw LLMError.processingFailed("response invailed")
        }

        return LLMMessage(
            content: content,
            role: role,
            additionalInfo: json
        )
    }
}
