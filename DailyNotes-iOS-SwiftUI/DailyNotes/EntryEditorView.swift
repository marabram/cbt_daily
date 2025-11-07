import SwiftUI
import SwiftData

struct EntryEditorView: View, Identifiable {
    @Environment(\\.dismiss) private var dismiss
    @Environment(\\.modelContext) private var ctx
    @State var entry: NoteEntry
    var id: String { entry.dayKey }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date.formatted(date: .long, time: .omitted))
                .font(.headline)
            TextEditor(text: $entry.content)
                .font(.body.monospaced())
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { try? ctx.save(); dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ExportMenu(entry: entry)
            }
        }
        .navigationTitle("Edit Entry")
    }
}
