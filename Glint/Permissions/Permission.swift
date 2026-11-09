import Foundation

enum PermissionKind: String, CaseIterable, Identifiable, Sendable {
    case screenRecording
    case microphone
    case camera
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screenRecording: "Screen Recording"
        case .microphone: "Microphone"
        case .camera: "Camera"
        case .accessibility: "Accessibility"
        }
    }

    var symbolName: String {
        switch self {
        case .screenRecording: "rectangle.dashed.badge.record"
        case .microphone: "mic.fill"
        case .camera: "video.fill"
        case .accessibility: "accessibility"
        }
    }

    var explanation: String {
        switch self {
        case .screenRecording:
            "Lets \(AppInfo.name) see your screen. Needed for every screenshot and recording."
        case .microphone:
            "Records your voice during a screen recording, only when you turn the mic on."
        case .camera:
            "Shows your webcam as a bubble in a recording, only when you turn it on."
        case .accessibility:
            "Auto-scrolls for long screenshots, shows keys you press in recordings, and detects Shift-drag for the Action Wheel."
        }
    }

    var settingsURL: URL {
        let anchor = switch self {
        case .screenRecording: "Privacy_ScreenCapture"
        case .microphone: "Privacy_Microphone"
        case .camera: "Privacy_Camera"
        case .accessibility: "Privacy_Accessibility"
        }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)")!
    }

    /// macOS applies a Screen Recording grant to a running process only after it relaunches.
    var needsRelaunchAfterGrant: Bool { self == .screenRecording }
}

enum PermissionStatus: Sendable, Equatable {
    case granted
    case denied
    /// Never asked, so the system prompt can still be shown.
    case notDetermined
    /// Blocked by device management; the user can't change it.
    case restricted
}
