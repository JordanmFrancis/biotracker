import Foundation
import SwiftData

@Model
final class BloodDraw {
    var id: UUID
    var collectionDate: Date
    var labSource: String
    var fasting: Bool?
    var sourceFileName: String?
    var notes: String?
    @Attribute(.externalStorage) var photoData: Data?

    @Relationship(deleteRule: .cascade, inverse: \BiomarkerReading.bloodDraw)
    var readings: [BiomarkerReading]

    var createdAt: Date
    var updatedAt: Date

    init(collectionDate: Date, labSource: String, fasting: Bool? = nil) {
        self.id = UUID()
        self.collectionDate = collectionDate
        self.labSource = labSource
        self.fasting = fasting
        self.readings = []
        self.createdAt = .now
        self.updatedAt = .now
    }

    var formattedDate: String {
        collectionDate.formatted(date: .abbreviated, time: .omitted)
    }

    var flaggedCount: Int {
        readings.filter { $0.flag == .high || $0.flag == .low || $0.flag == .critical }.count
    }
}
