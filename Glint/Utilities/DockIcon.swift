import AppKit

enum DockIcon {
    @MainActor
    static func apply(visible: Bool) {
        NSApp.setActivationPolicy(visible ? .regular : .accessory)
        // Changing policy can push our windows behind other apps.
        NSApp.activate()
    }
}
