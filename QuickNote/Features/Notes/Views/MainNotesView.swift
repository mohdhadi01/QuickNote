import SwiftUI

/// The main notes window: smoke-glass backdrop, sidebar → list → editor.
/// Custom chrome (hidden title bar) with the app's own layout. When several
/// notes are selected, the detail column shows batch actions.
struct MainNotesView: View {
    @ObservedObject var viewModel: NotesViewModel
    /// Non-nil when the store was recovered from a failure this launch.
    let persistenceRecovery: PersistenceRecoveryInfo?
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        ZStack {
            AuroraBackdrop()
                .ignoresSafeArea()

            HStack(spacing: 0) {
                SidebarView(viewModel: viewModel)
                    .frame(width: 218)
                GlassHairline()
                NotesListView(viewModel: viewModel)
                    .frame(width: 316)
                GlassHairline()
                detail
            }
            .preferredColorScheme(settings.appearanceMode.colorScheme)

            if let recovery = persistenceRecovery {
                recoveryBanner(recovery)
            }
        }
        .background(TransparentWindow())
        .frame(
            minWidth: DesignTokens.MainWindow.minWidth,
            minHeight: DesignTokens.MainWindow.minHeight
        )
    }

    @ViewBuilder
    private var detail: some View {
        // The parent-level .id resets the editor's state per note — fixing
        // stale body text when switching notes.
        if viewModel.selectedCount > 1 {
            MultiSelectionPanel(viewModel: viewModel)
        } else if let note = viewModel.selectedNote {
            NoteEditorView(note: note, viewModel: viewModel)
                .id(note.id)
        } else {
            EmptyStateView(
                symbolName: "text.page",
                title: "Select a note to view and edit it.",
                hint: "⌘N"
            )
        }
    }

    private func recoveryBanner(_ info: PersistenceRecoveryInfo) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(info.userFacingMessage)
                    .font(.system(size: 12))
                    .lineLimit(3)
                    .foregroundStyle(AuroraPalette.primaryText)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, DesignTokens.Spacing.m)
            .background(.ultraThinMaterial)
            Spacer()
        }
    }
}

/// Batch actions for a multi-selection.
private struct MultiSelectionPanel: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "square.on.square.dashed")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(AuroraPalette.silver)
                .frame(width: 58, height: 58)
                .glassInset(cornerRadius: 16)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("\(viewModel.selectedCount) notes selected")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                Text("Esc collapses back to one note")
                    .font(.system(size: 11))
                    .foregroundStyle(AuroraPalette.tertiaryText)
            }

            VStack(spacing: DesignTokens.Spacing.s) {
                batchButton("pin.fill", "Pin") { viewModel.setPinnedSelected(true) }
                batchButton("pin.slash", "Unpin") { viewModel.setPinnedSelected(false) }
                batchButton("doc.on.doc", "Copy All") { viewModel.copySelectedToPasteboard() }
                batchButton("arrow.triangle.merge", "Merge Into One Note") { viewModel.mergeSelected() }
                batchButton("trash", "Move to Trash", role: .destructive) { viewModel.trashSelected() }
            }
            .frame(width: 230)

            Spacer()
        }
        .padding(.top, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .confirmationDialog(
            "Delete \(viewModel.selectedCount) note\(viewModel.selectedCount == 1 ? "" : "s") permanently? This cannot be undone.",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                viewModel.deleteSelectedPermanently()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func batchButton(_ symbol: String, _ label: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.m) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(AuroraPalette.glassEdgeSoft, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red.opacity(0.9) : AuroraPalette.primaryText.opacity(0.85))
    }
}
