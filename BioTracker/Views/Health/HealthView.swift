import SwiftUI
import SwiftData

struct HealthView: View {
    @Query(sort: \Biomarker.sortOrder) private var biomarkers: [Biomarker]
    @Query(sort: \BloodDraw.collectionDate, order: .reverse) private var bloodDraws: [BloodDraw]
    @State private var collapsed: Set<String> = []

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
            if biomarkers.isEmpty {
                EmptyStateView(
                    icon: "drop.fill",
                    title: "No Biomarkers Yet",
                    message: "Capture a lab photo or import a JSON file from Settings to get started."
                )
                .navigationTitle("Health")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        HealthHeroCard(
                            markerCount: biomarkers.filter { $0.latestReading != nil }.count,
                            flaggedCount: flaggedCount,
                            lastDraw: bloodDraws.first?.collectionDate
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 18)

                        ForEach(populatedCategories, id: \.category) { group in
                            Section {
                                if !collapsed.contains(group.category.rawValue) {
                                    categoryCard(biomarkers: group.biomarkers)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 18)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            } header: {
                                CategoryHeader(
                                    name: group.category.rawValue,
                                    count: group.biomarkers.count,
                                    flagged: flaggedInGroup(group.biomarkers),
                                    isCollapsed: collapsed.contains(group.category.rawValue)
                                ) {
                                    toggle(group.category.rawValue)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("Health")
                .navigationDestination(for: UUID.self) { id in
                    if let bm = biomarkers.first(where: { $0.id == id }) {
                        BiomarkerDetailView(biomarker: bm)
                    }
                }
            }
        }
    }

    private func categoryCard(biomarkers: [Biomarker]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(biomarkers.enumerated()), id: \.element.id) { idx, biomarker in
                NavigationLink(value: biomarker.id) {
                    HStack {
                        BiomarkerRow(biomarker: biomarker)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < biomarkers.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func flaggedInGroup(_ biomarkers: [Biomarker]) -> Int {
        biomarkers.compactMap(\.latestReading).filter {
            $0.flag == .high || $0.flag == .low || $0.flag == .critical
        }.count
    }

    private func toggle(_ name: String) {
        withAnimation(.snappy(duration: 0.25)) {
            if collapsed.contains(name) {
                collapsed.remove(name)
            } else {
                collapsed.insert(name)
            }
        }
    }
}

// MARK: - Sticky section header

private struct CategoryHeader: View {
    let name: String
    let count: Int
    let flagged: Int
    let isCollapsed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)

                if flagged > 0 {
                    Text("\(flagged)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.flagAbove)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.flagAbove.opacity(0.18))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Opaque background so rows don't show through when pinned
                Color(.systemGroupedBackground)
                    .overlay(alignment: .bottom) {
                        Divider().opacity(isCollapsed ? 0 : 0.5)
                    }
            )
        }
        .buttonStyle(.plain)
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
                     color: flaggedCount > 0 ? Color.flagAbove : Color.flagInRange)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview {
    HealthView()
        .modelContainer(for: [BloodDraw.self, Biomarker.self, BiomarkerReading.self], inMemory: true)
        .preferredColorScheme(.dark)
}
