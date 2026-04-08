import Foundation

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case bloodDraw
    case protocolChange
    case bpCheck
    case labRetest
    case custom

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .bloodDraw: "syringe.fill"
        case .protocolChange: "pills.fill"
        case .bpCheck: "heart.fill"
        case .labRetest: "arrow.clockwise"
        case .custom: "bell.fill"
        }
    }

    var label: String {
        switch self {
        case .bloodDraw: "Blood Draw"
        case .protocolChange: "Protocol Change"
        case .bpCheck: "BP Check"
        case .labRetest: "Lab Retest"
        case .custom: "Custom"
        }
    }
}
