import AppKit
import SwiftUI

/// Owns the app's long-lived objects and routes actions between them.
@MainActor
final class AppCoordinator {
    let settings = AppSettings()
    let permissions = PermissionCenter(probe: SystemPermissionProbe())
    let launchAtLogin = LaunchAtLogin()

    private let windows = WindowPresenter()
    private var statusItem: StatusItemController?

    func start() {
        NSApp.mainMenu = MainMenu.make()
        DockIcon.apply(visible: settings.showDockIcon)
        statusItem = StatusItemController(coordinator: self)

        if !settings.hasCompletedOnboarding {
            showPermissions(isFirstRun: true)
        }
    }

    func perform(_ action: AppAction) {
        let gate = PermissionGate(permissions: permissions)
        guard gate.check(action.requiredPermissions, for: action.title) else { return }

        // Replaced phase by phase as each feature lands.
        let alert = NSAlert()
        alert.messageText = "\(action.title) isn’t built yet"
        alert.informativeText = "It arrives in Phase \(action.plannedPhase)."
        NSApp.activate()
        alert.runModal()
    }

    func showSettings() {
        windows.show(.settings, title: "\(AppInfo.name) Settings") { [settings, permissions, launchAtLogin] in
            SettingsView(settings: settings, permissions: permissions, launchAtLogin: launchAtLogin)
        }
    }

    func showPermissions(isFirstRun: Bool = false) {
        let title = isFirstRun ? "Welcome to \(AppInfo.name)" : "Permissions"
        windows.show(.permissions, title: title) { [self] in
            OnboardingView(permissions: permissions, isFirstRun: isFirstRun) { [self] in
                settings.hasCompletedOnboarding = true
                windows.close(.permissions)
            }
        }
    }
}
