import SwiftUI
import SwiftData

@Model
final class BPReading {
    var id: UUID
    var date: Date
    var systolic: Int
    var diastolic: Int
    var context: BPContext
    var notes: String?

    var createdAt: Date

    init(date: Date, systolic: Int, diastolic: Int, context: BPContext) {
        self.id = UUID()
        self.date = date
        self.systolic = systolic
        self.diastolic = diastolic
        self.context = context
        self.createdAt = .now
    }

    var displayText: String {
        "\(systolic)/\(diastolic)"
    }

    var category: BPCategory {
        if systolic >= 180 || diastolic >= 120 { return .crisis }
        if systolic >= 140 || diastolic >= 90 { return .stage2 }
        if systolic >= 130 || diastolic >= 80 { return .stage1 }
        if systolic >= 120 { return .elevated }
        return .normal
    }
}

enum BPCategory: String {
    case normal = "Normal"
    case elevated = "Elevated"
    case stage1 = "Stage 1"
    case stage2 = "Stage 2"
    case crisis = "Crisis"

    var color: Color {
        switch self {
        case .normal: .green
        case .elevated: .yellow
        case .stage1: .orange
        case .stage2: .red
        case .crisis: Color(red: 0.72, green: 0.11, blue: 0.11)
        }
    }
}
