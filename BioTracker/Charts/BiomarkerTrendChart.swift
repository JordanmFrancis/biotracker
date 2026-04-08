import SwiftUI
import Charts

struct BiomarkerTrendChart: View {
    let biomarker: Biomarker

    private var readings: [BiomarkerReading] {
        biomarker.sortedReadings.filter { !$0.isQualitative }
    }

    private var zones: [ChartZone] {
        var result: [ChartZone] = []

        // Has both low and high ref (e.g., Glucose 65-99)
        if let low = biomarker.referenceRangeLow, let high = biomarker.referenceRangeHigh {
            result.append(ChartZone(label: "Above", threshold: "> \(formatted(high))", color: .zoneAbove))
            result.append(ChartZone(label: "In Range", threshold: "\(formatted(low)) – \(formatted(high))", color: .zoneInRange))
            result.append(ChartZone(label: "Below", threshold: "< \(formatted(low))", color: .zoneAbove))
        }
        // Has only high ref (e.g., LDL < 100)
        else if let high = biomarker.referenceRangeHigh {
            result.append(ChartZone(label: "Above", threshold: "> \(formatted(high))", color: .zoneAbove))
            result.append(ChartZone(label: "In Range", threshold: "< \(formatted(high))", color: .zoneInRange))
        }
        // Has only low ref (e.g., HDL > 45)
        else if let low = biomarker.referenceRangeLow {
            result.append(ChartZone(label: "In Range", threshold: "> \(formatted(low))", color: .zoneInRange))
            result.append(ChartZone(label: "Below", threshold: "< \(formatted(low))", color: .zoneAbove))
        }

        return result
    }

    var body: some View {
        if readings.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.xyaxis.line",
                description: Text("No readings available for a chart.")
            )
        } else {
            HStack(alignment: .top, spacing: 0) {
                zoneBar
                    .frame(width: 80)
                chartView
            }
        }
    }

    private var zoneBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(zones.enumerated()), id: \.offset) { _, zone in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.color)
                        .frame(width: 4, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(zone.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(zone.threshold)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var chartView: some View {
        Chart {
            // In-range zone band
            if let low = biomarker.referenceRangeLow, let high = biomarker.referenceRangeHigh {
                RectangleMark(yStart: .value("Low", low), yEnd: .value("High", high))
                    .foregroundStyle(Color.zoneInRange.opacity(0.25))
            } else if let high = biomarker.referenceRangeHigh {
                RectangleMark(yStart: .value("Low", yDomain.lowerBound), yEnd: .value("High", high))
                    .foregroundStyle(Color.zoneInRange.opacity(0.25))
            } else if let low = biomarker.referenceRangeLow {
                RectangleMark(yStart: .value("Low", low), yEnd: .value("High", yDomain.upperBound))
                    .foregroundStyle(Color.zoneInRange.opacity(0.25))
            }

            // Out-of-range zone bands (above)
            if let high = biomarker.referenceRangeHigh {
                RectangleMark(yStart: .value("Threshold", high), yEnd: .value("Top", yDomain.upperBound))
                    .foregroundStyle(Color.zoneAbove.opacity(0.15))
            }

            // Out-of-range zone bands (below)
            if let low = biomarker.referenceRangeLow {
                RectangleMark(yStart: .value("Bottom", yDomain.lowerBound), yEnd: .value("Threshold", low))
                    .foregroundStyle(Color.zoneAbove.opacity(0.15))
            }

            // Threshold lines
            if let high = biomarker.referenceRangeHigh {
                RuleMark(y: .value("Threshold", high))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            if let low = biomarker.referenceRangeLow {
                RuleMark(y: .value("Threshold", low))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }

            // Data line
            ForEach(readings, id: \.id) { reading in
                LineMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(Color.chartLine)
                .interpolationMethod(.catmullRom)
            }

            // Data points with value labels
            ForEach(readings, id: \.id) { reading in
                PointMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(reading.flag.color)
                .symbolSize(44)
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
                    .foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(readings.count, 5))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.1))
            }
        }
        .chartYScale(domain: yDomain)
    }

    private var yDomain: ClosedRange<Double> {
        let values = readings.map(\.value)
        var low = values.min() ?? 0
        var high = values.max() ?? 100

        // Always include reference thresholds with generous margin
        // so both in-range and out-of-range zones are clearly visible
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

    private func formatted(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }
}

private struct ChartZone {
    let label: String
    let threshold: String
    let color: Color
}
