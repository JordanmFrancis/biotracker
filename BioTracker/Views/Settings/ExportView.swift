import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportData: Data?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Export all your BioTracker data as a JSON backup file.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    exportBackup()
                } label: {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }
            }

            if let error = errorMessage {
                Section("Error") {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Export")
        .sheet(isPresented: $showShareSheet) {
            if let data = exportData {
                ShareSheet(data: data, filename: "biotracker-backup-\(Date.now.formatted(.dateTime.year().month().day())).json")
            }
        }
    }

    private func exportBackup() {
        do {
            let service = ExportService(modelContext: modelContext)
            exportData = try service.exportBackup()
            showShareSheet = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(for: Biomarker.self, inMemory: true)
}
