import Foundation
import SwiftData

@Model
final class WhoopEntry {
    var id: UUID
    var date: Date

    var dayStrain: Double?
    var recoveryPercent: Double?
    var sleepPerformancePercent: Double?

    var hoursOfSleep: Double?
    var sleepNeeded: Double?
    var timeInBed: Double?
    var disturbances: Int?
    var sleepLatency: Double?
    var sleepEfficiencyPercent: Double?
    var sleepConsistency: Double?
    var respiratoryRate: Double?
    var awakeTime: Double?
    var lightSleep: Double?
    var remSleep: Double?
    var swsDeepSleep: Double?

    var hrvMs: Double?
    var restingHR: Double?

    var activityCount: Int?
    var activityType: String?
    var activityStrain: Double?
    var maxHR: Double?
    var avgHR: Double?
    var calories: Double?

    var notes: String?
    var createdAt: Date

    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.createdAt = .now
    }

    var recoveryColor: RecoveryZone {
        guard let pct = recoveryPercent else { return .unknown }
        if pct >= 67 { return .green }
        if pct >= 34 { return .yellow }
        return .red
    }
}

enum RecoveryZone {
    case green, yellow, red, unknown

    var label: String {
        switch self {
        case .green: "Green"
        case .yellow: "Yellow"
        case .red: "Red"
        case .unknown: "—"
        }
    }
}
