import Foundation

@MainActor
public protocol TTSPlayback {
    func stop() throws

    var isPlaying: Bool { get }

    func waitForCompletion() async
}

public enum TTSError: Error {
    case networkError(Error)
    case serverError(String)
    case invalidInput
    case processingFailed(String)
    case adapterNotAvailable
}

public protocol TTSService {
    @discardableResult
    func speak(_ text: String) async throws -> TTSPlayback
}

public protocol TTSAdapter {
    @discardableResult
    func speak(_ text: String) async throws -> TTSPlayback
}
