import SwiftUI
import SwiftData

struct HealthView: View {
    @Query(sort: \Biomarker.sortOrder) private var biomarkers: [Biomarker]
    @Query(sort: \BloodDraw.collectionDate, order: .reverse) private var bloodDraws: [BloodDraw]

    private var populatedCategories: [(category: BiomarkerCategory, biomarkers: [Biomarker])] {
        let withReadings = biomarkers.filter { $0.latestReading != nil }
        let grouped = Dictionary(grouping: withReadings) { $0.category }
        return BiomarkerCategory.allCases.compactMap { cat in
            guard let bms = grouped[cat.rawValue], !bms.isEmpty else { return nil }
            return (cat, bms.sorted { $0.name < $1.name })
        }
    }

    private var flaggedCount: Int {
        biomarkers.compactMap(\.latestReading).filter {
            $0.flag == .high || $0.flag == .low || $0.flag == .critical
        }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if biomarkers.isEmpty {
                    EmptyStateView(
                        icon: "drop.fill",
                        title: "No Biomarkers Yet",
                        message: "Capture a lab photo or import a JSON file from Settings to get started."
                    )
                } else {
                    List {
                        Section {
                            HealthHeroCard(
                                markerCount: biomarkers.filter { $0.latestReading != nil }.count,
                                flaggedCount: flaggedCount,
                                lastDraw: bloodDraws.first?.collectionDate
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }

                        Section("Categories") {
                            ForEach(populatedCategories, id: \.category) { group in
                                NavigationLink {
                                    CategoryDetailView(
                                        category: group.category,
                                        biomarkers: group.biomarkers
                                    )
                                } label: {
                                    CategoryRow(
                                        category: group.category,
                                        biomarkers: group.biomarkers
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Health")
        }
    }
}

// MARK: - Hero card

private struct HealthHeroCard: View {
    let markerCount: Int
    let flaggedCount: Int
    let lastDraw: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Panel")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    if let date = lastDraw {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.title2.bold())
                    } else {
                        Text("No draws yet")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundStyle(Color.brandAccent)
            }

            HStack(spacing: 24) {
                stat(value: "\(markerCount)", label: "Markers")
                Divider().frame(height: 28)
                stat(value: "\(flaggedCount)",
                     label: "Flagged",
                     color: flaggedCount > 0 ? .flagAbove : .flagInRange)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.brandAccent.opacity(0.25), lineWidth: 1)
        )
    }

    private func stat(value: String, label: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Category row

private struct CategoryRow: View {
    let category: BiomarkerCategory
    let biomarkers: [Biomarker]

    private var flaggedInCategory: Int {
        biomarkers.compactMap(\.latestReading).filter {
            $0.flag == .high || $0.flag == .low || $0.flag == .critical
        }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsTile(symbol: category.iconName, color: category.tileColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if flaggedInCategory > 0 {
                Text("\(flaggedInCategory)")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.flagAbove.opacity(0.18))
                    .foregroundStyle(Color.flagAbove)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        let count = biomarkers.count
        let noun = count == 1 ? "marker" : "markers"
        return "\(count) \(noun)"
    }
}

#Preview {
    HealthView()
        .modelContainer(for: [BloodDraw.self, Biomarker.self, BiomarkerReading.self], inMemory: true)
        .preferredColorScheme(.dark)
}
