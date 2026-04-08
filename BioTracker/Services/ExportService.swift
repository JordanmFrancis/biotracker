import Foundation
import SwiftData

@MainActor
final class ExportService {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportBackup() throws -> Data {
        let biomarkers = try modelContext.fetch(FetchDescriptor<Biomarker>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.sortOrder)]))

        let dayFmt: (Date) -> String = { d in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: d)
        }

        let dateFormatter = ISO8601DateFormatter()

        let exportBiomarkers: [BiomarkerExport.ExportBiomarker] = biomarkers.map { bm in
            let sorted = bm.sortedReadings
            let latest = sorted.last
            return BiomarkerExport.ExportBiomarker(
                name: bm.name,
                category: bm.category,
                unit: bm.unit,
                referenceRangeLow: bm.referenceRangeLow,
                referenceRangeHigh: bm.referenceRangeHigh,
                latestValue: latest?.isQualitative == true ? nil : latest?.value,
                latestFlag: latest?.flag.rawValue,
                latestDate: latest.map { dayFmt($0.drawDate) },
                readings: sorted.map { r in
                    BiomarkerExport.ExportReading(
                        date: dayFmt(r.drawDate),
                        labSource: r.bloodDraw?.labSource ?? "Unknown",
                        value: r.isQualitative ? nil : r.value,
                        flag: r.flag.rawValue,
                        qualitativeResult: r.qualitativeResult
                    )
                }
            )
        }

        let payload = BiomarkerExport(
            type: "biotracker_backup",
            version: "1.0",
            exportDate: dateFormatter.string(from: .now),
            biomarkers: exportBiomarkers
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }
}
