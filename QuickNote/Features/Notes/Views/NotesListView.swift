import SwiftUI
import AppKit

/// The notes list column: glass search pill, section title, gradient "+" and
/// a custom floating-row list with full keyboard navigation.
struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var notePendingPermanentDelete: Note?
    @State private var searchFocused = false
    @State private var router: MainWindowKeyboardRouter?

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
        .confirmationDialog(
            "Delete this note permanently? This cannot be undone.",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                if let note = notePendingPermanentDelete {
                    viewModel.deletePermanently(note)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { installKeyboardRouter() }
        .onDisappear { router?.remove() }
        .onChange(of: viewModel.searchFocusRequest) { _, _ in
            searchFocused = true
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
            HStack(spacing: DesignTokens.Spacing.m) {
                GlassSearchField(
                    text: $viewModel.searchText,
                    isFocused: $searchFocused,
                    onRequestEditorFocus: selectFirstSearchResult
                )

                Button {
                    viewModel.createNewNote()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AuroraPalette.accentGradient)
                                .shadow(color: AuroraPalette.accentIndigo.opacity(0.45), radius: 8, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("n", modifiers: .command)
                .help("New Note (⌘N)")
                .accessibilityLabel("New Note")
                .accessibilityIdentifier("new-note-button")
            }

            HStack(spacing: DesignTokens.Spacing.s) {
                Text(listTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                if isSearching {
                    Text("\(viewModel.notes.count) result\(viewModel.notes.count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                }
                Spacer()
                Text("↑↓ to navigate · ⏎ to edit")
                    .font(.system(size: 10))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.l)
        .padding(.top, 42)
        .padding(.bottom, DesignTokens.Spacing.m)
    }

    private var isSearching: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var listTitle: String {
        isSearching ? "Search" : viewModel.filter.title
    }

    // MARK: List

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if viewModel.notes.isEmpty {
                        EmptyStateView(
                            symbolName: isSearching ? "magnifyingglass" : viewModel.filter.symbolName,
                            title: isSearching ? "No matching notes." : viewModel.filter.emptyStateTitle
                        )
                        .padding(.top, DesignTokens.Spacing.xxxl)
                    } else {
                        ForEach(viewModel.notes) { note in
                            NoteRowView(note: note, isSelected: note.id == viewModel.selectedNoteID)
                                .id(note.id)
                                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .onTapGesture { viewModel.selectedNoteID = note.id }
                                .contextMenu { contextMenu(for: note) }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.m)
                .padding(.bottom, DesignTokens.Spacing.l)
            }
            .onChange(of: viewModel.selectedNoteID) { _, newID in
                if let newID {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
        .accessibilityIdentifier("notes-list")
    }

    // MARK: Context menus

    @ViewBuilder
    private func contextMenu(for note: Note) -> some View {
        if note.deletedAt != nil {
            Button("Restore") { viewModel.restore(note) }
            Button("Delete Permanently…", role: .destructive) {
                notePendingPermanentDelete = note
            }
        } else {
            Button(note.isPinned ? "Unpin" : "Pin") { viewModel.togglePin(note) }
            Divider()
            Button("Copy") { viewModel.copyToPasteboard(note) }
            Divider()
            Button("Move to Trash", role: .destructive) { viewModel.trash(note) }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { notePendingPermanentDelete != nil },
            set: { if !$0 { notePendingPermanentDelete = nil } }
        )
    }

    // MARK: Actions

    private func selectFirstSearchResult() {
        viewModel.selectedNoteID = viewModel.notes.first?.id
        viewModel.editorFocusRequest += 1
    }

    // MARK: Keyboard router

    private func installKeyboardRouter() {
        guard router == nil else { return }
        let installed = MainWindowKeyboardRouter(
            onArrow: { viewModel.moveSelection($0) },
            onReturn: { viewModel.editorFocusRequest += 1 },
            onEscape: { handleEscape() },
            onSection: { index in
                let filters = NoteFilter.allCases
                if filters.indices.contains(index) {
                    withAnimation(Motion.panelSpring) { viewModel.filter = filters[index] }
                }
            },
            onFind: { viewModel.searchFocusRequest += 1 }
        )
        installed.install(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first)
        router = installed
    }

    private func handleEscape() -> Bool {
        if !viewModel.searchText.isEmpty {
            viewModel.clearSearch()
            return true
        }
        if searchFocused {
            searchFocused = false
            return true
        }
        // Leave the editor, back to the list.
        if viewModel.selectedNote != nil {
            NSApp.keyWindow?.makeFirstResponder(nil)
            return true
        }
        return false
    }
}
