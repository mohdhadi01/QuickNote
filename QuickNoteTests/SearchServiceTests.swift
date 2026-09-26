import XCTest
@testable import QuickNote

@MainActor
final class SearchServiceTests: XCTestCase {
    private let searchService = SearchService()

    func testEmptyQueryReturnsAllNotes() {
        let notes = [
            Note(content: "alpha"),
            Note(content: "beta"),
        ]
        XCTAssertEqual(searchService.filter(notes, query: "").count, 2)
        XCTAssertEqual(searchService.filter(notes, query: "   ").count, 2)
    }

    func testMatchesContentCaseInsensitively() {
        let notes = [Note(content: "Fix React Native animation")]
        XCTAssertEqual(searchService.filter(notes, query: "react native").count, 1)
        XCTAssertEqual(searchService.filter(notes, query: "ANIMATION").count, 1)
        XCTAssertEqual(searchService.filter(notes, query: "swiftui").count, 0)
    }

    func testMatchesMultilineContent() {
        let notes = [Note(content: "Title line\nsecond line detail")]
        XCTAssertEqual(searchService.filter(notes, query: "second line").count, 1)
    }

    func testQueryWithOnlyWhitespaceMatchesEverything() {
        let notes = [Note(content: "anything")]
        XCTAssertEqual(searchService.filter(notes, query: "\t \n").count, 1)
    }

    func testFilterIsDeterministicAndPreservesOrder() {
        let notes = [
            Note(content: "apple pie"),
            Note(content: "banana bread"),
            Note(content: "apple crisp"),
        ]
        let result = searchService.filter(notes, query: "apple")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].content, "apple pie")
        XCTAssertEqual(result[1].content, "apple crisp")
    }
}
