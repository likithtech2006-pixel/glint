import Foundation
import Observation

enum CaptureImageFormat: String, CaseIterable, Identifiable {
    case png, jpeg, heic
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
}

enum AfterCaptureAction: String, CaseIterable, Identifiable {
    case copy, save, both
    var id: String { rawValue }
    var title: String {
        switch self {
        case .copy: "Copy to clipboard"
        case .save: "Save to file"
        case .both: "Copy and save"
        }
    }
}

enum VideoCodec: String, CaseIterable, Identifiable {
    case h264, hevc
    var id: String { rawValue }
    var title: String { self == .h264 ? "H.264" : "HEVC" }
}

enum VideoQuality: String, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ConverterOutputLocation: String, CaseIterable, Identifiable {
    case nextToOriginal, customFolder
    var id: String { rawValue }
    var title: String { self == .nextToOriginal ? "Next to the original" : "Custom folder" }
}

enum OverwriteRule: String, CaseIterable, Identifiable {
    case keepBoth, skip, replace
    var id: String { rawValue }
    var title: String {
        switch self {
        case .keepBoth: "Keep both (add a number)"
        case .skip: "Skip the file"
        case .replace: "Replace the existing file"
        }
    }
}

enum WheelModifier: String, CaseIterable, Identifiable {
    case shift, option, fn, disabled
    var id: String { rawValue }
    var title: String {
        switch self {
        case .shift: "Shift"
        case .option: "Option"
        case .fn: "Fn"
        case .disabled: "Off"
        }
    }
}

/// User preferences, persisted to UserDefaults on every change.
@MainActor
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboarded) } }
    var showDockIcon: Bool { didSet { defaults.set(showDockIcon, forKey: Key.dockIcon) } }
    var soundEffectsEnabled: Bool { didSet { defaults.set(soundEffectsEnabled, forKey: Key.sounds) } }

    var saveFolder: URL { didSet { defaults.set(saveFolder.path, forKey: Key.saveFolder) } }
    var fileNameTemplate: String { didSet { defaults.set(fileNameTemplate, forKey: Key.fileName) } }
    var imageFormat: CaptureImageFormat { didSet { defaults.set(imageFormat.rawValue, forKey: Key.imageFormat) } }
    var afterCapture: AfterCaptureAction { didSet { defaults.set(afterCapture.rawValue, forKey: Key.afterCapture) } }

    var videoCodec: VideoCodec { didSet { defaults.set(videoCodec.rawValue, forKey: Key.codec) } }
    var videoQuality: VideoQuality { didSet { defaults.set(videoQuality.rawValue, forKey: Key.quality) } }
    var videoFPS: Int { didSet { defaults.set(videoFPS, forKey: Key.fps) } }

    var converterOutput: ConverterOutputLocation { didSet { defaults.set(converterOutput.rawValue, forKey: Key.converterOutput) } }
    var converterFolder: URL { didSet { defaults.set(converterFolder.path, forKey: Key.converterFolder) } }
    var overwriteRule: OverwriteRule { didSet { defaults.set(overwriteRule.rawValue, forKey: Key.overwrite) } }
    var wheelModifier: WheelModifier { didSet { defaults.set(wheelModifier.rawValue, forKey: Key.wheelModifier) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        func stored<T: RawRepresentable>(_ key: String, default fallback: T) -> T where T.RawValue == String {
            guard let raw = defaults.string(forKey: key), let value = T(rawValue: raw) else { return fallback }
            return value
        }
        func folder(_ key: String, default fallback: URL) -> URL {
            defaults.string(forKey: key).map { URL(filePath: $0, directoryHint: .isDirectory) } ?? fallback
        }

        // ~/Pictures rather than ~/Desktop: Desktop is a protected folder, so
        // saving there would add another macOS permission prompt.
        let pictures = URL.picturesDirectory.appending(path: AppInfo.name, directoryHint: .isDirectory)

        hasCompletedOnboarding = defaults.bool(forKey: Key.onboarded)
        showDockIcon = defaults.bool(forKey: Key.dockIcon)
        soundEffectsEnabled = defaults.object(forKey: Key.sounds) as? Bool ?? true

        saveFolder = folder(Key.saveFolder, default: pictures)
        fileNameTemplate = defaults.string(forKey: Key.fileName) ?? FileNameTemplate.defaultTemplate
        imageFormat = stored(Key.imageFormat, default: .png)
        afterCapture = stored(Key.afterCapture, default: .both)

        videoCodec = stored(Key.codec, default: .hevc)
        videoQuality = stored(Key.quality, default: .high)
        videoFPS = defaults.object(forKey: Key.fps) as? Int ?? 60

        converterOutput = stored(Key.converterOutput, default: .nextToOriginal)
        converterFolder = folder(Key.converterFolder, default: pictures)
        overwriteRule = stored(Key.overwrite, default: .keepBoth)
        wheelModifier = stored(Key.wheelModifier, default: .shift)
    }

    private enum Key {
        static let onboarded = "app.onboardingComplete"
        static let dockIcon = "app.showDockIcon"
        static let sounds = "app.soundEffects"
        static let saveFolder = "capture.saveFolder"
        static let fileName = "capture.fileNameTemplate"
        static let imageFormat = "capture.imageFormat"
        static let afterCapture = "capture.afterCapture"
        static let codec = "recording.codec"
        static let quality = "recording.quality"
        static let fps = "recording.fps"
        static let converterOutput = "converter.output"
        static let converterFolder = "converter.folder"
        static let overwrite = "converter.overwrite"
        static let wheelModifier = "converter.wheelModifier"
    }
}
