import XCTest
@testable import QuickNote

/// Black-box UI tests for the main window flows. The global hotkey itself
/// cannot be simulated from XCUITest and is covered by manual QA (README).
@MainActor
final class QuickNoteUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", "1",
            "-recordSourceApp", "0",
            "-quicknote.uitest", "1",
        ]
        app.launch()
        return app
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMainNotesWindow() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["new-note-button"].waitForExistence(timeout: 10))
        app.terminate()
    }

    func testCreateEditAndSearchNote() throws {
        let app = launchApp()

        let newButton = app.buttons["new-note-button"]
        XCTAssertTrue(newButton.waitForExistence(timeout: 10))
        newButton.click()

        let editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.click()
        editor.typeText("UI test note about kiwi fruit")

        // Search should surface the note.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.click()
        searchField.typeText("kiwi")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "UI test note about kiwi fruit"))
            .firstMatch.waitForExistence(timeout: 5))

        app.terminate()
    }

    func testPinAndTrashNote() throws {
        let app = launchApp()

        let newButton = app.buttons["new-note-button"]
        XCTAssertTrue(newButton.waitForExistence(timeout: 10))
        newButton.click()

        let editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.click()
        editor.typeText("Pin and trash me")

        let pinToggle = app.buttons["pin-toggle-button"]
        XCTAssertTrue(pinToggle.waitForExistence(timeout: 5))
        pinToggle.click()

        let trashButton = app.buttons["trash-note-button"]
        XCTAssertTrue(trashButton.waitForExistence(timeout: 5))
        trashButton.click()

        // The editor should now show the In Trash state.
        XCTAssertTrue(app.buttons["restore-note-button"].waitForExistence(timeout: 5))
        app.terminate()
    }

    func testOnboardingShowsAndCompletes() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "0"]
        app.launch()

        let getStarted = app.buttons["get-started-button"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.click()

        // Completing onboarding reveals the main window.
        XCTAssertTrue(app.buttons["new-note-button"].waitForExistence(timeout: 10))
        app.terminate()
    }
}
