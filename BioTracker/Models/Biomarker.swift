import Foundation
import SwiftData

@Model
final class Biomarker {
    var id: UUID
    var name: String
    var category: String
    var unit: String
    var referenceRangeLow: Double?
    var referenceRangeHigh: Double?
    var referenceRangeText: String?
    var optimalRangeLow: Double?
    var optimalRangeHigh: Double?
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \BiomarkerReading.biomarker)
    var readings: [BiomarkerReading]

    @Relationship(inverse: \GeneticVariant.linkedBiomarkers)
    var linkedVariants: [GeneticVariant]

    init(name: String, category: String, unit: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.unit = unit
        self.sortOrder = 0
        self.readings = []
        self.linkedVariants = []
    }

    var latestReading: BiomarkerReading? {
        readings.sorted { ($0.bloodDraw?.collectionDate ?? .distantPast) > ($1.bloodDraw?.collectionDate ?? .distantPast) }.first
    }

    var sortedReadings: [BiomarkerReading] {
        readings.sorted { ($0.bloodDraw?.collectionDate ?? .distantPast) < ($1.bloodDraw?.collectionDate ?? .distantPast) }
    }

    var trend: TrendDirection {
        let sorted = sortedReadings.filter { !$0.isQualitative }
        guard sorted.count >= 2,
              let last = sorted.last,
              let secondLast = sorted.dropLast().last else {
            return .stable
        }
        let diff = last.value - secondLast.value
        let percentChange = abs(diff / secondLast.value) * 100

        guard percentChange > 3 else { return .stable }

        let isHigherBetter = referenceRangeLow != nil && referenceRangeHigh == nil
        if isHigherBetter {
            return diff > 0 ? .improving : .worsening
        }

        let isLowerBetter = referenceRangeLow == nil && referenceRangeHigh != nil
        if isLowerBetter {
            return diff < 0 ? .improving : .worsening
        }

        if let low = referenceRangeLow, let high = referenceRangeHigh {
            let midpoint = (low + high) / 2
            let lastDist = abs(last.value - midpoint)
            let prevDist = abs(secondLast.value - midpoint)
            return lastDist < prevDist ? .improving : .worsening
        }

        return diff > 0 ? .up : .down
    }
}

enum TrendDirection {
    case improving, worsening, stable, up, down

    var iconName: String {
        switch self {
        case .improving: "arrow.down.right"
        case .worsening: "arrow.up.right"
        case .stable: "arrow.right"
        case .up: "arrow.up.right"
        case .down: "arrow.down.right"
        }
    }

    var label: String {
        switch self {
        case .improving: "Improving"
        case .worsening: "Worsening"
        case .stable: "Stable"
        case .up: "Up"
        case .down: "Down"
        }
    }
}
