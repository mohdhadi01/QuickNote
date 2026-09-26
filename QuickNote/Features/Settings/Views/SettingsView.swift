import SwiftUI

/// Native Settings window with tabbed sections (spec §29).
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
        .frame(width: 540, height: 340)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }
}
