import SwiftUI

struct TrendIndicator: View {
    let trend: TrendDirection
    let percentChange: Double?

    init(trend: TrendDirection, percentChange: Double? = nil) {
        self.trend = trend
        self.percentChange = percentChange
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.iconName)
                .font(.caption2)
            if let pct = percentChange {
                Text(String(format: "%+.0f%%", pct))
                    .font(.caption2)
            }
        }
        .foregroundStyle(trendColor)
    }

    private var trendColor: Color {
        switch trend {
        case .improving: .green
        case .worsening: .red
        case .stable: .secondary
        case .up: .orange
        case .down: .orange
        }
    }
}

#Preview {
    VStack {
        TrendIndicator(trend: .improving, percentChange: -12)
        TrendIndicator(trend: .worsening, percentChange: 25)
        TrendIndicator(trend: .stable)
    }
}
