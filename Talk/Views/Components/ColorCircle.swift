//
//  ColorCircle.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import SwiftUI

struct ColorCircle: View {
    var listening: Bool = false // Whether recording is active
    var speaking: Bool = false // Whether real speech is detected
    var responding: Bool = false // Whether the circle is responding to the audio level
    var audioLevel: Float = 0.0
    let action: () -> Void

    private let baseRadius: CGFloat = 60
    private let maxScaleFactor: CGFloat = 1.5

    @State private var maxLevelSeen: Float = 0.2

    private var currentScale: CGFloat {
        if responding {
            return 1.0 // Fixed size, not responding to volume
        }
        if listening {
            let baseScale: CGFloat = 1.2
            if speaking {
                let normalizedLevel = maxLevelSeen > 0 ? min(audioLevel / maxLevelSeen, 1.0) : 0
                let additionalScale = CGFloat(normalizedLevel) * 0.3
                return baseScale + additionalScale
            }
            return baseScale
        }
        return 1.0
    }

    private func bounceOffset(at time: TimeInterval) -> CGFloat {
        let totalCycle = 2.0
        let t = time.truncatingRemainder(dividingBy: totalCycle)

        let bounceDuration = 0.4
        let bounceIndex = Int(t / bounceDuration)
        let phaseInBounce = (t.truncatingRemainder(dividingBy: bounceDuration)) / bounceDuration

        let baseHeight: CGFloat = 60
        let decay = pow(0.6, CGFloat(bounceIndex))
        let height = baseHeight * decay

        let y = -abs(sin(phaseInBounce * .pi)) * height
        return y
    }

    var body: some View {
        Button(action: action) {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let offset = bounceOffset(at: time)

                Circle()
                    .fill(ColorTheme.textColor())
                    .frame(width: baseRadius * 2, height: baseRadius * 2)
                    .scaleEffect(currentScale)
                    .offset(y: responding ? offset : 0)
                    .animation(.spring(response: 0.2), value: currentScale)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: audioLevel) { _, newLevel in
            if speaking && newLevel > 0 {
                if newLevel > maxLevelSeen {
                    // If new level is higher, update max immediately
                    maxLevelSeen = newLevel
                } else if maxLevelSeen > 0.05 {
                    maxLevelSeen *= 0.995
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 60) {
        ColorCircle(listening: false, speaking: false) {}
        ColorCircle(listening: false, speaking: true, audioLevel: 0.5) {}
        ColorCircle(listening: true, speaking: true, audioLevel: 0.5) {}
    }
    .padding()
}
