import Foundation
import SwiftData

@MainActor
struct SeedService {
    static func seedIfNeeded(modelContext: ModelContext) {
        seedBiomarkers(modelContext: modelContext)
    }

    private static func seedBiomarkers(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Biomarker>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: "DefaultBiomarkers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([SeedBiomarker].self, from: data) else {
            return
        }

        for (index, item) in items.enumerated() {
            let biomarker = Biomarker(name: item.name, category: item.category, unit: item.unit)
            biomarker.referenceRangeLow = item.refLow
            biomarker.referenceRangeHigh = item.refHigh
            biomarker.sortOrder = index
            modelContext.insert(biomarker)
        }
        try? modelContext.save()
    }

}

private struct SeedBiomarker: Decodable {
    let name: String
    let category: String
    let unit: String
    let refLow: Double?
    let refHigh: Double?
}
