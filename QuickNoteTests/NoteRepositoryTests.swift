import XCTest
@testable import QuickNote

@MainActor
final class NoteRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var repository: NoteRepository!
    private var now: Date!

    override func setUp() async throws {
        persistence = try PersistenceController.inMemory()
        now = Date()
        repository = NoteRepository(container: persistence.container, now: { [weak self] in self?.now ?? Date() })
    }

    func testCreateAndFetch() throws {
        let note = try repository.create(content: "Remember the milk", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        XCTAssertEqual(note.content, "Remember the milk")
        XCTAssertEqual(note.createdAt, now)
        XCTAssertEqual(note.updatedAt, now)
        XCTAssertFalse(note.isPinned)
        XCTAssertNil(note.deletedAt)

        let fetched = try repository.fetchNotes(in: .all)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, note.id)
    }

    func testFetchSortsNewestFirst() throws {
        let older = try repository.create(content: "older", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        now = now.addingTimeInterval(60)
        let newer = try repository.create(content: "newer", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        let fetched = try repository.fetchNotes(in: .all)
        XCTAssertEqual(fetched.map(\.id), [newer.id, older.id])
    }

    func testInboxExcludesPinnedAndTrashed() throws {
        let normal = try repository.create(content: "normal", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        let pinned = try repository.create(content: "pinned", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        let trashed = try repository.create(content: "trashed", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        try repository.setPinned(pinned, true)
        try repository.moveToTrash(trashed)

        let inbox = try repository.fetchNotes(in: .inbox)
        XCTAssertEqual(inbox.map(\.id), [normal.id])
    }

    func testPinnedFilter() throws {
        let a = try repository.create(content: "a", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        let b = try repository.create(content: "b", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        try repository.setPinned(a, true)

        let pinned = try repository.fetchNotes(in: .pinned)
        XCTAssertEqual(pinned.map(\.id), [a.id])
        XCTAssertFalse(b.isPinned)
    }

    func testTodayFilterUsesLocalCalendarDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        var dayComponents = DateComponents()
        dayComponents.year = 2026
        dayComponents.month = 9
        dayComponents.day = 26
        let dayStart = calendar.startOfDay(for: calendar.date(from: dayComponents)!)

        // Sep 25, 23:00 — yesterday.
        now = calendar.date(byAdding: .hour, value: -1, to: dayStart)
        let yesterdayNote = try repository.create(content: "yesterday", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        // Sep 26, 01:30 — today, early.
        now = calendar.date(byAdding: .minute, value: 90, to: dayStart)
        let todayEarlyNote = try repository.create(content: "today early", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        // Sep 26, 13:30 — today, afternoon.
        now = calendar.date(byAdding: .hour, value: 12, to: todayEarlyNote.createdAt)
        let todayLateNote = try repository.create(content: "today late", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        // Sep 27, 12:00 — tomorrow.
        now = calendar.date(byAdding: .hour, value: 36, to: dayStart)
        _ = try repository.create(content: "tomorrow", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        // Evaluate "today" while today is still Sep 26.
        now = calendar.date(byAdding: .minute, value: 1, to: todayLateNote.createdAt)
        let today = try repository.fetchNotes(in: .today)

        XCTAssertEqual(Set(today.map(\.id)), [todayEarlyNote.id, todayLateNote.id])
        XCTAssertFalse(today.contains { $0.id == yesterdayNote.id })
    }

    func testTrashRestoreAndPermanentDelete() throws {
        let note = try repository.create(content: "to trash", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        try repository.moveToTrash(note)
        XCTAssertNotNil(note.deletedAt)
        XCTAssertEqual(try repository.fetchNotes(in: .trash).map(\.id), [note.id])
        XCTAssertEqual(try repository.fetchNotes(in: .all).count, 0)

        try repository.restore(note)
        XCTAssertNil(note.deletedAt)
        XCTAssertEqual(try repository.fetchNotes(in: .trash).count, 0)
        XCTAssertEqual(try repository.fetchNotes(in: .all).map(\.id), [note.id])

        try repository.moveToTrash(note)
        try repository.deletePermanently(note)
        XCTAssertEqual(try repository.fetchNotes(in: .trash).count, 0)
        XCTAssertEqual(try repository.fetchNotes(in: .all).count, 0)
    }

    func testUpdateContentTouchesUpdatedAt() throws {
        let note = try repository.create(content: "before", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        now = now.addingTimeInterval(120)

        try repository.updateContent(note, to: "after")
        XCTAssertEqual(note.content, "after")
        XCTAssertEqual(note.updatedAt, now)
        XCTAssertEqual(note.createdAt, now.addingTimeInterval(-120))
    }

    func testSearchFindsContentCaseInsensitively() throws {
        try repository.create(content: "Fix React Native animation", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        try repository.create(content: "Buy oat milk", sourceApplicationName: nil, sourceApplicationBundleID: nil)

        XCTAssertEqual(try repository.search("REACT").count, 1)
        XCTAssertEqual(try repository.search("milk").count, 1)
        XCTAssertEqual(try repository.search("oat milk").count, 1)
        XCTAssertEqual(try repository.search("zebra").count, 0)
        // Empty search behaves like All Notes.
        XCTAssertEqual(try repository.search("  ").count, 2)
    }

    func testSearchExcludesTrashedNotes() throws {
        let note = try repository.create(content: "findable note", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        try repository.moveToTrash(note)
        XCTAssertEqual(try repository.search("findable").count, 0)
        try repository.restore(note)
        XCTAssertEqual(try repository.search("findable").count, 1)
    }

    func testStoreDidChangeIsPostedOnMutation() throws {
        let expectation = expectation(forNotification: NoteRepository.storeDidChange, object: nil)
        _ = try repository.create(content: "notify", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        wait(for: [expectation], timeout: 2)
    }

    func testSourceApplicationMetadataIsStored() throws {
        let note = try repository.create(
            content: "with source",
            sourceApplicationName: "VS Code",
            sourceApplicationBundleID: "com.microsoft.VSCode"
        )
        XCTAssertEqual(note.sourceApplicationName, "VS Code")
        XCTAssertEqual(note.sourceApplicationBundleID, "com.microsoft.VSCode")

        let withoutSource = try repository.create(content: "without source", sourceApplicationName: nil, sourceApplicationBundleID: nil)
        XCTAssertNil(withoutSource.sourceApplicationName)
        XCTAssertNil(withoutSource.sourceApplicationBundleID)
    }
}
