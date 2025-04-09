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
    
    // State to track the maximum level seen (for normalization)
    @State private var maxLevelSeen: Float = 0.2 // Start with a reasonable default
    
    // Compute current scale based on state
    private var currentScale: CGFloat {
        if listening {
            // When recording, base scale is 1.2
            let baseScale: CGFloat = 1.2
            
            // If real speech is detected, scale further based on volume
            if speaking {
                // Update max level for dynamic normalization
                // This is tracked in the view body, not here, since this is a computed property
                
                // Normalize current level to 0-1 range based on observed max
                let normalizedLevel = maxLevelSeen > 0 ? min(audioLevel / maxLevelSeen, 1.0) : 0
                
                // Map normalized level (0.0–1.0) to extra scale (0.0–0.3)
                let additionalScale = CGFloat(normalizedLevel) * 0.3
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
        .onChange(of: audioLevel) { newLevel in
            // Track maximum level with decay
            if speaking && newLevel > 0 {
                if newLevel > maxLevelSeen {
                    // If new level is higher, update max immediately
                    maxLevelSeen = newLevel
                } else if maxLevelSeen > 0.05 {
                    // Slowly decay max level over time to adapt to changing volume conditions
                    // This ensures the circle can still react well if someone starts speaking more quietly
                    maxLevelSeen = maxLevelSeen * 0.995
                }
            }
        }
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
