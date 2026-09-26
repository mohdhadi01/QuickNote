import Foundation
import SwiftData

/// All note persistence flows through this boundary (spec §16). Views and
/// view models must not touch SwiftData directly.
@MainActor
protocol NoteRepositoryProtocol: AnyObject {
    func create(content: String, sourceApplicationName: String?, sourceApplicationBundleID: String?) throws -> Note
    func updateContent(_ note: Note, to content: String) throws
    func setPinned(_ note: Note, _ pinned: Bool) throws
    func moveToTrash(_ note: Note) throws
    func restore(_ note: Note) throws
    func deletePermanently(_ note: Note) throws
    func fetchNotes(in filter: NoteFilter) throws -> [Note]
    func search(_ text: String) throws -> [Note]
}

@MainActor
final class NoteRepository: NoteRepositoryProtocol {
    /// Posted after every successful mutation so observers can refetch.
    static let storeDidChange = Notification.Name("QuickNote.storeDidChange")

    private let container: ModelContainer
    /// Injectable clock for deterministic tests.
    var now: () -> Date

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer, now: @escaping () -> Date = { Date() }) {
        self.container = container
        self.now = now
    }

    // MARK: Mutations

    func create(content: String, sourceApplicationName: String? = nil, sourceApplicationBundleID: String? = nil) throws -> Note {
        let note = Note(
            content: content,
            createdAt: now(),
            sourceApplicationName: sourceApplicationName,
            sourceApplicationBundleID: sourceApplicationBundleID
        )
        context.insert(note)
        try commit()
        Log.persistence.info("Created note \(note.id.uuidString, privacy: .public)")
        return note
    }

    func updateContent(_ note: Note, to content: String) throws {
        guard note.content != content else { return }
        note.content = content
        note.updatedAt = now()
        try commit()
    }

    func setPinned(_ note: Note, _ pinned: Bool) throws {
        guard note.isPinned != pinned else { return }
        note.isPinned = pinned
        note.updatedAt = now()
        try commit()
    }

    func moveToTrash(_ note: Note) throws {
        guard note.deletedAt == nil else { return }
        note.deletedAt = now()
        note.updatedAt = now()
        try commit()
        Log.persistence.info("Moved note \(note.id.uuidString, privacy: .public) to trash")
    }

    func restore(_ note: Note) throws {
        guard note.deletedAt != nil else { return }
        note.deletedAt = nil
        note.updatedAt = now()
        try commit()
    }

    func deletePermanently(_ note: Note) throws {
        context.delete(note)
        try commit()
        Log.persistence.info("Permanently deleted note")
    }

    // MARK: Queries

    func fetchNotes(in filter: NoteFilter) throws -> [Note] {
        var descriptor = FetchDescriptor<Note>(
            predicate: Self.predicate(for: filter, now: now()),
            sortBy: [SortDescriptor(\Note.createdAt, order: .reverse)]
        )
        // Filtered sections stay small; a generous batch keeps scroll smooth.
        descriptor.fetchLimit = 5000
        return try context.fetch(descriptor)
    }

    /// Local, case-insensitive search across note content of non-trashed
    /// notes (spec §22). The derived title is part of content, so searching
    /// content covers it.
    func search(_ text: String) throws -> [Note] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try fetchNotes(in: .all) }
        let notes = try fetchNotes(in: .all)
        return notes.filter { NoteContentFormatter.matches($0.content, query: query) }
    }

    private static func predicate(for filter: NoteFilter, now: Date) -> Predicate<Note> {
        switch filter {
        case .inbox:
            return #Predicate<Note> { $0.deletedAt == nil && !$0.isPinned }
        case .all:
            return #Predicate<Note> { $0.deletedAt == nil }
        case .pinned:
            return #Predicate<Note> { $0.deletedAt == nil && $0.isPinned }
        case .today:
            let range = NoteFilter.todayRange(now: now)
            let start = range.start
            let end = range.end
            return #Predicate<Note> { $0.deletedAt == nil && $0.createdAt >= start && $0.createdAt < end }
        case .trash:
            return #Predicate<Note> { $0.deletedAt != nil }
        }
    }

    private func commit() throws {
        do {
            try context.save()
        } catch {
            Log.persistence.error("Context save failed: \(String(describing: error), privacy: .public)")
            throw error
        }
        NotificationCenter.default.post(name: Self.storeDidChange, object: nil)
    }
}
