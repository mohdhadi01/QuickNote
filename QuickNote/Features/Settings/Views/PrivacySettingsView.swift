import SwiftUI

/// Privacy settings (spec §43, §44).
struct PrivacySettingsView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                SettingsCard(title: "Source Application") {
                    Toggle("Record Source Application", isOn: $settings.recordSourceApp)
                        .toggleStyle(.switch)
                        .font(.system(size: 13, weight: .medium))
                    Text("Off by default. When enabled, QuickNote stores only the name and bundle "
                        + "identifier of the app you were using when the note was captured. "
                        + "QuickNote never reads keystrokes, window contents, clipboard data, "
                        + "or web activity, and never sends your notes anywhere.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SettingsCard(title: "Your Data") {
                    HStack(spacing: DesignTokens.Spacing.m) {
                        shieldIcon
                        Text("Notes stay on this Mac. No account, no cloud, no telemetry.")
                            .font(.system(size: 12))
                            .foregroundStyle(AuroraPalette.secondaryText)
                    }
                }
            }
            .padding(DesignTokens.Spacing.l)
        }
    }

    private var shieldIcon: some View {
        Image(systemName: "checkmark.shield.fill")
            .font(.system(size: 16))
            .foregroundStyle(AuroraPalette.accentGradient)
    }
}
