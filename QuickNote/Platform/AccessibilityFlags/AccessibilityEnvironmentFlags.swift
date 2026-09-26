import AppKit
import Combine
import Foundation

/// Publishes macOS accessibility display flags so the UI can adapt
/// (spec §11, §31): Reduce Motion and Reduce Transparency.
@MainActor
final class AccessibilityEnvironmentFlags: ObservableObject {
    /// Shared instance used by QA snapshot hosting where the environment
    /// chain is assembled manually.
    static let shared = AccessibilityEnvironmentFlags()

    @Published private(set) var reduceMotion: Bool = false
    @Published private(set) var reduceTransparency: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency

        NSWorkspace.shared.publisher(for: \.accessibilityDisplayShouldReduceMotion)
            .receive(on: DispatchQueue.main)
            .assign(to: \.reduceMotion, on: self)
            .store(in: &cancellables)

        NSWorkspace.shared.publisher(for: \.accessibilityDisplayShouldReduceTransparency)
            .receive(on: DispatchQueue.main)
            .assign(to: \.reduceTransparency, on: self)
            .store(in: &cancellables)
    }
}
