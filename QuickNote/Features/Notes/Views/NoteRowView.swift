import SwiftUI

/// A single note row: derived title, preview, relative timestamp (spec §20).
struct NoteRowView: View {
    let note: Note
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Text(NoteContentFormatter.displayTitle(for: note.content))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
            }
            if !NoteContentFormatter.displayPreview(for: note.content).isEmpty {
                Text(NoteContentFormatter.displayPreview(for: note.content))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(NoteDateFormatting.listTimestamp(for: note.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.s)
                    .fill(Color.primary.opacity(0.035))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let title = NoteContentFormatter.displayTitle(for: note.content)
        let date = NoteDateFormatting.listTimestamp(for: note.createdAt)
        return note.isPinned ? "Pinned note: \(title), \(date)" : "Note: \(title), \(date)"
    }
}
