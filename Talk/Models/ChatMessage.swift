import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isUserMessage: Bool

    init(content: String, isUserMessage: Bool) {
        id = UUID()
        self.content = content
        timestamp = Date()
        self.isUserMessage = isUserMessage
    }
}
