import SwiftData
import Foundation

@Model
final class UserSettings {
    var userName: String
    
    init(userName: String) {
        self.userName = userName
    }
}
