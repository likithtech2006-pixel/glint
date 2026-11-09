import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hosted unit tests launch the app too; they must not open windows.
        guard !AppInfo.isRunningTests else { return }
        let coordinator = AppCoordinator()
        coordinator.start()
        self.coordinator = coordinator
    }

    /// Fires on a Dock click, or when the already-running app is opened again from Finder.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            coordinator?.showSettings()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
