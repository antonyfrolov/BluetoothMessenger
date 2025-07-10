import SwiftUI
import SwiftData

@main
struct BluetoothChatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: .init(sharedModelContainer))
                .modelContainer(sharedModelContainer)
        }
    }
}
