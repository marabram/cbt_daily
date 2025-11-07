import SwiftUI
import UserNotifications

struct SettingsScreen: View {
    @StateObject private var tmpl = AppTemplate()
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    var body: some View {
        Form {
            Section("Daily Template") {
                TextEditor(text: $tmpl.template)
                    .font(.body.monospaced())
                    .frame(minHeight: 180)
            }
            Section("Reminder") {
                Toggle("Daily reminder", isOn: $reminderEnabled.onChange(scheduleReminder))
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .disabled(!reminderEnabled)
            }
        }
        .navigationTitle("Settings")
    }

    private func scheduleReminder(_ on: Bool) {
        let center = UNUserNotificationCenter.current()
        if on {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                guard ok else { return }
                let content = UNMutableNotificationContent()
                content.title = "Don’t forget today’s note"
                content.body = "Open the app to fill your daily entry."
                var date = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                date.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                let req = UNNotificationRequest(identifier: "daily-note", content: content, trigger: trigger)
                center.add(req)
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["daily-note"])
        }
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { new in
                wrappedValue = new
                handler(new)
            }
        )
    }
}
