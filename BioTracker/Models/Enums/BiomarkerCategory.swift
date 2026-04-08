import Foundation

enum BiomarkerCategory: String, CaseIterable, Identifiable {
    case metabolic = "Metabolic / Diabetes"
    case lipidPanel = "Lipid Panel"
    case advancedLipids = "Advanced Lipids"
    case nmrSubfractions = "NMR Subfractions"
    case ionMobility = "Ion Mobility"
    case omegaCheck = "OmegaCheck"
    case inflammation = "Inflammation"
    case liver = "Liver Function"
    case kidney = "Kidney Function"
    case hormones = "Hormones"
    case thyroid = "Thyroid"
    case vitamins = "Vitamins & Minerals"
    case iron = "Iron Panel"
    case psa = "PSA"
    case cbc = "CBC"
    case differential = "Differential"
    case dutch = "DUTCH"
    case urinalysis = "Urinalysis"
    case other = "Other"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .metabolic: "drop.fill"
        case .lipidPanel: "heart.fill"
        case .advancedLipids: "heart.text.square"
        case .nmrSubfractions: "chart.bar.xaxis"
        case .ionMobility: "waveform.path"
        case .omegaCheck: "fish.fill"
        case .inflammation: "flame.fill"
        case .liver: "cross.vial.fill"
        case .kidney: "drop.triangle.fill"
        case .hormones: "testtube.2"
        case .thyroid: "bolt.heart"
        case .vitamins: "pills.fill"
        case .iron: "atom"
        case .psa: "shield.checkered"
        case .cbc: "drop.degreesign.fill"
        case .differential: "chart.pie.fill"
        case .dutch: "clock.fill"
        case .urinalysis: "flask.fill"
        case .other: "square.grid.2x2"
        }
    }

    var sortOrder: Int {
        switch self {
        case .metabolic: 0
        case .lipidPanel: 1
        case .advancedLipids: 2
        case .nmrSubfractions: 3
        case .ionMobility: 4
        case .omegaCheck: 5
        case .inflammation: 6
        case .liver: 7
        case .kidney: 8
        case .hormones: 9
        case .thyroid: 10
        case .vitamins: 11
        case .iron: 12
        case .psa: 13
        case .cbc: 14
        case .differential: 15
        case .dutch: 16
        case .urinalysis: 17
        case .other: 18
        }
    }
}
