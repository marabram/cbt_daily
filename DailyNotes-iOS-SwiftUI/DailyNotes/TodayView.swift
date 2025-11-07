import SwiftUI
import SwiftData

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
    @Environment(\\.modelContext) private var ctx
    @Query(sort: \\NoteEntry.date, order: .reverse) private var entries: [NoteEntry]
    @StateObject private var tmpl = AppTemplate()
    @State private var entry: NoteEntry?

    var body: some View {
        Group {
            if let e = entry {
                VStack(alignment: .leading, spacing: 8) {
                    Text(e.date.formatted(date: .long, time: .omitted))
                        .font(.headline)
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
        let e = NoteEntry(date: Date(), content: tmpl.template)
        ctx.insert(e)
        try? ctx.save()
        entry = e
    }
}
