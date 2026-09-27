import AppKit
import Foundation

/// Capture-facing note operations: validation, source-app metadata, and
/// repository persistence (spec §14, §44).
@MainActor
final class NoteService {
    private let repository: NoteRepositoryProtocol
    private let settings: SettingsService
    private let applicationContextProvider: ApplicationContextProviding

    init(
        repository: NoteRepositoryProtocol,
        settings: SettingsService,
        applicationContextProvider: ApplicationContextProviding = WorkspaceApplicationContextProvider()
    ) {
        self.repository = repository
        self.settings = settings
        self.applicationContextProvider = applicationContextProvider
    }

    /// Persists a quick capture. Throws `NoteCaptureError.empty` when the
    /// text is empty after normalization.
    func capture(_ rawText: String, sourceApp: ApplicationContextSnapshot? = nil) throws -> Note {
        guard let content = NoteContentFormatter.normalizedCaptureText(rawText) else {
            throw NoteCaptureError.empty
        }

        var source = sourceApp
        if source == nil && settings.recordSourceApp {
            source = applicationContextProvider.frontmostApplication()
        }

        let note = try repository.create(
            content: content,
            sourceApplicationName: source?.applicationName,
            sourceApplicationBundleID: source?.bundleIdentifier
        )
        Log.capture.info("Saved quick capture")
        return note
    }

    /// Creates an empty note from the main window's "+" action.
    func createManualNote() throws -> Note {
        try repository.create(content: "", sourceApplicationName: nil, sourceApplicationBundleID: nil)
    }

    /// QA/UI-test hook: seeds a note once so headless runs can exercise the
    /// list without synthesized typing.
    func seedNoteIfMissing(_ rawText: String) {
        guard let content = NoteContentFormatter.normalizedCaptureText(rawText) else { return }
        let existing = (try? repository.search(content)) ?? []
        guard existing.isEmpty else { return }
        // Seeded demo notes never carry a source app; the editor header
        // would otherwise show whatever app happened to launch the run.
        try? repository.create(content: content, sourceApplicationName: nil, sourceApplicationBundleID: nil)
    }
}
