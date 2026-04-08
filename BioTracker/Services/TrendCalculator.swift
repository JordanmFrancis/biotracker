import Foundation
import SwiftUI

enum TrendCalculator {
    static func sparklineValues(for biomarker: Biomarker, maxPoints: Int = 5) -> [Double] {
        let sorted = biomarker.sortedReadings.filter { !$0.isQualitative }
        return Array(sorted.suffix(maxPoints).map(\.value))
    }

    static func sparklineColors(for biomarker: Biomarker, maxPoints: Int = 5) -> [Color] {
        let sorted = biomarker.sortedReadings.filter { !$0.isQualitative }
        return Array(sorted.suffix(maxPoints).map(\.flag.color))
    }

    static func percentChange(for biomarker: Biomarker) -> Double? {
        let sorted = biomarker.sortedReadings.filter { !$0.isQualitative }
        guard sorted.count >= 2,
              let last = sorted.last,
              let prev = sorted.dropLast().last,
              prev.value != 0 else { return nil }
        return ((last.value - prev.value) / prev.value) * 100
    }

    static func daysUntilNextDraw(lastDraw: Date, intervalMonths: Int = 3) -> Int {
        let nextDraw = Calendar.current.date(byAdding: .month, value: intervalMonths, to: lastDraw) ?? lastDraw
        return Calendar.current.dateComponents([.day], from: .now, to: nextDraw).day ?? 0
    }
}
