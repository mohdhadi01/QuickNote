import Foundation

/// Content normalization and visual derivation (spec §14, §20, §22).
///
/// Stored content is never modified to produce titles; everything here is
/// presentational or validation-only.
enum NoteContentFormatter {
    /// Trims leading/trailing whitespace and newlines. Returns nil when the
    /// result is empty (used to reject empty captures). Internal whitespace
    /// is preserved untouched.
    static func normalizedCaptureText(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The first meaningful (non-empty) line, used as the visual title.
    static func displayTitle(for content: String) -> String {
        let firstLine = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty })
        return firstLine ?? "Untitled"
    }

    /// Everything after the title line, whitespace-collapsed for display only.
    static func displayPreview(for content: String) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard let firstIndex = lines.firstIndex(where: { !$0.isEmpty }) else { return "" }

        var previewLines = Array(lines[(firstIndex + 1)...])
        if previewLines.isEmpty {
            // The note is a single line; preview nothing.
            return ""
        }
        // Skip a single blank separator line after the title if present.
        if previewLines.first?.isEmpty == true { previewLines.removeFirst() }
        return previewLines
            .joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// True when the haystack contains the (case-insensitive) needle.
    static func matches(_ haystack: String, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return haystack.localizedCaseInsensitiveContains(trimmed)
    }
}
