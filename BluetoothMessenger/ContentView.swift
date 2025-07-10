import SwiftUI

struct ContentView: View {
    @StateObject private var chatSession = ChatSession()
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            // Статус соединения
            HStack {
                Circle()
                    .fill(chatSession.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                if chatSession.connectedPeers.isEmpty {
                    Text("Searching for devices...")
                        .font(.caption)
                } else {
                    Text("Connected with \(chatSession.connectedPeers.count) device(s)")
                        .font(.caption)
                }
            }
            .padding()
            
            // Список сообщений
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack {
                        ForEach(chatSession.messages) { message in
                            MessageView(message: message)
                        }
                    }
                    .onChange(of: chatSession.messages.count) { _ in
                        if let lastMessage = chatSession.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Поле ввода сообщения
            HStack {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.bottom)
        }
        .navigationTitle("Bluetooth Chat")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: chatSession.disconnect) {
                    Text("Disconnect")
                }
                .disabled(!chatSession.isConnected)
            }
        }
    }
    
    private func sendMessage() {
        chatSession.send(message: messageText)
        messageText = ""
    }
}

struct MessageView: View {
    let message: Message
    @StateObject private var chatSession = ChatSession()
    
    var body: some View {
            VStack(alignment: message.isFromLocalUser ? .trailing : .leading) {
                if !message.isFromLocalUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(message.content)
                    .padding()
                    .background(message.isFromLocalUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromLocalUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
        }
}
