import Foundation
import SwiftData

/// A single captured note (spec §15).
///
/// Kept CloudKit-friendly (spec §59): stable UUID, no transient UI state,
/// consistent createdAt/updatedAt, optional source metadata.
@Model
final class Note {
    var id: UUID = UUID()
    var content: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isPinned: Bool = false
    var isArchived: Bool = false
    var deletedAt: Date?
    var sourceApplicationName: String?
    var sourceApplicationBundleID: String?

    init(
        content: String,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        sourceApplicationName: String? = nil,
        sourceApplicationBundleID: String? = nil
    ) {
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isPinned = isPinned
        self.sourceApplicationName = sourceApplicationName
        self.sourceApplicationBundleID = sourceApplicationBundleID
    }
}
