import SwiftUI

/// Quick Capture settings: shortcut recorder + panel position (spec §6, §30).
struct QuickCaptureSettingsView: View {
    @EnvironmentObject private var settings: SettingsService
    @Environment(ShortcutService.self) private var shortcutService

    var body: some View {
        Form {
            Section("Quick Capture Shortcut") {
                HStack {
                    ShortcutRecorderView(shortcut: recorderBinding)
                    Spacer()
                    if shortcutService.isRegistered {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    } else if let error = shortcutService.registrationError {
                        Label("Unavailable", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .help(error.userFacingMessage)
                    }
                }
                if let error = shortcutService.registrationError {
                    Text(error.userFacingMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Panel Position") {
                Picker("Position", selection: $settings.panelPosition) {
                    ForEach(SettingsService.PanelPosition.allCases) { position in
                        Text(position.title).tag(position)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
        }
        .formStyle(.grouped)
    }

    /// Applies the shortcut through ShortcutService so it re-registers.
    private var recorderBinding: Binding<KeyboardShortcut> {
        Binding(
            get: { settings.shortcut },
            set: { newValue in
                guard newValue != settings.shortcut else { return }
                shortcutService.updateShortcut(newValue)
            }
        )
    }
}
