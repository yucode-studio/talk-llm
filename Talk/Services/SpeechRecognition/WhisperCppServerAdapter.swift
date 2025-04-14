import Alamofire
import Foundation

public class WhisperCppServerAdapter: SpeechRecognitionAdapter {
    private let serverURL: URL
    private let language: String?

    public init(serverURL: URL, language: String? = nil) {
        self.serverURL = serverURL
        self.language = language
    }

    public func recognize(pcmData: [Int16]) async throws -> SpeechRecognitionResult {
        let fileData = MultipartFormData()

        let wavData = AudioHelper.convertToWavData(pcmData)

        fileData.append(wavData, withName: "file", fileName: "audio.wav", mimeType: "audio/wav")

        if let language = language {
            fileData.append(language.data(using: .utf8)!, withName: "language")
        }

        fileData.append("json".data(using: .utf8)!, withName: "response_format")

        let response = try await AF.upload(multipartFormData: fileData, to: serverURL)
            .validate()
            .serializingData()
            .value

        return try handleResponse(data: response)
    }

    private func handleResponse(data: Data) throws -> SpeechRecognitionResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SpeechRecognitionError.processingFailed("connot parse server response")
        }

        if let errorMessage = json["error"] as? String {
            throw SpeechRecognitionError.serverError(errorMessage)
        }

        guard let text = json["text"] as? String else {
            throw SpeechRecognitionError.processingFailed("no text field in response")
        }

        var language = "en"
        if let lang = json["language"] as? String {
            language = lang
        }

        return SpeechRecognitionResult(
            text: text,
            language: language,
            additionalInfo: json
        )
    }
}

public struct WhisperRequestOptions {
    public var language: String?
    public var responseFormat: String = "json"
    public var temperature: Float = 0.0
    public var temperatureInc: Float = 0.2

    public var translate: Bool?
    public var detectLanguage: Bool?
    public var prompt: String?
    public var maxContext: Int?
    public var wordThold: Float?
    public var noSpeechThold: Float?
    public var suppressNonSpeech: Bool?

    public init(language: String? = nil, responseFormat: String = "json", temperature: Float = 0.0) {
        self.language = language
        self.responseFormat = responseFormat
        self.temperature = temperature
    }

    func addToFormData(_ formData: MultipartFormData) {
        if let language = language {
            formData.append(language.data(using: .utf8)!, withName: "language")
        }

        formData.append(responseFormat.data(using: .utf8)!, withName: "response_format")
        formData.append(String(temperature).data(using: .utf8)!, withName: "temperature")
        formData.append(String(temperatureInc).data(using: .utf8)!, withName: "temperature_inc")

        if let translate = translate {
            formData.append(String(translate).data(using: .utf8)!, withName: "translate")
        }

        if let detectLanguage = detectLanguage {
            formData.append(String(detectLanguage).data(using: .utf8)!, withName: "detect_language")
        }

        if let prompt = prompt {
            formData.append(prompt.data(using: .utf8)!, withName: "prompt")
        }

        if let maxContext = maxContext {
            formData.append(String(maxContext).data(using: .utf8)!, withName: "max_context")
        }

        if let wordThold = wordThold {
            formData.append(String(wordThold).data(using: .utf8)!, withName: "word_thold")
        }

        if let noSpeechThold = noSpeechThold {
            formData.append(String(noSpeechThold).data(using: .utf8)!, withName: "no_speech_thold")
        }

        if let suppressNonSpeech = suppressNonSpeech {
            formData.append(String(suppressNonSpeech).data(using: .utf8)!, withName: "suppress_non_speech")
        }
    }
}
