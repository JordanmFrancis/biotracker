import SwiftUI

struct BiomarkerRow: View {
    let biomarker: Biomarker

    private var flag: ReadingFlag {
        biomarker.latestReading?.flag ?? .normal
    }

    private var recentReadings: [BiomarkerReading] {
        biomarker.sortedReadings.filter { !$0.isQualitative }.suffix(6).map { $0 }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Name + status + value
            VStack(alignment: .leading, spacing: 4) {
                Text(biomarker.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let reading = biomarker.latestReading {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(flag.color)
                            .frame(width: 6, height: 6)
                        Text(reading.displayValue)
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(biomarker.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Real-scale sparkline
            MiniSparkline(
                readings: recentReadings,
                referenceLow: biomarker.referenceRangeLow,
                referenceHigh: biomarker.referenceRangeHigh
            )
        }
        .padding(.vertical, 2)
    }
}
