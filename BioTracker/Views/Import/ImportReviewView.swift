import SwiftUI
import SwiftData

/// Review screen shown after any successful import (photo or JSON).
/// Binds directly to the live SwiftData BloodDraw, so edits persist as you type.
struct ImportReviewView: View {
    @Bindable var draw: BloodDraw
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardConfirm = false

    var body: some View {
        Form {
            Section("Lab Draw") {
                DatePicker(
                    "Collection date",
                    selection: $draw.collectionDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                TextField("Lab source", text: $draw.labSource)
                Toggle("Fasting", isOn: Binding(
                    get: { draw.fasting ?? false },
                    set: { draw.fasting = $0 }
                ))
                TextField("Notes", text: Binding(
                    get: { draw.notes ?? "" },
                    set: { draw.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(1...3)
            }

            Section("Readings (\(draw.readings.count))") {
                if draw.readings.isEmpty {
                    Text("No readings in this draw yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedReadings, id: \.id) { reading in
                        ReadingEditorRow(reading: reading)
                    }
                    .onDelete { offsets in
                        let targets = offsets.map { sortedReadings[$0] }
                        for r in targets { modelContext.delete(r) }
                        try? modelContext.save()
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDiscardConfirm = true
                } label: {
                    Label("Discard This Import", systemImage: "trash")
                }
            } footer: {
                Text("Removes this draw and all of its readings. Biomarker history from other draws is unaffected.")
            }
        }
        .navigationTitle("Review Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .confirmationDialog(
            "Discard this import?",
            isPresented: $showDiscardConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                modelContext.delete(draw)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var sortedReadings: [BiomarkerReading] {
        draw.readings.sorted {
            ($0.biomarker?.category ?? "") < ($1.biomarker?.category ?? "")
        }
    }
}

// MARK: - Reading editor row

private struct ReadingEditorRow: View {
    @Bindable var reading: BiomarkerReading

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading.biomarker?.name ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                    if let cat = reading.biomarker?.category {
                        Text(cat)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let unit = reading.biomarker?.unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                TextField("Value", value: $reading.value, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)

                Picker("Flag", selection: $reading.flag) {
                    ForEach([ReadingFlag.normal, .high, .low, .critical], id: \.self) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.menu)
                .tint(reading.flag.color)
            }
        }
        .padding(.vertical, 4)
    }
}
