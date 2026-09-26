import Foundation
import os

/// Central logging. Note content and other private user data must never be logged.
enum Log {
    private static let subsystem = "com.quicknote.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let capture = Logger(subsystem: subsystem, category: "capture")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let window = Logger(subsystem: subsystem, category: "window")
    static let settings = Logger(subsystem: subsystem, category: "settings")
}

/// Named launch arguments / defaults used by QA, screenshots, and UI tests.
/// These are intentional, documented debug affordances (see README).
enum DebugFlags {
    static func isEnabled(_ flag: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }

    /// Automatically opens the quick capture panel shortly after launch (visual QA).
    static let showQuickCapture = "-quicknote.debugShowCapture"
    /// Opens the Settings window shortly after launch (visual QA).
    static let openSettings = "-quicknote.debugOpenSettings"
}
