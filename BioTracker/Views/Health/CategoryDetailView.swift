import SwiftUI

struct CategoryDetailView: View {
    let category: BiomarkerCategory
    let biomarkers: [Biomarker]

    var body: some View {
        List {
            Section {
                ForEach(biomarkers, id: \.id) { biomarker in
                    NavigationLink {
                        BiomarkerDetailView(biomarker: biomarker)
                    } label: {
                        BiomarkerRow(biomarker: biomarker)
                    }
                }
            } header: {
                HStack(spacing: 10) {
                    SettingsTile(symbol: category.iconName, color: category.tileColor, size: 24)
                    Text(category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
