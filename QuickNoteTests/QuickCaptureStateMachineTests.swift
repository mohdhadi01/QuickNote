import XCTest
@testable import QuickNote

final class QuickCaptureStateMachineTests: XCTestCase {
    func testHappyPath() {
        var machine = QuickCaptureStateMachine()
        XCTAssertEqual(machine.state, .idle)

        XCTAssertTrue(machine.handle(.beginPresent))
        XCTAssertEqual(machine.state, .presenting)

        XCTAssertTrue(machine.handle(.becameReady))
        XCTAssertEqual(machine.state, .ready)

        XCTAssertTrue(machine.handle(.textChanged))
        XCTAssertEqual(machine.state, .typing)

        XCTAssertTrue(machine.handle(.beganSave))
        XCTAssertEqual(machine.state, .saving)

        XCTAssertTrue(machine.handle(.saveSucceeded))
        XCTAssertEqual(machine.state, .dismissing)

        XCTAssertTrue(machine.handle(.finishedDismiss))
        XCTAssertEqual(machine.state, .idle)
    }

    func testEscapeFromReadyAndTyping() {
        var machine = QuickCaptureStateMachine()
        machine.handle(.beginPresent)
        machine.handle(.becameReady)
        XCTAssertTrue(machine.handle(.beginDismiss))
        XCTAssertEqual(machine.state, .dismissing)
        machine.handle(.finishedDismiss)
        XCTAssertEqual(machine.state, .idle)

        machine.handle(.beginPresent)
        machine.handle(.becameReady)
        machine.handle(.textChanged)
        XCTAssertTrue(machine.handle(.beginDismiss))
        XCTAssertEqual(machine.state, .dismissing)
    }

    func testSaveFailureReturnsToTyping() {
        var machine = QuickCaptureStateMachine()
        machine.handle(.beginPresent)
        machine.handle(.becameReady)
        machine.handle(.textChanged)
        XCTAssertTrue(machine.handle(.beganSave))
        XCTAssertTrue(machine.handle(.saveFailed))
        XCTAssertEqual(machine.state, .typing)

        // Retry is allowed after a failure.
        XCTAssertTrue(machine.handle(.beganSave))
        XCTAssertTrue(machine.handle(.saveSucceeded))
        XCTAssertEqual(machine.state, .dismissing)
    }

    func testIllegalTransitionsAreRejected() {
        var machine = QuickCaptureStateMachine()

        // Cannot save/dismiss before presenting.
        XCTAssertFalse(machine.handle(.beganSave))
        XCTAssertFalse(machine.handle(.beginDismiss))
        XCTAssertEqual(machine.state, .idle)

        // Cannot present while already presenting.
        machine.handle(.beginPresent)
        XCTAssertFalse(machine.handle(.beginPresent))
        XCTAssertEqual(machine.state, .presenting)

        // Cannot finish dismissal before dismissing.
        machine.handle(.becameReady)
        XCTAssertFalse(machine.handle(.finishedDismiss))
        XCTAssertEqual(machine.state, .ready)
    }

    func testDuplicateSaveIsRejectedWhileSaving() {
        var machine = QuickCaptureStateMachine()
        machine.handle(.beginPresent)
        machine.handle(.becameReady)
        machine.handle(.textChanged)
        XCTAssertTrue(machine.handle(.beganSave))
        // Rapid second Enter must not restart the save.
        XCTAssertFalse(machine.handle(.beganSave))
        XCTAssertEqual(machine.state, .saving)
    }

    func testDuplicatePresentIsRejectedWhileVisible() {
        var machine = QuickCaptureStateMachine()
        machine.handle(.beginPresent)
        machine.handle(.becameReady)
        // Hotkey while visible must not create a second presentation.
        XCTAssertFalse(machine.handle(.beginPresent))
        XCTAssertEqual(machine.state, .ready)
    }

    func testVisibilityReporting() {
        var machine = QuickCaptureStateMachine()
        XCTAssertFalse(machine.state.isPanelVisible)
        machine.handle(.beginPresent)
        XCTAssertTrue(machine.state.isPanelVisible)
        machine.handle(.becameReady)
        machine.handle(.beginDismiss)
        XCTAssertTrue(machine.state.isPanelVisible, "Panel is still on screen during dismissal")
        machine.handle(.finishedDismiss)
        XCTAssertFalse(machine.state.isPanelVisible)
    }
}
