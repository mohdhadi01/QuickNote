import SwiftUI

/// Document-like note editor with automatic, debounced persistence (spec §21),
/// glass header with metadata, and a subtle footer with live counts.
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
                .overlay(Color.white.opacity(0.08))
            editor
            Divider()
                .overlay(Color.white.opacity(0.08))
            footer
        }
        .id(note.id)
        .onAppear {
            text = note.content
            if viewModel.editorFocusRequest > 0 { editorFocused = true }
        }
        .onChange(of: text) { _, newValue in
            scheduleSave(newValue)
        }
        .onChange(of: viewModel.editorFocusRequest) { _, _ in
            editorFocused = true
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
            VStack(alignment: .leading, spacing: 3) {
                Text(NoteContentFormatter.displayTitle(for: note.content))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AuroraPalette.primaryText)
                    .lineLimit(1)
                HStack(spacing: DesignTokens.Spacing.s) {
                    if isInTrash {
                        Text("In Trash")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(.orange)
                    } else if let sourceName = note.sourceApplicationName {
                        Text("Captured from \(sourceName)")
                            .font(.system(size: 10.5))
                            .foregroundStyle(AuroraPalette.tertiaryText)
                    }
                    Text("Created \(NoteDateFormatting.listTimestamp(for: note.createdAt))")
                        .font(.system(size: 10.5))
                        .foregroundStyle(AuroraPalette.tertiaryText)
                }
                .lineLimit(1)
            }
            Spacer(minLength: DesignTokens.Spacing.m)

            if isInTrash {
                Button("Restore") {
                    viewModel.restore(note)
                }
                .buttonStyle(GradientProminentButtonStyle())
                .accessibilityIdentifier("restore-note-button")
                Button("Delete Permanently…", role: .destructive) {
                    notePendingPermanentDelete = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.9))
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
            } else {
                Button {
                    viewModel.togglePin(note)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(GlassIconButtonStyle(isActive: note.isPinned))
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .help("Pin (⌘⇧P)")
                .accessibilityLabel(note.isPinned ? "Unpin note" : "Pin note")
                .accessibilityIdentifier("pin-toggle-button")

                Button {
                    viewModel.trash(note)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(GlassIconButtonStyle())
                .keyboardShortcut(.delete, modifiers: .command)
                .help("Move to Trash (⌘⌫)")
                .accessibilityLabel("Move note to trash")
                .accessibilityIdentifier("trash-note-button")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.m)
    }

    // MARK: Editor

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 15.5))
                .lineSpacing(5)
                .foregroundStyle(AuroraPalette.primaryText.opacity(0.92))
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.l)
                .accessibilityIdentifier("note-editor")
                .accessibilityLabel("Note content")

            if text.isEmpty {
                Text("Note")
                    .font(.system(size: 15.5))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                    .allowsHitTesting(false)
                    .padding(.leading, DesignTokens.Spacing.xl + 5)
                    .padding(.top, DesignTokens.Spacing.l + 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Text(metadataLine)
                .font(.system(size: 10.5))
                .foregroundStyle(AuroraPalette.tertiaryText)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.s + 2)
    }

    private var metadataLine: String {
        var parts: [String] = []
        let words = text.split(whereSeparator: \.isWhitespace).count
        parts.append("\(words) word\(words == 1 ? "" : "s")")
        parts.append("\(text.count) character\(text.count == 1 ? "" : "s")")
        if abs(note.updatedAt.timeIntervalSince(note.createdAt)) > 1 {
            parts.append("Edited \(NoteDateFormatting.listTimestamp(for: note.updatedAt))")
        }
        return parts.joined(separator: "   ·   ")
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
