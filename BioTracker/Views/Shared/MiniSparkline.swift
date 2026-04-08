import SwiftUI
import Charts

struct MiniSparkline: View {
    let values: [Double]
    var colors: [Color] = []
    var color: Color = .secondary

    var body: some View {
        if values.count >= 2 {
            Chart {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(pointColor(at: index))
                    .symbolSize(16)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(width: 60, height: 24)
        }
    }

    private func pointColor(at index: Int) -> Color {
        if !colors.isEmpty, index < colors.count {
            return colors[index]
        }
        return color
    }
}

#Preview {
    MiniSparkline(values: [5.7, 5.4, 5.5, 5.4, 5.3], color: .green)
}
