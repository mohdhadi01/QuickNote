import SwiftUI

/// The main notes window: aurora backdrop, glass sidebar → list → editor.
/// Custom chrome (hidden title bar) with the app's own layout.
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
        if let note = viewModel.selectedNote {
            NoteEditorView(note: note, viewModel: viewModel)
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
