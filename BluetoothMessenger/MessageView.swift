import SwiftUI

struct MessageView: View {
    let message: Message
    @ObservedObject var chatSession: ChatSession
    
    var body: some View {
        VStack(alignment: message.isFromLocalUser ? .trailing : .leading, spacing: 4) {
            if !message.isFromLocalUser {
                Text(message.senderName)
                    .font(.caption2)
                    .foregroundColor(chatSession.colorForSender(message.senderName))
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if message.isFromLocalUser && message.status != .delivered {
                    MessageStatusView(status: message.status)
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isFromLocalUser ?
                        chatSession.colorForSender(message.senderName) :
                        Color(.systemGray5)
                    )
                    .foregroundColor(message.isFromLocalUser ? .white : .primary)
                    .cornerRadius(12)
            }
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: message.isFromLocalUser ? .trailing : .leading)
        .padding(.horizontal)
    }
}
