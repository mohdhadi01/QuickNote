import Carbon.HIToolbox
import Foundation

/// Human-readable names for virtual key codes. Carbon/TIS usage is confined
/// to this file; callers only see `String?` (spec §5).
enum KeyDisplay {
    private static let specialNames: [UInt32: String] = [
        VirtualKey.space: "Space",
        VirtualKey.tab: "⇥",
        VirtualKey.returnKey: "↩",
        VirtualKey.delete: "⌫",
        VirtualKey.forwardDelete: "⌦",
        VirtualKey.home: "↖",
        VirtualKey.end: "↘",
        VirtualKey.pageUp: "⇞",
        VirtualKey.pageDown: "⇟",
        VirtualKey.upArrow: "↑",
        VirtualKey.downArrow: "↓",
        VirtualKey.leftArrow: "←",
        VirtualKey.rightArrow: "→",
        VirtualKey.f1: "F1",
        VirtualKey.f2: "F2",
        VirtualKey.f3: "F3",
        VirtualKey.f4: "F4",
        VirtualKey.f5: "F5",
        VirtualKey.f6: "F6",
        VirtualKey.f7: "F7",
        VirtualKey.f8: "F8",
        VirtualKey.f9: "F9",
        VirtualKey.f10: "F10",
        VirtualKey.f11: "F11",
        VirtualKey.f12: "F12",
    ]

    /// The display name for a virtual key code using the current keyboard
    /// layout, or a native special-key name. Returns nil for keys that cannot
    /// be part of a shortcut (e.g. lone modifier keys).
    static func displayName(for keyCode: UInt32) -> String? {
        if let special = specialNames[keyCode] { return special }

        switch Int(keyCode) {
        case kVK_ANSI_Keypad0...kVK_ANSI_Keypad9:
            return "Keypad \(keyCode - UInt32(kVK_ANSI_Keypad0))"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_F18: return "F18"
        case kVK_F19: return "F19"
        default: break
        }

        return characterForKeyCode(keyCode)?.uppercased()
    }

    /// Resolves the character a key would produce with the current layout.
    private static func characterForKeyCode(_ keyCode: UInt32) -> String? {
        guard let layoutData = currentKeyboardLayoutData() else { return nil }

        var deadKeyState: UInt32 = 0
        let maxStringLength = 4
        var actualLength = 0
        var unicodeString = [UniChar](repeating: 0, count: maxStringLength)

        let status = layoutData.withUnsafeBytes { buffer -> OSStatus in
            guard let baseAddress = buffer.baseAddress else { return Int32(paramErr) }
            let layout = baseAddress.assumingMemoryBound(to: UCKeyboardLayout.self)
            return UCKeyTranslate(
                layout,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                maxStringLength,
                &actualLength,
                &unicodeString
            )
        }

        guard status == noErr, actualLength > 0 else { return nil }
        let result = String(utf16CodeUnits: unicodeString, count: actualLength)
        return result.isEmpty ? nil : result
    }

    private static func currentKeyboardLayoutData() -> Data? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else { return nil }
        guard let propertyPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        return Unmanaged<CFData>.fromOpaque(propertyPointer).takeUnretainedValue() as Data
    }
}
