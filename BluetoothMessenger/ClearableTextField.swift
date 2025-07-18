import SwiftUI

struct ClearableTextField: View {
    
    var title: String
    @Binding var text: String
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(title, text: $text)
            Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .onTapGesture {
                text = ""
            }
        }
    }
}
