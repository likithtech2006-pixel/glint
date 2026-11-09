import Foundation
import Testing
@testable import Glint

struct FileNameTemplateTests {
    private let utc = TimeZone(identifier: "UTC")!
    // 2026-11-08 09:05:03 UTC
    private let date = Date(timeIntervalSince1970: 1_794_128_703)

    @Test func fillsDateAndTime() {
        #expect(FileNameTemplate.render("Shot {date} at {time}", date: date, timeZone: utc) == "Shot 2026-11-08 at 09.05.03")
    }

    @Test func plainTextPassesThrough() {
        #expect(FileNameTemplate.render("Capture", date: date, timeZone: utc) == "Capture")
    }

    @Test func removesPathSeparators() {
        #expect(FileNameTemplate.render("a/b:c", date: date, timeZone: utc) == "a-b-c")
    }

    @Test func leadingDotsCannotHideTheFile() {
        #expect(FileNameTemplate.render("..secret", date: date, timeZone: utc) == "secret")
    }

    @Test(arguments: ["", "   ", "..."])
    func emptyResultFallsBackToDefault(template: String) {
        #expect(FileNameTemplate.render(template, date: date, timeZone: utc) == "Screenshot 2026-11-08 at 09.05.03")
    }
}
