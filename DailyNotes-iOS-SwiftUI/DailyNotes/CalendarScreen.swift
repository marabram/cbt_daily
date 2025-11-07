import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Environment(\.modelContext) private var ctx
    @Query private var entries: [NoteEntry]
    @State private var monthAnchor = Calendar.current.startOfDay(for: Date())
    @State private var showingEntry: NoteEntry?

    var body: some View {
        VStack {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthAnchor, format: .dateTime.year().month(.wide))
                    .font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)

            let days = CalendarGrid.daysForMonth(containing: monthAnchor)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
                ForEach(days, id: \.self) { day in
                    if CalendarGrid.isPlaceholder(day) {
                        Color.clear.frame(height: 40)
                    } else {
                        DayCell(day: day,
                                entry: entries.first(where: { $0.dayKey == NoteEntry.key(for: day) }))
                        .onTapGesture {
                            openOrCreate(for: day)
                        }
                    }
                }
            }
            .padding()
            Spacer()
        }
        .sheet(item: $showingEntry) { entry in
            NavigationStack {
                EntryEditorView(entry: entry)
            }
        }
        .navigationTitle("Calendar")
    }

    private func shiftMonth(_ delta: Int) {
        if let new = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = new
        }
    }

    private func openOrCreate(for date: Date) {
        let key = NoteEntry.key(for: date)
        if let e = entries.first(where: { $0.dayKey == key }) {
            showingEntry = e
        } else {
            let e = NoteEntry(date: date)
            ctx.insert(e)
            try? ctx.save()
            showingEntry = e
        }
    }
}

struct DayCell: View {
    let day: Date
    let entry: NoteEntry?
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day))")
                .frame(maxWidth: .infinity)
            Circle()
                .frame(width: 6, height: 6)
                .opacity(entry?.isCompleted == true ? 1 : 0.15)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Calendar.current.isDateInToday(day) ? .blue.opacity(0.12) : .clear)
        )
        .accessibilityLabel(Text(accessibilityText))
    }
    private var accessibilityText: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        let status = (entry?.isCompleted == true) ? "completed" : "not completed"
        return "\(df.string(from: day)), \(status)"
    }
}

enum CalendarGrid {
    static func daysForMonth(containing date: Date) -> [Date] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let range = cal.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = cal.component(.weekday, from: startOfMonth) // 1=Sun
        var days: [Date] = []
        // add placeholders for leading empty cells
        for _ in 1..<firstWeekday { days.append(.distantPast) }
        for d in range {
            days.append(cal.date(byAdding: .day, value: d - 1, to: startOfMonth)!)
        }
        return days
    }
    static func isPlaceholder(_ date: Date) -> Bool { date == .distantPast }
}
