import SwiftUI

/// Every live wallpaper the app ships. Add a case here and a branch in
/// `WallpaperRootView` to introduce a new scene.
enum WallpaperKind: String, CaseIterable, Identifiable, Codable {
    case starfield
    case aurora
    case fluid
    case neonGrid
    case bubbles
    case orbs
    case video

    var id: String { rawValue }

    /// The animated scenes shown in the gallery grid. The `.video` kind is
    /// excluded — it is driven entirely by the Video Library.
    static var presets: [WallpaperKind] {
        allCases.filter { $0 != .video }
    }

    var title: String {
        switch self {
        case .starfield: return "Cosmic Drift"
        case .aurora:    return "Aurora"
        case .fluid:     return "Lava Lamp"
        case .neonGrid:  return "Synthwave"
        case .bubbles:   return "Bubbles"
        case .orbs:      return "Lumina"
        case .video:     return "My Video"
        }
    }

    var subtitle: String {
        switch self {
        case .starfield: return "Parallax starfield with gravity"
        case .aurora:    return "Flowing northern lights"
        case .fluid:     return "Drifting metaball blobs"
        case .neonGrid:  return "Retro neon horizon"
        case .bubbles:   return "Rising soap bubbles"
        case .orbs:      return "Soft morphing gradient orbs"
        case .video:     return "Play your own MP4 or MOV"
        }
    }

    var symbol: String {
        switch self {
        case .starfield: return "sparkles"
        case .aurora:    return "moon.stars.fill"
        case .fluid:     return "drop.fill"
        case .neonGrid:  return "grid"
        case .bubbles:   return "circle.circle"
        case .orbs:      return "circle.hexagongrid.fill"
        case .video:     return "film.fill"
        }
    }

    var accent: Color {
        switch self {
        case .starfield: return Color(red: 0.62, green: 0.55, blue: 1.0)
        case .aurora:    return Color(red: 0.36, green: 0.95, blue: 0.74)
        case .fluid:     return Color(red: 1.0, green: 0.58, blue: 0.30)
        case .neonGrid:  return Color(red: 1.0, green: 0.32, blue: 0.72)
        case .bubbles:   return Color(red: 0.42, green: 0.78, blue: 1.0)
        case .orbs:      return Color(red: 0.40, green: 0.86, blue: 0.90)
        case .video:     return Color(red: 0.45, green: 0.65, blue: 1.0)
        }
    }

    var interactionHint: String {
        switch self {
        case .starfield: return "Move the cursor to bend gravity · click for a shockwave"
        case .aurora:    return "The cursor warps the curtains · click to send a ripple"
        case .fluid:     return "The cursor pulls the blobs · click to spawn a new one"
        case .neonGrid:  return "The cursor lights up the grid · click for a pulse"
        case .bubbles:   return "The cursor pushes bubbles aside · click to pop them"
        case .orbs:      return "The cursor drags the nearest orb · click to ripple"
        case .video:     return "Pick any video file · click to send a ripple"
        }
    }
}
