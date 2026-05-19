import SwiftUI

/// The animated-scene gallery: a grid of live, hover-interactive previews.
struct WallpapersPage: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wallpapers")
                        .font(.system(size: 28, weight: .bold))
                    Text("Choose a scene — it applies to your desktop instantly. Hover any preview to try its interaction.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300), spacing: 18)],
                    spacing: 18
                ) {
                    ForEach(WallpaperKind.allCases) { kind in
                        WallpaperCard(kind: kind,
                                      isSelected: settings.kind == kind,
                                      settings: settings)
                    }
                }
            }
            .padding(26)
        }
        .navigationTitle("Wallpapers")
    }
}

/// A single gallery tile with a live, hover-interactive preview.
struct WallpaperCard: View {
    let kind: WallpaperKind
    let isSelected: Bool
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LivePreview(kind: kind, settings: settings)
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, kind.accent)
                            .padding(8)
                            .shadow(radius: 3)
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: kind.symbol)
                        .foregroundStyle(kind.accent)
                    Text(kind.title)
                        .font(.headline)
                }
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? kind.accent.opacity(0.14) : Color.gray.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isSelected ? kind.accent : Color.gray.opacity(0.18),
                              lineWidth: isSelected ? 2 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture { settings.kind = kind }
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}

/// Renders a real wallpaper scene and feeds it cursor data from hover, so the
/// gallery previews are themselves interactive.
struct LivePreview: View {
    let kind: WallpaperKind
    @ObservedObject var settings: AppSettings
    @StateObject private var model = InteractionModel()

    var body: some View {
        WallpaperRootView(kind: kind, model: model, settings: settings)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    model.cursor = point
                    model.cursorActive = true
                case .ended:
                    model.cursor = nil
                    model.cursorActive = false
                }
            }
    }
}
