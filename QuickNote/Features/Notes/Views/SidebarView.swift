import SwiftUI
import UniformTypeIdentifiers

/// Smoke-glass sidebar: app identity, section rows with counts, drop targets
/// for organizing notes (drag a note onto a section to move it).
struct SidebarView: View {
    @ObservedObject var viewModel: NotesViewModel

    private let columns: [(filter: NoteFilter, shortcut: String)] = [
        (.inbox, "1"), (.today, "2"), (.all, "3"), (.pinned, "4"), (.trash, "5"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.top, 42) // clears the traffic-light controls
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.bottom, DesignTokens.Spacing.xl)

            VStack(spacing: 4) {
                ForEach(columns.indices, id: \.self) { index in
                    sectionRow(columns[index].filter, shortcut: columns[index].shortcut)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.m)

            Spacer(minLength: 0)

            footer
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.bottom, DesignTokens.Spacing.l)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityLabel("Sections")
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("QuickNote")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                Text("Instant Notes")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AuroraPalette.tertiaryText)
            }
            Spacer()
        }
    }

    private func sectionRow(_ filter: NoteFilter, shortcut: String) -> some View {
        SectionRow(
            filter: filter,
            shortcut: shortcut,
            count: viewModel.counts[filter] ?? 0,
            isSelected: viewModel.filter == filter,
            isDropTarget: dropTargetFilter == filter,
            onSelect: {
                withAnimation(Motion.panelSpring) {
                    viewModel.filter = filter
                }
            },
            onDropTargeted: { hovering in
                dropTargetFilter = hovering ? filter : nil
            },
            onDrop: { handleDrop(providers: $0, filter: filter) }
        )
    }

    @State private var dropTargetFilter: NoteFilter?

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            GlassKeycap(label: "⌘1–5")
            Text("sections")
                .font(.system(size: 10.5))
                .foregroundStyle(AuroraPalette.tertiaryText)
            Spacer()
        }
        .accessibilityHidden(true)
    }

    // MARK: Drag & drop organizing

    /// Dragging a note onto a section applies that section's meaning to the
    /// current selection (the dragged row is part of it): Pinned pins, Trash
    /// trashes, Inbox unpins/restores, All/Today restores from trash.
    private func handleDrop(providers: [NSItemProvider], filter: NoteFilter) -> Bool {
        guard !viewModel.selectedNotes.isEmpty else { return false }
        let targets = viewModel.selectedNotes
        for note in targets {
            switch filter {
            case .pinned:
                viewModel.setPinned(note, true)
            case .inbox:
                viewModel.restore(note)
                viewModel.setPinned(note, false)
            case .all, .today:
                viewModel.restore(note)
            case .trash:
                viewModel.trash(note)
            }
        }
        return true
    }
}

/// One sidebar section row: icon tile, title, count, selection wash, and a
/// drop target ring when a dragged note hovers over it.
private struct SectionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let filter: NoteFilter
    let shortcut: String
    let count: Int
    let isSelected: Bool
    let isDropTarget: Bool
    let onSelect: () -> Void
    let onDropTargeted: (Bool) -> Void
    let onDrop: ([NSItemProvider]) -> Bool

    @State private var hovered = false

    var body: some View {
        Button {
            onSelect()
        } label: {
            rowLabel
        }
        .buttonStyle(.plain)
        .background(rowBackground)
        .overlay(selectionRing)
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onDrop(of: [.text], isTargeted: $hovered, perform: onDrop)
        .onChange(of: hovered) { _, newValue in
            onDropTargeted(newValue)
        }
        .overlay(dropRing)
        .accessibilityLabel("\(filter.title), \(count) notes")
        .accessibilityHint("Section ⌘\(shortcut)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var rowLabel: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            iconTile
            Text(filter.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? AuroraPalette.selectionText(for: colorScheme) : AuroraPalette.primaryText.opacity(0.82))
            Spacer()
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? AuroraPalette.selectionSecondaryText(for: colorScheme) : AuroraPalette.tertiaryText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(isSelected ? 0.18 : 0.05)))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        // Fill the sidebar width so the whole row is clickable, not just the text.
        .frame(maxWidth: .infinity, alignment: .leading)
        // Declared inside the label so the Spacer region is hit-testable too —
        // without this, clicks in the empty middle of the row fall through.
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(isSelected ? AnyShapeStyle(AuroraPalette.selectionFill(for: colorScheme)) : AnyShapeStyle(Color.clear))
    }

    private var selectionRing: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdge, lineWidth: 1)
            }
        }
    }

    private var dropRing: some View {
        Group {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(AuroraPalette.frost.opacity(0.7), lineWidth: 1.5)
            }
        }
    }

    private var iconTile: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                isSelected
                    ? AnyShapeStyle(AuroraPalette.selectionFill(for: colorScheme))
                    : AnyShapeStyle(Color.white.opacity(0.07))
            )
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: filter.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? AuroraPalette.selectionText(for: colorScheme) : AuroraPalette.secondaryText)
            )
    }
}
