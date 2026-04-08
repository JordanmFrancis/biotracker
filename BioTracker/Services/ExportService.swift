import Foundation
import SwiftData

@MainActor
final class ExportService {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportSyncState() throws -> Data {
        let biomarkers = try modelContext.fetch(FetchDescriptor<Biomarker>(sortBy: [SortDescriptor(\.category), SortDescriptor(\.sortOrder)]))
        let variants = try modelContext.fetch(FetchDescriptor<GeneticVariant>())
        let protocolItems = try modelContext.fetch(FetchDescriptor<ProtocolItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        let whoopEntries = try modelContext.fetch(FetchDescriptor<WhoopEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        let bpReadings = try modelContext.fetch(FetchDescriptor<BPReading>(sortBy: [SortDescriptor(\.date, order: .reverse)]))

        let dateFormatter = ISO8601DateFormatter()
        let dateFmt: (Date) -> String = { dateFormatter.string(from: $0) }
        let dayFmt: (Date) -> String = { d in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: d)
        }

        let syncBiomarkers: [SyncState.SyncBiomarker] = biomarkers.map { bm in
            let sorted = bm.sortedReadings
            let latest = sorted.last
            return SyncState.SyncBiomarker(
                name: bm.name,
                category: bm.category,
                unit: bm.unit,
                referenceRangeLow: bm.referenceRangeLow,
                referenceRangeHigh: bm.referenceRangeHigh,
                latestValue: latest?.isQualitative == true ? nil : latest?.value,
                latestFlag: latest?.flag.rawValue,
                latestDate: latest.map { dayFmt($0.drawDate) },
                readings: sorted.map { r in
                    SyncState.SyncReading(
                        date: dayFmt(r.drawDate),
                        labSource: r.bloodDraw?.labSource ?? "Unknown",
                        value: r.isQualitative ? nil : r.value,
                        flag: r.flag.rawValue,
                        qualitativeResult: r.qualitativeResult
                    )
                },
                linkedVariants: bm.linkedVariants.map(\.rsid)
            )
        }

        let syncVariants: [GeneticVariantsImport.VariantDTO] = variants.map { v in
            GeneticVariantsImport.VariantDTO(
                rsid: v.rsid, gene: v.gene, category: v.category, genotype: v.genotype,
                status: v.status, description: v.statusDescription,
                magnitude: v.magnitude, chromosome: v.chromosome, position: v.position,
                isProtective: v.isProtective, clinicalNote: v.clinicalNote,
                linkedBiomarkers: v.linkedBiomarkers.map(\.name)
            )
        }

        let syncProtocol: [ProtocolImport.ProtocolItemDTO] = protocolItems.map { p in
            ProtocolImport.ProtocolItemDTO(
                name: p.name, itemType: p.itemType.rawValue, dose: p.dose,
                frequency: p.frequency, timeBlock: p.timeBlock,
                mechanism: p.mechanism, geneticRationale: p.geneticRationale,
                warnings: p.warnings,
                startDate: p.startDate.map(dayFmt), endDate: p.endDate.map(dayFmt),
                isActive: p.isActive
            )
        }

        let syncWhoop: [WhoopDataImport.WhoopEntryDTO] = whoopEntries.prefix(90).map { w in
            WhoopDataImport.WhoopEntryDTO(
                date: dayFmt(w.date),
                dayStrain: w.dayStrain, recoveryPercent: w.recoveryPercent,
                sleepPerformancePercent: w.sleepPerformancePercent,
                hoursOfSleep: w.hoursOfSleep, sleepNeeded: w.sleepNeeded,
                timeInBed: w.timeInBed, disturbances: w.disturbances,
                sleepLatency: w.sleepLatency, sleepEfficiencyPercent: w.sleepEfficiencyPercent,
                sleepConsistency: w.sleepConsistency, respiratoryRate: w.respiratoryRate,
                awakeTime: w.awakeTime, lightSleep: w.lightSleep,
                remSleep: w.remSleep, swsDeepSleep: w.swsDeepSleep,
                hrvMs: w.hrvMs, restingHR: w.restingHR,
                activityCount: w.activityCount, activityType: w.activityType,
                activityStrain: w.activityStrain, maxHR: w.maxHR,
                avgHR: w.avgHR, calories: w.calories, notes: w.notes
            )
        }

        let syncBP: [BPReadingsImport.BPReadingDTO] = bpReadings.map { bp in
            BPReadingsImport.BPReadingDTO(
                date: dateFmt(bp.date),
                systolic: bp.systolic, diastolic: bp.diastolic,
                context: bp.context.rawValue, notes: bp.notes
            )
        }

        let state = SyncState(
            type: "biotracker_state",
            version: "1.0",
            exportDate: dateFmt(.now),
            biomarkers: syncBiomarkers,
            geneticVariants: syncVariants,
            protocolItems: syncProtocol,
            whoopEntries: syncWhoop,
            bpReadings: syncBP
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(state)
    }

    func exportBackup() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Use sync state as a simplified backup for now
        return try exportSyncState()
    }
}
