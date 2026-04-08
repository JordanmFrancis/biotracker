import SwiftUI
import Charts

/// Sparkline plotted against a *fixed* Y domain so a tiny in-range wobble and
/// a catastrophic out-of-range move look visibly different.
///
/// Domain is chosen in this order:
/// 1. If the biomarker has a reference range, use it (with margin).
/// 2. Else fall back to the data min/max.
struct MiniSparkline: View {
    let readings: [BiomarkerReading]
    let referenceLow: Double?
    let referenceHigh: Double?

    var body: some View {
        if readings.count >= 2 {
            Chart {
                // In-range band — muted dusty green, kept deliberately subtle
                // so it reads as a "zone" behind the line, not an alert color.
                if let low = referenceLow, let high = referenceHigh {
                    RectangleMark(yStart: .value("Low", low), yEnd: .value("High", high))
                        .foregroundStyle(Color.zoneInRange.opacity(0.22))
                } else if let high = referenceHigh {
                    RectangleMark(yStart: .value("Low", yDomain.lowerBound), yEnd: .value("High", high))
                        .foregroundStyle(Color.zoneInRange.opacity(0.22))
                } else if let low = referenceLow {
                    RectangleMark(yStart: .value("Low", low), yEnd: .value("High", yDomain.upperBound))
                        .foregroundStyle(Color.zoneInRange.opacity(0.22))
                }

                // Trend line
                ForEach(Array(readings.enumerated()), id: \.element.id) { idx, reading in
                    LineMark(
                        x: .value("Index", idx),
                        y: .value("Value", clamp(reading.value))
                    )
                    .foregroundStyle(Color.chartLine)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }

                // Points colored by flag
                ForEach(Array(readings.enumerated()), id: \.element.id) { idx, reading in
                    PointMark(
                        x: .value("Index", idx),
                        y: .value("Value", clamp(reading.value))
                    )
                    .foregroundStyle(reading.flag.color)
                    .symbolSize(18)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: yDomain)
            .chartLegend(.hidden)
            .frame(width: 72, height: 28)
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = readings.map(\.value).filter { !$0.isNaN && !$0.isInfinite }
        let dataLow = values.min() ?? 0
        let dataHigh = values.max() ?? 1

        if let low = referenceLow, let high = referenceHigh {
            // Expand to include any out-of-range values so they aren't clipped flat
            let expandedLow = min(low, dataLow) - (high - low) * 0.15
            let expandedHigh = max(high, dataHigh) + (high - low) * 0.15
            return expandedLow...expandedHigh
        } else if let high = referenceHigh {
            let span = high * 0.5
            return max(0, dataLow - span * 0.2)...max(dataHigh, high) + span * 0.2
        } else if let low = referenceLow {
            let span = low * 0.5
            return max(0, min(dataLow, low) - span * 0.2)...(dataHigh + span * 0.2)
        } else {
            let span = max(dataHigh - dataLow, 1)
            return (dataLow - span * 0.1)...(dataHigh + span * 0.1)
        }
    }

    private func clamp(_ v: Double) -> Double {
        min(max(v, yDomain.lowerBound), yDomain.upperBound)
    }
}
