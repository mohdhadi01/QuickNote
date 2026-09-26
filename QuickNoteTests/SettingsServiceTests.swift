import XCTest
@testable import QuickNote

@MainActor
final class SettingsServiceTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "QuickNoteSettingsServiceTests"

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaults() {
        let settings = SettingsService(defaults: defaults)

        XCTAssertEqual(settings.shortcut, .default)
        XCTAssertFalse(settings.recordSourceApp, "Source app recording must default to OFF")
        XCTAssertEqual(settings.panelPosition, .nearCursor)
        XCTAssertEqual(settings.appearanceMode, .system)
        XCTAssertFalse(settings.hasCompletedOnboarding)
    }

    func testValuesPersistAcrossInstances() {
        let first = SettingsService(defaults: defaults)
        first.shortcut = KeyboardShortcut(keyCode: VirtualKey.k, modifiers: [.command, .option])
        first.recordSourceApp = true
        first.panelPosition = .centeredOnScreen
        first.appearanceMode = .dark
        first.hasCompletedOnboarding = true

        let second = SettingsService(defaults: defaults)
        XCTAssertEqual(second.shortcut, KeyboardShortcut(keyCode: VirtualKey.k, modifiers: [.command, .option]))
        XCTAssertTrue(second.recordSourceApp)
        XCTAssertEqual(second.panelPosition, .centeredOnScreen)
        XCTAssertEqual(second.appearanceMode, .dark)
        XCTAssertTrue(second.hasCompletedOnboarding)
    }

    func testInvalidStoredShortcutFallsBackToDefault() {
        defaults.set("garbage", forKey: "settings.captureShortcut")
        let settings = SettingsService(defaults: defaults)
        XCTAssertEqual(settings.shortcut, .default)
    }

    func testUnknownEnumValuesFallBackToDefaults() {
        defaults.set("rememberedPosition", forKey: "settings.panelPosition")
        defaults.set("neon", forKey: "settings.appearance")
        let settings = SettingsService(defaults: defaults)
        XCTAssertEqual(settings.panelPosition, .nearCursor)
        XCTAssertEqual(settings.appearanceMode, .system)
    }

    func testAppearanceModeColorSchemeMapping() {
        XCTAssertNil(SettingsService.AppearanceMode.system.colorScheme)
        XCTAssertEqual(SettingsService.AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(SettingsService.AppearanceMode.dark.colorScheme, .dark)
    }
}
