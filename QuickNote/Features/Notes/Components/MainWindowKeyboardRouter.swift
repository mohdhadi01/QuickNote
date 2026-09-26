import AppKit
import Foundation

/// Local (in-app) keyboard routing for the main window — the heavy-user
/// navigation layer:
/// - ↑/↓ move the list selection (when not editing text)
/// - Return jumps into the editor
/// - ⌘F focuses search, Escape clears search / leaves the editor
/// - ⌘1…⌘5 switch sidebar sections
///
/// Only events aimed at the main window are intercepted: the quick capture
/// panel, Settings, and active text editing keep their native behavior.
@MainActor
final class MainWindowKeyboardRouter {
    private var monitor: Any?
    private weak var window: NSWindow?
    private var onArrow: (Int) -> Void
    private var onReturn: () -> Void
    private var onEscape: () -> Bool // returns true when handled
    private var onSection: (Int) -> Void
    private var onFind: () -> Void

    init(
        onArrow: @escaping (Int) -> Void,
        onReturn: @escaping () -> Void,
        onEscape: @escaping () -> Bool,
        onSection: @escaping (Int) -> Void,
        onFind: @escaping () -> Void
    ) {
        self.onArrow = onArrow
        self.onReturn = onReturn
        self.onEscape = onEscape
        self.onSection = onSection
        self.onFind = onFind
    }

    func install(for window: NSWindow?) {
        self.window = window
        guard window != nil, monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, NSApp.keyWindow === self.window else { return event }
            return self.handle(event) ? nil : event
        }
    }

    func remove() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) -> Bool {
        let editing = isEditingText()
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // ⌘F — focus search (even while editing the editor).
        if modifiers == .command, event.charactersIgnoringModifiers == "f" {
            onFind()
            return true
        }

        // ⌘1…⌘5 — sections.
        if modifiers == .command, let character = event.characters, let index = Int(character), (1...5).contains(index) {
            onSection(index - 1)
            return true
        }

        // Escape — clear search or leave the editor.
        if event.keyCode == VirtualKey.escape {
            if onEscape() { return true }
            return false
        }

        guard !editing else { return false }

        let keyCode = UInt32(event.keyCode)
        switch keyCode {
        case VirtualKey.upArrow:
            onArrow(-1)
            return true
        case VirtualKey.downArrow:
            onArrow(1)
            return true
        case VirtualKey.returnKey:
            onReturn()
            return true
        default:
            return false
        }
    }

    /// True when the main window's first responder is a text-editing view
    /// (editor body or search field).
    private func isEditingText() -> Bool {
        guard let responder = window?.firstResponder else { return false }
        return responder is NSTextView
    }
}
