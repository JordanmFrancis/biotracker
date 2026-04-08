import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(ExtractionService.apiKeyDefaultsKey) private var apiKey: String = ""

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
                        PhotoCaptureView()
                    } label: {
                        Label("Capture from Photo", systemImage: "camera.fill")
                    }

                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export / Backup", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    SecureField("Anthropic API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("AI Extraction")
                } footer: {
                    Text("Used to parse lab result photos via Claude vision. Stored on-device only.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBase)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Biomarker.self, inMemory: true)
}
