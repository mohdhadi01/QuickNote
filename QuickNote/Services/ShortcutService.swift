import Foundation
import Observation

/// Owns the global shortcut lifecycle: registers at launch, re-registers on
/// change, unregisters on termination, and surfaces errors to Settings
/// (spec §5, §63).
@MainActor
@Observable
final class ShortcutService {
    private let hotkeyService: GlobalHotkeyService
    private let settings: SettingsService

    private(set) var registrationError: HotkeyError?
    private(set) var isRegistered = false

    /// Invoked on the main actor when the shortcut fires.
    var onHotkeyPressed: (() -> Void)?

    init(hotkeyService: GlobalHotkeyService, settings: SettingsService) {
        self.hotkeyService = hotkeyService
        self.settings = settings
        self.hotkeyService.onHotkeyPressed = { [weak self] in
            self?.onHotkeyPressed?()
        }
    }

    /// Registers the configured shortcut. Call once at app start.
    func start() {
        register(settings.shortcut)
    }

    /// Applies a user-chosen shortcut: persists it and re-registers.
    func updateShortcut(_ shortcut: KeyboardShortcut) {
        settings.shortcut = shortcut
        register(shortcut)
    }

    /// Unregisters before termination (spec §5).
    func stop() {
        hotkeyService.unregister()
        isRegistered = false
    }

    func revalidate() {
        register(settings.shortcut)
    }

    private func register(_ shortcut: KeyboardShortcut) {
        do {
            try hotkeyService.register(shortcut)
            isRegistered = true
            registrationError = nil
        } catch let error as HotkeyError {
            isRegistered = false
            registrationError = error
            Log.hotkey.error("Registration error: \(String(describing: error), privacy: .public)")
        } catch {
            isRegistered = false
            registrationError = .unknown(-1)
        }
    }
}
