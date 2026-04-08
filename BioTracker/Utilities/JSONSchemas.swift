import Foundation

// MARK: - Import Wrapper (detects type)

struct ImportWrapper: Codable {
    let type: String
    let version: String?
}

// MARK: - Lab Results Import

struct LabResultsImport: Codable {
    let type: String
    let version: String?
    let bloodDraw: BloodDrawDTO
    let readings: [ReadingDTO]

    struct BloodDrawDTO: Codable {
        let collectionDate: String
        let labSource: String
        let fasting: Bool?
        let sourceFileName: String?
        let notes: String?
    }

    struct ReadingDTO: Codable {
        let biomarkerName: String
        let category: String
        let value: Double?
        let unit: String?
        let flag: String?
        let referenceRange: RefRangeDTO?
        let referenceRangeText: String?
        let qualitativeResult: String?

        struct RefRangeDTO: Codable {
            let low: Double?
            let high: Double?
        }
    }
}

// MARK: - Biomarker Export (backup)

struct BiomarkerExport: Codable {
    let type: String
    let version: String
    let exportDate: String
    let biomarkers: [ExportBiomarker]

    struct ExportBiomarker: Codable {
        let name: String
        let category: String
        let unit: String
        let referenceRangeLow: Double?
        let referenceRangeHigh: Double?
        let latestValue: Double?
        let latestFlag: String?
        let latestDate: String?
        let readings: [ExportReading]
    }

    struct ExportReading: Codable {
        let date: String
        let labSource: String
        let value: Double?
        let flag: String?
        let qualitativeResult: String?
    }
}
