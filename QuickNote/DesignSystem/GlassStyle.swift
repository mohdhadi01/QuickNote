import AppKit
import SwiftUI

/// The aurora backdrop: translucent blur of the desktop behind a deep
/// gradient, with soft luminous glows in the corners. Used as the root
/// background of every scene so the whole app shares one atmosphere.
struct AuroraBackdrop: View {
    @EnvironmentObject private var flags: AccessibilityEnvironmentFlags
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Blurred desktop behind everything (skipped for Reduce
            // Transparency).
            if !flags.reduceTransparency {
                BlurRepresentable()
                    .ignoresSafeArea()
            }

            (colorScheme == .dark ? AuroraPalette.backdropGradient : AuroraPalette.backdropGradientLight)
                .opacity(colorScheme == .dark ? 0.88 : 0.94)
                .ignoresSafeArea()

            // Luminous glows.
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    glow(AuroraPalette.accentIndigo, diameter: max(w, h) * 0.9, opacity: colorScheme == .dark ? 0.30 : 0.16)
                        .offset(x: -w * 0.28, y: -h * 0.34)
                    glow(AuroraPalette.accentViolet, diameter: max(w, h) * 0.8, opacity: colorScheme == .dark ? 0.24 : 0.12)
                        .offset(x: w * 0.38, y: h * 0.42)
                    glow(AuroraPalette.accentCyan, diameter: max(w, h) * 0.55, opacity: colorScheme == .dark ? 0.14 : 0.10)
                        .offset(x: w * 0.42, y: -h * 0.30)
                }
                .frame(width: w, height: h, alignment: .topLeading)
                .clipped()
            }
            .ignoresSafeArea()
        }
    }

    private func glow(_ color: Color, diameter: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
    }
}

/// NSVisualEffectView showing the blurred desktop behind a transparent window.
private struct BlurRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// Makes the hosting window translucent so the backdrop blur reads through.
struct TransparentWindow: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}

// MARK: - Glass modifiers

extension View {
    /// A floating glass panel: blurred material, specular rim, soft shadow.
    func glassPanel(cornerRadius: CGFloat = 20, padding: CGFloat = 0) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Sheen: light pooling at the top edge of the glass.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdge, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 18, y: 10)
            .padding(padding)
    }

    /// A quieter inset surface (cards inside the backdrop).
    func glassInset(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.055))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdgeSoft, lineWidth: 1)
            )
    }
}

/// A small keyboard keycap used in shortcut hints (⌃ ⇧ Return …).
struct GlassKeycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(AuroraPalette.primaryText.opacity(0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .frame(minWidth: 22)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdgeSoft, lineWidth: 1)
            )
    }
}

/// Primary action button with the signature gradient fill.
struct GradientProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AuroraPalette.accentGradient)
                    .shadow(color: AuroraPalette.accentIndigo.opacity(configuration.isPressed ? 0.25 : 0.45), radius: configuration.isPressed ? 6 : 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.panelSpring, value: configuration.isPressed)
    }
}

/// Compact rounded glass icon button (pin, trash, plus…).
struct GlassIconButtonStyle: ButtonStyle {
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isActive ? Color.white : AuroraPalette.primaryText.opacity(0.75))
            .frame(width: 28, height: 28)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AuroraPalette.accentGradientWide)
                } else {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(configuration.isPressed ? 0.14 : 0.07))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdgeSoft, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Motion.panelSpring, value: configuration.isPressed)
    }
}

/// Vertical hairline that separates the window's columns — a faint light
/// edge rather than a hard divider.
struct GlassHairline: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.14), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1)
    }
}
