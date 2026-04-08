import SwiftUI
import SwiftData

struct BPLogView: View {
    @Query(sort: \BPReading.date, order: .reverse) private var readings: [BPReading]

    var body: some View {
        if readings.isEmpty {
            EmptyStateView(icon: "heart.fill", title: "No BP Readings", message: "Import blood pressure data to see your log.")
        } else {
            List {
                Section {
                    BPTrendChart(readings: Array(readings.prefix(30)))
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Readings") {
                    ForEach(readings, id: \.id) { reading in
                        BPReadingRow(reading: reading)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

struct BPReadingRow: View {
    let reading: BPReading

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                Text(reading.context.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(reading.displayText)
                .font(.title3.bold().monospacedDigit())

            Text(reading.category.rawValue)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(reading.category.color.opacity(0.15))
                .foregroundStyle(reading.category.color)
                .clipShape(Capsule())
        }
    }
}
