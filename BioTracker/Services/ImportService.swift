import Foundation
import SwiftData

struct ImportResult {
    let type: String
    let itemsImported: Int
    let itemsSkipped: Int
    let warnings: [String]
}

enum ImportError: LocalizedError {
    case unknownType(String)
    case invalidData(String)
    case fileReadError(String)

    var errorDescription: String? {
        switch self {
        case .unknownType(let type): "Unknown import type: \(type)"
        case .invalidData(let msg): "Invalid data: \(msg)"
        case .fileReadError(let msg): "File read error: \(msg)"
        }
    }
}

@MainActor
final class ImportService {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func importFile(at url: URL) async throws -> ImportResult {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileReadError("Cannot access file")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        return try importData(data)
    }

    func importData(_ data: Data) throws -> ImportResult {
        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(ImportWrapper.self, from: data)

        switch wrapper.type {
        case "lab_results":
            return try importLabResults(data: data, decoder: decoder)
        case "genetic_variants":
            return try importGeneticVariants(data: data, decoder: decoder)
        case "protocol":
            return try importProtocol(data: data, decoder: decoder)
        case "whoop_data":
            return try importWhoopData(data: data, decoder: decoder)
        case "bp_readings":
            return try importBPReadings(data: data, decoder: decoder)
        case "biotracker_backup":
            return try importFullBackup(data: data, decoder: decoder)
        default:
            throw ImportError.unknownType(wrapper.type)
        }
    }

    // MARK: - Lab Results

