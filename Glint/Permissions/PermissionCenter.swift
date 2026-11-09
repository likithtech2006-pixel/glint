import AppKit
import Observation

@MainActor
@Observable
final class PermissionCenter {
    private(set) var statuses: [PermissionKind: PermissionStatus] = [:]

    private let probe: any PermissionProbe

    init(probe: any PermissionProbe) {
        self.probe = probe
        refresh()
    }

    func status(of kind: PermissionKind) -> PermissionStatus {
        statuses[kind] ?? .notDetermined
    }

    var missing: [PermissionKind] {
        PermissionKind.allCases.filter { status(of: $0) != .granted }
    }

    func refresh() {
        for kind in PermissionKind.allCases {
            let status = probe.status(of: kind)
            // Avoid invalidating views when nothing changed; this runs every second.
            if statuses[kind] != status {
                statuses[kind] = status
            }
        }
    }

    /// Keeps statuses live while a view is on screen. macOS has no change
    /// notification covering these permissions, so poll. Call from `.task`,
    /// which cancels this when the view goes away.
    func watch() async {
        while !Task.isCancelled {
            refresh()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    func request(_ kind: PermissionKind) async {
        await probe.request(kind)
        refresh()
    }

    func openSystemSettings(for kind: PermissionKind) {
        NSWorkspace.shared.open(kind.settingsURL)
    }

    func relaunchApp() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            guard error == nil else { return }
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }
}
