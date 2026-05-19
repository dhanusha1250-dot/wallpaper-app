import SwiftUI

/// The gallery: a grid of live, hover-interactive previews on the left and a
/// control panel on the right.
struct PickerView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 0) {
            gallery
            Divider()
            controls
                .frame(width: 320)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 580)
    }

    private var gallery: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live Wallpapers")
                        .font(.system(size: 30, weight: .bold))
                    Text("Pick a scene — it applies to your desktop instantly. Hover a preview to try its interaction.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 14)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300), spacing: 18)],
                    spacing: 18
                ) {
                    ForEach(WallpaperKind.allCases) { kind in
                        WallpaperCard(
                            kind: kind,
                            isSelected: settings.kind == kind,
                            settings: settings)
                    }
                }
            }
            .padding(26)
        }
    }

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Now Showing")
                    .font(.headline)

                LivePreview(kind: settings.kind, settings: settings)
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.12)))

                Text(settings.kind.title)
                    .font(.title3.bold())
                Label(settings.kind.interactionHint, systemImage: "hand.point.up.left.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if settings.kind == .video {
                    videoControls
                }

                Divider()

                Toggle("Interactive on desktop", isOn: $settings.interactive)
                Text("When on, the wallpaper reacts to your cursor and clicks. It is then drawn above the desktop icons.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Toggle("Pause animation", isOn: $settings.isPaused)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Animation speed  %.2f×", settings.speed))
                        .font(.caption)
                    Slider(value: $settings.speed, in: 0.25...2.5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dim  \(Int(settings.dim * 100))%")
                        .font(.caption)
                    Slider(value: $settings.dim, in: 0...0.8)
                }

                Spacer(minLength: 8)

                Text("Tip: the menu-bar ✦ icon switches wallpapers without opening this window.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(22)
        }
    }

    private var videoControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text("Video Source")
                .font(.headline)
            Button {
                if let url = VideoPicker.choose() {
                    settings.videoPath = url.path
                }
            } label: {
                Label("Choose Video…", systemImage: "folder.fill")
            }
            Text(settings.videoURL?.lastPathComponent ?? "No video selected")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            VStack(alignment: .leading, spacing: 4) {
                Text("Scaling").font(.caption)
                Picker("", selection: $settings.videoFillMode) {
                    ForEach(VideoFillMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Toggle("Mute audio", isOn: $settings.videoMuted)

            Text("Supports MP4, MOV, M4V and other QuickTime-readable formats.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
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
