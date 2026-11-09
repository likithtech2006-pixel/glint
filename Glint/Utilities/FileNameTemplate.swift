import Foundation

/// Turns a user-editable pattern such as "Screenshot {date} at {time}" into a file name.
enum FileNameTemplate {
    static let defaultTemplate = "Screenshot {date} at {time}"

    static func render(_ template: String, date: Date, timeZone: TimeZone = .current) -> String {
        let rendered = template
            .replacingOccurrences(of: "{date}", with: format(date, "yyyy-MM-dd", timeZone))
            .replacingOccurrences(of: "{time}", with: format(date, "HH.mm.ss", timeZone))

        // "/" separates paths and ":" is shown as "/" in Finder, so neither can be in a name.
        let safe = rendered
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // A leading dot would hide the file.
        let visible = String(safe.drop(while: { $0 == "." }))
        return visible.isEmpty ? render(defaultTemplate, date: date, timeZone: timeZone) : visible
    }

    private static func format(_ date: Date, _ pattern: String, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
