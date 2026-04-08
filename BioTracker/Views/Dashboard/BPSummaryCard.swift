import SwiftUI
import Charts

struct BPSummaryCard: View {
    let reading: BPReading
    let recentReadings: [BPReading]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Blood Pressure")
                    .font(.headline)
                Spacer()
                Text(reading.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(reading.displayText)
                        .font(.title.bold())
                    Text(reading.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(reading.category.color)
                }

                if recentReadings.count >= 2 {
                    Chart {
                        ForEach(Array(recentReadings.reversed().enumerated()), id: \.offset) { index, bp in
                            LineMark(x: .value("Day", index), y: .value("Systolic", bp.systolic))
                                .foregroundStyle(.red)
                            LineMark(x: .value("Day", index), y: .value("Diastolic", bp.diastolic))
                                .foregroundStyle(.blue)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartLegend(.hidden)
                    .frame(height: 40)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
