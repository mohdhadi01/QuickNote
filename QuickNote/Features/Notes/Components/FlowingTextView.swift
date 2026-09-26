import AppKit
import SwiftUI

/// The quick-note editor surface: one flowing NSTextView where the first
/// line renders as a heading automatically (visually only — the stored
/// content is never modified). Matches how quick captures actually look:
/// no separate title field, just the thought.
struct FlowingTextView: NSViewRepresentable {
    @Binding var text: String
    let onEdit: (String) -> Void
    let onViewReady: (NSTextView) -> Void

    private static let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
        .foregroundColor: NSColor.labelColor,
    ]
    private static let bodyAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 15),
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 4
            return style
        }(),
    ]

    func makeNSView(context: Context) -> NSScrollView {
        let textView = FlowingTextViewImpl()
        configure(textView)
        textView.delegate = context.coordinator
        textView.onAttributesChanged = { [weak coordinator = context.coordinator] in
            coordinator?.applyFlowStyling()
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        textView.string = text
        context.coordinator.applyFlowStyling()
        context.coordinator.textView = textView
        onViewReady(textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.applyFlowStyling()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func configure(_ textView: FlowingTextViewImpl) {
        textView.isRichText = true
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
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.focusRingType = .none
        textView.isContinuousSpellCheckingEnabled = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: FlowingTextView
        weak var textView: FlowingTextViewImpl?
        /// Guard so programmatic restyling doesn't recurse.
        private var isRestyling = false

        init(parent: FlowingTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            applyFlowStyling()
            guard let textView else { return }
            parent.text = textView.string
            parent.onEdit(textView.string)
        }

        /// Styles the first non-empty line as a heading and the rest as body,
        /// and sets typing attributes so new text adopts the style at the
        /// insertion point.
        func applyFlowStyling() {
            guard let textView, !isRestyling else { return }
            isRestyling = true
            defer { isRestyling = false }

            let content = textView.string as NSString
            guard content.length > 0 else {
                textView.typingAttributes = FlowingTextView.titleAttributes
                return
            }

            let full = NSRange(location: 0, length: content.length)
            let attributed = NSMutableAttributedString(attributedString: textView.attributedString())
            attributed.setAttributes(FlowingTextView.bodyAttributes, range: full)

            var lineEnd = 0
            content.getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: NSRange(location: 0, length: 0))
            if lineEnd > 0 {
                attributed.setAttributes(FlowingTextView.titleAttributes, range: NSRange(location: 0, length: lineEnd))
            }

            textView.textStorage?.setAttributedString(attributed)

            // Typing attributes at the insertion point.
            let location = min(textView.selectedRange().location, max(content.length - 1, 0))
            var lineEndForLocation = 0
            content.getLineStart(nil, end: &lineEndForLocation, contentsEnd: nil, for: NSRange(location: location, length: 0))
            textView.typingAttributes = location < lineEndForLocation ? FlowingTextView.titleAttributes : FlowingTextView.bodyAttributes
        }
    }
}

/// NSTextView that reports attribute-affecting edits (so the flow styling
/// re-runs when the first line changes).
final class FlowingTextViewImpl: NSTextView {
    var onAttributesChanged: (() -> Void)?

    override func insertLineBreak(_ sender: Any?) {
        super.insertLineBreak(sender)
        onAttributesChanged?()
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)
        onAttributesChanged?()
    }

    override func deleteBackward(_ sender: Any?) {
        super.deleteBackward(sender)
        onAttributesChanged?()
    }
}
