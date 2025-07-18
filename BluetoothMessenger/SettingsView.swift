import SwiftUI

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
                    ClearableTextField("Your name", text: $tempUserName)
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
