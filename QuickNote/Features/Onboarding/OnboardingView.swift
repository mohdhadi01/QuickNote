import SwiftUI

/// Minimal first-run explanation (spec §48). Lives inside the main window on
/// first launch; no multi-screen flow, no permissions.
struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.s) {
                Text("QuickNote")
                    .font(.system(size: 28, weight: .semibold))
                Text("Capture a thought from anywhere.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: DesignTokens.Spacing.l) {
                Text(settings.shortcut.displayString)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.m)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .accessibilityLabel("Quick capture shortcut")

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("Press the shortcut, type, and press Return.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("You can change the shortcut in Settings.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
                    .frame(width: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("get-started-button")
        }
        .padding(DesignTokens.Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }
}
