import SwiftUI
import SwiftData

@main
struct PotteryAlbumApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                PotteryEntry.self,
                PotteryPhoto.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("CRITICAL ERROR: Could not create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
