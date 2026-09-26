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
    @Published private(set) var counts: [NoteFilter: Int] = [:]
    @Published var selectedNoteID: UUID? {
        didSet {
            if oldValue != selectedNoteID { syncSelectionToNotes() }
        }
    }
    /// Incremented to move keyboard focus into the editor.
    @Published var editorFocusRequest = 0
    /// Incremented to move keyboard focus into the search field.
    @Published var searchFocusRequest = 0

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
            computeCounts()
            syncSelectionToNotes()
        } catch {
            Log.persistence.error("Fetch failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Sidebar badges, computed from one lightweight pass over all notes.
    private func computeCounts() {
        let all = (try? repository.fetchNotes(in: .all)) ?? []
        let trash = (try? repository.fetchNotes(in: .trash)) ?? []
        let todayStart = NoteFilter.todayRange().start
        counts = [
            .all: all.count,
            .inbox: all.filter { !$0.isPinned }.count,
            .pinned: all.filter(\.isPinned).count,
            .today: all.filter { $0.createdAt >= todayStart }.count,
            .trash: trash.count,
        ]
    }

    /// Arrow-key navigation in the list.
    func moveSelection(_ delta: Int) {
        guard !notes.isEmpty else { return }
        let currentIndex = notes.firstIndex { $0.id == selectedNoteID } ?? (delta > 0 ? -1 : 0)
        let nextIndex = min(max(currentIndex + delta, 0), notes.count - 1)
        selectedNoteID = notes[nextIndex].id
    }

    func clearSearch() {
        searchText = ""
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
            editorFocusRequest += 1
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
