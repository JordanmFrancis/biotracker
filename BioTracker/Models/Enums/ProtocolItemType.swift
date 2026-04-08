import SwiftUI

enum ProtocolItemType: String, Codable, CaseIterable, Identifiable {
    case supplement
    case peptide
    case medication
    case sarm
    case topical
    case other

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .supplement: .blue
        case .peptide: .purple
        case .medication: .orange
        case .sarm: .red
        case .topical: .teal
        case .other: .secondary
        }
    }

    var label: String {
        rawValue.capitalized
    }
}
