import SwiftUI
import Charts

/// Function Health–style biomarker chart:
/// - Left-side legend with labeled range zones (Above / In Range / Below)
///   handles all three cases: both thresholds, high-only, low-only.
/// - Clean plot area: no colored bands, no reference lines.
/// - Thin grey trend line, dots colored by flag, value annotations.
/// - Month/year X axis.
struct BiomarkerTrendChart: View {
    let biomarker: Biomarker
    @State private var plotFrame: CGRect = .zero

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
            HStack(alignment: .top, spacing: 12) {
                if !zones.isEmpty {
                    YAxisLegend(zones: zones, domain: yDomain, plotFrame: plotFrame)
                        .frame(width: 82)
                }
                chart
            }
            .onPreferenceChange(PlotFramePreferenceKey.self) { plotFrame = $0 }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Thin connecting line — muted grey, no area fill, no bands.
            ForEach(readings, id: \.id) { reading in
                LineMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(Color.secondary.opacity(0.4))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            }

            // Points colored by flag with value annotation.
            ForEach(readings, id: \.id) { reading in
                PointMark(
                    x: .value("Date", reading.drawDate),
                    y: .value("Value", reading.value)
                )
                .foregroundStyle(reading.flag.color)
                .symbolSize(80)
                .annotation(position: .top, spacing: 4) {
                    Text(reading.displayValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(reading.flag.color)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(readings.count, 5))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.12))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: PlotFramePreferenceKey.self,
                        value: geo[proxy.plotAreaFrame]
                    )
            }
        }
    }

    // MARK: - Zones

    /// Ordered top-to-bottom. The "In Range" zone always exists; "Above"
    /// and "Below" only appear when the relevant threshold is defined.
    private var zones: [Zone] {
        let low = biomarker.referenceRangeLow
        let high = biomarker.referenceRangeHigh
        let domainLow = yDomain.lowerBound
        let domainHigh = yDomain.upperBound

        switch (low, high) {
        case let (.some(lowV), .some(highV)):
            return [
                Zone(label: "Above",
                     sublabel: "> \(format(highV))",
                     color: .flagAbove,
                     from: highV, to: domainHigh),
                Zone(label: "In Range",
                     sublabel: "\(format(lowV)) - \(format(highV))",
                     color: .flagInRange,
                     from: lowV, to: highV),
                Zone(label: "Below",
                     sublabel: "< \(format(lowV))",
                     color: .flagBelow,
                     from: domainLow, to: lowV)
            ]
        case let (nil, .some(highV)):
            return [
                Zone(label: "Above",
                     sublabel: "> \(format(highV))",
                     color: .flagAbove,
                     from: highV, to: domainHigh),
                Zone(label: "In Range",
                     sublabel: "< \(format(highV))",
                     color: .flagInRange,
                     from: domainLow, to: highV)
            ]
        case let (.some(lowV), nil):
            return [
                Zone(label: "In Range",
                     sublabel: "> \(format(lowV))",
                     color: .flagInRange,
                     from: lowV, to: domainHigh),
                Zone(label: "Below",
                     sublabel: "< \(format(lowV))",
                     color: .flagBelow,
                     from: domainLow, to: lowV)
            ]
        case (nil, nil):
            return []
        }
    }

    // MARK: - Y domain

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

    // MARK: - Formatting

    private func format(_ v: Double) -> String {
        if v == v.rounded() { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Zone model

private struct Zone: Identifiable {
    let id = UUID()
    let label: String
    let sublabel: String
    let color: Color
    let from: Double
    let to: Double
}

// MARK: - Y-axis legend column

/// Stacks zone labels aligned to the chart's plot area. Uses the plotFrame
/// reported via PreferenceKey to match the chart's Y pixel positions exactly
/// (so labels stay anchored regardless of X-axis label height).
private struct YAxisLegend: View {
    let zones: [Zone]
    let domain: ClosedRange<Double>
    let plotFrame: CGRect

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(zones) { zone in
                zoneRow(zone)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func zoneRow(_ zone: Zone) -> some View {
        let topY = plotFrame.minY + yPos(for: zone.to)
        let bottomY = plotFrame.minY + yPos(for: zone.from)
        let zoneHeight = max(bottomY - topY, 0)

        HStack(alignment: .center, spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(zone.color)
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(zone.sublabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(height: zoneHeight, alignment: .center)
        .offset(y: topY)
        .opacity(plotFrame == .zero ? 0 : 1)
    }

    private func yPos(for value: Double) -> CGFloat {
        let clamped = min(max(value, domain.lowerBound), domain.upperBound)
        let span = domain.upperBound - domain.lowerBound
        guard span > 0 else { return 0 }
        let t = (domain.upperBound - clamped) / span
        return CGFloat(t) * plotFrame.height
    }
}

// MARK: - Preference key

private struct PlotFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