    private func importLabResults(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        let import_ = try decoder.decode(LabResultsImport.self, from: data)
        var imported = 0
        var skipped = 0
        var warnings: [String] = []

        guard let collDate = Date.from(import_.bloodDraw.collectionDate) else {
            throw ImportError.invalidData("Invalid collection date: \(import_.bloodDraw.collectionDate)")
        }

        // Check for duplicate blood draw
        let existingDraws = try modelContext.fetch(FetchDescriptor<BloodDraw>())
        let isDuplicate = existingDraws.contains { draw in
            Calendar.current.isDate(draw.collectionDate, inSameDayAs: collDate) &&
            draw.labSource == import_.bloodDraw.labSource
        }

        if isDuplicate {
            warnings.append("Blood draw from \(import_.bloodDraw.labSource) on \(import_.bloodDraw.collectionDate) already exists — merging readings")
        }

        let draw = isDuplicate
            ? existingDraws.first { Calendar.current.isDate($0.collectionDate, inSameDayAs: collDate) && $0.labSource == import_.bloodDraw.labSource }!
            : BloodDraw(collectionDate: collDate, labSource: import_.bloodDraw.labSource, fasting: import_.bloodDraw.fasting)

        if !isDuplicate {
            draw.sourceFileName = import_.bloodDraw.sourceFileName
            draw.notes = import_.bloodDraw.notes
            modelContext.insert(draw)
        }

        for readingDTO in import_.readings {
            let biomarker = findOrCreateBiomarker(
                name: readingDTO.biomarkerName,
                category: readingDTO.category,
                unit: readingDTO.unit ?? "",
                refRange: readingDTO.referenceRange,
                refRangeText: readingDTO.referenceRangeText
            )

            // Skip if reading already exists for this biomarker + draw
            let alreadyExists = draw.readings.contains { $0.biomarker?.name == readingDTO.biomarkerName }
            if alreadyExists {
                skipped += 1
                continue
            }

            let reading = BiomarkerReading(value: readingDTO.value ?? 0, flag: ReadingFlag(rawValue: readingDTO.flag ?? "normal") ?? .normal)
            reading.rawValueText = readingDTO.value == nil ? readingDTO.qualitativeResult : nil
            reading.isQualitative = readingDTO.value == nil
            reading.qualitativeResult = readingDTO.qualitativeResult
            reading.biomarker = biomarker
            reading.bloodDraw = draw
            modelContext.insert(reading)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(type: "lab_results", itemsImported: imported, itemsSkipped: skipped, warnings: warnings)
    }

    // MARK: - Genetic Variants

    private func importGeneticVariants(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        let import_ = try decoder.decode(GeneticVariantsImport.self, from: data)
        var imported = 0
        var skipped = 0

        let existingVariants = try modelContext.fetch(FetchDescriptor<GeneticVariant>())
        let existingRsids = Set(existingVariants.map(\.rsid))

        for dto in import_.variants {
            if existingRsids.contains(dto.rsid) {
                skipped += 1
                continue
            }

            let variant = GeneticVariant(rsid: dto.rsid, gene: dto.gene, category: dto.category, genotype: dto.genotype)
            variant.status = dto.status ?? ""
            variant.statusDescription = dto.description ?? ""
            variant.magnitude = dto.magnitude ?? 0
            variant.chromosome = dto.chromosome
            variant.position = dto.position
            variant.isProtective = dto.isProtective ?? false
            variant.clinicalNote = dto.clinicalNote

            // Link to biomarkers
            if let linkedNames = dto.linkedBiomarkers {
                let allBiomarkers = try modelContext.fetch(FetchDescriptor<Biomarker>())
                for name in linkedNames {
                    if let biomarker = allBiomarkers.first(where: { $0.name == name }) {
                        variant.linkedBiomarkers.append(biomarker)
                    }
                }
            }

            modelContext.insert(variant)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(type: "genetic_variants", itemsImported: imported, itemsSkipped: skipped, warnings: [])
    }

    // MARK: - Protocol

    private func importProtocol(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        let import_ = try decoder.decode(ProtocolImport.self, from: data)
        var imported = 0

        // Clear existing protocol items and replace
        let existing = try modelContext.fetch(FetchDescriptor<ProtocolItem>())
        for item in existing { modelContext.delete(item) }

        for (index, dto) in import_.items.enumerated() {
            let itemType = ProtocolItemType(rawValue: dto.itemType) ?? .other
            let item = ProtocolItem(name: dto.name, itemType: itemType, dose: dto.dose)
            item.frequency = dto.frequency ?? "daily"
            item.timeBlock = dto.timeBlock ?? ""
            item.mechanism = dto.mechanism
            item.geneticRationale = dto.geneticRationale
            item.warnings = dto.warnings
            item.startDate = dto.startDate.flatMap { Date.from($0) }
            item.endDate = dto.endDate.flatMap { Date.from($0) }
            item.isActive = dto.isActive ?? true
            item.sortOrder = index
            modelContext.insert(item)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(type: "protocol", itemsImported: imported, itemsSkipped: 0, warnings: [])
    }

    // MARK: - WHOOP

    private func importWhoopData(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        let import_ = try decoder.decode(WhoopDataImport.self, from: data)
        var imported = 0
        var skipped = 0

        let existingEntries = try modelContext.fetch(FetchDescriptor<WhoopEntry>())
        let existingDates = Set(existingEntries.compactMap { Calendar.current.startOfDay(for: $0.date) })

        for dto in import_.entries {
            guard let date = Date.from(dto.date) else { continue }
            let dayStart = Calendar.current.startOfDay(for: date)

            if existingDates.contains(dayStart) {
                skipped += 1
                continue
            }

            let entry = WhoopEntry(date: date)
            entry.dayStrain = dto.dayStrain
            entry.recoveryPercent = dto.recoveryPercent
            entry.sleepPerformancePercent = dto.sleepPerformancePercent
            entry.hoursOfSleep = dto.hoursOfSleep
            entry.sleepNeeded = dto.sleepNeeded
            entry.timeInBed = dto.timeInBed
            entry.disturbances = dto.disturbances
            entry.sleepLatency = dto.sleepLatency
            entry.sleepEfficiencyPercent = dto.sleepEfficiencyPercent
            entry.sleepConsistency = dto.sleepConsistency
            entry.respiratoryRate = dto.respiratoryRate
            entry.awakeTime = dto.awakeTime
            entry.lightSleep = dto.lightSleep
            entry.remSleep = dto.remSleep
            entry.swsDeepSleep = dto.swsDeepSleep
            entry.hrvMs = dto.hrvMs
            entry.restingHR = dto.restingHR
            entry.activityCount = dto.activityCount
            entry.activityType = dto.activityType
            entry.activityStrain = dto.activityStrain
            entry.maxHR = dto.maxHR
            entry.avgHR = dto.avgHR
            entry.calories = dto.calories
            entry.notes = dto.notes
            modelContext.insert(entry)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(type: "whoop_data", itemsImported: imported, itemsSkipped: skipped, warnings: [])
    }

    // MARK: - BP Readings

    private func importBPReadings(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        let import_ = try decoder.decode(BPReadingsImport.self, from: data)
        var imported = 0

        for dto in import_.readings {
            guard let date = Date.from(dto.date) else { continue }
            let context = BPContext(rawValue: dto.context) ?? .random
            let reading = BPReading(date: date, systolic: dto.systolic, diastolic: dto.diastolic, context: context)
            reading.notes = dto.notes
            modelContext.insert(reading)
            imported += 1
        }

        try modelContext.save()
        return ImportResult(type: "bp_readings", itemsImported: imported, itemsSkipped: 0, warnings: [])
    }

    // MARK: - Full Backup

    private func importFullBackup(data: Data, decoder: JSONDecoder) throws -> ImportResult {
        // TODO: Implement full backup restore
        return ImportResult(type: "biotracker_backup", itemsImported: 0, itemsSkipped: 0, warnings: ["Full backup import not yet implemented"])
    }

    // MARK: - Helpers

    private func findOrCreateBiomarker(name: String, category: String, unit: String, refRange: LabResultsImport.ReadingDTO.RefRangeDTO?, refRangeText: String?) -> Biomarker {
        let allBiomarkers = (try? modelContext.fetch(FetchDescriptor<Biomarker>())) ?? []

        if let existing = allBiomarkers.first(where: { $0.name == name }) {
            // Update reference range if not set
            if existing.referenceRangeLow == nil, let low = refRange?.low {
                existing.referenceRangeLow = low
            }
            if existing.referenceRangeHigh == nil, let high = refRange?.high {
                existing.referenceRangeHigh = high
            }
            if existing.referenceRangeText == nil {
                existing.referenceRangeText = refRangeText
            }
            return existing
        }

        let biomarker = Biomarker(name: name, category: category, unit: unit)
        biomarker.referenceRangeLow = refRange?.low
        biomarker.referenceRangeHigh = refRange?.high
        biomarker.referenceRangeText = refRangeText
        modelContext.insert(biomarker)
        return biomarker
    }
}
