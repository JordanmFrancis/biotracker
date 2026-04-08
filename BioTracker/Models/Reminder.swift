import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var title: String
    var reminderType: ReminderType
    var date: Date
    var isRecurring: Bool
    var recurrenceRule: String?
    var isCompleted: Bool
    var notes: String?

    var createdAt: Date

    init(title: String, reminderType: ReminderType, date: Date) {
        self.id = UUID()
        self.title = title
        self.reminderType = reminderType
        self.date = date
        self.isRecurring = false
        self.isCompleted = false
        self.createdAt = .now
    }

    var isOverdue: Bool {
        !isCompleted && date < .now
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
