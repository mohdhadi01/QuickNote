import AppKit
import Combine
import Foundation

/// Drives the main notes window: sections, search, multi-selection, and all
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

    /// Multi-selection: every highlighted row. The primary note drives the
    /// editor; batch actions apply to the whole set.
    @Published var selectedNoteIDs: Set<UUID> = []
    @Published var primaryNoteID: UUID?

    /// Incremented to move keyboard focus into the editor.
    @Published var editorFocusRequest = 0
    /// Incremented to move keyboard focus into the search field.
    @Published var searchFocusRequest = 0

    var selectedNote: Note? {
        notes.first { $0.id == primaryNoteID }
    }

    var selectedCount: Int { selectedNoteIDs.count }

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
            pruneSelection()
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

    /// Drops selection entries that no longer exist in the current list;
    /// falls back to the first note so the editor is never orphaned.
    private func pruneSelection() {
        let visible = Set(notes.map(\.id))
        selectedNoteIDs = selectedNoteIDs.intersection(visible)

        if let currentPrimary = primaryNoteID, !visible.contains(currentPrimary) {
            primaryNoteID = nil
        }
        if primaryNoteID == nil, let first = notes.first?.id {
            primaryNoteID = first
            selectedNoteIDs = [first]
        }
        if primaryNoteID != nil && !selectedNoteIDs.contains(primaryNoteID!) {
            selectedNoteIDs.insert(primaryNoteID!)
        }
    }

    /// Arrow-key navigation moves the primary selection.
    func moveSelection(_ delta: Int) {
        guard !notes.isEmpty else { return }
        let currentIndex = notes.firstIndex { $0.id == primaryNoteID } ?? (delta > 0 ? -1 : 0)
        let nextIndex = min(max(currentIndex + delta, 0), notes.count - 1)
        selectSingle(noteID: notes[nextIndex].id)
    }

    // MARK: Selection

    func selectSingle(noteID: UUID) {
        selectedNoteIDs = [noteID]
        primaryNoteID = noteID
    }

    /// Click semantics: plain click selects one, ⌘ click toggles membership,
    /// ⇧ click extends a range from the primary note.
    func handleClick(noteID: UUID, command: Bool, shift: Bool) {
        if shift, let anchor = primaryNoteID,
           let startIndex = notes.firstIndex(where: { $0.id == anchor }),
           let endIndex = notes.firstIndex(where: { $0.id == noteID }) {
            let range = startIndex <= endIndex ? startIndex...endIndex : endIndex...startIndex
            selectedNoteIDs = Set(notes[range].map(\.id))
            return
        }
        if command {
            if selectedNoteIDs.contains(noteID) {
                selectedNoteIDs.remove(noteID)
                if primaryNoteID == noteID {
                    primaryNoteID = selectedNoteIDs.first
                }
            } else {
                selectedNoteIDs.insert(noteID)
                primaryNoteID = noteID
            }
            return
        }
        selectSingle(noteID: noteID)
    }

    func selectAllVisible() {
        selectedNoteIDs = Set(notes.map(\.id))
    }

    func clearSelection() {
        selectedNoteIDs = []
        primaryNoteID = nil
    }

    // MARK: Actions (single or batch)

    func trash(_ note: Note) { try? repository.moveToTrash(note) }
    func restore(_ note: Note) { try? repository.restore(note) }
    func deletePermanently(_ note: Note) { try? repository.deletePermanently(note) }
    func setPinned(_ note: Note, _ pinned: Bool) { try? repository.setPinned(note, pinned) }
    func togglePin(_ note: Note) { setPinned(note, !note.isPinned) }
    func updateContent(_ note: Note, to text: String) { try? repository.updateContent(note, to: text) }

    func copyToPasteboard(_ note: Note) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(note.content, forType: .string)
    }

    var selectedNotes: [Note] {
        notes.filter { selectedNoteIDs.contains($0.id) }
    }

    func note(withID id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func trashSelected() {
        selectedNotes.forEach { try? repository.moveToTrash($0) }
    }

    func restoreSelected() {
        selectedNotes.forEach { try? repository.restore($0) }
    }

    func setPinnedSelected(_ pinned: Bool) {
        selectedNotes.forEach { try? repository.setPinned($0, pinned) }
    }

    func deleteSelectedPermanently() {
        selectedNotes.forEach { try? repository.deletePermanently($0) }
    }

    /// Copies every selected note, separated by blank lines.
    func copySelectedToPasteboard() {
        let combined = selectedNotes.map(\.content).joined(separator: "\n\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(combined, forType: .string)
    }

    /// Merges all selected notes into one new note (newest-last order) and
    /// moves the originals to trash. Returns true when a merge happened.
    @discardableResult
    func mergeSelected() -> Bool {
        let selected = selectedNotes
        guard selected.count > 1 else { return false }
        let combined = selected
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.content)
            .joined(separator: "\n\n· · ·\n\n")
        do {
            let merged = try noteService?.createManualNote()
            try repository.updateContent(merged ?? selected[0], to: combined)
            selected.forEach { try? repository.moveToTrash($0) }
            if let merged {
                refresh()
                selectSingle(noteID: merged.id)
            }
            return true
        } catch {
            Log.persistence.error("Merge failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    // MARK: Creation

    func createNewNote() {
        do {
            let note = try noteService?.createManualNote()
            if let note {
                refresh()
                selectSingle(noteID: note.id)
            }
            editorFocusRequest += 1
        } catch {
            Log.persistence.error("Could not create note: \(String(describing: error), privacy: .public)")
        }
    }

    /// Drop target: creates a note from text or a dropped file's content.
    func createNote(from rawText: String) {
        guard NoteContentFormatter.normalizedCaptureText(rawText) != nil else { return }
        do {
            let note = try noteService?.createManualNote()
            if let note {
                try repository.updateContent(note, to: NoteContentFormatter.normalizedCaptureText(rawText) ?? "")
                refresh()
                selectSingle(noteID: note.id)
            }
        } catch {
            Log.persistence.error("Drop-create failed: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: Search

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

    func clearSearch() {
        searchText = ""
    }
}
