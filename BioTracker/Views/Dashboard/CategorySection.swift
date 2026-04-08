import SwiftUI

struct CategorySection: View {
    let category: String
    let biomarkers: [Biomarker]
    @State private var isExpanded = true

    private var categoryEnum: BiomarkerCategory? {
        BiomarkerCategory(rawValue: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    if let cat = categoryEnum {
                        Image(systemName: cat.iconName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Text(category)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(biomarkers, id: \.id) { biomarker in
                        NavigationLink(value: biomarker.id) {
                            BiomarkerRow(biomarker: biomarker)
                        }
                        .buttonStyle(.plain)
                        if biomarker.id != biomarkers.last?.id {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
    }
}
