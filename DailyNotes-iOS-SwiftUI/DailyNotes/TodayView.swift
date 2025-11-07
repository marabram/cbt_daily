import SwiftUI
import SwiftData
import Combine

final class AppTemplate: ObservableObject {
    @AppStorage("noteTemplate")
    var template: String = """
    # Daily Notes
    - Focus:
    - Top 3 tasks:
      1.
      2.
      3.
    - Wins:
    - Blockers:
    - Notes:
    """
}

struct TodayView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \NoteEntry.date, order: .reverse) private var entries: [NoteEntry]
    @StateObject private var tmpl = AppTemplate()
    @State private var entry: NoteEntry?

    var body: some View {
        Group {
            if let e = entry {
                VStack(alignment: .leading, spacing: 8) {
                    Text(e.date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Label("Mood", systemImage: "face.smiling")
                        Spacer()
                        Text(e.mood.map(String.init) ?? "—")
                            .font(.callout).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    Slider(value: Binding(
                        get: { Double(e.mood ?? 5) },
                        set: { newVal in
                            let newMood = Int(newVal.rounded())
                            // Only set mood when the user changes it explicitly
                            if e.mood != newMood {
                                e.mood = newMood
                                e.updatedAt = Date()
                                try? ctx.save()
                            }
                        }
                    ), in: 0...10, step: 1)
                    .tint(.blue)
                    .accessibilityLabel("Mood")
                    .accessibilityValue(Text(e.mood != nil ? "\(e.mood!) out of 10" : "not set"))

                    TextEditor(text: Binding(
                        get: { e.content },
                        set: { newVal in
                            e.content = newVal
                            e.updatedAt = Date()
                            try? ctx.save()
                        }
                    ))
                    .font(.body.monospaced())
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ExportMenu(entry: e)
                    }
                }
                .navigationTitle("Today")
            } else {
                ProgressView("Loading today…")
                    .onAppear(perform: ensureToday)
            }
        }
    }

    private func ensureToday() {
        let todayKey = NoteEntry.key(for: Date())
        if let existing = entries.first(where: { $0.dayKey == todayKey }) {
            entry = existing
            return
        }
        let e = NoteEntry(date: Date(), content: tmpl.template) // mood defaults to 5
        ctx.insert(e)
        try? ctx.save()
        entry = e
    }
}
