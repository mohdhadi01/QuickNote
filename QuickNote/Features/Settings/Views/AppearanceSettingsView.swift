import SwiftUI

/// Appearance settings (spec §31). System-following semantic colors only.
struct AppearanceSettingsView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $settings.appearanceMode) {
                    ForEach(SettingsService.AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } footer: {
                Text("QuickNote follows Apple's system appearance and adapts to Light, Dark, "
                    + "Increased Contrast, Reduce Transparency, and Reduce Motion automatically.")
            }
        }
        .formStyle(.grouped)
    }
}
