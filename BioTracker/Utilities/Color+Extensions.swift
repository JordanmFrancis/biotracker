import SwiftUI

extension Color {
    // Flag colors — matched from screenshot
    static let flagInRange = Color(red: 0.45, green: 0.72, blue: 0.45)
    static let flagAbove = Color(red: 0.82, green: 0.53, blue: 0.28)
    static let flagBelow = Color(red: 0.82, green: 0.53, blue: 0.28)
    static let flagCritical = Color(red: 0.90, green: 0.25, blue: 0.25)

    // Chart zone bars — from detail screenshot
    static let zoneInRange = Color(red: 0.31, green: 0.65, blue: 0.61)
    static let zoneAbove = Color(red: 0.78, green: 0.48, blue: 0.26)

    // Chart
    static let chartLine = Color(red: 0.63, green: 0.63, blue: 0.63)
    static let chartReferenceBand = Color.green.opacity(0.12)
    static let chartOptimalBand = Color.green.opacity(0.25)
    static let chartProtocolLine = Color.blue.opacity(0.5)

    // BP
    static let bpNormal = Color.green
    static let bpElevated = Color.yellow
    static let bpStage1 = Color.orange
    static let bpStage2 = Color.red

    // WHOOP
    static let whoopGreen = Color(red: 0, green: 0.78, blue: 0.33)
    static let whoopYellow = Color(red: 1, green: 0.84, blue: 0)
    static let whoopRed = Color(red: 1, green: 0.09, blue: 0.27)
}
