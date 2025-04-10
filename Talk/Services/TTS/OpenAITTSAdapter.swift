import Foundation
import AVFoundation
import ChunkedAudioPlayer
import CoreMedia
import Combine
import Alamofire

public class OpenAITTSAdapter: TTSAdapter {
    
    public enum ResponseFormat: String, Encodable, CaseIterable {
        case mp3 = "mp3"
        case wav = "wav"
        case aac = "aac"
        
        var fileType: AudioFileTypeID {
            switch self {
            case .mp3: return kAudioFileMP3Type
            case .wav: return kAudioFileWAVEType
            case .aac: return kAudioFileAAC_ADTSType
            }
        }
    }
    
    struct TTSParameters: Encodable {
        let model: String
        let voice: String
        let input: String
        let responseFormat: ResponseFormat
        let speed: Float
        let stream: Bool
        let instructions: String?
        
        enum CodingKeys: String, CodingKey {
            case model
            case voice
            case input
            case responseFormat = "response_format"
            case speed
            case stream
            case instructions
        }
    }
    
    @MainActor
    class OpenAITTSPlayback: TTSPlayback {
        private let player: AudioPlayer
        private var completionContinuation: CheckedContinuation<Void, Never>?
        
        init(player: AudioPlayer) {
            self.player = player
        }
        
        public func stop() throws {
            player.stop()
        }
        
        var isPlaying: Bool {
            return player.currentState == .playing
        }
        
        func resumeContinuation(){
            if let continuation = completionContinuation {
                continuation.resume()
                completionContinuation = nil
            }
        }
        
        public func waitForCompletion() async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.completionContinuation = continuation
            }
        }
    }
    
    private class TTSDataStream: NSObject, URLSessionDataDelegate {
        private var session: URLSession?
        private var onComplete: (() -> Void)?
        private let request: URLRequest
        private let continuation: AsyncThrowingStream<Data, Error>.Continuation
        
        init(request: URLRequest, continuation: AsyncThrowingStream<Data, Error>.Continuation) {
            self.request = request
            self.continuation = continuation
            super.init()
            
            let configuration = URLSessionConfiguration.default
            configuration.waitsForConnectivity = true
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
            self.continuation.onTermination = { [weak self] _ in self?.cancel() }
        }
        
        func start() {
            session?.dataTask(with: request).resume()
        }
        
        func cancel() {
            session?.invalidateAndCancel()
        }
        
        func onComplete(_ action: @escaping () -> Void) {
            onComplete = action
        }
                
        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive response: URLResponse,
            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
        ) {
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let error = NSError(
                    domain: "OpenAI.TTS",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"]
                )
                continuation.finish(throwing: error)
                completionHandler(.cancel)
                return
            }
            
            completionHandler(.allow)
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            continuation.yield(data)
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            continuation.finish(throwing: error)
            onComplete?()
        }
    }
    
    private let apiKey: String
    private let model: String
    private let voice: String
    private let responseFormat: ResponseFormat
    private let speed: Float
    private let instructions: String?
    private let baseURL: URL
    
    private var activeStreams: Set<TTSDataStream> = []
    private var playback: OpenAITTSPlayback?
    private var cancellables = Set<AnyCancellable>()
    private var audioPlayer: AudioPlayer?
    private var completionContinuation: CheckedContinuation<Void, Never>?
    
    public init(
        apiKey: String,
        model: String,
        voice: String,
        responseFormat: ResponseFormat = .wav,
        speed: Float = 1.0,
        instructions: String? = nil,
        baseURL: String
    ) {
        self.apiKey = apiKey
        self.model = model
        self.voice = voice
        self.responseFormat = responseFormat
        self.speed = speed
        self.instructions = instructions
        
        if let url = URL(string: baseURL) {
            self.baseURL = url
        } else {
            self.baseURL = URL(string: "https://example.com")!
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession error: \(error)")
        }
    }
    
    @MainActor
    private func handlePlaybackCompletion() {
        playback?.resumeContinuation()
        playback = nil
    }
    
    @discardableResult
    public func speak(_ text: String) async throws -> TTSPlayback {
        let parameters = TTSParameters(
            model: model,
            voice: voice,
            input: text,
            responseFormat: responseFormat,
            speed: speed,
            stream: true,
            instructions: instructions
        )
        
        let dataStream = createTTSDataStream(parameters: parameters)
        
        await stopActivePlayback()
        
        let player = await getOrCreatePlayer()
        
        await player.start(dataStream, type: responseFormat.fileType)
        
        let playback = await OpenAITTSPlayback(player: player)
        
        self.playback = playback
                
        return playback
    }
    
    @MainActor
    private func getOrCreatePlayer() -> AudioPlayer {
        if let player = audioPlayer {
            return player
        } else {
            let player = AudioPlayer()
            
            player.$currentState
                .sink { [weak self] state in
                    if state == .completed || state == .failed {
                        self?.handlePlaybackCompletion()
                    }
                }
                .store(in: &cancellables)
            
            player.$currentError
                .compactMap { $0 }
                .sink { [weak self] error in
                    print("play error: \(error.localizedDescription)")
                    self?.handlePlaybackCompletion()
                }
                .store(in: &cancellables)
            
            audioPlayer = player
            return player
        }
    }
    
    @MainActor
    private func stopActivePlayback() async {
        if let player = audioPlayer, player.currentState == .playing || player.currentState == .paused {
            player.stop()
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func createTTSDataStream(parameters: TTSParameters) -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream<Data, Error> { continuation in
            let request = createRequest(parameters: parameters)
            
            let dataStream = TTSDataStream(request: request, continuation: continuation)
            activeStreams.insert(dataStream)
            
            dataStream.onComplete { [weak self] in
                guard let self = self else { return }
                self.activeStreams.remove(dataStream)
            }
            
            dataStream.start()
        }
    }
    
    private func createRequest(parameters: TTSParameters) -> URLRequest {
        let url = baseURL.appendingPathComponent("audio/speech")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let body: Data
        do {
            body = try encoder.encode(parameters)
        } catch {
            print("encode error: \(error)")
            body = Data()
        }
        
        let headers = [
            "Content-Type": "application/json",
            "Content-Length": String(body.count),
            "Authorization": "Bearer \(apiKey)"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        return request
    }
} 

