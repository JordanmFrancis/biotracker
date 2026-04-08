import Foundation
import SwiftData

@Model
final class GeneticVariant {
    var id: UUID
    var rsid: String
    var gene: String
    var category: String
    var genotype: String
    var status: String
    var statusDescription: String
    var magnitude: Int
    var chromosome: String?
    var position: Int?
    var isProtective: Bool
    var clinicalNote: String?

    var linkedBiomarkers: [Biomarker]

    init(rsid: String, gene: String, category: String, genotype: String) {
        self.id = UUID()
        self.rsid = rsid
        self.gene = gene
        self.category = category
        self.genotype = genotype
        self.status = ""
        self.statusDescription = ""
        self.magnitude = 0
        self.isProtective = false
        self.linkedBiomarkers = []
    }

    var magnitudeLabel: String {
        switch magnitude {
        case 0: "Info"
        case 1: "Low"
        case 2: "Moderate"
        case 3: "High"
        case 4...6: "Very High"
        default: "Unknown"
        }
    }
}
