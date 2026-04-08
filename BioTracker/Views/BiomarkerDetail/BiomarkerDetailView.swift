import SwiftUI
import SwiftData

struct BiomarkerDetailView: View {
    let biomarker: Biomarker
    @Query private var protocolItems: [ProtocolItem]

    init(biomarker: Biomarker) {
        self.biomarker = biomarker
        _protocolItems = Query(filter: #Predicate<ProtocolItem> { $0.isActive }, sort: \ProtocolItem.sortOrder)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text(biomarker.name)
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // Status + current value section
                if let reading = biomarker.latestReading {
                    currentValueSection(reading: reading)
                }

                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                // Trend chart
                BiomarkerTrendChart(
                    biomarker: biomarker,
                    protocolItems: protocolItems
                )
                .frame(height: 280)
                .padding(.horizontal, 20)

                // All readings
                readingsTable
                    .padding(.top, 24)

                // Genetic context
                if !biomarker.linkedVariants.isEmpty {
                    geneticContextSection
                        .padding(.top, 24)
                }

                Spacer(minLength: 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func currentValueSection(reading: BiomarkerReading) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Flag label
            Text(reading.flag.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(reading.flag.color)
                .padding(.top, 12)

            // Value row: colored dot + value + unit
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(reading.flag.color)
                    .frame(width: 10, height: 10)
                    .offset(y: -2)

                Text(reading.displayValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(biomarker.unit)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Source date
            Text("Based on lab results from \(reading.drawDate.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits)))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Reference range
            if let refLow = biomarker.referenceRangeLow, let refHigh = biomarker.referenceRangeHigh {
                Text("Reference: \(formatted(refLow)) – \(formatted(refHigh)) \(biomarker.unit)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let refHigh = biomarker.referenceRangeHigh {
                Text("Reference: < \(formatted(refHigh)) \(biomarker.unit)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let refLow = biomarker.referenceRangeLow {
                Text("Reference: > \(formatted(refLow)) \(biomarker.unit)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if let refText = biomarker.referenceRangeText {
                Text("Reference: \(refText)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
    }

    private var readingsTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("All Readings")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ForEach(biomarker.sortedReadings.reversed(), id: \.id) { reading in
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reading.drawDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                            if let source = reading.bloodDraw?.labSource {
                                Text(source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(reading.flag.color)
                                .frame(width: 6, height: 6)
                            Text(reading.displayValue)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                            Text(biomarker.unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    if reading.id != biomarker.sortedReadings.first?.id {
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }

    private var geneticContextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Genetic Context")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(biomarker.linkedVariants, id: \.id) { variant in
                GeneticVariantCard(variant: variant)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }
}
