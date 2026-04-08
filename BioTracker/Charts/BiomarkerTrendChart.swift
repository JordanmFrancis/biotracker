import SwiftUI
import Charts

/// Function Health–style biomarker chart:
/// - In-range band shaded soft green across the plot area
/// - Out-of-range shaded soft orange
/// - Trend line with gradient fill below
/// - Points colored by flag with annotated values
/// - Y axis always includes the reference thresholds so moves are visible at real scale
struct BiomarkerTrendChart: View {
    let biomarker: Biomarker

    private var readings: [BiomarkerReading] {
        biomarker.sortedReadings.filter { !$0.isQualitative }
    }

    var body: some View {
        if readings.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.xyaxis.line",
                description: Text("No numeric readings yet.")
            )
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            // Above-range band
            if let high = biomarker.referenceRangeHigh {
                RectangleMark(
                    yStart: .value("Above", high),
                    yEnd: .value("Top", yDomain.upperBound)
                )
                .foregroundStyle(Color.flagAbove.opacity(0.12))
            }

            // Below-range band
            if let low = biomarker.referenceRangeLow {
                RectangleMark(
                    yStart: .value("Bottom", yDomain.lowerBound),
                    yEnd: .value("Below", low)
                )
                .foregroundStyle(Color.flagBelow.opacity(0.12))
            }

            // In-range band
            if let low = biomarker.referenceRangeLow, let high = biomarker.referenceRangeHigh {
                RectangleMark(
                    yStart: .value("Low", low),
                    yEnd: .value("High", high)
                )
                .foregroundStyle(Color.flagInRange.opacity(0.18))
            } else if let high = biomarker.referenceRangeHigh {
                RectangleMark(
                    yStart: .value("Low", yDomain.lowerBound),
                    yEnd: .value("High", high)
                )
                .foregroundStyle(Color.flagInRange.opacity(0.18))
            } else if let low = biomarker.referenceRangeLow {
                RectangleMark(
                    yStart: .value("Low", low),
                    yEnd: .value("High", yDomain.upperBound)
                )
                .foregroundStyle(Color.flagInRange.opacity(0.18))
            }

            // Dashed threshold lines
            if let high = biomarker.referenceRangeHigh {
                RuleMark(y: .value("Upper", high))
                    .foregroundStyle(Color.flagAbove.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            if let low = biomarker.referenceRangeLow {
                RuleMark(y: .value("Lower", low))
                    .foregroundStyle(Color.flagBelow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }

            // Area under the trend line (gradient)
            ForEach(readings, id: \.id) { reading in
                AreaMark(
                    x: .value("Date", reading.drawDate),
                    yStart: .value("Bottom", yDomain.lowerBound),
                    yEnd: .value("Value", reading.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.brandAccent.opacity(0.25), Color.brandAccent.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Trend line
            ForEach(readings, id: \.id) { reading in
                LineMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(Color.brandAccent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }

            // Points
            ForEach(readings, id: \.id) { reading in
                PointMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(reading.flag.color)
                .symbolSize(56)
                .annotation(position: .top, spacing: 4) {
                    Text(reading.displayValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(reading.flag.color)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(readings.count, 5))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.12))
            }
        }
        .chartYScale(domain: yDomain)
    }

    private var yDomain: ClosedRange<Double> {
        let values = readings.map(\.value)
        var low = values.min() ?? 0
        var high = values.max() ?? 100

        if let refHigh = biomarker.referenceRangeHigh {
            high = max(high, refHigh * 1.25)
            low = min(low, refHigh * 0.6)
        }
        if let refLow = biomarker.referenceRangeLow {
            low = min(low, refLow * 0.75)
            high = max(high, refLow * 1.5)
        }

        let range = high - low
        let padding = max(range * 0.1, 1)
        return max(0, low - padding)...(high + padding)
    }
}
