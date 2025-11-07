import SwiftUI
import SwiftData

@main
struct DailyNotesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: NoteEntry.self)
    }
}
