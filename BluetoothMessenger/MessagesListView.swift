import SwiftUI

struct MessagesListView: View {
    @ObservedObject var chatSession: ChatSession
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 12) {
                    ForEach(chatSession.messages) { message in
                        MessageView(message: message, chatSession: chatSession)
                            .id(message.id)
                    }
                }
                .padding()
                .onChange(of: chatSession.messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatSession.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
