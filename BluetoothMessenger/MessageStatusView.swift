import SwiftUI

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


