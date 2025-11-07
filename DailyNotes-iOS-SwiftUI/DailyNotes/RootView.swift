import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "square.and.pencil") }
            NavigationStack { CalendarScreen() }
                .tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationStack { HistoryScreen() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            NavigationStack { SettingsScreen() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
