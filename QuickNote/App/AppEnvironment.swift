import Foundation
import SwiftData

/// Composition root: builds and owns all services (spec §4, §63).
@MainActor
final class AppEnvironment {
    let persistence: PersistenceController
    let settings: SettingsService
    let flags: AccessibilityEnvironmentFlags
    let loginItem: LoginItemService
    let repository: NoteRepository
    let noteService: NoteService
    let shortcutService: ShortcutService
    let notesViewModel: NotesViewModel
    let captureViewModel: QuickCaptureViewModel

    var persistenceRecovery: PersistenceRecoveryInfo? { persistence.recoveryInfo }

    static func bootstrap() -> AppEnvironment {
        let persistence = PersistenceController.bootstrap()
        if let recovery = persistence.recoveryInfo {
            Log.persistence.error("Persistence recovered: \(recovery.userFacingMessage, privacy: .public)")
        }

        let settings = SettingsService()
        let repository = NoteRepository(container: persistence.container)
        let noteService = NoteService(repository: repository, settings: settings)
        let shortcutService = ShortcutService(hotkeyService: CarbonHotkeyService(), settings: settings)
        let notesViewModel = NotesViewModel(repository: repository, noteService: noteService, searchService: SearchService())
        let captureViewModel = QuickCaptureViewModel()

        return AppEnvironment(
            persistence: persistence,
            settings: settings,
            flags: AccessibilityEnvironmentFlags(),
            loginItem: LoginItemService(),
            repository: repository,
            noteService: noteService,
            shortcutService: shortcutService,
            notesViewModel: notesViewModel,
            captureViewModel: captureViewModel
        )
    }

    private init(
        persistence: PersistenceController,
        settings: SettingsService,
        flags: AccessibilityEnvironmentFlags,
        loginItem: LoginItemService,
        repository: NoteRepository,
        noteService: NoteService,
        shortcutService: ShortcutService,
        notesViewModel: NotesViewModel,
        captureViewModel: QuickCaptureViewModel
    ) {
        self.persistence = persistence
        self.settings = settings
        self.flags = flags
        self.loginItem = loginItem
        self.repository = repository
        self.noteService = noteService
        self.shortcutService = shortcutService
        self.notesViewModel = notesViewModel
        self.captureViewModel = captureViewModel
    }
}
