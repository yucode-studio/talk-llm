import Foundation
import SwiftData
import SwiftUI

enum ChatHistory {
    
    private static func fetchMessages(from context: ModelContext) -> [ChatMessage] {
        let descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.timestamp)])
        do {
            return try context.fetch(descriptor)
        } catch {
            print("load chat history error: \(error.localizedDescription)")
            return []
        }
    }
    
    @discardableResult
    static func addMessage(content: String, isUserMessage: Bool, in context: ModelContext) -> ChatMessage {
        let message = ChatMessage(content: content, isUserMessage: isUserMessage)
        context.insert(message)
        
        do {
            try context.save()
            return message
        } catch {
            print("save chat history error: \(error.localizedDescription)")
            return message
        }
    }
    
    static func clearAllMessages(in context: ModelContext) {
        let descriptor = FetchDescriptor<ChatMessage>()
        do {
            let allMessages = try context.fetch(descriptor)
            for message in allMessages {
                context.delete(message)
            }
            try context.save()
            
            // clear Dify conversation id
            DifyAdapterUtils.clearConversationId()
        } catch {
            print("delete all message error: \(error.localizedDescription)")
        }
    }
    
    static func getLatestMessages(count: Int, in context: ModelContext) -> [ChatMessage] {
        let messages = fetchMessages(from: context)
        let startIndex = max(0, messages.count - count)
        return Array(messages[startIndex..<messages.count])
    }
} 
