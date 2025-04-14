import SwiftUI

enum ColorTheme {
    static func backgroundColor() -> Color {
        Color(.systemBackground)
    }

    static func textColor() -> Color {
        Color(.label)
    }

    static func accentColor() -> Color {
        Color(.systemGray)
    }

    static func bubbleBackground(isUserMessage: Bool) -> Color {
        if isUserMessage {
            return Color(.systemGray6)
        } else {
            return Color(.systemBackground)
        }
    }

    static func secondaryTextColor() -> Color {
        Color(.secondaryLabel)
    }

    static func borderColor() -> Color {
        Color(.separator)
    }
}
