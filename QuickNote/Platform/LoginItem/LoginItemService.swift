import Foundation
import ServiceManagement

/// Launch-at-login via Apple's modern Service Management API (spec §28).
@MainActor
final class LoginItemService: ObservableObject {
    enum LoginItemError: LocalizedError {
        case registrationFailed(Error)
        case unregistrationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .registrationFailed(let error):
                "Could not enable Launch at Login. \(error.localizedDescription)"
            case .unregistrationFailed(let error):
                "Could not disable Launch at Login. \(error.localizedDescription)"
            }
        }
    }

    @Published private(set) var isEnabled: Bool = false

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw error is LoginItemError ? error : LoginItemError.registrationFailed(error)
        }
        refreshStatus()
        Log.settings.info("Launch at login set to \(enabled, privacy: .public)")
    }
}
