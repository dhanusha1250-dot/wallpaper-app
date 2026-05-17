import AppKit

/// The menu-bar (status item) entry point. Lets the user switch wallpapers and
/// toggle modes without opening the gallery.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settings: AppSettings
    var onOpenGallery: (() -> Void)?

    init(settings: AppSettings) {
        self.settings = settings
        super.init()
        statusItem.button?.image = NSImage(
            systemSymbolName: "sparkles",
            accessibilityDescription: "Live Wallpaper")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let open = menu.addItem(withTitle: "Open Wallpaper Gallery…",
                                action: #selector(openGallery),
                                keyEquivalent: "")
        open.target = self
        menu.addItem(.separator())

        let wallpapers = NSMenu()
        for kind in WallpaperKind.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(pick(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = kind
            item.state = (kind == settings.kind) ? .on : .off
            wallpapers.addItem(item)
        }
        let wallpaperItem = NSMenuItem(title: "Wallpaper", action: nil, keyEquivalent: "")
        wallpaperItem.submenu = wallpapers
        menu.addItem(wallpaperItem)

        let interactive = menu.addItem(withTitle: "Interactive Mode",
                                       action: #selector(toggleInteractive),
                                       keyEquivalent: "")
        interactive.target = self
        interactive.state = settings.interactive ? .on : .off

        let pause = menu.addItem(withTitle: "Pause Animation",
                                 action: #selector(togglePause),
                                 keyEquivalent: "")
        pause.target = self
        pause.state = settings.isPaused ? .on : .off

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Live Wallpaper",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
    }

    @objc private func openGallery() { onOpenGallery?() }

    @objc private func pick(_ sender: NSMenuItem) {
        if let kind = sender.representedObject as? WallpaperKind {
            settings.kind = kind
        }
    }

    @objc private func toggleInteractive() { settings.interactive.toggle() }
    @objc private func togglePause() { settings.isPaused.toggle() }
}
