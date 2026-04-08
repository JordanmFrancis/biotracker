import SwiftUI

struct BiomarkerRow: View {
    let biomarker: Biomarker

    private var flag: ReadingFlag {
        biomarker.latestReading?.flag ?? .normal
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(flag.color)
                .frame(width: 4)

            // Name + status/value
            VStack(alignment: .leading, spacing: 3) {
                Text(biomarker.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let reading = biomarker.latestReading {
                    HStack(spacing: 4) {
                        Text(flag.label)
                            .foregroundStyle(flag.color)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(reading.displayValue)")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(biomarker.unit)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Spacer()

            // Sparkline
            MiniSparkline(
                values: TrendCalculator.sparklineValues(for: biomarker),
                colors: TrendCalculator.sparklineColors(for: biomarker)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
