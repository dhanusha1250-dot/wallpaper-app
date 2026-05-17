import SwiftUI

/// Routes to the selected scene and applies the global dim overlay. This is the
/// view embedded both in the desktop windows and in the gallery previews.
struct WallpaperRootView: View {
    let kind: WallpaperKind
    @ObservedObject var model: InteractionModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        ZStack {
            switch kind {
            case .starfield: StarfieldWallpaper(model: model, settings: settings)
            case .aurora:    AuroraWallpaper(model: model, settings: settings)
            case .fluid:     FluidWallpaper(model: model, settings: settings)
            case .neonGrid:  NeonGridWallpaper(model: model, settings: settings)
            case .bubbles:   BubblesWallpaper(model: model, settings: settings)
            case .orbs:      OrbsWallpaper(model: model, settings: settings)
            }
            if settings.dim > 0 {
                Color.black.opacity(settings.dim).allowsHitTesting(false)
            }
        }
        .clipped()
    }
}
