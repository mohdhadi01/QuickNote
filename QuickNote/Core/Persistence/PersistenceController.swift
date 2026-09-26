import Foundation
import SwiftData

/// Owns the SwiftData container and handles store initialization failures
/// without crashing or losing data (spec §17, §69).
@MainActor
final class PersistenceController {
    let container: ModelContainer
    /// Non-nil when the store was recovered from a failure this launch.
    let recoveryInfo: PersistenceRecoveryInfo?

    static func defaultStoreURL() -> URL {
        let support = URL.applicationSupportDirectory
        return support.appending(path: "QuickNote/Notes.store")
    }

    /// Boots the store with graceful degradation:
    /// 1. Open normally.
    /// 2. On failure, quarantine the corrupted files aside (never delete) and
    ///    retry with a fresh store.
    /// 3. On failure again, fall back to an in-memory container so the user
    ///    can at least capture notes this session, with a visible warning.
    static func bootstrap() -> PersistenceController {
        do {
            let container = try makeContainer(at: defaultStoreURL(), inMemory: false)
            return PersistenceController(container: container, recoveryInfo: nil)
        } catch {
            Log.persistence.error("Store initialization failed: \(String(describing: error), privacy: .public)")
        }

        // Quarantine and retry.
        let quarantined = quarantineStore(at: defaultStoreURL())
        let retryURL = defaultStoreURL()
        do {
            let container = try makeContainer(at: retryURL, inMemory: false)
            let original = quarantined?.path ?? "unknown location"
            Log.persistence.error("Recovered with a fresh store; original preserved at \(original, privacy: .public)")
            return PersistenceController(
                container: container,
                recoveryInfo: .init(mode: .freshStoreAfterRecovery(originalFileURL: original))
            )
        } catch {
            Log.persistence.fault("Fresh store also failed: \(String(describing: error), privacy: .public)")
        }

        // Last resort: in memory so the user can still capture this session.
        do {
            let schema = Schema([Note.self])
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            let memoryContainer = try ModelContainer(for: schema, configurations: [memoryConfig])
            return PersistenceController(
                container: memoryContainer,
                recoveryInfo: .init(mode: .inMemoryOnly)
            )
        } catch {
            Log.persistence.fault("Unable to create any ModelContainer: \(String(describing: error), privacy: .public)")
            fatalError("QuickNote could not create a persistence container.")
        }
    }

    static func inMemory() throws -> PersistenceController {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return PersistenceController(container: container, recoveryInfo: nil)
    }

    private init(container: ModelContainer, recoveryInfo: PersistenceRecoveryInfo?) {
        self.container = container
        self.recoveryInfo = recoveryInfo
    }

    private static func makeContainer(at url: URL, inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([Note.self])
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            config = ModelConfiguration(url: url, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Moves an unreadable store (and its sidecar files) into a timestamped
    /// backup directory. Data is never deleted.
    private static func quarantineStore(at url: URL) -> URL? {
        let backupDir = url.deletingLastPathComponent()
            .appending(path: "Recovered-\(Int(Date().timeIntervalSince1970))")
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
            var moved: URL?
            for suffix in ["", "-shm", "-wal"] {
                let source = URL(fileURLWithPath: url.path + suffix)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                let destination = backupDir.appending(path: source.lastPathComponent)
                try fileManager.moveItem(at: source, to: destination)
                if suffix.isEmpty { moved = destination }
            }
            Log.persistence.info("Quarantined unreadable store")
            return moved
        } catch {
            Log.persistence.error("Quarantine failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }
}
