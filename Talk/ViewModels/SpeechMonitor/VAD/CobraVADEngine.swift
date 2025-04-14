//
//  CobraVADEngine.swift
//  Talk
//
//  Created by Yu on 2025/4/8.
//

import Cobra
import Combine

class CobraVADEngine: VADEngine {
    private let cobra: Cobra

    /// Probability threshold for detecting speech
    /// Range: 0 to 1. Higher values make the detection more strict.

    private let threshold: Float

    /// Weight for smoothing speech probability to prevent misjudgment caused by sudden changes
    /// Higher values give more weight to new data; lower values result in stronger smoothing

    private let alpha: Float

    /// Current smoothed speech probability value
    private var smoothedProbability: Float = 0.0

    init(accessKey: String, threshold: Float = 0.6, alpha: Float = 0.5) throws {
        cobra = try Cobra(accessKey: accessKey)
        self.threshold = threshold
        self.alpha = alpha
    }

    func process(frame: [Int16]) throws -> Bool {
        let probability = try cobra.process(pcm: frame)

        smoothedProbability = alpha * probability + (1 - alpha) * smoothedProbability

        return smoothedProbability >= threshold
    }

    static var frameLength: UInt32 {
        return Cobra.frameLength
    }

    static var sampleRate: UInt32 {
        return Cobra.sampleRate
    }

    func delete() {
        cobra.delete()
    }
}
