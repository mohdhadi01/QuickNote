import XCTest
@testable import QuickNote

final class KeyboardShortcutTests: XCTestCase {
    func testDefaultShortcutIsCommandShiftSpace() {
        let shortcut = KeyboardShortcut.default
        XCTAssertEqual(shortcut.keyCode, VirtualKey.space)
        XCTAssertEqual(shortcut.modifiers, [.command, .shift])
        XCTAssertTrue(shortcut.isValid)
    }

    func testDefaultShortcutDisplayString() {
        // HIG modifier order: ⌃ ⌥ ⇧ ⌘.
        XCTAssertEqual(KeyboardShortcut.default.displayString, "⇧⌘Space")
    }

    func testModifierDisplayOrder() {
        var modifiers: ModifierSet = [.command, .option, .control, .shift]
        XCTAssertEqual(modifiers.displaySymbols, "⌃⌥⇧⌘")
        modifiers = [.shift, .command]
        XCTAssertEqual(modifiers.displaySymbols, "⇧⌘")
    }

    func testValidationRequiresStrongModifier() {
        XCTAssertFalse(KeyboardShortcut(keyCode: VirtualKey.space, modifiers: []).isValid)
        XCTAssertFalse(KeyboardShortcut(keyCode: VirtualKey.a, modifiers: []).isValid)
        XCTAssertFalse(KeyboardShortcut(keyCode: VirtualKey.a, modifiers: [.shift]).isValid, "Shift-only would hijack typing")
        XCTAssertTrue(KeyboardShortcut(keyCode: VirtualKey.a, modifiers: [.command]).isValid)
        XCTAssertTrue(KeyboardShortcut(keyCode: VirtualKey.space, modifiers: [.control, .option]).isValid)
    }

    func testValidationAllowsBareFunctionKeys() {
        XCTAssertTrue(KeyboardShortcut(keyCode: VirtualKey.f5, modifiers: []).isValid)
        XCTAssertTrue(KeyboardShortcut(keyCode: VirtualKey.f9, modifiers: []).isValid)
        XCTAssertFalse(KeyboardShortcut(keyCode: VirtualKey.f4, modifiers: []).isValid, "Only F5–F12 are safe bare")
        XCTAssertFalse(KeyboardShortcut(keyCode: VirtualKey.fn, modifiers: []).isValid)
    }

    func testValidationRejectsUnknownKeyCodes() {
        XCTAssertFalse(KeyboardShortcut(keyCode: 9999, modifiers: [.command]).isValid)
    }

    func testSerializationRoundTrip() {
        let cases: [KeyboardShortcut] = [
            .default,
            KeyboardShortcut(keyCode: VirtualKey.a, modifiers: [.command, .option]),
            KeyboardShortcut(keyCode: VirtualKey.f5, modifiers: []),
            KeyboardShortcut(keyCode: VirtualKey.k, modifiers: [.command, .option, .shift]),
            KeyboardShortcut(keyCode: VirtualKey.space, modifiers: [.control]),
        ]
        for shortcut in cases {
            let serialized = KeyboardShortcut.serialized(shortcut)
            let deserialized = KeyboardShortcut.deserialize(serialized)
            XCTAssertEqual(deserialized, shortcut, "Round trip failed for \(serialized)")
        }
    }

    func testDeserializationRejectsGarbage() {
        XCTAssertNil(KeyboardShortcut.deserialize(""))
        XCTAssertNil(KeyboardShortcut.deserialize("not-a-shortcut"))
        XCTAssertNil(KeyboardShortcut.deserialize("49|bogus"))
        XCTAssertNil(KeyboardShortcut.deserialize("abc|cmd"))
        // A bare letter must not deserialize (invalid shortcut).
        XCTAssertNil(KeyboardShortcut.deserialize("\(VirtualKey.a)|"))
    }

    func testCarbonModifierMapping() {
        let shortcut = KeyboardShortcut(keyCode: VirtualKey.space, modifiers: [.command, .shift, .option, .control])
        let expected = CarbonModifierMask.command | CarbonModifierMask.shift | CarbonModifierMask.option | CarbonModifierMask.control
        XCTAssertEqual(shortcut.carbonModifierFlags, expected)

        XCTAssertEqual(KeyboardShortcut(keyCode: VirtualKey.a, modifiers: [.command]).carbonModifierFlags, CarbonModifierMask.command)
    }

    func testModifierSetFromNSEventFlags() {
        var flags: NSEvent.ModifierFlags = [.command, .shift, .capsLock]
        XCTAssertEqual(ModifierSet.from(flags), [.command, .shift])

        flags = [.control, .option]
        XCTAssertEqual(ModifierSet.from(flags), [.control, .option])
    }
}
