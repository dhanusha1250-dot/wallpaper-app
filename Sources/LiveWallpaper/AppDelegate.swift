import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: AppSettings!
    private var manager: WallpaperManager!
    private var menuBar: MenuBarController!
    private var picker: PickerWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings()
        self.settings = settings
        manager = WallpaperManager(settings: settings)
        picker = PickerWindowController(settings: settings)
        menuBar = MenuBarController(settings: settings)
        menuBar.onOpenGallery = { [weak self] in self?.picker.show() }
        picker.show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        picker.show()
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
