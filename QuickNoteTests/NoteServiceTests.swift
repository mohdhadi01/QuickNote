import XCTest
@testable import QuickNote

@MainActor
final class NoteServiceTests: XCTestCase {
    private var persistence: PersistenceController!
    private var repository: NoteRepository!
    private var defaults: UserDefaults!
    private var settings: SettingsService!
    private var noteService: NoteService!

    override func setUp() async throws {
        persistence = try PersistenceController.inMemory()
        repository = NoteRepository(container: persistence.container)
        defaults = UserDefaults(suiteName: "QuickNoteServiceTests")
        defaults.removePersistentDomain(forName: "QuickNoteServiceTests")
        settings = SettingsService(defaults: defaults)
        noteService = NoteService(
            repository: repository,
            settings: settings,
            applicationContextProvider: MockApplicationContextProvider(snapshot: ApplicationContextSnapshot(
                applicationName: "Safari",
                bundleIdentifier: "com.apple.Safari"
            ))
        )
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: "QuickNoteServiceTests")
    }

    func testCaptureTrimsAndPersists() throws {
        let note = try noteService.capture("  hello world  ")
        XCTAssertEqual(note.content, "hello world")
        XCTAssertEqual(try repository.fetchNotes(in: .all).count, 1)
    }

    func testCaptureRejectsEmptyText() {
        XCTAssertThrowsError(try noteService.capture("   \n ")) { error in
            XCTAssertEqual(error as? NoteCaptureError, .empty)
        }
        XCTAssertEqual(try repository.fetchNotes(in: .all).count, 0)
    }

    func testSourceAppNotRecordedByDefault() throws {
        let note = try noteService.capture("no source")
        XCTAssertNil(note.sourceApplicationName)
        XCTAssertNil(note.sourceApplicationBundleID)
    }

    func testSourceAppRecordedWhenEnabled() throws {
        settings.recordSourceApp = true
        let note = try noteService.capture("with source")
        XCTAssertEqual(note.sourceApplicationName, "Safari")
        XCTAssertEqual(note.sourceApplicationBundleID, "com.apple.Safari")
    }

    func testExplicitSourceAppOverridesProvider() throws {
        settings.recordSourceApp = true
        let explicit = ApplicationContextSnapshot(applicationName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode")
        let note = try noteService.capture("explicit source", sourceApp: explicit)
        XCTAssertEqual(note.sourceApplicationName, "Xcode")
    }

    func testCreateManualNoteCreatesEmptyNote() throws {
        let note = try noteService.createManualNote()
        XCTAssertEqual(note.content, "")
        XCTAssertNil(note.sourceApplicationName)
    }
}

/// Deterministic stand-in for the frontmost-application provider.
final class MockApplicationContextProvider: ApplicationContextProviding {
    let snapshot: ApplicationContextSnapshot?

    init(snapshot: ApplicationContextSnapshot?) {
        self.snapshot = snapshot
    }

    func frontmostApplication() -> ApplicationContextSnapshot? {
        snapshot
    }
}
