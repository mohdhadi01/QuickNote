import AppKit
import Foundation

/// Owns the quick capture panel lifecycle: presentation, dismissal, save
/// flow, positioning, and state transitions (spec §7, §9, §14, §40, §41).
@MainActor
final class QuickCaptureCoordinator: QuickCapturePanelEventDelegate {
    private let viewModel: QuickCaptureViewModel
    private let noteService: NoteService
    private let settings: SettingsService
    private let flags: AccessibilityEnvironmentFlags

    private var panel: QuickCapturePanel?
    private var stateMachine = QuickCaptureStateMachine()
    private weak var textView: CaptureTextViewImpl?

    var state: QuickCaptureState { stateMachine.state }
    var isPanelVisible: Bool { stateMachine.state.isPanelVisible }

    init(
        viewModel: QuickCaptureViewModel,
        noteService: NoteService,
        settings: SettingsService,
        flags: AccessibilityEnvironmentFlags
    ) {
        self.viewModel = viewModel
        self.noteService = noteService
        self.settings = settings
        self.flags = flags

        viewModel.onSaveRequested = { [weak self] in self?.requestSave() }
        viewModel.onCancelRequested = { [weak self] in self?.requestCancel() }
        viewModel.onTextChanged = { [weak self] in self?.textChanged() }
        viewModel.onHeightChanged = { [weak self] in self?.updatePanelHeight() }
    }

    // MARK: Presentation

    /// Hotkey toggle behavior (spec §40): present when hidden; when visible,
    /// save any text and dismiss rather than creating a second panel.
    func toggle() {
        switch stateMachine.state {
        case .idle:
            present()
        case .presenting, .ready, .typing:
            if viewModel.hasCommittedText {
                requestSave()
            } else {
                requestCancel()
            }
        case .saving, .dismissing:
            break
        }
    }

