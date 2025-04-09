import Foundation
import WhisperKit

public class WhisperKitAdapter: SpeechRecognitionAdapter {
    
    private let whisperKit: WhisperKit
    private let language: String?
    
    public init(config: WhisperKitConfig, language: String? = nil) async throws {
        self.whisperKit = try await WhisperKit(config)
        self.language = language
    }
    
    public func recognize(pcmData: [Int16]) async throws -> SpeechRecognitionResult {
        let samples = convertPCMInt16ToFloatArray(pcmData)
        
        var decodeOptions = DecodingOptions()
        if let language = language {
            decodeOptions.language = language
        }
        decodeOptions.task = .transcribe
                
        let transcriptionResults = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: decodeOptions,
            callback: { _ in nil }
        )
        
        return try handleResults(transcriptionResults)
    }

    
    func convertPCMInt16ToFloatArray(_ pcm: [Int16]) -> [Float] {
        pcm.map { Float($0) / 32768.0 }
    }

    private func handleResults(_ results: [TranscriptionResult]) throws -> SpeechRecognitionResult {
        guard !results.isEmpty else {
            throw SpeechRecognitionError.processingFailed("no transcription result")
        }
        
        let text = results.compactMap { $0.text }.joined(separator: " ")
        
        let detectedLanguage = language ?? "en"
        
        let additionalInfo: [String: Any] = [
            "segments": results.count,
            "results": results.map { transcription -> [String: Any] in
                var segment: [String: Any] = [
                    "text": transcription.text
                ]
                
                    var segmentInfos: [[String: Any]] = []
                    
                    for seg in transcription.segments {
                        var segInfo: [String: Any] = [:]
                        
                        segInfo["text"] = seg.text
                        segInfo["start"] = seg.start
                        segInfo["end"] = seg.end
                        segInfo["id"] = seg.id
                        
                        if let words = seg.words {
                            segInfo["words"] = words
                        }
                        
                        segmentInfos.append(segInfo)
                    }
                    
                    segment["segments"] = segmentInfos
                
                return segment
            }
        ]
        
        return SpeechRecognitionResult(
            text: text,
            language: detectedLanguage,
            additionalInfo: additionalInfo
        )
    }
}

public typealias ProgressHandler = (TranscriptionProgress) -> Bool?

public struct WhisperKitRequestOptions {
    public var language: String?
    public var task: String?
    public var temperature: Float?
    
    public var sampleLength: Int?
    public var logProbThreshold: Float?
    public var noSpeechThreshold: Float?
    public var progressCallback: ProgressHandler?
    
    public init(language: String? = nil, task: String? = "transcribe", temperature: Float? = 0.0) {
        self.language = language
        self.task = task
        self.temperature = temperature
    }
    
    func toDecodingOptions() -> DecodingOptions {
        var options = DecodingOptions()
        
        if let language = language {
            options.language = language
        }
        
        if let task = task, task == "translate" {
            options.task = .translate
        } else {
            options.task = .transcribe
        }
        
        if let temperature = temperature {
            options.temperature = temperature
        }
        
        if let sampleLength = sampleLength {
            options.sampleLength = sampleLength
        }
        
        if let logProbThreshold = logProbThreshold {
            options.logProbThreshold = logProbThreshold
        }
        
        if let noSpeechThreshold = noSpeechThreshold {
            options.noSpeechThreshold = noSpeechThreshold
        }
        
        return options
    }
} 
