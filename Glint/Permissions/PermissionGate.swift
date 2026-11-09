import AppKit

/// Checks permissions before a feature runs, and explains what's missing rather
/// than letting the feature fail silently.
@MainActor
struct PermissionGate {
    let permissions: PermissionCenter

    /// Returns true when the feature can go ahead.
    func check(_ required: [PermissionKind], for feature: String) -> Bool {
        permissions.refresh()
        guard let kind = required.first(where: { permissions.status(of: $0) != .granted }) else {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "\(feature) needs \(kind.title) access"
        alert.informativeText = informativeText(for: kind)

        let status = permissions.status(of: kind)
        if status != .restricted {
            alert.addButton(withTitle: status == .notDetermined ? "Allow…" : "Open System Settings")
        }
        alert.addButton(withTitle: status == .restricted ? "OK" : "Not Now")

        NSApp.activate()
        let response = alert.runModal()
        guard status != .restricted, response == .alertFirstButtonReturn else { return false }

        if status == .notDetermined {
            Task { await permissions.request(kind) }
        } else {
            permissions.openSystemSettings(for: kind)
        }
        return false
    }

    private func informativeText(for kind: PermissionKind) -> String {
        var text = kind.explanation
        if permissions.status(of: kind) == .restricted {
            text += "\n\nThis Mac’s administrator has blocked it."
        } else if kind.needsRelaunchAfterGrant {
            text += "\n\nAfter you turn it on, relaunch \(AppInfo.name) so macOS applies it."
        }
        return text
    }
}
