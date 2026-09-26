import SwiftUI

/// General settings: launch at login (spec §28).
struct GeneralSettingsView: View {
    @EnvironmentObject private var loginItem: LoginItemService
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: launchBinding)
            } footer: {
                Text("QuickNote starts when you log in so the capture shortcut is always available.")
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
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
