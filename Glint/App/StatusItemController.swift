import AppKit

/// The menu bar icon and its menu.
///
/// This is a plain NSStatusItem rather than SwiftUI's MenuBarExtra because later
/// phases need things MenuBarExtra can't do: dropping files on the icon and
/// showing conversion progress in it.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private unowned let coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: AppInfo.name)
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    /// Rebuilt on every open so the missing-permission warning is never stale.
    func menuNeedsUpdate(_ menu: NSMenu) {
        coordinator.permissions.refresh()
        menu.removeAllItems()

        let missing = coordinator.permissions.missing.count
        if missing > 0 {
            let title = missing == 1 ? "1 permission needs attention…" : "\(missing) permissions need attention…"
            let item = addItem(to: menu, title: title, action: #selector(openPermissions))
            item.image = symbol("exclamationmark.triangle.fill")
            menu.addItem(.separator())
        }

        addActions([.captureArea, .captureWindow, .captureFullScreen], to: menu)
        menu.addItem(.separator())
        addActions([.recordScreen], to: menu)
        menu.addItem(.separator())
        addActions([.convertFiles, .openHistory], to: menu)
        menu.addItem(.separator())

        addItem(to: menu, title: "Permissions…", action: #selector(openPermissions))
        addItem(to: menu, title: "Settings…", action: #selector(openSettings), key: ",")
        menu.addItem(.separator())
        addItem(to: menu, title: "Quit \(AppInfo.name)", action: #selector(quit), key: "q")
    }

    private func addActions(_ actions: [AppAction], to menu: NSMenu) {
        for action in actions {
            let item = addItem(to: menu, title: action.title, action: #selector(runAction(_:)))
            item.representedObject = action.rawValue
            item.image = symbol(action.symbolName)
        }
    }

    @discardableResult
    private func addItem(to menu: NSMenu, title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    @objc private func runAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let action = AppAction(rawValue: raw) else { return }
        coordinator.perform(action)
    }

    @objc private func openPermissions() { coordinator.showPermissions() }
    @objc private func openSettings() { coordinator.showSettings() }
    @objc private func quit() { NSApp.terminate(nil) }
}
