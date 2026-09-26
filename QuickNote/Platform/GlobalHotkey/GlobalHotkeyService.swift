import Foundation

/// Errors surfaced when a shortcut cannot be registered (spec §5, §49).
enum HotkeyError: Error, Equatable {
    /// Another application (or this one) already owns the shortcut.
    case conflict
    /// The shortcut itself is not usable.
    case invalidShortcut
    /// Any other Carbon failure.
    case unknown(OSStatus)

    var userFacingMessage: String {
        switch self {
        case .conflict:
            "This shortcut is already in use by another application. Choose a different combination."
        case .invalidShortcut:
            "This key combination can't be used for Quick Capture."
        case .unknown:
            "The shortcut could not be registered. Try a different combination."
        }
    }
}

/// Abstraction over global shortcut registration. Implementations must keep
/// platform specifics (Carbon) private (spec §4, §63).
protocol GlobalHotkeyService: AnyObject {
    /// Called on the main actor when the registered shortcut fires.
    var onHotkeyPressed: (() -> Void)? { get set }

    func register(_ shortcut: KeyboardShortcut) throws
    func unregister()
}
