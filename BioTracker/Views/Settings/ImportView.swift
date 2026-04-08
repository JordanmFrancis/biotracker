import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showFilePicker = false
    @State private var importResult: ImportResult?
    @State private var reviewingDraw: BloodDraw?
    @State private var errorMessage: String?
    @State private var isImporting = false

    var body: some View {
        List {
            Section {
                Text("Import JSON files containing lab results.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    showFilePicker = true
                } label: {
                    Label("Select JSON File", systemImage: "doc.badge.plus")
                }
                .disabled(isImporting)
            }

            if isImporting {
                Section {
                    HStack {
                        ProgressView()
                        Text("Importing…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let result = importResult {
                Section("Import Result") {
                    LabeledContent("Imported", value: "\(result.itemsImported)")
                    LabeledContent("Skipped", value: "\(result.itemsSkipped)")
                    if !result.warnings.isEmpty {
                        ForEach(result.warnings, id: \.self) { warning in
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(Color.flagAbove)
                        }
                    }
                    if let drawID = result.drawID,
                       let draw = modelContext.model(for: drawID) as? BloodDraw {
                        Button {
                            reviewingDraw = draw
                        } label: {
                            Label("Review & Edit", systemImage: "pencil.line")
                        }
                    }
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.flagCritical)
                }
            }

            Section("Supported Formats") {
                ForEach(["lab_results", "biotracker_backup"], id: \.self) { type in
                    Text(type)
                        .font(.caption.monospaced())
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceBase)
        .navigationTitle("Import")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleImport(result)
            }
        }
        .navigationDestination(item: $reviewingDraw) { draw in
            ImportReviewView(draw: draw)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) async {
        isImporting = true
        importResult = nil
        errorMessage = nil

        do {
            let urls = try result.get()
            guard let url = urls.first else { return }

            let service = ImportService(modelContext: modelContext)
            let importRes = try await service.importFile(at: url)
            importResult = importRes
        } catch {
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
    .modelContainer(for: [BloodDraw.self, Biomarker.self, BiomarkerReading.self], inMemory: true)
    .preferredColorScheme(.dark)
}
