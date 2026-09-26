import SwiftUI

/// The notes list column with search, empty states, and context menus
/// (spec §20, §22, §46, §47).
struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var notePendingPermanentDelete: Note?

    var body: some View {
        Group {
            if viewModel.notes.isEmpty {
                EmptyStateView(
                    symbolName: viewModel.searchText.isEmpty ? viewModel.filter.symbolName : "magnifyingglass",
                    title: viewModel.searchText.isEmpty
                        ? viewModel.filter.emptyStateTitle
                        : "No matching notes."
                )
            } else {
                list
            }
        }
        .navigationTitle(navigationTitle)
        .navigationSubtitle(navigationSubtitle)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.createNewNote()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Note")
                .accessibilityLabel("New Note")
                .accessibilityIdentifier("new-note-button")
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .toolbar,
            prompt: "Search Notes"
        )
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
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { notePendingPermanentDelete != nil },
            set: { if !$0 { notePendingPermanentDelete = nil } }
        )
    }

    private var list: some View {
        List(selection: $viewModel.selectedNoteID) {
            ForEach(viewModel.notes) { note in
                NoteRowView(note: note)
                    .tag(note.id)
                    .contextMenu { contextMenu(for: note) }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: false))
        .accessibilityIdentifier("notes-list")
    }

    private var navigationTitle: String {
        viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty
            ? viewModel.filter.title
            : "Search"
    }

    private var navigationSubtitle: String {
        let count = viewModel.notes.count
        if !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(count) result\(count == 1 ? "" : "s")"
        }
        return ""
    }

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
}
