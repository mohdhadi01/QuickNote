import AppKit
import SwiftUI

/// The floating quick capture surface: a borderless, non-activating NSPanel
/// that hosts SwiftUI content (spec §7).
///
/// The panel never activates the app, so the user's current application keeps
/// focus while they type.
@MainActor
final class QuickCapturePanel: NSPanel {
    weak var eventDelegate: QuickCapturePanelEventDelegate?

    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: DesignTokens.CapturePanel.initialWidth,
                height: DesignTokens.CapturePanel.initialHeight
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        becomesKeyOnlyIfNeeded = false
        animationBehavior = .none
        worksWhenModal = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        identifier = NSUserInterfaceItemIdentifier("quicknote.capture-panel")
        delegate = self
    }

    override var canBecomeKey: Bool { true }

    func setContentView(_ rootView: some View) {
        let hosting = NSHostingController(rootView: rootView)
        hosting.sizingOptions = []
        contentViewController = hosting

        // Native macOS Liquid Glass behind the SwiftUI content (spec §10).
        let glass = NSGlassEffectView()
        glass.cornerRadius = DesignTokens.CornerRadius.capture
        glass.contentView = hosting.view
        // hostingView must resize with the glass view.
        hosting.view.autoresizingMask = [.width, .height]
        contentView = glass
    }
}

/// Panel lifecycle events consumed by the coordinator.
@MainActor
protocol QuickCapturePanelEventDelegate: AnyObject {
    func panelDidLoseKey()
    func panelWillClose()
}

extension QuickCapturePanel: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        eventDelegate?.panelDidLoseKey()
    }

    func windowWillClose(_ notification: Notification) {
        eventDelegate?.panelWillClose()
    }
}
