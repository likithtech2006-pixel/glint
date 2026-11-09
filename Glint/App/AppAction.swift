/// Everything the user can trigger from the menu bar. Global hotkeys will bind to these too.
enum AppAction: String, CaseIterable, Identifiable {
    case captureArea
    case captureWindow
    case captureFullScreen
    case recordScreen
    case convertFiles
    case openHistory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .captureArea: "Capture Area"
        case .captureWindow: "Capture Window"
        case .captureFullScreen: "Capture Full Screen"
        case .recordScreen: "Record Screen"
        case .convertFiles: "Convert Files…"
        case .openHistory: "History…"
        }
    }

    var symbolName: String {
        switch self {
        case .captureArea: "crop"
        case .captureWindow: "macwindow"
        case .captureFullScreen: "display"
        case .recordScreen: "record.circle"
        case .convertFiles: "arrow.triangle.2.circlepath"
        case .openHistory: "clock.arrow.circlepath"
        }
    }

    var requiredPermissions: [PermissionKind] {
        switch self {
        case .captureArea, .captureWindow, .captureFullScreen, .recordScreen: [.screenRecording]
        case .convertFiles, .openHistory: []
        }
    }

    /// The build phase that implements this action. Removed once they all exist.
    var plannedPhase: Int {
        switch self {
        case .captureArea, .captureWindow, .captureFullScreen: 2
        case .recordScreen: 3
        case .convertFiles: 9
        case .openHistory: 13
        }
    }
}
