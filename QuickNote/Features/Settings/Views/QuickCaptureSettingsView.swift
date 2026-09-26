import SwiftUI

/// Quick Capture settings: shortcut recorder + panel position (spec §6, §30).
struct QuickCaptureSettingsView: View {
    @EnvironmentObject private var settings: SettingsService
    @Environment(ShortcutService.self) private var shortcutService

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                SettingsCard(title: "Quick Capture Shortcut") {
                    HStack(spacing: DesignTokens.Spacing.l) {
                        ShortcutRecorderView(shortcut: recorderBinding)
                        Spacer()
                        statusBadge
                    }
                    if let error = shortcutService.registrationError {
                        Text(error.userFacingMessage)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.orange.opacity(0.95))
                    }
                }

                SettingsCard(title: "Panel Position") {
                    Picker("Position", selection: $settings.panelPosition) {
                        ForEach(SettingsService.PanelPosition.allCases) { position in
                            Text(position.title).tag(position)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                }
            }
            .padding(DesignTokens.Spacing.l)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if shortcutService.isRegistered {
            HStack(spacing: 6) {
                Circle()
                    .fill(AuroraPalette.silver)
                    .frame(width: 7, height: 7)
                    .shadow(color: AuroraPalette.silver.opacity(0.8), radius: 4)
                Text("Active")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AuroraPalette.secondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        } else if let error = shortcutService.registrationError {
            Label("Unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.orange.opacity(0.95))
                .help(error.userFacingMessage)
        }
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
