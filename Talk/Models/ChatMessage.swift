import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isUserMessage: Bool
    
    init(content: String, isUserMessage: Bool) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.isUserMessage = isUserMessage
    }
} 