import Foundation

/// Plain-integer virtual key codes re-exported from Carbon's key constants so
/// the rest of the app never imports Carbon (spec §5: no Carbon leakage).
enum VirtualKey {
    static let a: UInt32 = 0x00
    static let k: UInt32 = 0x28
    static let space: UInt32 = 0x31
    static let tab: UInt32 = 0x30
    static let returnKey: UInt32 = 0x24
    static let delete: UInt32 = 0x33
    static let forwardDelete: UInt32 = 0x75
    static let escape: UInt32 = 0x35
    static let home: UInt32 = 0x73
    static let end: UInt32 = 0x77
    static let pageUp: UInt32 = 0x74
    static let pageDown: UInt32 = 0x79
    static let upArrow: UInt32 = 0x7E
    static let downArrow: UInt32 = 0x7D
    static let leftArrow: UInt32 = 0x7B
    static let rightArrow: UInt32 = 0x7C
    static let f1: UInt32 = 0x7A
    static let f2: UInt32 = 0x78
    static let f3: UInt32 = 0x63
    static let f4: UInt32 = 0x76
    static let f5: UInt32 = 0x60
    static let f6: UInt32 = 0x61
    static let f7: UInt32 = 0x62
    static let f8: UInt32 = 0x64
    static let f9: UInt32 = 0x65
    static let f10: UInt32 = 0x6D
    static let f11: UInt32 = 0x67
    static let f12: UInt32 = 0x6F
    static let fn: UInt32 = 0x3F
}

/// Carbon event modifier masks (subset of Events.h values), re-exported as
/// plain numbers so Carbon imports stay confined to the hotkey implementation.
enum CarbonModifierMask {
    static let command: UInt32 = 1 << 8
    static let shift: UInt32 = 1 << 9
    static let option: UInt32 = 1 << 11
    static let control: UInt32 = 1 << 12
}
