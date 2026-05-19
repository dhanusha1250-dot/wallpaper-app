import AppKit
import SwiftUI

/// Manages the gallery window. Promotes the app to a regular (Dock) app while
/// the window is visible so it behaves like a normal settings window.
final class PickerWindowController {
    private var window: NSWindow?
    private let settings: AppSettings
    private let library: VideoLibrary

    init(settings: AppSettings, library: VideoLibrary) {
        self.settings = settings
        self.library = library
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1120, height: 740),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            window.title = "Live Wallpaper Studio"
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 980, height: 640)
            window.center()
            window.contentView = NSHostingView(
                rootView: MainView(settings: settings, library: library))
            self.window = window
        }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
