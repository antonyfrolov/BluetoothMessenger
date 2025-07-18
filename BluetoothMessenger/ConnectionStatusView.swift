import SwiftUI

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
