import AppKit

/// The menu-bar (status item) entry point. Lets the user switch wallpapers,
/// pick videos, and toggle modes without opening the gallery.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settings: AppSettings
    private let library: VideoLibrary
    var onOpenGallery: (() -> Void)?

    init(settings: AppSettings, library: VideoLibrary) {
        self.settings = settings
        self.library = library
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

        // Animated scenes.
        let wallpapers = NSMenu()
        for kind in WallpaperKind.allCases {
            let item = NSMenuItem(title: kind.title, action: #selector(pickKind(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = kind
            item.state = (kind == settings.kind) ? .on : .off
            wallpapers.addItem(item)
        }
        let wallpaperItem = NSMenuItem(title: "Wallpaper", action: nil, keyEquivalent: "")
        wallpaperItem.submenu = wallpapers
        menu.addItem(wallpaperItem)

        // Saved videos.
        let videoMenu = NSMenu()
        let videos = library.allVideos
        for video in videos.prefix(25) {
            let item = NSMenuItem(title: video.name, action: #selector(pickVideo(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = video.path
            item.state = (settings.kind == .video && settings.videoPath == video.path) ? .on : .off
            videoMenu.addItem(item)
        }
        if !videos.isEmpty { videoMenu.addItem(.separator()) }
        let addVideo = videoMenu.addItem(withTitle: "Add Video…",
                                         action: #selector(addVideo),
                                         keyEquivalent: "")
        addVideo.target = self
        let addFolder = videoMenu.addItem(withTitle: "Add Folder…",
                                          action: #selector(addFolder),
                                          keyEquivalent: "")
        addFolder.target = self
        let videoItem = NSMenuItem(title: "Video Library", action: nil, keyEquivalent: "")
        videoItem.submenu = videoMenu
        menu.addItem(videoItem)

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

    @objc private func pickKind(_ sender: NSMenuItem) {
        if let kind = sender.representedObject as? WallpaperKind {
            settings.kind = kind
        }
    }

    @objc private func pickVideo(_ sender: NSMenuItem) {
        if let path = sender.representedObject as? String {
            settings.videoPath = path
            settings.kind = .video
        }
    }

    @objc private func addVideo() {
        let urls = VideoPicker.chooseMultiple()
        guard !urls.isEmpty else { return }
        library.addVideos(urls)
        if let first = urls.first {
            settings.videoPath = first.path
            settings.kind = .video
        }
    }

    @objc private func addFolder() {
        if let url = VideoPicker.chooseFolder() {
            library.addFolder(url)
        }
    }

    @objc private func toggleInteractive() { settings.interactive.toggle() }
    @objc private func togglePause() { settings.isPaused.toggle() }
}
