import Foundation
import SwiftData

@Model
final class ProtocolItem {
    var id: UUID
    var name: String
    var itemType: ProtocolItemType
    var dose: String
    var frequency: String
    var timeBlock: String
    var mechanism: String?
    var geneticRationale: String?
    var warnings: String?
    var startDate: Date?
    var endDate: Date?
    var isActive: Bool
    var sortOrder: Int

    var createdAt: Date
    var updatedAt: Date

    init(name: String, itemType: ProtocolItemType, dose: String) {
        self.id = UUID()
        self.name = name
        self.itemType = itemType
        self.dose = dose
        self.frequency = "daily"
        self.timeBlock = ""
        self.isActive = true
        self.sortOrder = 0
        self.createdAt = .now
        self.updatedAt = .now
    }

    var durationText: String {
        guard let start = startDate else { return "No start date" }
        if let end = endDate {
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            return "\(days) days"
        }
        let days = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        return "\(days) days (ongoing)"
    }
}
