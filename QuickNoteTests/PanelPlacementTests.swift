import CoreGraphics
import XCTest
@testable import QuickNote

final class PanelPlacementTests: XCTestCase {
    private let panelSize = CGSize(width: 460, height: 132)
    private let margin = DesignTokens.CapturePanel.screenMargin

    // A 1440×900 screen with menu bar (25 pt) and no Dock.
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 875)

    func testPanelNearCursorAppearsBelowAndNearPointer() {
        let cursor = CGPoint(x: 700, y: 600)
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: visibleFrame, mode: .nearCursor
        )

        XCTAssertTrue(visibleFrame.insetBy(dx: margin, dy: margin).contains(frame), "Panel must be fully on screen")
        // Top edge sits a small gap below the cursor.
        XCTAssertEqual(frame.maxY, cursor.y - DesignTokens.CapturePanel.cursorGap, accuracy: 0.5)
        // Panel is roughly anchored at the pointer's x.
        XCTAssertEqual(frame.minX, cursor.x - panelSize.width * 0.2, accuracy: 0.5)
    }

    func testPanelFlipsAboveCursorNearBottomOfScreen() {
        let cursor = CGPoint(x: 700, y: 60)
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: visibleFrame, mode: .nearCursor
        )

        // The panel moved above the cursor rather than covering it.
        XCTAssertEqual(frame.minY, cursor.y + DesignTokens.CapturePanel.cursorGap, accuracy: 0.5)
        XCTAssertEqual(frame.maxY, cursor.y + DesignTokens.CapturePanel.cursorGap + panelSize.height, accuracy: 0.5)
        XCTAssertTrue(visibleFrame.insetBy(dx: margin, dy: margin).contains(frame))
    }

    func testPanelIsClampedAtRightScreenEdge() {
        let cursor = CGPoint(x: 1420, y: 600)
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: visibleFrame, mode: .nearCursor
        )

        XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX - margin)
        XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX + margin)
    }

    func testPanelIsClampedAtLeftScreenEdge() {
        let cursor = CGPoint(x: 5, y: 600)
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: visibleFrame, mode: .nearCursor
        )

        XCTAssertEqual(frame.minX, visibleFrame.minX + margin, accuracy: 0.5)
    }

    func testPanelStaysInsideWhenTallerThanAvailableSpace() {
        let smallFrame = CGRect(x: 0, y: 0, width: 800, height: 300)
        let cursor = CGPoint(x: 400, y: 150)
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: smallFrame, mode: .nearCursor
        )

        XCTAssertTrue(smallFrame.insetBy(dx: margin, dy: margin).contains(frame))
    }

    func testCenteredModeCentersOnVisibleFrame() {
        let frame = PanelPlacement.frame(
            size: panelSize, cursor: CGPoint(x: 10, y: 10), visibleFrame: visibleFrame, mode: .centeredOnScreen
        )

        XCTAssertEqual(frame.midX, visibleFrame.midX, accuracy: 0.5)
        XCTAssertEqual(frame.midY, visibleFrame.midY, accuracy: 0.5)
    }

    func testCenteredModeIsClampedWhenPanelExceedsScreen() {
        let hugeSize = CGSize(width: 1400, height: 860)
        let frame = PanelPlacement.frame(
            size: hugeSize, cursor: .zero, visibleFrame: visibleFrame, mode: .centeredOnScreen
        )

        XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX + margin)
        // Height exceeds the inset area: must stay flush inside the screen.
        XCTAssertGreaterThanOrEqual(frame.minY, visibleFrame.minY)
        XCTAssertLessThanOrEqual(frame.maxY, visibleFrame.maxY)
        XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX - margin)
    }

    func testFrameResizingDownwardKeepsTopEdgeFixed() {
        let original = CGRect(x: 100, y: 200, width: 460, height: 132)
        let resized = PanelPlacement.frameResizingDownward(from: original, newHeight: 300)

        XCTAssertEqual(resized.maxY, original.maxY, accuracy: 0.001, "Top edge must stay put while growing")
        XCTAssertEqual(resized.height, 300)
        XCTAssertEqual(resized.origin.x, original.origin.x)
        XCTAssertEqual(resized.minY, original.maxY - 300, accuracy: 0.001)
    }

    func testRespectsSecondaryDisplayGeometry() {
        // A display placed to the right of the main one with a Dock at bottom.
        let rightDisplay = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let visible = rightDisplay.insetBy(dx: 0, dy: 80) // menu bar + dock
        let cursor = CGPoint(x: 1500, y: 100) // near the bottom-left of that display

        let frame = PanelPlacement.frame(
            size: panelSize, cursor: cursor, visibleFrame: visible, mode: .nearCursor
        )

        XCTAssertTrue(visible.insetBy(dx: margin, dy: margin).contains(frame), "Panel must stay on the display containing the cursor")
        XCTAssertGreaterThanOrEqual(frame.minX, visible.minX + margin)
    }
}
