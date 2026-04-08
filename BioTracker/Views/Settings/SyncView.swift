import SwiftUI
import SwiftData

struct SyncView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var syncService: SyncService?
    @State private var isPushing = false
    @State private var isPulling = false
    @State private var pushSuccess = false
    @State private var pullResults: [ImportResult]?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Sync data with Claude Cowork via iCloud Drive. Push sends your current state; Pull imports files Cowork has prepared.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Status") {
                LabeledContent("iCloud", value: syncService?.iCloudAvailable == true ? "Available" : "Unavailable")
                if let lastSync = syncService?.lastSyncDate {
                    LabeledContent("Last Sync", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                } else {
                    LabeledContent("Last Sync", value: "Never")
                }
            }

            Section("Actions") {
                Button {
                    Task { await pushToCowork() }
                } label: {
                    HStack {
                        Label("Push to Cowork", systemImage: "arrow.up.circle.fill")
                        Spacer()
                        if isPushing { ProgressView() }
                    }
                }
                .disabled(isPushing || syncService?.iCloudAvailable != true)

                Button {
                    Task { await pullFromCowork() }
                } label: {
                    HStack {
                        Label("Pull from Cowork", systemImage: "arrow.down.circle.fill")
                        Spacer()
                        if isPulling { ProgressView() }
                    }
                }
                .disabled(isPulling || syncService?.iCloudAvailable != true)
            }

            if pushSuccess {
                Section {
                    Label("Push successful", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let results = pullResults {
                Section("Pull Results") {
                    if results.isEmpty {
                        Text("No new files to import.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.type)
                                .font(.subheadline.bold())
                            Text("Imported: \(result.itemsImported), Skipped: \(result.itemsSkipped)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(result.warnings, id: \.self) { w in
                                Text(w).font(.caption).foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Cowork Sync")
        .onAppear {
            syncService = SyncService(modelContext: modelContext)
        }
    }

    private func pushToCowork() async {
        isPushing = true
        pushSuccess = false
        errorMessage = nil
        do {
            try await syncService?.pushToCowork()
            pushSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isPushing = false
    }

    private func pullFromCowork() async {
        isPulling = true
        pullResults = nil
        errorMessage = nil
        do {
            pullResults = try await syncService?.pullFromCowork()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPulling = false
    }
}

#Preview {
    NavigationStack {
        SyncView()
    }
    .modelContainer(for: Biomarker.self, inMemory: true)
}
