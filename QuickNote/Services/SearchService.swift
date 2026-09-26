import Foundation

/// In-memory note filtering for the search field (spec §22). Repository
/// fetching is debounced by the owning view model; this service applies the
/// final text match.
@MainActor
final class SearchService {
    /// Filters notes by the query, matching content (which includes the
    /// derived title) case-insensitively. An empty query passes everything.
    func filter(_ notes: [Note], query: String) -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return notes }
        return notes.filter {
            NoteContentFormatter.matches($0.content, query: trimmed)
        }
    }
}
