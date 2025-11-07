import UIKit
import SwiftUI
import UniformTypeIdentifiers

struct ExportMenu: View {
    let entry: NoteEntry
    @State private var shareURL: URL?

    var body: some View {
        Menu {
            Button("Export as CSV") {
                shareURL = Exporter.csvFor(entries: [entry])
            }
            Button("Export as PDF") {
                shareURL = Exporter.pdfFor(entry: entry)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .sheet(item: Binding(
            get: { shareURL.map(ShareItem.init(url:)) },
            set: { _ in shareURL = nil })
        ) { item in
            ShareSheet(activityItems: [item.url])
        }
    }
}

struct ShareItem: Identifiable { let id = UUID(); let url: URL }

enum Exporter {
    static func csvFor(entries: [NoteEntry]) -> URL {
        let header = "date,completed,content\n"
        let rows = entries.map { e in
            let dateStr = ISO8601DateFormatter().string(from: e.date)
            let completed = e.isCompleted ? "true" : "false"
            let content = e.content
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            return "\"\(dateStr)\",\(completed),\"\(content)\""
        }.joined(separator: "\n")
        let csv = header + rows
        return writeTempFile(named: "notes.csv", data: Data(csv.utf8))
    }

    static func pdfFor(entry: NoteEntry) -> URL {
        let view = VStack(alignment: .leading, spacing: 10) {
            Text(entry.date.formatted(date: .long, time: .omitted))
                .font(.title.bold())
            Divider()
            Text(entry.content).font(.body)
        }
        .padding()

        let renderer = ImageRenderer(content: view)
        let url = tempURL(named: "note.pdf")
        let pdfMeta = [
            kCGPDFContextCreator: "DailyNotes",
            kCGPDFContextAuthor: "DailyNotes"
        ] as CFDictionary

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, pdfMeta) else {
            return url
        }

        ctx.beginPDFPage(nil)
        if let uiImage = renderer.uiImage,
           let cg = uiImage.cgImage {
            let scale = min(612 / uiImage.size.width, 792 / uiImage.size.height)
            let w = uiImage.size.width * scale
            let h = uiImage.size.height * scale
            let x = (612 - w) / 2
            let y = (792 - h) / 2
            ctx.draw(cg, in: CGRect(x: x, y: y, width: w, height: h))
        } else {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            let text = entry.date.formatted(date: .long, time: .omitted) + "\n\n" + entry.content
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraph
            ]
            text.draw(in: CGRect(x: 36, y: 36, width: 540, height: 720), withAttributes: attrs)
        }
        ctx.endPDFPage()
        ctx.closePDF()
        return url
    }

    private static func writeTempFile(named: String, data: Data) -> URL {
        let url = tempURL(named: named)
        try? data.write(to: url, options: .atomic)
        return url
    }
    private static func tempURL(named: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(named)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
