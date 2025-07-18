import SwiftUI

struct InputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let sendAction: () -> Void
    
    var body: some View {
        HStack {
            
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
