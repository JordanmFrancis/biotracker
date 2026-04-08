import SwiftUI

/// Apple Settings–style squircle icon tile: colored rounded-rect background
/// with a white SF Symbol. Drop it into any List row as the leading accessory.
struct SettingsTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(color.gradient)
            Image(systemName: symbol)
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 12) {
        SettingsTile(symbol: "drop.fill", color: .tileBlue)
        SettingsTile(symbol: "heart.fill", color: .tileOrange)
        SettingsTile(symbol: "bolt.heart", color: .tilePink)
    }
    .padding()
}
