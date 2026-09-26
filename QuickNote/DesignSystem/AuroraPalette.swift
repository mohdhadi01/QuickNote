import SwiftUI

/// "Aurora" palette: deep gradient backdrops, luminous accent glows, and
/// adaptive text that reads on glass in light and dark mode.
enum AuroraPalette {
    // MARK: Accent (interactive gradient)

    /// Indigo → violet → cyan: the app's signature gradient.
    static let accentGradient = LinearGradient(
        colors: [accentIndigo, accentViolet, accentCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// A softer horizontal variant for wide surfaces (selection pills, bars).
    static let accentGradientWide = LinearGradient(
        colors: [accentIndigo, accentViolet],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentIndigo = Color(red: 0.388, green: 0.400, blue: 0.945)   // #6366F1
    static let accentViolet = Color(red: 0.545, green: 0.361, blue: 0.965)   // #8B5CF6
    static let accentCyan = Color(red: 0.133, green: 0.827, blue: 0.933)     // #22D3EE

    // MARK: Backdrop (deep-space gradient)

    static let backdropGradient = LinearGradient(
        colors: [
            Color(red: 0.055, green: 0.063, blue: 0.118),   // #0E1020 deep space
            Color(red: 0.098, green: 0.114, blue: 0.212),   // #191D36
            Color(red: 0.051, green: 0.059, blue: 0.110),   // #0D0F1C
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Airy variant for light appearance.
    static let backdropGradientLight = LinearGradient(
        colors: [
            Color(red: 0.925, green: 0.937, blue: 1.000),
            Color(red: 0.973, green: 0.976, blue: 1.000),
            Color(red: 0.902, green: 0.918, blue: 0.988),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Glass strokes

    /// Specular edge: bright at the top-leading, fading out — reads as light
    /// catching the rim of a glass panel.
    static let glassEdge = LinearGradient(
        colors: [Color.white.opacity(0.30), Color.white.opacity(0.10), Color.white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassEdgeSoft = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Text on glass

    static let primaryText = Color.primary
    static let secondaryText = Color.primary.opacity(0.62)
    static let tertiaryText = Color.primary.opacity(0.40)
}
