import SwiftUI
import SwiftData

@main
struct PotteryAlbumApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            PotteryEntry.self,
            PotteryPhoto.self,
        ]);
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false);

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Attempt to recover by deleting the persistent store if it's corrupted or incompatible
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("CRITICAL ERROR: Could not create ModelContainer after reset: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.primary)
        }
        .modelContainer(container)
    }
}
