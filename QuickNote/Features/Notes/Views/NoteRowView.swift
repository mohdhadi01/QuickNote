import SwiftUI

/// A single note row: derived title, preview, relative timestamp, pin badge.
/// The selected row gets the signature gradient pill.
struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: DesignTokens.Spacing.s) {
                Text(NoteContentFormatter.displayTitle(for: note.content))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : AuroraPalette.primaryText)
                    .lineLimit(1)
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.9) : AuroraPalette.accentCyan)
                        .accessibilityLabel("Pinned")
                }
                Spacer(minLength: 0)
            }
            if !NoteContentFormatter.displayPreview(for: note.content).isEmpty {
                Text(NoteContentFormatter.displayPreview(for: note.content))
                    .font(.system(size: 11.5))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.78) : AuroraPalette.secondaryText)
                    .lineLimit(2)
            }
            Text(NoteDateFormatting.listTimestamp(for: note.createdAt))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(isSelected ? Color.white.opacity(0.66) : AuroraPalette.tertiaryText)
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
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var rowFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(AuroraPalette.accentGradient)
        }
        if isHovered {
            return AnyShapeStyle(Color.white.opacity(0.07))
        }
        return AnyShapeStyle(Color.white.opacity(0.03))
    }

    private var accessibilityText: String {
        let title = NoteContentFormatter.displayTitle(for: note.content)
        let date = NoteDateFormatting.listTimestamp(for: note.createdAt)
        return note.isPinned ? "Pinned note: \(title), \(date)" : "Note: \(title), \(date)"
    }
}
