import AppKit
import SwiftUI

/// Menu bar extra contents (spec §26). Native menu style only.
struct MenuBarContentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        Button("New Quick Note") {
            hideMenuExtra()
            coordinator.toggleQuickCapture()
        }
        Button("Open Notes…") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Search Notes…") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
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

    /// Menu bar extras dismiss their menu when an item's action runs; this
    /// only ensures the panel doesn't appear behind a lingering menu.
    private func hideMenuExtra() {
        NSApp.activate(ignoringOtherApps: false)
    }
}
