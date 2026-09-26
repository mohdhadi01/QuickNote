import AppKit
import ServiceManagement

/// NSApplication lifecycle bridge (spec §27, §28).
@MainActor
final class AppLifecycle: NSObject, NSApplicationDelegate {
    weak var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.handleTermination()
    }

    /// Suppresses the automatic main window when the app was launched at
    /// login. Login-item launches should stay silent (hotkey + menu bar only);
    /// Dock clicks reopen the window via standard reopen handling.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Snapshot/QA runs must always present the main window.
        if DebugSnapshot.directoryPath != nil { return true }
        guard isLaunchedAtLogin() else { return true }
        Log.app.info("Suppressing main window for login launch")
        return false
    }

    private func isLaunchedAtLogin() -> Bool {
        guard SMAppService.mainApp.status == .enabled else { return false }
        // Within two minutes of boot + login item enabled → assume login launch.
        return ProcessInfo.processInfo.systemUptime < 120
    }
}
