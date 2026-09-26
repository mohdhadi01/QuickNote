import AppKit
import Carbon.HIToolbox
import Foundation

/// Carbon RegisterEventHotKey wrapper. Main-actor only; the C callback hops
/// to the main actor before notifying observers (spec §5, §39).
@MainActor
final class CarbonHotkeyService: GlobalHotkeyService {
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var registeredShortcut: KeyboardShortcut?

    private static let hotKeySignature: OSType = 0x5143_4B4E // 'QCKN'

    init() {
        installEventHandler()
    }

    deinit {
        // Unregistration must happen on the main thread; this is best-effort
        // since deinit may run on an arbitrary thread during teardown.
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
    }

    func register(_ shortcut: KeyboardShortcut) throws {
        guard shortcut.isValid else {
            throw HotkeyError.invalidShortcut
        }
        unregisterHotKey()

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: 1)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        switch status {
        case noErr:
            hotKeyRef = ref
            registeredShortcut = shortcut
            Log.hotkey.info("Registered hotkey (keyCode: \(shortcut.keyCode))")
        case Int32(eventHotKeyExistsErr):
            Log.hotkey.error("Hotkey registration failed: already in use")
            throw HotkeyError.conflict
        default:
            Log.hotkey.error("Hotkey registration failed: OSStatus \(status)")
            throw HotkeyError.unknown(status)
        }
    }

    func unregister() {
        unregisterHotKey()
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
            registeredShortcut = nil
            Log.hotkey.info("Unregistered previous hotkey")
        }
    }

    // MARK: Event handler installation

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventCallback,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        if status != noErr {
            Log.hotkey.fault("InstallEventHandler failed: OSStatus \(status)")
        }
    }

    private static let eventCallback: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else { return noErr }
        let kind = GetEventKind(eventRef)
        guard kind == UInt32(kEventHotKeyPressed) else { return noErr }

        let service = Unmanaged<CarbonHotkeyService>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
            service.onHotkeyPressed?()
        }
        return noErr
    }
}
