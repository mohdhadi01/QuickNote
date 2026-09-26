import SwiftUI

/// General settings: launch at login (spec §28).
struct GeneralSettingsView: View {
    @EnvironmentObject private var loginItem: LoginItemService
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                SettingsCard(title: "Startup") {
                    Toggle("Launch at Login", isOn: launchBinding)
                        .toggleStyle(.switch)
                        .font(.system(size: 13, weight: .medium))
                        .accessibilityIdentifier("launch-at-login-toggle")
                    Text("QuickNote starts when you log in so the capture shortcut is always available.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.red.opacity(0.95))
                    }
                }
            }
            .padding(DesignTokens.Spacing.l)
        }
        .onAppear { loginItem.refreshStatus() }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { newValue in
                do {
                    try loginItem.setEnabled(newValue)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        )
    }
}
