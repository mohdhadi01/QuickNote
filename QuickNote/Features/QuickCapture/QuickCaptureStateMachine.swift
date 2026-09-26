import Foundation

/// Explicit lifecycle states for quick capture (spec §40).
enum QuickCaptureState: Equatable {
    case idle
    case presenting
    case ready
    case typing
    case saving
    case dismissing

    var isPanelVisible: Bool {
        switch self {
        case .idle: false
        default: true
        }
    }
}

enum QuickCaptureEvent: Equatable {
    case beginPresent
    case becameReady
    case textChanged
    case beganSave
    case saveSucceeded
    case saveFailed
    case beginDismiss
    case finishedDismiss
}

/// A tiny table-driven state machine. Illegal transitions are rejected so
/// rapid hotkey/Enter events can never corrupt state (spec §41).
struct QuickCaptureStateMachine: Equatable {
    private(set) var state: QuickCaptureState = .idle

    /// Applies an event. Returns false (leaving state unchanged) when the
    /// transition is not allowed.
    mutating func handle(_ event: QuickCaptureEvent) -> Bool {
        let nextState: QuickCaptureState

        switch (state, event) {
        case (.idle, .beginPresent): nextState = .presenting
        case (.presenting, .becameReady): nextState = .ready
        case (.ready, .textChanged), (.typing, .textChanged): nextState = .typing
        case (.ready, .beganSave), (.typing, .beganSave): nextState = .saving
        case (.saving, .saveSucceeded): nextState = .dismissing
        case (.saving, .saveFailed): nextState = .typing
        case (.ready, .beginDismiss), (.typing, .beginDismiss), (.saving, .beginDismiss): nextState = .dismissing
        case (.dismissing, .finishedDismiss): nextState = .idle
        default:
            return false
        }

        state = nextState
        return true
    }
}
