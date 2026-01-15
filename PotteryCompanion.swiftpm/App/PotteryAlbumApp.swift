import SwiftUI
import SwiftData

@main
struct PotteryAlbumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PotteryEntry.self, PotteryPhoto.self])
    }
}
