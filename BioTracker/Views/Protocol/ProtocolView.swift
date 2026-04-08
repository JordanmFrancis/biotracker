import SwiftUI
import SwiftData

struct ProtocolView: View {
    @Query(sort: \ProtocolItem.sortOrder) private var items: [ProtocolItem]
    @State private var showInactive = false

    private let timeBlocks = ["Morning Fasted", "Morning Post-Meal", "Midday", "Evening", "Bedtime", ""]

    private var filteredItems: [ProtocolItem] {
        showInactive ? items : items.filter(\.isActive)
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        icon: "pills.fill",
                        title: "No Protocol",
                        message: "Import your protocol data to see your supplement and medication stack."
                    )
                } else {
                    List {
                        ForEach(timeBlocks, id: \.self) { block in
                            let blockItems = filteredItems.filter { $0.timeBlock == block || (block.isEmpty && $0.timeBlock.isEmpty) }
                            if !blockItems.isEmpty {
                                Section(block.isEmpty ? "Unscheduled" : block) {
                                    ForEach(blockItems, id: \.id) { item in
                                        NavigationLink {
                                            ProtocolItemDetailView(item: item)
                                        } label: {
                                            ProtocolItemRow(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Protocol")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $showInactive) {
                        Label("Show Inactive", systemImage: "eye")
                    }
                }
            }
        }
    }
}

struct ProtocolItemRow: View {
    let item: ProtocolItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.subheadline.bold())
                    TypeBadge(itemType: item.itemType)
                }
                Text(item.dose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.frequency.isEmpty && item.frequency != "daily" {
                    Text(item.frequency)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !item.isActive {
                Text("Inactive")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(item.isActive ? 1 : 0.5)
    }
}

struct ProtocolItemDetailView: View {
    let item: ProtocolItem

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: item.name)
                LabeledContent("Type", value: item.itemType.label)
                LabeledContent("Dose", value: item.dose)
                LabeledContent("Frequency", value: item.frequency)
                if !item.timeBlock.isEmpty {
                    LabeledContent("Time Block", value: item.timeBlock)
                }
                LabeledContent("Status", value: item.isActive ? "Active" : "Inactive")
                LabeledContent("Duration", value: item.durationText)
            }

            if let mechanism = item.mechanism, !mechanism.isEmpty {
                Section("Mechanism") {
                    Text(mechanism)
                        .font(.subheadline)
                }
            }

            if let rationale = item.geneticRationale, !rationale.isEmpty {
                Section("Genetic Rationale") {
                    Text(rationale)
                        .font(.subheadline)
                }
            }

            if let warnings = item.warnings, !warnings.isEmpty {
                Section("Warnings") {
                    Text(warnings)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProtocolView()
        .modelContainer(for: ProtocolItem.self, inMemory: true)
}
