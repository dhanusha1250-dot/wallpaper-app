import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

/// How a video is scaled to fill the screen.
enum VideoFillMode: String, CaseIterable, Identifiable {
    case fill
    case fit
    case stretch

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fill:    return "Fill"
        case .fit:     return "Fit"
        case .stretch: return "Stretch"
        }
    }

    var gravity: AVLayerVideoGravity {
        switch self {
        case .fill:    return .resizeAspectFill
        case .fit:     return .resizeAspect
        case .stretch: return .resize
        }
    }
}

/// Shared file picker for choosing a background video.
enum VideoPicker {
    static func choose() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a Background Video"
        panel.prompt = "Use Video"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.movie, .audiovisualContent, .video,
                                     .mpeg4Movie, .quickTimeMovie]
        return panel.runModal() == .OK ? panel.url : nil
    }
}

/// Plays a user-chosen video file (MP4, MOV, M4V, …) as the wallpaper, on a
/// seamless loop. A light interactive overlay keeps clicks/cursor responsive.
struct VideoWallpaper: View {
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        ZStack {
            if let url = settings.videoURL,
               FileManager.default.fileExists(atPath: url.path) {
                VideoLayerView(url: url,
                               fillMode: settings.videoFillMode,
                               muted: settings.videoMuted,
                               paused: settings.isPaused,
                               rate: Float(max(settings.speed, 0.1)))
            } else {
                VideoPlaceholder()
            }
            InteractiveGlowOverlay(model: model, paused: settings.isPaused)
        }
    }
}

/// Shown when no video file has been selected yet.
private struct VideoPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.18),
                         Color(red: 0.04, green: 0.05, blue: 0.10)],
                startPoint: .top, endPoint: .bottom)
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.7))
                Text("No video selected")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Open Live Wallpaper Studio to choose an MP4 or MOV file.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

/// A subtle cursor spotlight + click ripples drawn over the video.
private struct InteractiveGlowOverlay: View {
    @ObservedObject var model: InteractionModel
    let paused: Bool

    var body: some View {
        TimelineView(.animation(paused: paused)) { timeline in
            Canvas { context, _ in
                if let cursor = model.cursor {
                    var glow = context
                    glow.blendMode = .plusLighter
                    let r: CGFloat = 170
                    glow.fill(
                        Path(ellipseIn: CGRect(x: cursor.x - r, y: cursor.y - r,
                                               width: r * 2, height: r * 2)),
                        with: .radialGradient(
                            Gradient(colors: [Color.white.opacity(0.16), .clear]),
                            center: cursor, startRadius: 0, endRadius: r))
                }
                context.drawRipples(model.pulses, now: timeline.date,
                                    color: .white, maxRadius: 320, life: 1.6)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Bridges an `AVPlayerLayer` (looping video) into SwiftUI.
struct VideoLayerView: NSViewRepresentable {
    let url: URL
    let fillMode: VideoFillMode
    let muted: Bool
    let paused: Bool
    let rate: Float

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        context.coordinator.view = view
        context.coordinator.load(url: url)
        apply(context.coordinator)
        return view
    }

    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.load(url: url)
        }
        apply(context.coordinator)
    }

    static func dismantleNSView(_ nsView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
    }

    private func apply(_ coordinator: Coordinator) {
        coordinator.view?.playerLayer.videoGravity = fillMode.gravity
        coordinator.player?.isMuted = muted
        if paused {
            coordinator.player?.pause()
        } else {
            coordinator.player?.play()
            coordinator.player?.rate = rate
        }
    }

    final class Coordinator {
        weak var view: PlayerContainerView?
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
        var currentURL: URL?

        func load(url: URL) {
            currentURL = url
            let item = AVPlayerItem(url: url)
            let queue = AVQueuePlayer()
            // AVPlayerLooper gives a gapless, seamless loop.
            looper = AVPlayerLooper(player: queue, templateItem: item)
            player = queue
            view?.playerLayer.player = queue
        }
    }
}

/// Layer-backed view whose backing layer hosts the video.
final class PlayerContainerView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("PlayerContainerView is not created from a nib")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
