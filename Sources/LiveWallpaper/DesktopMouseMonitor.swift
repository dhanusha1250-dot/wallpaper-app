import AppKit

/// Tracks the cursor across the desktop with a *passive* global event monitor
/// and feeds each wallpaper window's `InteractionModel`.
///
/// Because the monitor only observes events (it never consumes them), desktop
/// icons, folders and mounted disk images keep working normally and the
/// wallpaper window can stay below them.
final class DesktopMouseMonitor {
    private var monitor: Any?
    private var windows: [WallpaperWindow] = []

    /// Updates the tracked windows and starts/stops monitoring.
    func update(windows: [WallpaperWindow], enabled: Bool) {
        self.windows = windows
        if enabled {
            if monitor == nil { start() }
        } else {
            stop()
        }
    }

    private func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .leftMouseDragged]
        ) { [weak self] event in
            self?.handle(event)
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        clearAll()
    }

    private func clearAll() {
        for window in windows {
            window.model.cursor = nil
            window.model.cursorActive = false
        }
    }

    private func handle(_ event: NSEvent) {
        let location = NSEvent.mouseLocation  // global, bottom-left origin
        let isClick = event.type == .leftMouseDown
        for window in windows {
            let frame = window.screenFrame
            guard frame.contains(location) else {
                window.model.cursor = nil
                window.model.cursorActive = false
                continue
            }
            // Convert to the window's local, top-left-origin coordinates.
            let local = CGPoint(x: location.x - frame.minX,
                                y: frame.maxY - location.y)
            window.model.cursor = local
            window.model.cursorActive = true
            if isClick { window.model.click(at: local) }
        }
    }

    deinit { stop() }
}
