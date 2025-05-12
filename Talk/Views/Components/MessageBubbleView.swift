import MarkdownUI
import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Markdown(message.content)
                    .textSelection(.enabled)
                    .foregroundColor(ColorTheme.textColor())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryTextColor())
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .background(ColorTheme.bubbleBackground(isUserMessage: message.isUserMessage))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorTheme.borderColor(), lineWidth: 1)
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUserMessage ? .trailing : .leading)

            if !message.isUserMessage {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: ChatMessage(
                content: "这是一条用户发送的消息示例。",
                isUserMessage: true
            )
        )

        MessageBubbleView(
            message: ChatMessage(
                content: "这是一条回复消息示例，它可以包含**Markdown**格式。\n\n- 项目1\n- 项目2",
                isUserMessage: false
            )
        )
    }
    .padding()
}
