import SwiftUI

/// Typography tokens. Native system fonts only — no external fonts.
enum Typography {
    /// Quick capture input field (spec §12: 17–18 pt).
    static let captureInput = Font.system(size: 17, weight: .regular)
    static let capturePlaceholder = Font.system(size: 17, weight: .regular)
    static let captureHint = Font.system(size: 11, weight: .regular)

    /// Main editor body text.
    static let editorBody = Font.system(size: 15, weight: .regular)

    /// Shortcut glyph display (⌘ ⇧ Space).
    static let shortcutGlyph = Font.system(size: 15, weight: .medium, design: .rounded)
}
