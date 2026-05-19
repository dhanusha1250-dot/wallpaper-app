import AppKit
import SwiftUI

/// A borderless, full-screen window that sits at the desktop-picture layer
/// (below the desktop icons) and hosts a SwiftUI wallpaper scene. One window
/// is created per `NSScreen`.
///
/// The window never receives mouse events itself — interaction is driven by
/// `DesktopMouseMonitor` — so desktop icons always stay visible and usable.
final class WallpaperWindow: NSWindow {
    private(set) var currentKind: WallpaperKind?
    let model = InteractionModel()
    /// The screen frame, in global coordinates, that this window covers.
    let screenFrame: CGRect

    private var hosting: NSView?

    /// Behind the desktop icons, above the static system wallpaper.
    static let ambientLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))

    init(screen: NSScreen) {
        screenFrame = screen.frame
        super.init(contentRect: screen.frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        level = Self.ambientLevel
        setFrame(screen.frame, display: true)
        contentView = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
    }

    required init?(coder: NSCoder) {
        fatalError("WallpaperWindow is not created from a nib")
    }

    // A wallpaper must never steal keyboard focus from real apps.
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func setKind(_ kind: WallpaperKind, settings: AppSettings) {
        currentKind = kind
        hosting?.removeFromSuperview()

        let root = WallpaperRootView(kind: kind, model: model, settings: settings)
        let host = NSHostingView(rootView: AnyView(root))
        host.frame = contentView!.bounds
        host.autoresizingMask = [.width, .height]
        contentView!.addSubview(host)
        hosting = host
    }
}
