import Foundation

/// Sidebar sections / list filters (spec §19, §23).
enum NoteFilter: String, CaseIterable, Identifiable, Hashable {
    case inbox
    case today
    case all
    case pinned
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: "Inbox"
        case .today: "Today"
        case .all: "All Notes"
        case .pinned: "Pinned"
        case .trash: "Trash"
        }
    }

    var symbolName: String {
        switch self {
        case .inbox: "tray"
        case .today: "calendar"
        case .all: "note.text"
        case .pinned: "pin"
        case .trash: "trash"
        }
    }

    /// Empty-state copy per section (spec §47).
    var emptyStateTitle: String {
        switch self {
        case .inbox: "Your quick notes will appear here."
        case .today: "No notes captured today."
        case .all: "No notes yet."
        case .pinned: "Pin notes you want to keep close."
        case .trash: "Deleted notes will appear here."
        }
    }

    /// The calendar-day window for "today", computed in the user's local
    /// calendar and time zone (spec §23 — never UTC blindly).
    static func todayRange(calendar: Calendar = .current, now: Date = Date()) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }
}
