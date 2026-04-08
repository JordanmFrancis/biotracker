import Foundation
import SwiftData

@Model
final class BiomarkerReading {
    var id: UUID
    var value: Double
    var flag: ReadingFlag
    var rawValueText: String?
    var isQualitative: Bool
    var qualitativeResult: String?
    var notes: String?

    var biomarker: Biomarker?
    var bloodDraw: BloodDraw?

    var createdAt: Date

    init(value: Double, flag: ReadingFlag = .normal) {
        self.id = UUID()
        self.value = value
        self.flag = flag
        self.isQualitative = false
        self.createdAt = .now
    }

    var displayValue: String {
        if isQualitative, let result = qualitativeResult {
            return result
        }
        if let raw = rawValueText {
            return raw
        }
        if value == value.rounded() && value < 10000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    var drawDate: Date {
        bloodDraw?.collectionDate ?? createdAt
    }
}
