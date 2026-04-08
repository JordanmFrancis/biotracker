import SwiftUI
import SwiftData

struct TrendsView: View {
    @Query(sort: \Biomarker.sortOrder) private var biomarkers: [Biomarker]
    @State private var searchText = ""
    @State private var selectedCategory: BiomarkerCategory?
    @State private var showFlaggedOnly = false

    private var filtered: [Biomarker] {
        var result = biomarkers.filter { $0.latestReading != nil }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if let cat = selectedCategory {
            result = result.filter { $0.category == cat.rawValue }
        }

        if showFlaggedOnly {
            result = result.filter {
                let f = $0.latestReading?.flag ?? .normal
                return f == .high || f == .low || f == .critical
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if biomarkers.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No Trends",
                        message: "Import lab results to see biomarker trends."
                    )
                } else {
                    List(filtered, id: \.id) { biomarker in
                        NavigationLink(value: biomarker.id) {
                            BiomarkerRow(biomarker: biomarker)
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: UUID.self) { id in
                        if let biomarker = biomarkers.first(where: { $0.id == id }) {
                            BiomarkerDetailView(biomarker: biomarker)
                        }
                    }
                }
            }
            .navigationTitle("Trends")
            .searchable(text: $searchText, prompt: "Search biomarkers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Flagged Only", isOn: $showFlaggedOnly)

                        Picker("Category", selection: $selectedCategory) {
                            Text("All Categories").tag(nil as BiomarkerCategory?)
                            ForEach(BiomarkerCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.iconName)
                                    .tag(cat as BiomarkerCategory?)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    TrendsView()
        .modelContainer(for: Biomarker.self, inMemory: true)
}
