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
