import SwiftUI

/// Manage saved video files and watched folders, and set any clip as the
/// live desktop wallpaper.
struct VideoLibraryPage: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var library: VideoLibrary

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if library.folders.isEmpty && library.allVideos.isEmpty {
                    emptyState
                } else {
                    if !library.folders.isEmpty { foldersSection }
                    videosSection
                }
            }
            .padding(26)
        }
        .navigationTitle("Video Library")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Video Library")
                    .font(.system(size: 28, weight: .bold))
                Text("Add MP4 or MOV files and folders. Set any clip as your live wallpaper at any time.")
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                Button(action: addVideos) {
                    Label("Add Video…", systemImage: "plus")
                }
                Button(action: addFolder) {
                    Label("Add Folder…", systemImage: "folder.badge.plus")
                }
                if !library.folders.isEmpty {
                    Button { library.rescanFolders() } label: {
                        Label("Rescan Folders", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Your library is empty")
                .font(.title3.bold())
            Text("Add individual video files or a whole folder to build a collection you can switch between any time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watched Folders")
                .font(.headline)
            ForEach(library.folders) { folder in
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(folder.url.lastPathComponent)
                            .font(.subheadline)
                        Text(folder.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        library.removeFolder(folder)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.08)))
            }
        }
    }

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Videos (\(library.allVideos.count))")
                .font(.headline)
            if library.allVideos.isEmpty {
                Text("No video files found in your watched folders.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(library.allVideos) { video in
                        VideoLibraryCard(
                            video: video,
                            isCurrent: settings.kind == .video && settings.videoPath == video.path,
                            canRemove: library.isSaved(path: video.path),
                            onSelect: { select(video) },
                            onRemove: { library.removeVideo(video) })
                    }
                }
            }
        }
    }

    private func select(_ video: SavedVideo) {
        settings.videoPath = video.path
        settings.kind = .video
    }

    private func addVideos() {
        let urls = VideoPicker.chooseMultiple()
        guard !urls.isEmpty else { return }
        library.addVideos(urls)
        if let first = urls.first {
            select(SavedVideo(name: first.lastPathComponent, path: first.path))
        }
    }

    private func addFolder() {
        if let url = VideoPicker.chooseFolder() {
            library.addFolder(url)
        }
    }
}

/// A tile for one saved video.
struct VideoLibraryCard: View {
    let video: SavedVideo
    let isCurrent: Bool
    let canRemove: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // A fixed 16:10 base guarantees every card is the same size,
            // regardless of selection state or thumbnail load progress.
            Color.clear
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
                .overlay { VideoThumbnailView(url: video.url) }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if isCurrent {
                        Label("On Desktop", systemImage: "checkmark.circle.fill")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if !video.exists {
                        Label("Missing", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }

            HStack(spacing: 6) {
                Text(video.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Remove from library")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrent ? Color.accentColor.opacity(0.14) : Color.gray.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isCurrent ? Color.accentColor : Color.gray.opacity(0.18),
                              lineWidth: isCurrent ? 2 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onSelect)
    }
}
