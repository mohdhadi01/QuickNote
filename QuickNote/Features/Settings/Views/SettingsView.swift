import SwiftUI

/// Native Settings window with aurora-glass section cards.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            QuickCaptureSettingsView()
                .tabItem { Label("Quick Capture", systemImage: "bolt") }
            PrivacySettingsView()
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 420)
        .background(
            AuroraBackdrop()
                .ignoresSafeArea()
        )
        .background(TransparentWindow())
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
}

/// A titled glass card used inside settings tabs.
struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AuroraPalette.secondaryText)
                .textCase(.uppercase)
                .kerning(0.6)
            content
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassInset(cornerRadius: 16)
    }
}
