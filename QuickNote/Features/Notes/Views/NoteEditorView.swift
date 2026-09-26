import SwiftUI

/// Document-like note editor with automatic, debounced persistence (spec §21).
struct NoteEditorView: View {
    let note: Note
    @ObservedObject var viewModel: NotesViewModel

    @State private var text: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var notePendingPermanentDelete = false
    @FocusState private var editorFocused: Bool

    private var isInTrash: Bool { note.deletedAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            editor
        }
        .id(note.id)
        .onAppear { text = note.content }
        .onChange(of: text) { _, newValue in
            scheduleSave(newValue)
        }
        .onDisappear {
            flushSave()
        }
        .confirmationDialog(
            "Delete this note permanently? This cannot be undone.",
            isPresented: $notePendingPermanentDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                viewModel.deletePermanently(note)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timestampLine)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if isInTrash {
                    Text("In Trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                } else if let sourceName = note.sourceApplicationName {
                    Text("Captured from \(sourceName)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: DesignTokens.Spacing.m)

            if isInTrash {
                Button("Restore") {
                    viewModel.restore(note)
                }
                .accessibilityIdentifier("restore-note-button")
                Button("Delete Permanently…", role: .destructive) {
                    notePendingPermanentDelete = true
                }
            } else {
                Button {
                    viewModel.togglePin(note)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                }
                .help(note.isPinned ? "Unpin" : "Pin")
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityLabel(note.isPinned ? "Unpin note" : "Pin note")
                .accessibilityIdentifier("pin-toggle-button")

                Button {
                    viewModel.trash(note)
                } label: {
                    Image(systemName: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .help("Move to Trash")
                .accessibilityLabel("Move note to trash")
                .accessibilityIdentifier("trash-note-button")
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.m)
    }

    private var timestampLine: String {
        var parts = ["Created \(NoteDateFormatting.fullTimestamp(for: note.createdAt))"]
        if abs(note.updatedAt.timeIntervalSince(note.createdAt)) > 1 {
            parts.append("Updated \(NoteDateFormatting.fullTimestamp(for: note.updatedAt))")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Editor

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(Typography.editorBody)
                .focused($editorFocused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.l)
                .accessibilityIdentifier("note-editor")
                .accessibilityLabel("Note content")

            if text.isEmpty {
                Text("Note")
                    .font(Typography.editorBody)
                    .foregroundStyle(.tertiary)
                    .allowsHitTesting(false)
                    .padding(.leading, DesignTokens.Spacing.xl + 5)
                    .padding(.top, DesignTokens.Spacing.l + 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Autosave

    private func scheduleSave(_ newValue: String) {
        saveTask?.cancel()
        saveTask = Task { [weak viewModel] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            viewModel?.updateContent(note, to: newValue)
        }
    }

    private func flushSave() {
        saveTask?.cancel()
        saveTask = nil
        if text != note.content {
            viewModel.updateContent(note, to: text)
        }
    }
}
