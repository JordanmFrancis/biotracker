import SwiftUI

// MARK: - BioTracker Design Palette
//
// Dark-first. Muted, low-chroma scientific palette.
// Accent is teal (not system blue) — distinctive, calm, "medical" without being cold.
// Flag colors follow the spec: green = in-range, orange = out-of-range, red = critical only.

extension Color {

    // MARK: Brand

    /// Primary accent — used for app tint, active controls, trend lines.
    /// Teal-400, works in both color schemes.
    static let brandAccent = Color(hex: 0x2DD4BF)

    /// Secondary accent — used sparingly for emphasis on hero cards.
    static let brandAccentSoft = Color(hex: 0x5EEAD4)

    // MARK: Flag / status

    /// In range (green) — emerald 400
    static let flagInRange = Color(hex: 0x34D399)
    /// Above or below range (orange) — orange 400
    static let flagAbove = Color(hex: 0xFB923C)
    static let flagBelow = Color(hex: 0xFB923C)
    /// Critical only — red 400
    static let flagCritical = Color(hex: 0xF87171)

    // MARK: Chart zones (used inside BiomarkerTrendChart)

    /// In-range band — soft emerald with transparency
    static let zoneInRange = Color(hex: 0x34D399)
    /// Out-of-range band — warm orange with transparency
    static let zoneAbove = Color(hex: 0xFB923C)
    /// The trend line itself
    static let chartLine = Color(hex: 0x2DD4BF)

    // MARK: Hex helper

    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
