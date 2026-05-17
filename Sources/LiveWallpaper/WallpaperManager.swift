import AppKit
import Combine

/// Owns one `WallpaperWindow` per screen and keeps them in sync with settings.
final class WallpaperManager {
    let settings: AppSettings
    private var windows: [WallpaperWindow] = []
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings) {
        self.settings = settings
        rebuildWindows()

        // `objectWillChange` fires before the value updates; the async hop to
        // the main queue ensures we read the new settings.
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.reconfigure() }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    @objc private func screensChanged() {
        rebuildWindows()
    }

    private func rebuildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { screen in
            let window = WallpaperWindow(screen: screen)
            window.setKind(settings.kind, settings: settings)
            window.setInteractive(settings.interactive)
            window.orderFront(nil)
            return window
        }
    }

    /// Cheap reconciliation: only rebuild the scene when the wallpaper kind
    /// changes. Speed / dim / pause are observed directly by the SwiftUI views.
    private func reconfigure() {
        for window in windows {
            if window.currentKind != settings.kind {
                window.setKind(settings.kind, settings: settings)
            }
            if window.interactive != settings.interactive {
                window.setInteractive(settings.interactive)
            }
        }
    }
}