    func present() {
        guard stateMachine.handle(.beginPresent) else { return }

        let panel = ensurePanel()
        viewModel.reset()
        viewModel.sourceApp = settings.recordSourceApp
            ? WorkspaceApplicationContextProvider().frontmostApplication()
            : nil

        let size = CGSize(
            width: DesignTokens.CapturePanel.initialWidth,
            height: viewModel.desiredPanelHeight
        )
        let visibleFrame = screenContainingMouse()?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let targetFrame = PanelPlacement.frame(
            size: size,
            cursor: NSEvent.mouseLocation,
            visibleFrame: visibleFrame,
            mode: settings.panelPosition
        )

        panel.setFrame(targetFrame, display: false)
        panel.alphaValue = 0

        let reduceMotion = flags.reduceMotion
        panel.makeKeyAndOrderFront(nil)
        focusTextView(afterDelay: reduceMotion ? 0 : Motion.adjustedPresentationDuration(reduceMotion: false))

        if reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Motion.adjustedPresentationDuration(reduceMotion: true)
                context.allowsImplicitAnimation = true
                panel.animator().alphaValue = 1
            } completionHandler: { [weak self] in
                _ = self?.stateMachine.handle(.becameReady)
            }
        } else {
            let fromFrame = Self.frameAnchoredToTop(
                of: targetFrame,
                scale: Motion.presentationInitialScale,
                verticalOffset: Motion.presentationInitialOffset
            )
            panel.setFrame(fromFrame, display: false)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Motion.adjustedPresentationDuration(reduceMotion: false)
                context.timingFunction = Motion.panelTimingFunction
                context.allowsImplicitAnimation = true
                panel.animator().alphaValue = 1
                panel.animator().setFrame(targetFrame, display: true)
            } completionHandler: { [weak self] in
                _ = self?.stateMachine.handle(.becameReady)
            }
        }
        Log.window.debug("Capture panel presented")
    }

    // MARK: Save / cancel / dismiss

    func requestSave() {
        guard viewModel.canSave else { return }
        guard stateMachine.handle(.beganSave) else { return }
        viewModel.beginSaving()

        do {
            _ = try noteService.capture(viewModel.text, sourceApp: viewModel.sourceApp)
            viewModel.endSaving()
            _ = stateMachine.handle(.saveSucceeded)
            animateDismissal()
            Log.capture.info("Quick capture saved")
        } catch {
            _ = stateMachine.handle(.saveFailed)
            viewModel.reportSaveFailure()
            Log.capture.error("Quick capture save failed")
        }
    }

    func requestCancel() {
        guard stateMachine.handle(.beginDismiss) else { return }
        animateDismissal()
    }

    private func textChanged() {
        _ = stateMachine.handle(.textChanged)
        updatePanelHeight()
    }

    /// Grows/shrinks the panel with content, keeping its top edge fixed
    /// (spec §8).
    private func updatePanelHeight() {
        guard let panel, stateMachine.state.isPanelVisible else { return }
        let newHeight = viewModel.desiredPanelHeight
        guard abs(panel.frame.height - newHeight) > 0.5 else { return }

        var newFrame = PanelPlacement.frameResizingDownward(from: panel.frame, newHeight: newHeight)
        if let screen = panel.screen ?? screenContainingMouse() {
            newFrame = PanelPlacement.clampedFrame(newFrame, inside: screen.visibleFrame)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = Motion.panelTimingFunction
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(newFrame, display: true)
        }
    }

    private func animateDismissal() {
        guard let panel else {
            finishDismissal()
            return
        }
        let reduceMotion = flags.reduceMotion
        let targetFrame = Self.frameAnchoredToTop(
            of: panel.frame,
            scale: Motion.dismissalFinalScale,
            verticalOffset: -2
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Motion.adjustedDismissalDuration(reduceMotion: reduceMotion)
            context.timingFunction = Motion.panelTimingFunction
            context.allowsImplicitAnimation = true
            panel.animator().alphaValue = 0
            if !reduceMotion {
                panel.animator().setFrame(targetFrame, display: true)
            }
        } completionHandler: { [weak self] in
            self?.finishDismissal()
        }
    }

    private func finishDismissal() {
        panel?.orderOut(nil)
        viewModel.reset()
        _ = stateMachine.handle(.finishedDismiss)
        Log.window.debug("Capture panel dismissed")
    }

    // MARK: Panel events

    /// Clicking away dismisses the panel. Text is preserved by saving it
    /// rather than discarding (spec §69: never lose text unnecessarily).
    func panelDidLoseKey() {
        guard stateMachine.state == .ready || stateMachine.state == .typing else { return }
        if viewModel.hasCommittedText {
            requestSave()
        } else {
            requestCancel()
        }
    }

    func panelWillClose() {
        // Defensive: if the window ever closes directly, return to idle.
        panel?.orderOut(nil)
        viewModel.reset()
        stateMachine = QuickCaptureStateMachine()
    }

    // MARK: Teardown

    /// App is quitting: preserve any typed text (spec §69).
    func saveDraftIfPresent() {
        guard isPanelVisible, viewModel.hasCommittedText else { return }
        try? noteService.capture(viewModel.text, sourceApp: viewModel.sourceApp)
        Log.capture.info("Preserved in-progress capture during quit")
    }

    // MARK: Panel management

    private func ensurePanel() -> QuickCapturePanel {
        if let panel { return panel }

        let newPanel = QuickCapturePanel()
        newPanel.eventDelegate = self
        newPanel.setContentView(
            QuickCaptureView(viewModel: viewModel, flags: flags, onTextViewReady: { [weak self] textView in
                self?.handleTextViewReady(textView)
            })
        )
        panel = newPanel
        return newPanel
    }

    private func focusTextView(afterDelay delay: TimeInterval) {
        let focus = { [weak self] in
            guard let self, let panel = self.panel, let textView = self.textView else { return }
            panel.makeFirstResponder(textView)
        }
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: focus)
        } else {
            DispatchQueue.main.async(execute: focus)
        }
    }

    func handleTextViewReady(_ textView: CaptureTextViewImpl) {
        self.textView = textView
    }

    /// Repositions a visible panel after display configuration changes
    /// (display disconnect / resolution change, spec §69).
    func handleScreenConfigurationChanged() {
        guard let panel, stateMachine.state.isPanelVisible else { return }
        let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        guard let visibleFrame else { return }
        let clamped = PanelPlacement.clampedFrame(panel.frame, inside: visibleFrame)
        panel.setFrame(clamped, display: true, animate: false)
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) }
    }

    /// Returns a frame scaled about its top edge, offset upward by
    /// `verticalOffset` points (used for entrance/exit motion).
    private static func frameAnchoredToTop(of base: CGRect, scale: CGFloat, verticalOffset: CGFloat) -> CGRect {
        let width = base.width * scale
        let height = base.height * scale
        return CGRect(
            x: base.midX - width / 2,
            y: base.maxY + verticalOffset - height,
            width: width,
            height: height
        )
    }
}
