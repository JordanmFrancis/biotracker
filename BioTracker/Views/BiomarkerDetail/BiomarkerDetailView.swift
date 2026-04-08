import SwiftUI

struct BiomarkerDetailView: View {
    let biomarker: Biomarker

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                trendCard
                readingsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(biomarker.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header (current value)

    @ViewBuilder
    private var headerCard: some View {
        if let reading = biomarker.latestReading {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        statusPill(for: reading.flag)
                        Spacer()
                        Text(reading.drawDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(reading.displayValue)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                        Text(biomarker.unit)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    if let refText = rangeText {
                        Text(refText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func statusPill(for flag: ReadingFlag) -> some View {
        HStack(spacing: 6) {
            Circle().fill(flag.color).frame(width: 7, height: 7)
            Text(flag.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(flag.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(flag.color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var rangeText: String? {
        let unit = biomarker.unit
        if let low = biomarker.referenceRangeLow, let high = biomarker.referenceRangeHigh {
            return "Optimal: \(format(low)) – \(format(high)) \(unit)"
        } else if let high = biomarker.referenceRangeHigh {
            return "Optimal: < \(format(high)) \(unit)"
        } else if let low = biomarker.referenceRangeLow {
            return "Optimal: > \(format(low)) \(unit)"
        } else if let text = biomarker.referenceRangeText {
            return "Reference: \(text)"
        }
        return nil
    }

    // MARK: - Trend

    private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Trend")
                    .font(.headline)
                BiomarkerTrendChart(biomarker: biomarker)
                    .frame(height: 240)
            }
        }
    }

    // MARK: - Readings list

    private var readingsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("All Readings")
                    .font(.headline)

                ForEach(Array(biomarker.sortedReadings.reversed().enumerated()), id: \.element.id) { idx, reading in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reading.drawDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                            if let src = reading.bloodDraw?.labSource {
                                Text(src)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Circle().fill(reading.flag.color).frame(width: 6, height: 6)
                            Text(reading.displayValue)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                            Text(biomarker.unit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)

                    if idx < biomarker.sortedReadings.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func format(_ v: Double) -> String {
        if v == v.rounded() { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Card wrapper

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}
