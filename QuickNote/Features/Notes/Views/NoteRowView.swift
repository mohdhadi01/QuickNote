import SwiftUI
import UniformTypeIdentifiers

/// Drag payload carrying a note's identity (for in-app section drops) plus
/// its text (for dragging into other apps).
enum NoteDragType {
    static let identifier = "com.quicknote.note"
}

/// A single note row: derived title, preview, timestamp, pin badge. Selected
/// rows get a quiet white-glass wash. Draggable as text.
struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    let isPrimary: Bool
    let selectionIds: Set<UUID>
    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: DesignTokens.Spacing.s) {
                Text(NoteContentFormatter.displayTitle(for: note.content))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AuroraPalette.selectionText(for: colorScheme))
                    .opacity(isSelected ? 1.0 : 0.9)
                    .lineLimit(1)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(AuroraPalette.silver)
                        .accessibilityLabel("Pinned")
                }
                Spacer(minLength: 0)
            }
            if !NoteContentFormatter.displayPreview(for: note.content).isEmpty {
                Text(NoteContentFormatter.displayPreview(for: note.content))
                    .font(.system(size: 11.5))
                    .foregroundStyle(
                        isSelected ? AuroraPalette.selectionSecondaryText(for: colorScheme) : AuroraPalette.secondaryText
                    )
                    .lineLimit(2)
            }
            Text(NoteDateFormatting.listTimestamp(for: note.createdAt))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(AuroraPalette.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(rowFill)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdge, lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onHover { isHovered = $0 }
        .onDrag {
            // Dragging a row hands its content to any app; section drops in
            // our own sidebar act on the current selection.
            NSItemProvider(object: note.content as NSString)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var rowFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(AuroraPalette.selectionFill(for: colorScheme))
        }
        if isHovered {
            return AnyShapeStyle(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.035)
            )
        }
        return AnyShapeStyle(
            colorScheme == .dark
                ? Color.white.opacity(0.03)
                : Color.black.opacity(0.018)
        )
    }

    private var accessibilityText: String {
        let title = NoteContentFormatter.displayTitle(for: note.content)
        let date = NoteDateFormatting.listTimestamp(for: note.createdAt)
        return note.isPinned ? "Pinned note: \(title), \(date)" : "Note: \(title), \(date)"
    }
}
