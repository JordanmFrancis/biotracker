import SwiftUI
import Charts

struct WhoopRecoveryChart: View {
    let entries: [WhoopEntry]

    private var sorted: [WhoopEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart {
            ForEach(sorted, id: \.id) { entry in
                if let recovery = entry.recoveryPercent {
                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Recovery", recovery)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [recoveryGradientColor(recovery).opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Recovery", recovery)
                    )
                    .foregroundStyle(recoveryGradientColor(recovery))
                    .symbol(Circle())
                }
            }

            // Zone threshold lines
            RuleMark(y: .value("Green", 67))
                .foregroundStyle(.green.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            RuleMark(y: .value("Yellow", 34))
                .foregroundStyle(.yellow.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .chartYAxisLabel("%")
        .chartYScale(domain: 0...100)
    }

    private func recoveryGradientColor(_ value: Double) -> Color {
        if value >= 67 { return .whoopGreen }
        if value >= 34 { return .whoopYellow }
        return .whoopRed
    }
}

struct WhoopHRVTrendChart: View {
    let entries: [WhoopEntry]

    private var sorted: [WhoopEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var rollingAverage: [(date: Date, avg: Double)] {
        let data = sorted.compactMap { e -> (Date, Double)? in
            guard let hrv = e.hrvMs else { return nil }
            return (e.date, hrv)
        }
        guard data.count >= 7 else { return [] }
        return (6..<data.count).map { i in
            let window = data[(i-6)...i]
            let avg = window.map(\.1).reduce(0, +) / 7
            return (data[i].0, avg)
        }
    }

    var body: some View {
        Chart {
            ForEach(sorted, id: \.id) { entry in
                if let hrv = entry.hrvMs {
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("HRV", hrv),
                        series: .value("Series", "Daily")
                    )
                    .foregroundStyle(.teal.opacity(0.5))
                    .symbol(Circle())
                }
            }

            ForEach(Array(rollingAverage.enumerated()), id: \.offset) { _, item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("HRV", item.avg),
                    series: .value("Series", "7-Day Avg")
                )
                .foregroundStyle(.teal)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartForegroundStyleScale([
            "Daily": Color.teal.opacity(0.5),
            "7-Day Avg": Color.teal
        ])
        .chartYAxisLabel("ms")
    }
}

struct WhoopSleepStackedChart: View {
    let entries: [WhoopEntry]

    private var sorted: [WhoopEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart {
            ForEach(sorted, id: \.id) { entry in
                if let deep = entry.swsDeepSleep {
                    BarMark(x: .value("Date", entry.date), y: .value("Hours", deep))
                        .foregroundStyle(by: .value("Stage", "Deep"))
                }
                if let rem = entry.remSleep {
                    BarMark(x: .value("Date", entry.date), y: .value("Hours", rem))
                        .foregroundStyle(by: .value("Stage", "REM"))
                }
                if let light = entry.lightSleep {
                    BarMark(x: .value("Date", entry.date), y: .value("Hours", light))
                        .foregroundStyle(by: .value("Stage", "Light"))
                }
                if let awake = entry.awakeTime {
                    BarMark(x: .value("Date", entry.date), y: .value("Hours", awake))
                        .foregroundStyle(by: .value("Stage", "Awake"))
                }
            }
        }
        .chartForegroundStyleScale([
            "Deep": Color.indigo,
            "REM": Color.cyan,
            "Light": Color.blue.opacity(0.4),
            "Awake": Color.orange.opacity(0.5)
        ])
        .chartYAxisLabel("hours")
    }
}
