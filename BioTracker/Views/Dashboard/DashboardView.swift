import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Biomarker.sortOrder) private var biomarkers: [Biomarker]
    @Query(sort: \WhoopEntry.date, order: .reverse) private var whoopEntries: [WhoopEntry]
    @Query(sort: \BPReading.date, order: .reverse) private var bpReadings: [BPReading]
    @Query(sort: \BloodDraw.collectionDate, order: .reverse) private var bloodDraws: [BloodDraw]

    var body: some View {
        NavigationStack {
            Group {
                if biomarkers.isEmpty {
                    EmptyStateView(
                        icon: "drop.fill",
                        title: "No Biomarkers",
                        message: "Import your lab results from Settings to see your biomarker dashboard."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            QuickStatsBar(
                                biomarkerCount: biomarkers.count,
                                flaggedCount: flaggedCount,
                                lastDrawDate: bloodDraws.first?.collectionDate,
                                drawCount: bloodDraws.count
                            )

                            if let latest = whoopEntries.first {
                                WhoopSummaryCard(entry: latest)
                            }

                            if let latest = bpReadings.first {
                                BPSummaryCard(reading: latest, recentReadings: Array(bpReadings.prefix(7)))
                            }

                            ForEach(groupedCategories, id: \.category) { group in
                                CategorySection(
                                    category: group.category,
                                    biomarkers: group.biomarkers
                                )
                            }
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: UUID.self) { id in
                if let biomarker = biomarkers.first(where: { $0.id == id }) {
                    BiomarkerDetailView(biomarker: biomarker)
                }
            }
        }
    }

    private var flaggedCount: Int {
        biomarkers.compactMap(\.latestReading).filter { $0.flag == .high || $0.flag == .low || $0.flag == .critical }.count
    }

    private var groupedCategories: [(category: String, biomarkers: [Biomarker])] {
        let grouped = Dictionary(grouping: biomarkers.filter { $0.latestReading != nil }) { $0.category }
        return BiomarkerCategory.allCases.compactMap { cat in
            guard let bms = grouped[cat.rawValue], !bms.isEmpty else { return nil }
            return (category: cat.rawValue, biomarkers: bms)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Biomarker.self, inMemory: true)
}
