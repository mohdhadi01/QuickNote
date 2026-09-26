import XCTest
@testable import QuickNote

final class NoteFilterTests: XCTestCase {
    func testTodayRangeCoversLocalCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 26
        components.hour = 23
        components.minute = 45
        let lateEvening = calendar.date(from: components)!

        let (start, end) = NoteFilter.todayRange(calendar: calendar, now: lateEvening)

        XCTAssertEqual(calendar.compare(start, to: lateEvening, toGranularity: .day), .orderedSame)
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
        XCTAssertEqual(calendar.component(.minute, from: start), 0)
        XCTAssertTrue(lateEvening >= start && lateEvening < end)

        // A note one minute later is a different day in the same time zone.
        let afterMidnight = lateEvening.addingTimeInterval(60 * 16)
        XCTAssertFalse(afterMidnight >= start && afterMidnight < end)
    }

    func testTodayRangeFollowsCalendarTimeZoneNotUTC() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 26
        components.hour = 1
        let earlyMorningTokyo = calendar.date(from: components)!

        let (start, end) = NoteFilter.todayRange(calendar: calendar, now: earlyMorningTokyo)

        // The UTC date for this instant is still Sep 25 — "today" must be Sep 26 local.
        XCTAssertEqual(calendar.compare(start, to: earlyMorningTokyo, toGranularity: .day), .orderedSame)
        XCTAssertTrue(earlyMorningTokyo >= start && earlyMorningTokyo < end)
        XCTAssertEqual(end.timeIntervalSince(start), 86_400, accuracy: 1)
    }

    func testSidebarSymbolsUseSystemSFSymbols() {
        XCTAssertEqual(NoteFilter.inbox.symbolName, "tray")
        XCTAssertEqual(NoteFilter.today.symbolName, "calendar")
        XCTAssertEqual(NoteFilter.all.symbolName, "note.text")
        XCTAssertEqual(NoteFilter.pinned.symbolName, "pin")
        XCTAssertEqual(NoteFilter.trash.symbolName, "trash")
    }
}
