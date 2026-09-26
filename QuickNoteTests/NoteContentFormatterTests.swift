import XCTest
@testable import QuickNote

final class NoteContentFormatterTests: XCTestCase {
    func testNormalizedCaptureTextTrimsWhitespace() {
        XCTAssertEqual(NoteContentFormatter.normalizedCaptureText("  hello  "), "hello")
        XCTAssertEqual(NoteContentFormatter.normalizedCaptureText("\n\n line one\n line two \n"), "line one\n line two")
    }

    func testNormalizedCaptureTextPreservesInternalWhitespace() {
        let text = "line one\n\n  indented   line"
        XCTAssertEqual(NoteContentFormatter.normalizedCaptureText(text), text)
    }

    func testNormalizedCaptureTextRejectsEmpty() {
        XCTAssertNil(NoteContentFormatter.normalizedCaptureText(""))
        XCTAssertNil(NoteContentFormatter.normalizedCaptureText("   \n\t "))
    }

    func testDisplayTitleUsesFirstMeaningfulLine() {
        XCTAssertEqual(NoteContentFormatter.displayTitle(for: "Fix React Native animation\nNeed to inspect why frame rate drops"), "Fix React Native animation")
        XCTAssertEqual(NoteContentFormatter.displayTitle(for: "\n\n  \nSecond line is first"), "Second line is first")
    }

    func testDisplayTitleForEmptyContent() {
        XCTAssertEqual(NoteContentFormatter.displayTitle(for: ""), "Untitled")
        XCTAssertEqual(NoteContentFormatter.displayTitle(for: "   \n "), "Untitled")
    }

    func testDisplayPreviewSkipsTitleAndBlankLine() {
        let content = "Title\n\nBody text here\nmore body"
        XCTAssertEqual(NoteContentFormatter.displayPreview(for: content), "Body text here more body")
    }

    func testDisplayPreviewForSingleLineNote() {
        XCTAssertEqual(NoteContentFormatter.displayPreview(for: "Only a title line"), "")
    }

    func testDisplayPreviewCollapsesRunsOfWhitespace() {
        let content = "Title\nBody     with\t\tgaps"
        XCTAssertEqual(NoteContentFormatter.displayPreview(for: content), "Body with gaps")
    }

    func testMatchesIsCaseInsensitiveAndTrimsQuery() {
        XCTAssertTrue(NoteContentFormatter.matches("Remember the Milk", query: "milk"))
        XCTAssertTrue(NoteContentFormatter.matches("Line one\nLine two", query: "  line two "))
        XCTAssertFalse(NoteContentFormatter.matches("Hello", query: "world"))
        XCTAssertTrue(NoteContentFormatter.matches("Anything", query: "   "))
    }
}
