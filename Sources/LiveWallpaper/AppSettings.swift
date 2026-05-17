import SwiftUI

/// User-facing, persisted configuration. Shared (as an `ObservableObject`)
/// between the gallery UI and the live desktop windows so edits apply instantly.
final class AppSettings: ObservableObject {
    @Published var kind: WallpaperKind { didSet { save() } }
    @Published var speed: Double { didSet { save() } }
    @Published var dim: Double { didSet { save() } }
    @Published var interactive: Bool { didSet { save() } }
    @Published var isPaused: Bool

    private let defaults = UserDefaults.standard

    init() {
        kind = WallpaperKind(rawValue: defaults.string(forKey: Keys.kind) ?? "") ?? .starfield
        speed = defaults.object(forKey: Keys.speed) as? Double ?? 1.0
        dim = defaults.object(forKey: Keys.dim) as? Double ?? 0.0
        interactive = defaults.object(forKey: Keys.interactive) as? Bool ?? true
        isPaused = false
    }

    private func save() {
        defaults.set(kind.rawValue, forKey: Keys.kind)
        defaults.set(speed, forKey: Keys.speed)
        defaults.set(dim, forKey: Keys.dim)
        defaults.set(interactive, forKey: Keys.interactive)
    }

    private enum Keys {
        static let kind = "wallpaper.kind"
        static let speed = "wallpaper.speed"
        static let dim = "wallpaper.dim"
        static let interactive = "wallpaper.interactive"
    }
}
