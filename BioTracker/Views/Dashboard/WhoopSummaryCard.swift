import SwiftUI

struct WhoopSummaryCard: View {
    let entry: WhoopEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(.red)
                Text("WHOOP")
                    .font(.headline)
                Spacer()
                Text(entry.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                metricView(
                    label: "Recovery",
                    value: entry.recoveryPercent.map { String(format: "%.0f%%", $0) } ?? "—",
                    color: recoveryColor
                )
                metricView(
                    label: "Strain",
                    value: entry.dayStrain.map { String(format: "%.1f", $0) } ?? "—",
                    color: .blue
                )
                metricView(
                    label: "Sleep",
                    value: entry.hoursOfSleep.map { String(format: "%.1fh", $0) } ?? "—",
                    color: .purple
                )
                metricView(
                    label: "HRV",
                    value: entry.hrvMs.map { String(format: "%.0f ms", $0) } ?? "—",
                    color: .teal
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var recoveryColor: Color {
        switch entry.recoveryColor {
        case .green: .whoopGreen
        case .yellow: .whoopYellow
        case .red: .whoopRed
        case .unknown: .secondary
        }
    }

    private func metricView(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
