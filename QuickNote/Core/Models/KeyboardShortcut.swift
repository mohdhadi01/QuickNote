import AppKit
import Foundation

/// Modifier keys tracked for a capture shortcut.
struct ModifierSet: OptionSet, Codable, Hashable {
    let rawValue: UInt8

    init(rawValue: UInt8) { self.rawValue = rawValue }

    static let command = ModifierSet(rawValue: 1 << 0)
    static let shift = ModifierSet(rawValue: 1 << 1)
    static let option = ModifierSet(rawValue: 1 << 2)
    static let control = ModifierSet(rawValue: 1 << 3)

    /// Modifiers that make a shortcut safe to register (won't hijack typing).
    static let strongModifiers: ModifierSet = [.command, .control, .option]

    var isStrong: Bool {
        !intersection(.strongModifiers).isEmpty
    }

    /// Canonical display order: ⌃ ⌥ ⇧ ⌘ (matches macOS conventions).
    var displaySymbols: String {
        var symbols = ""
        if contains(.control) { symbols += "⌃" }
        if contains(.option) { symbols += "⌥" }
        if contains(.shift) { symbols += "⇧" }
        if contains(.command) { symbols += "⌘" }
        return symbols
    }

    /// NSEvent.ModifierFlags → ModifierSet.
    static func from(_ flags: NSEvent.ModifierFlags) -> ModifierSet {
        var set: ModifierSet = []
        if flags.contains(.command) { set.insert(.command) }
        if flags.contains(.shift) { set.insert(.shift) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.control) { set.insert(.control) }
        return set
    }
}

/// A global shortcut: a virtual key code plus modifiers (spec §5, §6).
struct KeyboardShortcut: Codable, Hashable {
    var keyCode: UInt32
    var modifiers: ModifierSet

    static let `default` = KeyboardShortcut(keyCode: VirtualKey.space, modifiers: [.command, .shift])

    init(keyCode: UInt32, modifiers: ModifierSet) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// A shortcut must name a displayable key and include at least one of
    /// ⌘/⌃/⌥ (or be a bare function key) so it can never swallow normal typing.
    static func isValid(keyCode: UInt32, modifiers: ModifierSet) -> Bool {
        guard keyCode != VirtualKey.fn else { return false }
        guard KeyDisplay.displayName(for: keyCode) != nil else { return false }
        if modifiers.isEmpty { return keyCode >= VirtualKey.f5 && keyCode <= VirtualKey.f12 }
        return modifiers.isStrong
    }

    var isValid: Bool {
        Self.isValid(keyCode: keyCode, modifiers: modifiers)
    }

    var displayString: String {
        let key = KeyDisplay.displayName(for: keyCode) ?? "Key"
        return modifiers.displaySymbols + key
    }

    /// Carbon modifier mask (used only by the platform hotkey layer).
    var carbonModifierFlags: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= CarbonModifierMask.command }
        if modifiers.contains(.shift) { flags |= CarbonModifierMask.shift }
        if modifiers.contains(.option) { flags |= CarbonModifierMask.option }
        if modifiers.contains(.control) { flags |= CarbonModifierMask.control }
        return flags
    }

    // MARK: Serialization (UserDefaults)

    static func serialized(_ shortcut: KeyboardShortcut) -> String {
        var parts: [String] = []
        if shortcut.modifiers.contains(.command) { parts.append("cmd") }
        if shortcut.modifiers.contains(.shift) { parts.append("shift") }
        if shortcut.modifiers.contains(.option) { parts.append("opt") }
        if shortcut.modifiers.contains(.control) { parts.append("ctrl") }
        return "\(shortcut.keyCode)|\(parts.joined(separator: "+"))"
    }

    static func deserialize(_ string: String) -> KeyboardShortcut? {
        let pieces = string.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard pieces.count == 2, let keyCode = UInt32(pieces[0]) else { return nil }
        var modifiers: ModifierSet = []
        for token in pieces[1].split(separator: "+") {
            switch token {
            case "cmd": modifiers.insert(.command)
            case "shift": modifiers.insert(.shift)
            case "opt": modifiers.insert(.option)
            case "ctrl": modifiers.insert(.control)
            default: return nil
            }
        }
        let shortcut = KeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
        return shortcut.isValid ? shortcut : nil
    }
}
