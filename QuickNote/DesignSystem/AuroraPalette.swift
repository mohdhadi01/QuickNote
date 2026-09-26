import SwiftUI

/// "Smoke glass" palette: classic, restrained, monochrome. Deep graphite
/// backdrops, silver glass edges, no saturated color — the class comes from
/// material and light, not hue.
enum AuroraPalette {
    // MARK: Graphite & silver

    /// Graphite gradient for primary actions and active tiles.
    static let inkGradient = LinearGradient(
        colors: [Color(red: 0.263, green: 0.286, blue: 0.329),   // #434A54
                 Color(red: 0.157, green: 0.173, blue: 0.204)],  // #282C34
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let graphite = Color(red: 0.243, green: 0.267, blue: 0.310)  // #3E4450
    static let steel = Color(red: 0.373, green: 0.404, blue: 0.455)    // #5F6774
    static let silver = Color(red: 0.639, green: 0.670, blue: 0.714)   // #A3ABB6
    static let frost = Color(red: 0.812, green: 0.831, blue: 0.855)    // #CFD4DA

    // MARK: Backdrop (smoked glass over the desktop)

    static let backdropGradient = LinearGradient(
        colors: [
            Color(red: 0.086, green: 0.094, blue: 0.110),   // #16181D
            Color(red: 0.125, green: 0.137, blue: 0.157),   // #202328
            Color(red: 0.063, green: 0.071, blue: 0.086),   // #101216
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Airy platinum variant for light appearance.
    static let backdropGradientLight = LinearGradient(
        colors: [
            Color(red: 0.956, green: 0.961, blue: 0.969),
            Color(red: 0.980, green: 0.982, blue: 0.988),
            Color(red: 0.925, green: 0.933, blue: 0.945),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Glass strokes

    /// Specular edge: bright at the top-leading, fading out — light catching
    /// the rim of a glass panel.
    static let glassEdge = LinearGradient(
        colors: [Color.white.opacity(0.26), Color.white.opacity(0.09), Color.white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassEdgeSoft = LinearGradient(
        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Selection: a quiet glass wash — white on dark backdrops, black on
    /// light ones — the classic macOS feel.
    static let selectionFill = LinearGradient(
        colors: [Color.white.opacity(0.16), Color.white.opacity(0.08)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func selectionFill(for scheme: ColorScheme) -> LinearGradient {
        scheme == .dark
            ? LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
            : LinearGradient(colors: [Color.black.opacity(0.10), Color.black.opacity(0.045)], startPoint: .top, endPoint: .bottom)
    }

    static func selectionText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .primary
    }

    static func selectionSecondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.85) : Color.primary.opacity(0.7)
    }

    // MARK: Text on glass

    static let primaryText = Color.primary
    static let secondaryText = Color.primary.opacity(0.62)
    static let tertiaryText = Color.primary.opacity(0.40)
}
