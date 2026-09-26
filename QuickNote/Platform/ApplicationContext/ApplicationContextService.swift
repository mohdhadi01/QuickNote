import AppKit
import Foundation

/// Optional source-application metadata (spec §44). Only name and bundle ID
/// are ever recorded, and only when the user enables the setting.
struct ApplicationContextSnapshot: Equatable {
    let applicationName: String?
    let bundleIdentifier: String?
}

protocol ApplicationContextProviding: AnyObject {
    func frontmostApplication() -> ApplicationContextSnapshot?
}

final class WorkspaceApplicationContextProvider: ApplicationContextProviding {
    func frontmostApplication() -> ApplicationContextSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return ApplicationContextSnapshot(
            applicationName: app.localizedName,
            bundleIdentifier: app.bundleIdentifier
        )
    }
}
