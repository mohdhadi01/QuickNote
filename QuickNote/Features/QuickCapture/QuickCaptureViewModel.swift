import AppKit
import Foundation

/// View model for the quick capture surface: owns the draft text, save/error
/// state, duplicate protection, and the editor's dynamic height (spec §12–§14,
/// §41, §42). Persistence is driven by QuickCaptureCoordinator.
@MainActor
final class QuickCaptureViewModel: ObservableObject {
    @Published var text: String = "" {
        didSet {
            if oldValue != text {
                onTextChanged?()
            }
        }
    }
    @Published private(set) var isSaving = false
    /// Non-nil when persistence failed; the panel stays open with the text
    /// intact so the user can retry (spec §42).
    @Published private(set) var saveError: String?
    /// The editor's content height, reported by the NSTextView wrapper.
    @Published var contentHeight: CGFloat = 0
    /// Source-application metadata captured when the panel was presented.
    var sourceApp: ApplicationContextSnapshot?

    // Event hooks wired by QuickCaptureCoordinator.
    var onSaveRequested: (() -> Void)?
    var onCancelRequested: (() -> Void)?
    var onTextChanged: (() -> Void)?
    var onHeightChanged: (() -> Void)?

    var desiredPanelHeight: CGFloat {
        let metrics = DesignTokens.CapturePanel.self
        let chrome = metrics.verticalPadding * 2 + metrics.footerSpacing + metrics.footerHeight
        let natural = contentHeight + chrome
        return min(max(DesignTokens.CapturePanel.initialHeight, natural), metrics.maxHeight)
    }

    /// True when there is text worth persisting.
    var hasCommittedText: Bool {
        NoteContentFormatter.normalizedCaptureText(text) != nil
    }

    /// Duplicate protection: repeated Enter during the save transition is a
    /// no-op (spec §41).
    var canSave: Bool {
        hasCommittedText && !isSaving
    }

    func reset() {
        text = ""
        isSaving = false
        saveError = nil
        contentHeight = 0
        sourceApp = nil
    }

    /// Marks the start of the save transition.
    func beginSaving() {
        isSaving = true
        saveError = nil
    }

    func endSaving() {
        isSaving = false
    }

    /// Keeps text and panel; surfaces a retry action (spec §42).
    func reportSaveFailure() {
        isSaving = false
        saveError = "Couldn't save your note."
    }

    func clearSaveError() {
        saveError = nil
    }
}
