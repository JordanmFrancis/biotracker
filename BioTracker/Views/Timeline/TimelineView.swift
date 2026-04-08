import SwiftUI
import SwiftData

struct TimelineView: View {
    var body: some View {
        NavigationStack {
            BloodDrawTimeline()
                .navigationTitle("Timeline")
        }
    }
}

struct BloodDrawTimeline: View {
    @Query(sort: \BloodDraw.collectionDate, order: .reverse) private var draws: [BloodDraw]

    var body: some View {
        if draws.isEmpty {
            EmptyStateView(icon: "syringe.fill", title: "No Blood Draws", message: "Import lab results to see your draw timeline.")
        } else {
            List(draws, id: \.id) { draw in
                NavigationLink {
                    BloodDrawDetailView(draw: draw)
                } label: {
                    HStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(draw.formattedDate)
                                .font(.headline)
                            HStack(spacing: 8) {
                                Text(draw.labSource)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let fasting = draw.fasting {
                                    Text(fasting ? "Fasting" : "Non-fasting")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(fasting ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                        .foregroundStyle(fasting ? .green : .orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(draw.readings.count)")
                                .font(.title3.bold())
                            Text("markers")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if draw.flaggedCount > 0 {
                            Text("\(draw.flaggedCount)")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

struct BloodDrawDetailView: View {
    let draw: BloodDraw

    private var sortedReadings: [BiomarkerReading] {
        draw.readings.sorted { ($0.biomarker?.category ?? "") < ($1.biomarker?.category ?? "") }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: draw.formattedDate)
                LabeledContent("Lab Source", value: draw.labSource)
                if let fasting = draw.fasting {
                    LabeledContent("Fasting", value: fasting ? "Yes" : "No")
                }
                LabeledContent("Total Markers", value: "\(draw.readings.count)")
                LabeledContent("Flagged", value: "\(draw.flaggedCount)")
                if let notes = draw.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Results") {
                ForEach(sortedReadings, id: \.id) { reading in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reading.biomarker?.name ?? "Unknown")
                                .font(.subheadline)
                            if let cat = reading.biomarker?.category {
                                Text(cat)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(reading.displayValue) \(reading.biomarker?.unit ?? "")")
                            .font(.subheadline.monospacedDigit())
                        if reading.flag != .normal {
                            StatusBadge(flag: reading.flag)
                        }
                    }
                }
            }
        }
        .navigationTitle(draw.formattedDate)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: BloodDraw.self, inMemory: true)
}
