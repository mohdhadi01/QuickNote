import Foundation

/// Timestamp formatting for note rows and the editor header.
enum NoteDateFormatting {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// "Today · 7:42 PM", "Yesterday · 7:42 PM", or "Sep 12, 2026".
    static func listTimestamp(for date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today · \(timeFormatter.string(from: date))"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday · \(timeFormatter.string(from: date))"
        }
        return shortDateFormatter.string(from: date)
    }

    /// "Sep 26, 2026 at 7:42 PM" — used in the editor header.
    static func fullTimestamp(for date: Date) -> String {
        mediumFormatter.string(from: date)
    }
}
