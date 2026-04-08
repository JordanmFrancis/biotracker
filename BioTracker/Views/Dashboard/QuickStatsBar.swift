import SwiftUI

struct QuickStatsBar: View {
    let biomarkerCount: Int
    let flaggedCount: Int
    let lastDrawDate: Date?
    let drawCount: Int

    var body: some View {
        HStack(spacing: 12) {
            statItem(value: "\(biomarkerCount)", label: "Markers", icon: "drop.fill", color: .blue)
            statItem(value: "\(flaggedCount)", label: "Flagged", icon: "exclamationmark.triangle.fill", color: flaggedCount > 0 ? .red : .green)
            statItem(value: "\(drawCount)", label: "Draws", icon: "syringe.fill", color: .purple)
            if let date = lastDrawDate {
                statItem(value: date.shortFormatted, label: "Last Draw", icon: "calendar", color: .orange)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    QuickStatsBar(biomarkerCount: 93, flaggedCount: 5, lastDrawDate: .now, drawCount: 5)
        .padding()
}
