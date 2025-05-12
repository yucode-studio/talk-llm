//
//  ChatHistoryView.swift
//  Talk
//
//  Created by Yu on 2025/4/6.
//

import SwiftData
import SwiftUI

struct ChatHistoryView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.timestamp, order: .reverse) private var messages: [ChatMessage]

    @State private var showingDeleteAlert = false

    @State private var appeared = false

    private let bottomContent: Content

    init(@ViewBuilder bottomContent: () -> Content) {
        self.bottomContent = bottomContent()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if messages.isEmpty {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 64))
                            .foregroundColor(ColorTheme.secondaryTextColor())

                        Text("No chat history")
                            .font(.title2)
                            .foregroundColor(ColorTheme.secondaryTextColor())
                    }

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(messagesGroupedByDay.keys.sorted(by: >), id: \.self) { date in
                                Section(
                                    header:
                                    Text(formatDate(date))
                                        .foregroundColor(ColorTheme.secondaryTextColor())
                                        .font(.footnote)

                                ) {
                                    ForEach(messagesGroupedByDay[date] ?? [], id: \.id) { message in
                                        MessageBubbleView(message: message)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }

                VStack {
                    Spacer()

                    bottomContent
                        .scaleEffect(appeared ? 1 : 0)
                        .onAppear {
                            withAnimation(.spring) {
                                appeared = true
                            }
                        }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(ColorTheme.textColor())
                    }
                    .disabled(messages.isEmpty)
                }
            }
            .alert("Delete All Messages", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    ChatHistory.clearAllMessages(in: modelContext)
                }
            } message: {
                Text("Are you sure you want to delete all chat history? This action cannot be undone.")
            }
            .background(ColorTheme.backgroundColor())
        }
    }

    private var messagesGroupedByDay: [Date: [ChatMessage]] {
        let calendar = Calendar.current
        var result = [Date: [ChatMessage]]()

        for message in messages {
            let date = calendar.startOfDay(for: message.timestamp)
            var messagesForDay = result[date] ?? []

            messagesForDay.append(message)
            result[date] = messagesForDay
        }

        return result
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview("ChatHistoryView") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)

        let modelContext = container.mainContext

        let messages = [
            ChatMessage(content: "Hello, how can I help you?", isUserMessage: false),
            ChatMessage(content: "I'd like to know today's weather.", isUserMessage: true),
            ChatMessage(content: "Today is sunny with temperatures between 22–28°C. It's great weather for outdoor activities.", isUserMessage: false),
            ChatMessage(content: "Thanks! Any recommended activities for today?", isUserMessage: true),
            ChatMessage(content: "Given the weather, a picnic, hiking, or visiting an outdoor attraction would be great. I recommend checking out the local city park—there's a small music concert there today.", isUserMessage: false),
        ]

        for message in messages {
            modelContext.insert(message)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving sample messages: \(error)")
        }

        return ChatHistoryView {
            ColorCircle(listening: false, speaking: false, responding: false, audioLevel: 0.0) {}
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}

#Preview("ChatHistoryView Empty") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)

        let modelContext = container.mainContext

        do {
            try modelContext.save()
        } catch {
            print("Error saving sample messages: \(error)")
        }

        return ChatHistoryView {
            Text("Content")
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
