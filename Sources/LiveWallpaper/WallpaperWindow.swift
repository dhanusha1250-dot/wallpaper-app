import AppKit
import SwiftUI

/// A borderless, full-screen window that sits at the desktop layer and hosts a
/// SwiftUI wallpaper scene. One window is created per `NSScreen`.
final class WallpaperWindow: NSWindow {
    private(set) var currentKind: WallpaperKind?
    private(set) var interactive = false

    let model = InteractionModel()
    private let relay = InteractionRelayView()
    private var hosting: NSView?

    /// Behind the desktop icons — pure ambient wallpaper.
    static let ambientLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
    /// Above the desktop icons so the scene can receive mouse events.
    static let interactiveLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

    init(screen: NSScreen) {
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

        let container = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        contentView = container
        relay.model = model
        relay.autoresizingMask = [.width, .height]
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

        // The relay always stays on top so it captures pointer events.
        relay.frame = contentView!.bounds
        contentView!.addSubview(relay)
    }

    func setInteractive(_ on: Bool) {
        interactive = on
        relay.enabled = on
        ignoresMouseEvents = !on
        level = on ? Self.interactiveLevel : Self.ambientLevel
        if !on {
            model.cursor = nil
            model.cursorActive = false
        }
    }
}

/// Transparent overlay that forwards pointer activity into an `InteractionModel`.
/// Flipped so its coordinates line up with SwiftUI's top-left origin.
final class InteractionRelayView: NSView {
    weak var model: InteractionModel?
    var enabled = false { didSet { refreshTracking() } }

    private var trackingAreaRef: NSTrackingArea?

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { enabled }
    override func hitTest(_ point: NSPoint) -> NSView? { enabled ? super.hitTest(point) : nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        refreshTracking()
    }

    private func refreshTracking() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
            self.trackingAreaRef = nil
        }
        guard enabled else { return }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseMoved(with event: NSEvent) { push(event) }
    override func mouseDragged(with event: NSEvent) { push(event) }
    override func mouseEntered(with event: NSEvent) { push(event) }

    override func mouseExited(with event: NSEvent) {
        model?.cursor = nil
        model?.cursorActive = false
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        model?.click(at: point)
        push(event)
    }

    private func push(_ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        model?.cursor = point
        model?.cursorActive = true
    }
}
