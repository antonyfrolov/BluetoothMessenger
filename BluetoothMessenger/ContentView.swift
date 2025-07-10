import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var chatSession: ChatSession
    @State private var messageText = ""
    @State private var showingSettings = false
  // @State private var userName = "User \(UIDevice.current.identifierForVendor!.uuidString)"
    
    init(modelContext: ModelContext) {
        _chatSession = StateObject(wrappedValue: ChatSession(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Статус соединения
                ConnectionStatusView(chatSession: chatSession)
                
                // Список сообщений
                MessagesListView(chatSession: chatSession)
                
                // Поле ввода и кнопки
                InputView(
                    messageText: $messageText,
                    isLoading: chatSession.isLoading,
                    sendAction: sendMessage,
                    //retryAction: retryFailedMessages
                )
            }
            .navigationTitle("Bluetooth Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(chatSession: chatSession)
            }
        }
    }
    
    private func sendMessage() {
        chatSession.send(message: messageText)
        messageText = ""
    }
    
    private func retryFailedMessages() {
        chatSession.messages
            .filter { $0.status == .failed && $0.isFromLocalUser }
            .forEach { chatSession.retrySend(message: $0) }
    }
}

// MARK: - Subviews

struct ConnectionStatusView: View {
    @ObservedObject var chatSession: ChatSession
    
    var body: some View {
        HStack {
            Circle()
                .fill(chatSession.isConnected ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
                .animation(.easeInOut, value: chatSession.isConnected)
            
            Text(chatSession.connectionStatus)
                .font(.caption)
            
            if !chatSession.isConnected {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

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

struct MessageStatusView: View {
    let status: Message.MessageStatus
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
        }
        .frame(width: 15, height: 15)
    }
}

struct InputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let sendAction: () -> Void
   // let retryAction: () -> Void
    
    var body: some View {
        HStack {
            /*Button(action: retryAction) {
                Image(systemName: "arrow.clockwise")
                    .padding(8)
                    .foregroundColor(.red)
            }*/
            
            TextField("Type a message", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Button(action: sendAction) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct SettingsView: View {
    @State private var tempUserName: String
    @ObservedObject var chatSession: ChatSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    init(chatSession: ChatSession) {
        self._tempUserName = State(initialValue: chatSession.currentUserName)
        self.chatSession = chatSession
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Your name", text: $tempUserName)
                }
                Section(header: Text("Connection")) {
                    Button(action: {
                        chatSession.disconnect()
                        chatSession.reconnect()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Reconnect")
                    }
                    
                    Button(role: .destructive) {
                        chatSession.disconnect()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Disconnect")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        chatSession.updateUserName(tempUserName)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(tempUserName.isEmpty)
                }
            }
        }
    }
}

