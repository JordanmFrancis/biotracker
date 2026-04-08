import SwiftUI
import SwiftData
import PhotosUI

struct PhotoCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [PhotoItem] = []
    @State private var isExtracting = false

    var body: some View {
        List {
            Section {
                Text("Pick one or more lab result photos. Set the collection date for each, then tap Extract All — the date you set overrides whatever the model reads from the image.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 0,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(photos.isEmpty ? "Choose Photos" : "Add / Replace Photos",
                          systemImage: "photo.on.rectangle.angled")
                }
                .disabled(isExtracting)
            }

            if !photos.isEmpty {
                Section("Photos (\(photos.count))") {
                    ForEach($photos) { $photo in
                        PhotoRow(photo: $photo)
                    }
                    .onDelete { offsets in
                        photos.remove(atOffsets: offsets)
                    }
                }

                Section {
                    Button {
                        Task { await extractAll() }
                    } label: {
                        if isExtracting {
                            HStack { ProgressView(); Text("Extracting…") }
                        } else {
                            Label("Extract All (\(pendingCount))", systemImage: "wand.and.stars")
                        }
                    }
                    .disabled(isExtracting || pendingCount == 0)

                    if photos.contains(where: { if case .done = $0.status { return true } else { return false } }) {
                        Button("Done", role: .cancel) { dismiss() }
                    }
                }
            }
        }
        .navigationTitle("Capture Lab Photos")
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadPickedItems(newItems) }
        }
    }

    private var pendingCount: Int {
        photos.filter { if case .pending = $0.status { return true } else { return false } }.count
    }

    private func loadPickedItems(_ items: [PhotosPickerItem]) async {
        var loaded: [PhotoItem] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            loaded.append(PhotoItem(data: data, date: .now, status: .pending))
        }
        photos = loaded
    }

    private func extractAll() async {
        isExtracting = true
        defer { isExtracting = false }

        for index in photos.indices {
            if case .done = photos[index].status { continue }
            photos[index].status = .extracting
            do {
                let res = try await extract(photo: photos[index])
                photos[index].status = .done(res)
            } catch {
                photos[index].status = .error(error.localizedDescription)
            }
        }
    }

    private func extract(photo: PhotoItem) async throws -> ImportResult {
        let jpeg = UIImage(data: photo.data)?.jpegData(compressionQuality: 0.75) ?? photo.data
        let extractedJSON = try await ExtractionService.extract(imageData: jpeg)

        // Override the model-read collectionDate with the user-supplied one.
        let patchedJSON = try patchCollectionDate(in: extractedJSON, to: photo.date)

        let importer = ImportService(modelContext: modelContext)
        let result = try importer.importData(patchedJSON)

        // Stash the photo on the matching draw for later viewing.
        if let parsed = try? JSONDecoder().decode(LabResultsImport.self, from: patchedJSON),
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

        return result
    }

    private func patchCollectionDate(in data: Data, to date: Date) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var draw = root["bloodDraw"] as? [String: Any] else {
            return data
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        draw["collectionDate"] = f.string(from: date)
        root["bloodDraw"] = draw
        return try JSONSerialization.data(withJSONObject: root)
    }
}

// MARK: - Per-photo state

struct PhotoItem: Identifiable {
    let id = UUID()
    let data: Data
    var date: Date
    var status: Status

    enum Status {
        case pending
        case extracting
        case done(ImportResult)
        case error(String)
    }
}

private struct PhotoRow: View {
    @Binding var photo: PhotoItem

    var body: some View {
        HStack(spacing: 12) {
            if let img = UIImage(data: photo.data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                DatePicker(
                    "Collection date",
                    selection: $photo.date,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                statusLine
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusLine: some View {
        switch photo.status {
        case .pending:
            Text("Ready to extract")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .extracting:
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text("Extracting…").font(.caption).foregroundStyle(.secondary)
            }
        case .done(let result):
            Label("\(result.itemsImported) imported, \(result.itemsSkipped) skipped",
                  systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .error(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }
}

#Preview {
    NavigationStack { PhotoCaptureView() }
        .modelContainer(for: [BloodDraw.self, Biomarker.self, BiomarkerReading.self], inMemory: true)
}
