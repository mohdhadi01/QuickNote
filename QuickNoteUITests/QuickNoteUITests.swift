import XCTest
@testable import QuickNote

/// Black-box UI tests for the main window flows.
///
/// Hardware keyboard events cannot be synthesized in headless runs, so these
/// tests exercise clicks, selection, and state changes; note text is provided
/// by the documented `-quicknote.seedNote` QA hook and every launch uses a
/// fresh in-memory store (`-quicknote.inMemoryStore`). Real typing behavior is
/// covered by manual QA (see README) and unit tests.
@MainActor
final class QuickNoteUITests: XCTestCase {
    private static let seedText = "UI test note about kiwi fruit"

    private func launchApp(onboardingCompleted: Bool = true, seedNote: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-hasCompletedOnboarding", onboardingCompleted ? "1" : "0",
            "-recordSourceApp", "0",
            "-quicknote.uitest", "1",
            // Hermetic: every launch starts with a fresh in-memory store.
            "-quicknote.inMemoryStore", "1",
        ]
        if onboardingCompleted {
            app.launchArguments += ["-hasCompletedOnboarding", "1"]
        } else {
            app.launchArguments += ["-quicknote.forceOnboarding"]
        }
        if seedNote {
            app.launchArguments += ["-quicknote.seedNote", Self.seedText]
        }
        app.launch()
        app.activate()
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

    func testCreateNoteShowsEditor() throws {
        let app = launchApp()

        let newButton = app.buttons["new-note-button"]
        XCTAssertTrue(newButton.waitForExistence(timeout: 10))
        newButton.click()

        // The new note is selected and the editor opens with placeholder.
        let editor = app.textViews["note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        app.terminate()
    }

    func testSeededNotePinTrashRestore() throws {
        let app = launchApp(seedNote: true)

        // The seeded note appears in the Inbox list (combined row element).
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", Self.seedText))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.click()

        // Pin it from the editor header.
        let pinToggle = app.buttons["pin-toggle-button"]
        XCTAssertTrue(pinToggle.waitForExistence(timeout: 5))
        pinToggle.click()

        // The pinned note moved to the Pinned section; open it there.
        app.staticTexts["Pinned"].firstMatch.click()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.click()

        // Move to trash, then check it in the Trash section.
        let trashButton = app.buttons["trash-note-button"]
        XCTAssertTrue(trashButton.waitForExistence(timeout: 5))
        trashButton.click()

        app.staticTexts["Trash"].firstMatch.click()
        XCTAssertTrue(app.buttons["restore-note-button"].waitForExistence(timeout: 5))

        // Restore brings the note back out of the trash: the row first
        // disappears from the Trash list, then reappears under All Notes
        // (it is still pinned, so Inbox would not show it).
        app.buttons["restore-note-button"].click()
        XCTAssertTrue(row.waitForNonExistence(timeout: 5))

        app.staticTexts["All Notes"].firstMatch.click()
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        app.terminate()
    }

    func testSidebarSectionNavigation() throws {
        let app = launchApp(seedNote: true)

        XCTAssertTrue(app.buttons["new-note-button"].waitForExistence(timeout: 10))

        for section in ["Trash", "Pinned", "Today", "All Notes", "Inbox"] {
            let item = app.staticTexts[section].firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 5), "Missing sidebar section \(section)")
            item.click()
        }
        app.terminate()
    }

    func testOnboardingShowsAndCompletes() throws {
        let app = launchApp(onboardingCompleted: false)

        let getStarted = app.buttons["get-started-button"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10))
        getStarted.click()

        // Completing onboarding reveals the main window.
        XCTAssertTrue(app.buttons["new-note-button"].waitForExistence(timeout: 10))
        app.terminate()
    }
}


