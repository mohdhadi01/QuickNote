import SwiftUI

/// The main notes window: sidebar → list → editor (spec §18).
struct MainNotesView: View {
    @ObservedObject var viewModel: NotesViewModel
    /// Non-nil when the store was recovered from a failure this launch.
    let persistenceRecovery: PersistenceRecoveryInfo?
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $viewModel.filter)
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 260)
        } content: {
            NotesListView(viewModel: viewModel)
        } detail: {
            detail
        }
        .frame(
            minWidth: DesignTokens.MainWindow.minWidth,
            minHeight: DesignTokens.MainWindow.minHeight
        )
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    @ViewBuilder
    private var detail: some View {
        VStack(spacing: 0) {
            if let recovery = persistenceRecovery {
                recoveryBanner(recovery)
            }
            if let note = viewModel.selectedNote {
                NoteEditorView(note: note, viewModel: viewModel)
            } else {
                EmptyStateView(symbolName: "text.page", title: "Select a note to view and edit it.")
            }
        }
    }

    private func recoveryBanner(_ info: PersistenceRecoveryInfo) -> some View {
        HStack(spacing: DesignTokens.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(info.userFacingMessage)
                .font(.system(size: 12))
                .lineLimit(3)
            Spacer()
        }
        .padding(DesignTokens.Spacing.m)
        .background(Color.yellow.opacity(0.12))
    }
}
