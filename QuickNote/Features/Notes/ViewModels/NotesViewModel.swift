import AppKit
import Combine
import Foundation

/// Drives the main notes window: current section, search, selection, and all
/// list operations. All persistence goes through the repository (spec §16).
@MainActor
final class NotesViewModel: ObservableObject {
    @Published var filter: NoteFilter = .inbox {
        didSet {
            if oldValue != filter { refresh() }
        }
    }
    @Published var searchText: String = "" {
        didSet {
            scheduleSearch()
        }
    }
    @Published private(set) var notes: [Note] = []
    @Published var selectedNoteID: UUID? {
        didSet {
            if oldValue != selectedNoteID { syncSelectionToNotes() }
        }
    }

    var selectedNote: Note? {
        notes.first { $0.id == selectedNoteID }
    }

    private let repository: NoteRepositoryProtocol
    private let noteService: NoteService?
    private let searchService: SearchService
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: NoteRepositoryProtocol,
        noteService: NoteService? = nil,
        searchService: SearchService
    ) {
        self.repository = repository
        self.noteService = noteService
        self.searchService = searchService

        NotificationCenter.default.publisher(for: NoteRepository.storeDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        refresh()
    }

    // MARK: Queries

    func refresh() {
        do {
            let fetched: [Note]
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                fetched = try repository.fetchNotes(in: filter)
            } else {
                // Search is global across non-trashed notes (spec §22).
                fetched = try repository.search(searchText)
            }
            notes = fetched
            syncSelectionToNotes()
        } catch {
            Log.persistence.error("Fetch failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Debounced search refresh (spec §22: no work per keystroke without a
    /// debounce).
    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    private func syncSelectionToNotes() {
        if let selectedNoteID, notes.contains(where: { $0.id == selectedNoteID }) { return }
        selectedNoteID = notes.first?.id
    }

    // MARK: Actions

    func trash(_ note: Note) {
        try? repository.moveToTrash(note)
    }

    func restore(_ note: Note) {
        try? repository.restore(note)
    }

    func deletePermanently(_ note: Note) {
        try? repository.deletePermanently(note)
    }

    func setPinned(_ note: Note, _ pinned: Bool) {
        try? repository.setPinned(note, pinned)
    }

    func togglePin(_ note: Note) {
        setPinned(note, !note.isPinned)
    }

    func updateContent(_ note: Note, to text: String) {
        try? repository.updateContent(note, to: text)
    }

    func copyToPasteboard(_ note: Note) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(note.content, forType: .string)
    }

    func createNewNote() {
        do {
            let note = try noteService?.createManualNote()
            selectedNoteID = note?.id
        } catch {
            Log.persistence.error("Could not create note: \(String(describing: error), privacy: .public)")
        }
    }

    func trashSelected() {
        guard let selectedNote else { return }
        trash(selectedNote)
    }

    func togglePinSelected() {
        guard let selectedNote else { return }
        togglePin(selectedNote)
    }
}
