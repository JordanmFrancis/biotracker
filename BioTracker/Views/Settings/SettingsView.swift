import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }

                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export / Backup", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        SyncView()
                    } label: {
                        Label("Cowork Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        RemindersListView()
                    } label: {
                        Label("Reminders", systemImage: "bell.fill")
                    }
                }

                Section("WHOOP") {
                    NavigationLink {
                        WhoopDetailView()
                    } label: {
                        Label("WHOOP Dashboard", systemImage: "heart.circle.fill")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Biomarker.self, inMemory: true)
}
