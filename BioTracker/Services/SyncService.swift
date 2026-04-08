import Foundation
import SwiftData

@MainActor
final class SyncService {
    let modelContext: ModelContext
    private let exportService: ExportService
    private let importService: ImportService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.exportService = ExportService(modelContext: modelContext)
        self.importService = ImportService(modelContext: modelContext)
    }

    // MARK: - iCloud Drive Container

    private var iCloudSyncURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.jordanfrancis.BioTracker")
    }

    private var syncFolderURL: URL? {
        guard let container = iCloudSyncURL else { return nil }
        return container.appendingPathComponent("Documents/sync", isDirectory: true)
    }

    var iCloudAvailable: Bool {
        iCloudSyncURL != nil
    }

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastSyncDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastSyncDate") }
    }

    // MARK: - Push to Cowork

    func pushToCowork() async throws {
        guard let syncFolder = syncFolderURL else {
            throw SyncError.iCloudUnavailable
        }

        // Ensure sync folder exists
        try FileManager.default.createDirectory(at: syncFolder, withIntermediateDirectories: true)

        // Export current state
        let stateData = try exportService.exportSyncState()

        // Write to iCloud
        let stateURL = syncFolder.appendingPathComponent("biotracker-state.json")
        try stateData.write(to: stateURL)

        lastSyncDate = .now
    }

    // MARK: - Pull from Cowork

    func pullFromCowork() async throws -> [ImportResult] {
        guard let syncFolder = syncFolderURL else {
            throw SyncError.iCloudUnavailable
        }

        var results: [ImportResult] = []

        // Look for import files in the sync/inbox/ folder
        let inboxURL = syncFolder.appendingPathComponent("inbox", isDirectory: true)

        guard FileManager.default.fileExists(atPath: inboxURL.path) else {
            return results
        }

        let files = try FileManager.default.contentsOfDirectory(at: inboxURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }

        for file in files {
            do {
                let result = try await importService.importFile(at: file)
                results.append(result)

                // Move processed file to archive
                let archiveURL = syncFolder.appendingPathComponent("archive", isDirectory: true)
                try FileManager.default.createDirectory(at: archiveURL, withIntermediateDirectories: true)
                let archiveDest = archiveURL.appendingPathComponent(file.lastPathComponent)
                if FileManager.default.fileExists(atPath: archiveDest.path) {
                    try FileManager.default.removeItem(at: archiveDest)
                }
                try FileManager.default.moveItem(at: file, to: archiveDest)
            } catch {
                results.append(ImportResult(type: "error", itemsImported: 0, itemsSkipped: 0, warnings: ["\(file.lastPathComponent): \(error.localizedDescription)"]))
            }
        }

        lastSyncDate = .now
        return results
    }
}

enum SyncError: LocalizedError {
    case iCloudUnavailable

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            "iCloud Drive is not available. Make sure you're signed into iCloud and iCloud Drive is enabled."
        }
    }
}
