import Foundation
import SwiftUI

/// User preferences, persisted to UserDefaults (spec §29, §30, §31).
@MainActor
final class SettingsService: ObservableObject {
    enum PanelPosition: String, CaseIterable, Identifiable {
        case nearCursor
        case centeredOnScreen

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nearCursor: "Near Cursor"
            case .centeredOnScreen: "Centered on Screen"
            }
        }
    }

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: "Follow System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    private enum Keys {
        static let shortcut = "settings.captureShortcut"
        static let recordSourceApp = "settings.recordSourceApp"
        static let panelPosition = "settings.panelPosition"
        static let appearance = "settings.appearance"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var shortcut: KeyboardShortcut {
        didSet { defaults.set(KeyboardShortcut.serialized(shortcut), forKey: Keys.shortcut) }
    }
    /// Default OFF (spec §44).
    @Published var recordSourceApp: Bool {
        didSet { defaults.set(recordSourceApp, forKey: Keys.recordSourceApp) }
    }
    @Published var panelPosition: PanelPosition {
        didSet { defaults.set(panelPosition.rawValue, forKey: Keys.panelPosition) }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearance) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let stored = defaults.string(forKey: Keys.shortcut),
           let shortcut = KeyboardShortcut.deserialize(stored) {
            self.shortcut = shortcut
        } else {
            self.shortcut = .default
        }

        self.recordSourceApp = defaults.bool(forKey: Keys.recordSourceApp)
        self.panelPosition = PanelPosition(rawValue: defaults.string(forKey: Keys.panelPosition) ?? "") ?? .nearCursor
        self.appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }
}
