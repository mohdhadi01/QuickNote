import SwiftUI
import AppKit

/// Quick-note editor: one flowing surface where the first line reads as the
/// heading (styled visually only), with a minimal floating action bar — no
/// separate title chrome, because quick captures don't have titles.
/// Autosaves with a short debounce (spec §21).
struct NoteEditorView: View {
    let note: Note
    @ObservedObject var viewModel: NotesViewModel

    @State private var text: String = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var notePendingPermanentDelete = false
    @State private var editorTextView: NSTextView?

    private var isInTrash: Bool { note.deletedAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                editor
                actionBar
            }
            footer
        }
        .id(note.id)
        .onAppear {
            text = note.content
            if viewModel.editorFocusRequest > 0 {
                focusEditor()
            }
        }
        .onChange(of: text) { _, newValue in
            scheduleSave(newValue)
        }
        .onChange(of: viewModel.editorFocusRequest) { _, _ in
            focusEditor()
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

    // MARK: Editor surface

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            FlowingTextView(
                text: $text,
                onEdit: { _ in },
                onViewReady: { textView in
                    editorTextView = textView
                }
            )
            .padding(.horizontal, DesignTokens.Spacing.xl + 8)
            .padding(.top, 56)
            .padding(.bottom, DesignTokens.Spacing.m)
            .accessibilityIdentifier("note-editor")
            .accessibilityLabel("Note content")

            if text.isEmpty {
                Text("Start typing…")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                    .allowsHitTesting(false)
                    .padding(.leading, DesignTokens.Spacing.xl + 12)
                    .padding(.top, 58)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture {
            focusEditor()
        }
    }

    /// Slim glass bar: date on the left, pin/trash on the right.
    private var actionBar: some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            if isInTrash {
                Text("In Trash")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.orange)
            } else if let sourceName = note.sourceApplicationName {
                Text("Captured from \(sourceName)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(AuroraPalette.tertiaryText)
                    .lineLimit(1)
            }
            Spacer()
            if isInTrash {
                Button("Restore") {
                    viewModel.restore(note)
                }
                .buttonStyle(GradientProminentButtonStyle())
                .accessibilityIdentifier("restore-note-button")
                Button("Delete Permanently…", role: .destructive) {
                    notePendingPermanentDelete = true
                }
                .font(.system(size: 12, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.9))
                .padding(.horizontal, 6)
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
        .padding(.leading, DesignTokens.Spacing.xl)
        .padding(.trailing, DesignTokens.Spacing.xl)
        .padding(.top, 12)
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
        .background(.ultraThinMaterial)
    }

    private var metadataLine: String {
        var parts: [String] = []
        let words = text.split(whereSeparator: \.isWhitespace).count
        parts.append("\(words) word\(words == 1 ? "" : "s")")
        parts.append("\(text.count) character\(text.count == 1 ? "" : "s")")
        parts.append("Created \(NoteDateFormatting.listTimestamp(for: note.createdAt))")
        if abs(note.updatedAt.timeIntervalSince(note.createdAt)) > 1 {
            parts.append("Edited \(NoteDateFormatting.listTimestamp(for: note.updatedAt))")
        }
        return parts.joined(separator: "   ·   ")
    }

    // MARK: Autosave & focus

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

    private func focusEditor() {
        DispatchQueue.main.async { [weak editorTextView] in
            if let window = editorTextView?.window {
                window.makeFirstResponder(editorTextView)
            }
        }
    }
}
