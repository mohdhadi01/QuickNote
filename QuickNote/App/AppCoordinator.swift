import AppKit
import Combine
import Foundation
import Observation

/// Top-level application coordinator: wires the global hotkey to quick
/// capture, handles launch/termination, and owns final integration (spec §62,
/// §63).
@MainActor
@Observable
final class AppCoordinator {
    let notesViewModel: NotesViewModel
    let quickCaptureCoordinator: QuickCaptureCoordinator
    let persistenceRecovery: PersistenceRecoveryInfo?

    private let shortcutService: ShortcutService
    private let settings: SettingsService
    private let noteService: NoteService
    private var cancellables = Set<AnyCancellable>()
    /// Retained while a QA snapshot sequence is in flight.
    var snapshotDriver: DebugSnapshotDriver?

    init(environment: AppEnvironment) {
        self.notesViewModel = environment.notesViewModel
        self.shortcutService = environment.shortcutService
        self.settings = environment.settings
        self.noteService = environment.noteService
        self.persistenceRecovery = environment.persistenceRecovery
        self.quickCaptureCoordinator = QuickCaptureCoordinator(
            viewModel: environment.captureViewModel,
            noteService: environment.noteService,
            settings: environment.settings,
            flags: environment.flags
        )
    }

    func start() {
        shortcutService.onHotkeyPressed = { [weak self] in
            self?.quickCaptureCoordinator.toggle()
        }
        shortcutService.start()

        // First-run hotkey failure: never crash, offer an alternative (spec §49).
        if shortcutService.registrationError != nil {
            showHotkeyUnavailableAlert()
        }

        // Reposition a visible panel when displays change (spec §35, §69).
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.quickCaptureCoordinator.handleScreenConfigurationChanged()
            }
            .store(in: &cancellables)

        applyDebugFlags()

        // UI-test/QA hook: seed one note for headless list testing.
        if let seed = DebugFlags.value(for: DebugFlags.seedNote) {
            noteService.seedNoteIfMissing(seed)
        }

        Log.app.info("AppCoordinator started")
    }

    func toggleQuickCapture() {
        quickCaptureCoordinator.toggle()
    }

    func handleTermination() {
        quickCaptureCoordinator.saveDraftIfPresent()
        shortcutService.stop()
    }

    // MARK: Private

    private func showHotkeyUnavailableAlert() {
        guard let error = shortcutService.registrationError else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Quick Capture shortcut is unavailable."
        alert.informativeText = "\(settings.shortcut.displayString) — \(error.userFacingMessage)"
        alert.addButton(withTitle: "Open Settings…")
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    private func applyDebugFlags() {
        if DebugFlags.isEnabled(DebugFlags.showQuickCapture) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.quickCaptureCoordinator.present()
            }
        }
        if DebugFlags.isEnabled(DebugFlags.openSettings) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }
}
