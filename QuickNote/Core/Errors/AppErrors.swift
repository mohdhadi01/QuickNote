import Foundation

/// Capture-time validation errors.
enum NoteCaptureError: Error, Equatable {
    /// The text is empty (or whitespace-only) after normalization.
    case empty
}

/// Describes what happened when the persistent store could not be opened,
/// and how the app recovered. Surfaced to the user in the main window.
struct PersistenceRecoveryInfo: Equatable {
    enum Mode: Equatable {
        /// A fresh store replaced an unreadable one; the old file was preserved.
        case freshStoreAfterRecovery(originalFileURL: String)
        /// Notes work in memory only for this session.
        case inMemoryOnly
    }

    let mode: Mode

    var userFacingMessage: String {
        switch mode {
        case .freshStoreAfterRecovery(let url):
            "Your notes library couldn't be opened, so a new library was created. "
                + "The original file was preserved at: \(url)"
        case .inMemoryOnly:
            "Notes can't be saved to disk right now. Notes captured this session will not be kept."
        }
    }
}
