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
    /// Forces the onboarding view on launch regardless of stored state (UI tests).
    static let forceOnboarding = "-quicknote.forceOnboarding"

    /// Returns the value following `flag` in the launch arguments, if present.
    static func value(for flag: String) -> String? {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: flag) else { return nil }
        let next = ProcessInfo.processInfo.arguments.index(after: index)
        guard next < ProcessInfo.processInfo.arguments.count else { return nil }
        return ProcessInfo.processInfo.arguments[next]
    }

    /// Seeds one note at launch with the given text if not already present
    /// (UI tests / QA). Real typing cannot be synthesized in headless runs.
    static let seedNote = "-quicknote.seedNote"
    /// Uses an in-memory store so every launch starts empty (UI tests).
    static let inMemoryStore = "-quicknote.inMemoryStore"
}
