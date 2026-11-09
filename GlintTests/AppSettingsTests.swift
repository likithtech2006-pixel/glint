import Foundation
import Testing
@testable import Glint

@MainActor
struct AppSettingsTests {
    private let suiteName = "glint.tests.\(UUID().uuidString)"
    private var defaults: UserDefaults { UserDefaults(suiteName: suiteName)! }

    @Test func firstRunDefaults() {
        let settings = AppSettings(defaults: defaults)
        #expect(!settings.hasCompletedOnboarding)
        #expect(!settings.showDockIcon)
        #expect(settings.soundEffectsEnabled)
        #expect(settings.afterCapture == .both)
        #expect(settings.converterOutput == .nextToOriginal)
        #expect(settings.overwriteRule == .keepBoth)
        #expect(settings.wheelModifier == .shift)
    }

    @Test func changesSurviveRelaunch() {
        let first = AppSettings(defaults: defaults)
        first.hasCompletedOnboarding = true
        first.soundEffectsEnabled = false
        first.imageFormat = .heic
        first.videoFPS = 30
        first.wheelModifier = .fn
        first.saveFolder = URL(filePath: "/tmp/glint shots", directoryHint: .isDirectory)

        let second = AppSettings(defaults: defaults)
        #expect(second.hasCompletedOnboarding)
        #expect(!second.soundEffectsEnabled)
        #expect(second.imageFormat == .heic)
        #expect(second.videoFPS == 30)
        #expect(second.wheelModifier == .fn)
        #expect(second.saveFolder.path(percentEncoded: false).hasPrefix("/tmp/glint shots"))
    }

    @Test func unknownStoredValueFallsBackToDefault() {
        defaults.set("bmp-from-the-future", forKey: "capture.imageFormat")
        #expect(AppSettings(defaults: defaults).imageFormat == .png)
    }
}
