import SwiftUI

/// User-facing, persisted configuration. Shared (as an `ObservableObject`)
/// between the gallery UI and the live desktop windows so edits apply instantly.
final class AppSettings: ObservableObject {
    @Published var kind: WallpaperKind { didSet { save() } }
    @Published var speed: Double { didSet { save() } }
    @Published var dim: Double { didSet { save() } }
    @Published var interactive: Bool { didSet { save() } }
    @Published var isPaused: Bool

    /// Background-video settings (used by the `.video` wallpaper).
    @Published var videoPath: String? { didSet { save() } }
    @Published var videoFillMode: VideoFillMode { didSet { save() } }
    @Published var videoMuted: Bool { didSet { save() } }

    var videoURL: URL? {
        videoPath.map { URL(fileURLWithPath: $0) }
    }

    private let defaults = UserDefaults.standard

    init() {
        kind = WallpaperKind(rawValue: defaults.string(forKey: Keys.kind) ?? "") ?? .starfield
        speed = defaults.object(forKey: Keys.speed) as? Double ?? 1.0
        dim = defaults.object(forKey: Keys.dim) as? Double ?? 0.0
        interactive = defaults.object(forKey: Keys.interactive) as? Bool ?? true
        isPaused = false
        videoPath = defaults.string(forKey: Keys.videoPath)
        videoFillMode = VideoFillMode(rawValue: defaults.string(forKey: Keys.videoFillMode) ?? "") ?? .fill
        videoMuted = defaults.object(forKey: Keys.videoMuted) as? Bool ?? true
    }

    func resetToDefaults() {
        speed = 1.0
        dim = 0.0
        interactive = true
        isPaused = false
        videoFillMode = .fill
        videoMuted = true
    }

    private func save() {
        defaults.set(kind.rawValue, forKey: Keys.kind)
        defaults.set(speed, forKey: Keys.speed)
        defaults.set(dim, forKey: Keys.dim)
        defaults.set(interactive, forKey: Keys.interactive)
        defaults.set(videoFillMode.rawValue, forKey: Keys.videoFillMode)
        defaults.set(videoMuted, forKey: Keys.videoMuted)
        if let videoPath {
            defaults.set(videoPath, forKey: Keys.videoPath)
        } else {
            defaults.removeObject(forKey: Keys.videoPath)
        }
    }

    private enum Keys {
        static let kind = "wallpaper.kind"
        static let speed = "wallpaper.speed"
        static let dim = "wallpaper.dim"
        static let interactive = "wallpaper.interactive"
        static let videoPath = "wallpaper.videoPath"
        static let videoFillMode = "wallpaper.videoFillMode"
        static let videoMuted = "wallpaper.videoMuted"
    }
}
