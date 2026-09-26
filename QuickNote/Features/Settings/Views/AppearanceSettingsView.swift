import SwiftUI

/// Appearance settings (spec §31). System-following semantic colors only.
struct AppearanceSettingsView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                SettingsCard(title: "Theme") {
                    Picker("Theme", selection: $settings.appearanceMode) {
                        ForEach(SettingsService.AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Text("QuickNote follows Apple's system appearance and adapts to Light, Dark, "
                    + "Increased Contrast, Reduce Transparency, and Reduce Motion automatically.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .padding(DesignTokens.Spacing.l)
        }
    }
}
