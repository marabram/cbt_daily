import SwiftData
import Foundation

@Model
final class NoteEntry: Identifiable {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var mood: Int? = nil
    
    var isCompleted: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(date: Date, content: String = "") {
        let normalized = Calendar.current.startOfDay(for: date)
        self.date = normalized
        self.dayKey = NoteEntry.key(for: normalized)
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func key(for date: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar.current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Calendar.current.startOfDay(for: date))
    }
}

