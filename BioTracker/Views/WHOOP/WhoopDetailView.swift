import SwiftUI
import SwiftData

struct WhoopDetailView: View {
    @Query(sort: \WhoopEntry.date, order: .reverse) private var entries: [WhoopEntry]
    @State private var selectedChart = 0

    var body: some View {
        NavigationStack {
            if entries.isEmpty {
                EmptyStateView(icon: "heart.circle.fill", title: "No WHOOP Data", message: "Import your WHOOP daily log to see recovery, strain, and sleep metrics.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let latest = entries.first {
                            gaugesSection(latest)
                        }

                        chartSelector

                        chartSection
                            .frame(height: 250)
                            .padding(.horizontal)

                        recentEntriesList
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("WHOOP")
    }

    private func gaugesSection(_ entry: WhoopEntry) -> some View {
        HStack(spacing: 16) {
            gaugeItem(
                label: "Recovery",
                value: entry.recoveryPercent,
                format: "%.0f%%",
                color: entry.recoveryColor == .green ? .whoopGreen : entry.recoveryColor == .yellow ? .whoopYellow : .whoopRed,
                max: 100
            )
            gaugeItem(
                label: "Strain",
                value: entry.dayStrain,
                format: "%.1f",
                color: .blue,
                max: 21
            )
            gaugeItem(
                label: "Sleep",
                value: entry.sleepPerformancePercent,
                format: "%.0f%%",
                color: .purple,
                max: 100
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func gaugeItem(label: String, value: Double?, format: String, color: Color, max: Double) -> some View {
        VStack(spacing: 8) {
            Gauge(value: value ?? 0, in: 0...max) {
                Text(label)
            } currentValueLabel: {
                Text(value.map { String(format: format, $0) } ?? "—")
                    .font(.headline.bold())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSelector: some View {
        Picker("Chart", selection: $selectedChart) {
            Text("Recovery").tag(0)
            Text("HRV").tag(1)
            Text("Sleep").tag(2)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var chartSection: some View {
        let chartEntries = Array(entries.prefix(30))
        switch selectedChart {
        case 0:
            WhoopRecoveryChart(entries: chartEntries)
        case 1:
            WhoopHRVTrendChart(entries: chartEntries)
        default:
            WhoopSleepStackedChart(entries: chartEntries)
        }
    }

    private var recentEntriesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Days")
                .font(.headline)

            ForEach(entries.prefix(14), id: \.id) { entry in
                HStack {
                    Text(entry.date.shortFormatted)
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)

                    HStack(spacing: 12) {
                        metricLabel("R", value: entry.recoveryPercent, format: "%.0f%%")
                        metricLabel("S", value: entry.dayStrain, format: "%.1f")
                        metricLabel("HRV", value: entry.hrvMs, format: "%.0f")
                        metricLabel("RHR", value: entry.restingHR, format: "%.0f")
                        metricLabel("Sleep", value: entry.hoursOfSleep, format: "%.1fh")
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func metricLabel(_ label: String, value: Double?, format: String) -> some View {
        VStack(spacing: 2) {
            Text(value.map { String(format: format, $0) } ?? "—")
                .font(.caption.monospacedDigit())
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
    }
}

#Preview {
    WhoopDetailView()
        .modelContainer(for: WhoopEntry.self, inMemory: true)
}
