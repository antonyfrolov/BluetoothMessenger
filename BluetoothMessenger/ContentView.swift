import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var chatSession: ChatSession
    @State private var messageText = ""
    @State private var showingSettings = false
    
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
                    sendAction: sendMessage
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
