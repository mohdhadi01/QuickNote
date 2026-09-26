import AppKit
import SwiftUI

/// Menu bar extra contents (spec §26): quick actions, sections shortcut
/// hints, and the Launch-at-Login toggle — the way background utilities work.
struct MenuBarContentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var settings: SettingsService
    @EnvironmentObject private var loginItem: LoginItemService

    var body: some View {
        Button("New Quick Note") {
            coordinator.toggleQuickCapture()
        }
        .keyboardShortcut("n", modifiers: [.shift, .command])

        Button("New Note") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            coordinator.notesViewModel.createNewNote()
        }

        Button("Open Notes…") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Search Notes…") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
            // The list view isn't alive yet when the window opens — request
            // focus once it has appeared.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                coordinator.notesViewModel.searchFocusRequest += 1
            }
        }

        Divider()

        Toggle("Launch at Login", isOn: launchBinding)

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit QuickNote") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { newValue in
                do {
                    try loginItem.setEnabled(newValue)
                } catch {
                    Log.settings.error("Menu bar login toggle failed: \(String(describing: error), privacy: .public)")
                }
            }
        )
    }
}
