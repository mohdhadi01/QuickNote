import AppKit
import SwiftUI

/// NSTextView subclass with quick-capture key semantics (spec §13):
/// - Return (without Shift) saves; ⌘Return also saves.
/// - Shift+Return inserts a newline.
/// - Escape cancels.
/// All other keys fall through to standard, document-like text editing
/// (undo/redo, paste, select all).
final class CaptureTextViewImpl: NSTextView {
    var onReturn: (() -> Bool)?
    var onEscape: (() -> Bool)?

    override func keyDown(with event: NSEvent) {
        let modifiers = ModifierSet.from(event.modifierFlags)
        let keyCode = UInt32(event.keyCode)

        switch keyCode {
        case VirtualKey.returnKey:
            if modifiers.contains(.shift) {
                super.keyDown(with: event)
            } else if onReturn?() == true {
                return
            } else {
                super.keyDown(with: event)
            }
        case VirtualKey.escape:
            if onEscape?() == true { return }
            super.keyDown(with: event)
        default:
            super.keyDown(with: event)
        }
    }
}

/// NSViewRepresentable bridging the capture NSTextView into SwiftUI.
struct CaptureTextView: NSViewRepresentable {
    @Binding var text: String
    /// Called with the new text and the content height after edits.
    let onEdit: (String, CGFloat) -> Void
    let onReturn: () -> Bool
    let onEscape: () -> Bool
    let onViewReady: (CaptureTextViewImpl) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = CaptureTextViewImpl()
        configure(textView)
        textView.delegate = context.coordinator
        textView.onReturn = onReturn
        textView.onEscape = onEscape

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView
        onViewReady(textView)
        DispatchQueue.main.async { [weak coordinator = context.coordinator] in
            coordinator?.reportHeight()
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        textView.onReturn = onReturn
        textView.onEscape = onEscape
        if textView.string != text {
            textView.string = text
            context.coordinator.reportHeight()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func configure(_ textView: CaptureTextViewImpl) {
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.usesInspectorBar = false
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 4
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.font = NSFont.systemFont(ofSize: 17)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.focusRingType = .none
        textView.isContinuousSpellCheckingEnabled = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: CaptureTextView
        weak var textView: CaptureTextViewImpl?

        init(parent: CaptureTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            parent.text = textView.string
            reportHeight()
        }

        func reportHeight() {
            guard let textView, let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
            layoutManager.ensureLayout(for: container)
            let used = layoutManager.usedRect(for: container)
            let height = ceil(used.height + textView.textContainerInset.height * 2)
            parent.onEdit(textView.string, height)
        }
    }
}
