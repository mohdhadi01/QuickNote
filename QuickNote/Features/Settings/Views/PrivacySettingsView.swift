import SwiftUI

/// Privacy settings (spec §43, §44).
struct PrivacySettingsView: View {
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        Form {
            Section {
                Toggle("Record Source Application", isOn: $settings.recordSourceApp)
            } footer: {
                Text(
                    "Off by default. When enabled, QuickNote stores only the name and bundle "
                    + "identifier of the app you were using when the note was captured. "
                    + "QuickNote never reads keystrokes, window contents, clipboard data, "
                    + "or web activity, and never sends your notes anywhere."
                )
            }
        }
        .formStyle(.grouped)
    }
}
