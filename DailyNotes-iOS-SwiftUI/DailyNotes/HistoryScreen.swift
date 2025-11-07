import SwiftUI
import SwiftData

struct HistoryScreen: View {
    @Query(sort: \\NoteEntry.date, order: .reverse) private var entries: [NoteEntry]
    @State private var search = ""

    var body: some View {
        List(filtered(entries)) { e in
            NavigationLink(destination: EntryEditorView(entry: e)) {
                VStack(alignment: .leading) {
                    Text(e.date, style: .date).bold()
                    Text(e.content).lineLimit(2).foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $search)
        .navigationTitle("History")
    }
    private func filtered(_ items: [NoteEntry]) -> [NoteEntry] {
        guard !search.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(search) }
    }
}
