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
            if let mood = entry?.mood {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(DayCell.moodColor(for: mood))
                    .accessibilityHidden(true)
            } else {
                Circle()
                    .frame(width: 6, height: 6)
                    .opacity(entry?.isCompleted == true ? 1 : 0.15)
                    .accessibilityHidden(true)
            }
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
        let dateString = df.string(from: day)
        var parts: [String] = [dateString]
        if let e = entry {
            let status = e.isCompleted ? "completed" : "not completed"
            parts.append(status)
            if let mood = e.mood, (0...10).contains(mood) {
                let moodDesc: String
                switch mood {
                case 0...2: moodDesc = "very low mood"
                case 3...4: moodDesc = "low mood"
                case 5: moodDesc = "neutral mood"
                case 6...7: moodDesc = "good mood"
                case 8...10: moodDesc = "great mood"
                default: moodDesc = ""
                }
                if !moodDesc.isEmpty { parts.append(moodDesc) }
            }
        }
        return parts.joined(separator: ", ")
    }
}

extension DayCell {
    static func faceSymbol(for mood: Int) -> String {
        switch mood {
        case 0...2: return "face.frown"
        case 3...4: return "face.neutral"
        case 5: return "face.neutral"
        case 6...7: return "face.smiling"
        case 8...10: return "face.smiling.fill"
        default: return "face.smiling"
        }
    }
    static func faceColor(for mood: Int) -> Color {
        switch mood {
        case 0...2: return .red
        case 3...4: return .orange
        case 5: return .yellow
        case 6...7: return .green
        case 8...10: return .blue
        default: return .secondary
        }
    }
    static func emoji(for mood: Int) -> String {
        switch mood {
        case 0...2: return "😞"
        case 3...4: return "☹️"
        case 5: return "😐"
        case 6...7: return "🙂"
        case 8...10: return "😄"
        default: return "🙂"
        }
    }
    static func moodColor(for mood: Int) -> Color {
        switch mood {
        case 0...2: return .red
        case 3...4: return .orange
        case 5: return .yellow
        case 6...7: return .green
        case 8...10: return .blue
        default: return .secondary
        }
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
