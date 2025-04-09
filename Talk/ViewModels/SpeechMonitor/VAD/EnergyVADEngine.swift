//
//  EnergyVADEngine.swift
//  Talk
//
//  Created by Yu on 2025/4/9.
//

import Foundation
import WhisperKit

class EnergyVADEngine: VoiceActivityDetector, VADEngine {
    private let threshold: Float

    init(threshold: Float = 0.02) {
        self.threshold = threshold
        super.init(sampleRate: 16000, frameLengthSamples: 1600) // 0.1s
    }

    override func voiceActivity(in waveform: [Float]) -> [Bool] {
        let chunkRatio = Double(waveform.count) / Double(frameLengthSamples)
        let count = Int(chunkRatio.rounded(.up))
        return AudioProcessor.calculateVoiceActivityInChunks(
            of: waveform,
            chunkCount: count,
            frameLengthSamples: frameLengthSamples,
            frameOverlapSamples: frameOverlapSamples,
            energyThreshold: threshold
        )
    }

    private var buffer: [Float] = []

    func process(frame: [Int16]) throws -> Bool {
        let floats = frame.map { Float($0) / Float(Int16.max) }
        buffer.append(contentsOf: floats)

        if buffer.count < frameLengthSamples { return false }

        let segment = Array(buffer.prefix(frameLengthSamples))
        buffer.removeFirst(frameLengthSamples)

        let activity = voiceActivity(in: segment)
        return activity.contains(true)
    }

    static var frameLength: UInt32 { 1600 }
    static var sampleRate: UInt32 { 16000 }

    func delete() {
        buffer.removeAll()
    }
}
