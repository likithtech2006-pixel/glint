import AppKit
import SwiftUI

/// Shows SwiftUI views in single-instance windows.
@MainActor
final class WindowPresenter: NSObject, NSWindowDelegate {
    enum Slot: Hashable {
        case settings
        case permissions
    }

    private var windows: [Slot: NSWindow] = [:]

    func show<Content: View>(_ slot: Slot, title: String, @ViewBuilder content: () -> Content) {
        if let existing = windows[slot] {
            bringToFront(existing)
            return
        }

        let window = NSWindow(contentViewController: NSHostingController(rootView: content()))
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        windows[slot] = window
        bringToFront(window)
    }

    func close(_ slot: Slot) {
        windows[slot]?.close()
    }

    /// Dropping the window here tears down its SwiftUI view, ending any `.task` it runs.
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows = windows.filter { $0.value !== window }
    }

    private func bringToFront(_ window: NSWindow) {
        // Without a Dock icon we're never the active app by default, so a plain
        // makeKeyAndOrderFront would open the window behind whatever is frontmost.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
