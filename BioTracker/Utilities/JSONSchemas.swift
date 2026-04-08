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

// MARK: - Genetic Variants Import

struct GeneticVariantsImport: Codable {
    let type: String
    let version: String?
    let source: String?
    let variants: [VariantDTO]

    struct VariantDTO: Codable {
        let rsid: String
        let gene: String
        let category: String
        let genotype: String
        let status: String?
        let description: String?
        let magnitude: Int?
        let chromosome: String?
        let position: Int?
        let isProtective: Bool?
        let clinicalNote: String?
        let linkedBiomarkers: [String]?
    }
}

// MARK: - Protocol Import

struct ProtocolImport: Codable {
    let type: String
    let version: String?
    let items: [ProtocolItemDTO]

    struct ProtocolItemDTO: Codable {
        let name: String
        let itemType: String
        let dose: String
        let frequency: String?
        let timeBlock: String?
        let mechanism: String?
        let geneticRationale: String?
        let warnings: String?
        let startDate: String?
        let endDate: String?
        let isActive: Bool?
    }
}

// MARK: - WHOOP Data Import

struct WhoopDataImport: Codable {
    let type: String
    let version: String?
    let entries: [WhoopEntryDTO]

    struct WhoopEntryDTO: Codable {
        let date: String
        let dayStrain: Double?
        let recoveryPercent: Double?
        let sleepPerformancePercent: Double?
        let hoursOfSleep: Double?
        let sleepNeeded: Double?
        let timeInBed: Double?
        let disturbances: Int?
        let sleepLatency: Double?
        let sleepEfficiencyPercent: Double?
        let sleepConsistency: Double?
        let respiratoryRate: Double?
        let awakeTime: Double?
        let lightSleep: Double?
        let remSleep: Double?
        let swsDeepSleep: Double?
        let hrvMs: Double?
        let restingHR: Double?
        let activityCount: Int?
        let activityType: String?
        let activityStrain: Double?
        let maxHR: Double?
        let avgHR: Double?
        let calories: Double?
        let notes: String?
    }
}

// MARK: - BP Readings Import

struct BPReadingsImport: Codable {
    let type: String
    let version: String?
    let readings: [BPReadingDTO]

    struct BPReadingDTO: Codable {
        let date: String
        let systolic: Int
        let diastolic: Int
        let context: String
        let notes: String?
    }
}

// MARK: - Full Backup

struct BioTrackerBackup: Codable {
    let type: String
    let version: String?
    let exportDate: String
    let appVersion: String?
    let bloodDraws: [BackupBloodDraw]
    let biomarkers: [BackupBiomarker]
    let geneticVariants: [GeneticVariantsImport.VariantDTO]
    let protocol_: [ProtocolImport.ProtocolItemDTO]
    let whoopEntries: [WhoopDataImport.WhoopEntryDTO]
    let bpReadings: [BPReadingsImport.BPReadingDTO]

    enum CodingKeys: String, CodingKey {
        case type, version, exportDate, appVersion
        case bloodDraws, biomarkers, geneticVariants
        case protocol_ = "protocol"
        case whoopEntries, bpReadings
    }

    struct BackupBloodDraw: Codable {
        let collectionDate: String
        let labSource: String
        let fasting: Bool?
        let sourceFileName: String?
        let notes: String?
        let readings: [BackupReading]
    }

    struct BackupReading: Codable {
        let biomarkerName: String
        let value: Double?
        let flag: String?
        let rawValueText: String?
        let qualitativeResult: String?
        let notes: String?
    }

    struct BackupBiomarker: Codable {
        let name: String
        let category: String
        let unit: String
        let referenceRangeLow: Double?
        let referenceRangeHigh: Double?
        let referenceRangeText: String?
        let optimalRangeLow: Double?
        let optimalRangeHigh: Double?
    }
}

// MARK: - Sync State (pushed to iCloud for Cowork)

struct SyncState: Codable {
    let type: String
    let version: String
    let exportDate: String
    let biomarkers: [SyncBiomarker]
    let geneticVariants: [GeneticVariantsImport.VariantDTO]
    let protocolItems: [ProtocolImport.ProtocolItemDTO]
    let whoopEntries: [WhoopDataImport.WhoopEntryDTO]
    let bpReadings: [BPReadingsImport.BPReadingDTO]

    struct SyncBiomarker: Codable {
        let name: String
        let category: String
        let unit: String
        let referenceRangeLow: Double?
        let referenceRangeHigh: Double?
        let latestValue: Double?
        let latestFlag: String?
        let latestDate: String?
        let readings: [SyncReading]
        let linkedVariants: [String]
    }

    struct SyncReading: Codable {
        let date: String
        let labSource: String
        let value: Double?
        let flag: String?
        let qualitativeResult: String?
    }
}
