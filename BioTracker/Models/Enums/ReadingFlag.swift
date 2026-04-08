import SwiftUI

enum ReadingFlag: String, Codable, CaseIterable {
    case normal
    case high
    case low
    case critical
    case qualitative

    var color: Color {
        switch self {
        case .normal: .flagInRange
        case .high: .flagAbove
        case .low: .flagBelow
        case .critical: .flagCritical
        case .qualitative: .secondary
        }
    }

    var label: String {
        switch self {
        case .normal: "In Range"
        case .high: "Above Range"
        case .low: "Below Range"
        case .critical: "Critical"
        case .qualitative: "—"
        }
    }

    var shortLabel: String {
        switch self {
        case .normal: "Normal"
        case .high: "H"
        case .low: "L"
        case .critical: "!"
        case .qualitative: "—"
        }
    }
}
