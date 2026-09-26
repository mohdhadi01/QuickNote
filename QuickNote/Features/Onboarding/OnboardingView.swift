import SwiftUI

/// Minimal first-run explanation (spec §48): aurora hero card with real
/// keycaps showing the actual configured shortcut.
struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsService
    @EnvironmentObject private var flags: AccessibilityEnvironmentFlags

    var body: some View {
        ZStack {
            AuroraBackdrop()
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.xl) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 92, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: AuroraPalette.accentIndigo.opacity(0.55), radius: 22, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: DesignTokens.Spacing.s) {
                    Text("QuickNote")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AuroraPalette.primaryText)
                    Text("Capture a thought from anywhere.")
                        .font(.system(size: 14))
                        .foregroundStyle(AuroraPalette.secondaryText)
                }

                shortcutShowcase

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("Press the shortcut, type, and press Return.")
                        .font(.system(size: 13))
                        .foregroundStyle(AuroraPalette.secondaryText)
                    Text("You can change the shortcut in Settings.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                }

                Button {
                    settings.hasCompletedOnboarding = true
                } label: {
                    Text("Get Started")
                }
                .buttonStyle(GradientProminentButtonStyle())
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("get-started-button")
            }
            .padding(DesignTokens.Spacing.xxxl)
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private var shortcutShowcase: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            ForEach(shortcutKeycaps, id: \.self) { key in
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AuroraPalette.glassEdge, lineWidth: 1)
                    Text(key)
                        .font(.system(size: key.count > 1 ? 15 : 19, weight: .medium, design: .rounded))
                        .foregroundStyle(AuroraPalette.primaryText)
                        .padding(.horizontal, 10)
                }
                .frame(minWidth: 46, minHeight: 46)
                .shadow(color: AuroraPalette.accentIndigo.opacity(0.25), radius: 8, y: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quick capture shortcut: \(settings.shortcut.displayString)")
    }

    private var shortcutKeycaps: [String] {
        var keys: [String] = []
        if settings.shortcut.modifiers.contains(.control) { keys.append("⌃") }
        if settings.shortcut.modifiers.contains(.option) { keys.append("⌥") }
        if settings.shortcut.modifiers.contains(.shift) { keys.append("⇧") }
        if settings.shortcut.modifiers.contains(.command) { keys.append("⌘") }
        keys.append(KeyDisplay.displayName(for: settings.shortcut.keyCode) ?? "Key")
        return keys
    }
}
