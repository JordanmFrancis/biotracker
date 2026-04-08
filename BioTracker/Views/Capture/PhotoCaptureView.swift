import SwiftUI
import SwiftData
import PhotosUI

struct PhotoCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isExtracting = false
    @State private var result: ImportResult?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Take or pick a photo of a lab result. The image is sent to Anthropic's vision API and parsed into biomarkers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Label(imageData == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo.on.rectangle")
                }
                .disabled(isExtracting)
            }

            if let imageData, let uiImage = UIImage(data: imageData) {
                Section("Preview") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                }

                Section {
                    Button {
                        Task { await runExtraction(imageData) }
                    } label: {
                        if isExtracting {
                            HStack { ProgressView(); Text("Extracting…") }
                        } else {
                            Label("Extract Lab Results", systemImage: "wand.and.stars")
                        }
                    }
                    .disabled(isExtracting)
                }
            }

            if let result {
                Section("Result") {
                    LabeledContent("Imported", value: "\(result.itemsImported)")
                    LabeledContent("Skipped", value: "\(result.itemsSkipped)")
                    ForEach(result.warnings, id: \.self) { w in
                        Text(w).font(.caption).foregroundStyle(.orange)
                    }
                    Button("Done") { dismiss() }
                }
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Capture Lab Photo")
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    imageData = data
                    result = nil
                    errorMessage = nil
                }
            }
        }
    }

    private func runExtraction(_ data: Data) async {
        isExtracting = true
        result = nil
        errorMessage = nil
        defer { isExtracting = false }

        do {
            // Compress to JPEG to keep payload reasonable.
            let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.75) ?? data
            let extractedJSON = try await ExtractionService.extract(imageData: jpeg)
            let importer = ImportService(modelContext: modelContext)
            let res = try importer.importData(extractedJSON)

            // Stash the photo on the most recent matching draw so it's viewable later.
            if let parsed = try? JSONDecoder().decode(LabResultsImport.self, from: extractedJSON),
               let date = Date.from(parsed.bloodDraw.collectionDate) {
                let allDraws = try modelContext.fetch(FetchDescriptor<BloodDraw>())
                if let match = allDraws.first(where: {
                    Calendar.current.isDate($0.collectionDate, inSameDayAs: date) &&
                    $0.labSource == parsed.bloodDraw.labSource
                }) {
                    match.photoData = jpeg
                    try? modelContext.save()
                }
            }

            result = res
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { PhotoCaptureView() }
        .modelContainer(for: [BloodDraw.self, Biomarker.self, BiomarkerReading.self], inMemory: true)
}
