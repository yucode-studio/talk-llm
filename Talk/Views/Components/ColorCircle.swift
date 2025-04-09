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
    var audioLevel: Float = 0.0
    let action: () -> Void

    // Base radius and max scale factor
    private let baseRadius: CGFloat = 60
    private let maxScaleFactor: CGFloat = 1.5
    
    // Compute current scale based on state
    private var currentScale: CGFloat {
        if listening {
            // When recording, base scale is 1.2
            let baseScale: CGFloat = 1.2
            
            // If real speech is detected, scale further based on volume
            if speaking {
                // Map audioLevel (0.0–1.0) to extra scale (0.0–0.3)
                let additionalScale = CGFloat(audioLevel) * 0.3
                return baseScale + additionalScale
            }
            
            return baseScale
        }
        
        // Keep original size when not recording
        return 1.0
    }
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(ColorTheme.textColor())
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .scaleEffect(currentScale)
                .animation(.spring(response: 0.2), value: currentScale)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle()) // Use plain style to avoid extra visual effects
    }
}

#Preview {
    VStack(spacing: 60) {
        ColorCircle(listening: false, speaking: false){}
        ColorCircle(listening: false, speaking: true, audioLevel: 0.5){}
        ColorCircle(listening: true, speaking: true, audioLevel: 0.5){}
    }
    .padding()
}
