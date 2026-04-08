import SwiftUI

struct StatusBadge: View {
    let flag: ReadingFlag

    var body: some View {
        Text(flag.label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(flag.color.opacity(0.15))
            .foregroundStyle(flag.color)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        StatusBadge(flag: .normal)
        StatusBadge(flag: .high)
        StatusBadge(flag: .low)
        StatusBadge(flag: .critical)
    }
}
