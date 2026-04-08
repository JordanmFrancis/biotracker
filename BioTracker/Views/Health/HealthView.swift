import SwiftUI
import SwiftData

enum BiomarkerFilter: Hashable {
    case all, inRange, outOfRange
}

struct HealthView: View {
    @Query(sort: \Biomarker.sortOrder) private var biomarkers: [Biomarker]
    @Query(sort: \BloodDraw.collectionDate, order: .reverse) private var bloodDraws: [BloodDraw]
    @State private var collapsed: Set<String> = []
    @State private var filter: BiomarkerFilter = .all

    private var biomarkersWithReadings: [Biomarker] {
        biomarkers.filter { $0.latestReading != nil }
    }

    private var totalCount: Int { biomarkersWithReadings.count }

    private var inRangeCount: Int {
        biomarkersWithReadings.compactMap(\.latestReading).filter {
            $0.flag != .high && $0.flag != .low && $0.flag != .critical
        }.count
    }

    private var outOfRangeCount: Int {
        biomarkersWithReadings.compactMap(\.latestReading).filter {
            $0.flag == .high || $0.flag == .low || $0.flag == .critical
        }.count
    }

    private var filteredBiomarkers: [Biomarker] {
        switch filter {
        case .all:
            return biomarkersWithReadings
        case .inRange:
            return biomarkersWithReadings.filter { bm in
                guard let flag = bm.latestReading?.flag else { return true }
                return flag != .high && flag != .low && flag != .critical
            }
        case .outOfRange:
            return biomarkersWithReadings.filter { bm in
                guard let flag = bm.latestReading?.flag else { return false }
                return flag == .high || flag == .low || flag == .critical
            }
        }
    }

    private var populatedCategories: [(category: BiomarkerCategory, biomarkers: [Biomarker])] {
        let grouped = Dictionary(grouping: filteredBiomarkers) { $0.category }
        return BiomarkerCategory.allCases.compactMap { cat in
            guard let bms = grouped[cat.rawValue], !bms.isEmpty else { return nil }
            return (cat, bms.sorted { $0.name < $1.name })
        }
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
                VStack(spacing: 0) {
                    FixedHeader(
                        filter: $filter,
                        total: totalCount,
                        inRange: inRangeCount,
                        outOfRange: outOfRangeCount
                    )

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            HealthHeroCard(
                                markerCount: totalCount,
                                flaggedCount: outOfRangeCount,
                                lastDraw: bloodDraws.first?.collectionDate
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 14)

                            ForEach(populatedCategories, id: \.category) { group in
                                Section {
                                    if !collapsed.contains(group.category.rawValue) {
                                        categoryCard(biomarkers: group.biomarkers)
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 14)
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
                }
                .background(Color.surfaceBase.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
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
                .fill(Color.surfaceElevated)
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

// MARK: - Fixed top header (title + filter chips)

private struct FixedHeader: View {
    @Binding var filter: BiomarkerFilter
    let total: Int
    let inRange: Int
    let outOfRange: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Health")
                .font(.headline)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                chip(label: "All", count: total, dot: nil, tag: .all)
                chip(label: "In Range", count: inRange, dot: .flagInRange, tag: .inRange)
                chip(label: "Out of Range", count: outOfRange, dot: .flagAbove, tag: .outOfRange)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 6)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            Color.surfaceBase
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.4)
                }
                .ignoresSafeArea(edges: .top)
        )
    }

    @ViewBuilder
    private func chip(label: String, count: Int, dot: Color?, tag: BiomarkerFilter) -> some View {
        let isSelected = filter == tag
        Button {
            withAnimation(.snappy(duration: 0.2)) { filter = tag }
        } label: {
            HStack(spacing: 6) {
                if let dot {
                    Circle()
                        .fill(dot)
                        .frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("· \(count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.brandAccent.opacity(0.18) : Color.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.brandAccent.opacity(0.9) : Color.borderQuiet, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
            HStack(spacing: 8) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                if flagged > 0 {
                    Text("\(flagged)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.flagAbove)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.flagAbove.opacity(0.18))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Opaque background so rows don't show through when pinned
                Color.surfaceBase
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
                .fill(Color.surfaceElevated)
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
