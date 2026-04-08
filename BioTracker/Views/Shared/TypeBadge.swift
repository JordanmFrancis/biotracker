import SwiftUI

struct TypeBadge: View {
    let itemType: ProtocolItemType

    var body: some View {
        Text(itemType.label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(itemType.color.opacity(0.15))
            .foregroundStyle(itemType.color)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        TypeBadge(itemType: .supplement)
        TypeBadge(itemType: .peptide)
        TypeBadge(itemType: .medication)
    }
}
