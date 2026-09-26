import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// The notes list column: glass search pill, section title, graphite "+",
/// multi-select rows (⌘/⇧ click), keyboard navigation, drop targets for
/// text and files, and batch context menus.
struct NotesListView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var notePendingPermanentDelete = false
    @State private var searchFocused = false
    @State private var router: MainWindowKeyboardRouter?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: $notePendingPermanentDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                viewModel.deleteSelectedPermanently()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { installKeyboardRouter() }
        .onDisappear { router?.remove() }
        .onChange(of: viewModel.searchFocusRequest) { _, _ in
            searchFocused = true
        }
    }

    private var deleteTitle: String {
        let count = viewModel.selectedNoteIDs.count
        return "Delete \(count) note\(count == 1 ? "" : "s") permanently? This cannot be undone."
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
                                .fill(AuroraPalette.inkGradient)
                                .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
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
                if viewModel.selectedCount > 1 {
                    Text("\(viewModel.selectedCount) selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AuroraPalette.secondaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.09)))
                }
                Spacer()
                Text("↑↓ navigate · ⏎ edit · ⇧⌘ click multi-select")
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
                        dropHint
                        EmptyStateView(
                            symbolName: isSearching ? "magnifyingglass" : viewModel.filter.symbolName,
                            title: isSearching ? "No matching notes." : viewModel.filter.emptyStateTitle,
                            hint: isSearching ? nil : "⌘N"
                        )
                        .padding(.top, DesignTokens.Spacing.xxxl)
                    } else {
                        ForEach(viewModel.notes) { note in
                            NoteRowView(
                                note: note,
                                isSelected: viewModel.selectedNoteIDs.contains(note.id),
                                isPrimary: viewModel.primaryNoteID == note.id,
                                selectionIds: viewModel.selectedNoteIDs
                            )
                            .id(note.id)
                            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .onTapGesture(count: 2) {
                                viewModel.selectSingle(noteID: note.id)
                                viewModel.editorFocusRequest += 1
                            }
                            .simultaneousGesture(
                                TapGesture().modifiers(.command).onEnded {
                                    viewModel.handleClick(noteID: note.id, command: true, shift: false)
                                }
                            )
                            .simultaneousGesture(
                                TapGesture().modifiers(.shift).onEnded {
                                    viewModel.handleClick(noteID: note.id, command: false, shift: true)
                                }
                            )
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    viewModel.handleClick(noteID: note.id, command: false, shift: false)
                                }
                            )
                            .contextMenu { contextMenu(for: note) }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.m)
                .padding(.bottom, DesignTokens.Spacing.l)
            }
            .onChange(of: viewModel.primaryNoteID) { _, newID in
                if let newID {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
            .overlay {
                if isDropTargeted && viewModel.notes.isEmpty {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AuroraPalette.frost.opacity(0.6), lineWidth: 1.5)
                        .padding(DesignTokens.Spacing.l)
                }
            }
            .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }
        }
        .accessibilityIdentifier("notes-list")
    }

    @ViewBuilder
    private var dropHint: some View {
        if !isSearching {
            HStack(spacing: DesignTokens.Spacing.s) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                Text("Drop text or .txt files here to capture")
                    .font(.system(size: 10.5))
                    .foregroundStyle(AuroraPalette.tertiaryText)
            }
            .padding(.top, DesignTokens.Spacing.xl)
        }
    }

    // MARK: Drops

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                handled = true
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    guard let string = object as? String else { return }
                    Task { @MainActor in
                        viewModel.createNote(from: string)
                    }
                }
            }
        }
        return handled
    }

    // MARK: Context menus

    @ViewBuilder
    private func contextMenu(for note: Note) -> some View {
        let batch = viewModel.selectedNoteIDs.contains(note.id) && viewModel.selectedCount > 1
        if batch {
            let allTrashed = viewModel.selectedNotes.allSatisfy { $0.deletedAt != nil }
            let anyPinned = viewModel.selectedNotes.contains { $0.isPinned }

            if allTrashed {
                Button("Restore \(viewModel.selectedCount) Notes") { viewModel.restoreSelected() }
                Divider()
                Button("Delete Permanently…", role: .destructive) {
                    notePendingPermanentDelete = true
                }
            } else {
                Button(anyPinned ? "Unpin \(viewModel.selectedCount) Notes" : "Pin \(viewModel.selectedCount) Notes") {
                    viewModel.setPinnedSelected(!anyPinned)
                }
                Divider()
                Button("Copy \(viewModel.selectedCount) Notes") { viewModel.copySelectedToPasteboard() }
                Button("Merge Into One Note") { viewModel.mergeSelected() }
                Divider()
                Button("Move \(viewModel.selectedCount) to Trash", role: .destructive) {
                    viewModel.trashSelected()
                }
            }
        } else if note.deletedAt != nil {
            Button("Restore") { viewModel.restore(note) }
            Divider()
            Button("Copy") { viewModel.copyToPasteboard(note) }
            Divider()
            Button("Delete Permanently…", role: .destructive) {
                viewModel.selectSingle(noteID: note.id)
                notePendingPermanentDelete = true
            }
        } else {
            Button(note.isPinned ? "Unpin" : "Pin") { viewModel.togglePin(note) }
            Divider()
            Button("Copy") { viewModel.copyToPasteboard(note) }
            Divider()
            Button("Move to Trash", role: .destructive) { viewModel.trash(note) }
        }
    }

    // MARK: Actions

    private func selectFirstSearchResult() {
        if let first = viewModel.notes.first {
            viewModel.selectSingle(noteID: first.id)
        }
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
            onFind: { viewModel.searchFocusRequest += 1 },
            onSelectAll: { viewModel.selectAllVisible() }
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
        if viewModel.selectedCount > 1 {
            if let primary = viewModel.primaryNoteID {
                viewModel.selectSingle(noteID: primary)
            }
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
