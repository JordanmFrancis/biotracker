import SwiftUI
import Charts

struct BPTrendChart: View {
    let readings: [BPReading]

    private var sorted: [BPReading] {
        readings.sorted { $0.date < $1.date }
    }

    var body: some View {
        if sorted.count < 2 {
            ContentUnavailableView("Not Enough Data", systemImage: "chart.xyaxis.line", description: Text("At least 2 readings needed."))
        } else {
            Chart {
                // Threshold lines
                RuleMark(y: .value("Stage2", 140))
                    .foregroundStyle(.red.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                RuleMark(y: .value("Stage1", 130))
                    .foregroundStyle(.orange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                RuleMark(y: .value("Elevated", 120))
                    .foregroundStyle(.yellow.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                ForEach(sorted, id: \.id) { reading in
                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Systolic", reading.systolic),
                        series: .value("Type", "Systolic")
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())

                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Diastolic", reading.diastolic),
                        series: .value("Type", "Diastolic")
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle())
                }
            }
            .chartForegroundStyleScale([
                "Systolic": Color.red,
                "Diastolic": Color.blue
            ])
            .chartYAxisLabel("mmHg")
        }
    }
}
