import Foundation
import SwiftUI

/// Animation tokens for the quick capture panel (spec §11).
enum Motion {
    /// Presentation duration in seconds (target 180–260 ms).
    static let presentationDuration: TimeInterval = 0.22
    /// Dismissal duration in seconds (target 140–190 ms).
    static let dismissalDuration: TimeInterval = 0.16
    /// Panel appears at 96% scale and 4 pt above its final position.
    static let presentationInitialScale: CGFloat = 0.96
    static let presentationInitialOffset: CGFloat = 4
    /// Panel shrinks toward 98% scale when dismissed.
    static let dismissalFinalScale: CGFloat = 0.98

    /// A fast, physical ease-out used for the panel's frame animations.
    static let panelTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1.0)

    /// SwiftUI spring used for in-panel micro-interactions.
    static var panelSpring: Animation {
        .spring(response: 0.22, dampingFraction: 0.85, blendDuration: 0)
    }

    /// Substitutes a plain short fade when Reduce Motion is active.
    static func adjustedPresentationDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.08 : presentationDuration
    }

    static func adjustedDismissalDuration(reduceMotion: Bool) -> TimeInterval {
        reduceMotion ? 0.08 : dismissalDuration
    }
}
