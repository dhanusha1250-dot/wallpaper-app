import Foundation

/// A video file the user has added to their library.
struct SavedVideo: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var path: String
    var dateAdded = Date()

    var url: URL { URL(fileURLWithPath: path) }
    var exists: Bool { FileManager.default.fileExists(atPath: path) }
}

/// A folder that is scanned for video files.
struct WatchedFolder: Identifiable, Codable, Hashable {
    var id = UUID()
    var path: String
    var dateAdded = Date()

    var url: URL { URL(fileURLWithPath: path) }
}

/// The user's persistent collection of background videos: individually added
/// files plus folders that are scanned for video files.
final class VideoLibrary: ObservableObject {
    @Published private(set) var savedVideos: [SavedVideo] = []
    @Published private(set) var folders: [WatchedFolder] = []
    /// Videos discovered inside watched folders; refreshed by `rescanFolders()`.
    @Published private(set) var folderVideos: [SavedVideo] = []

    static let videoExtensions: Set<String> = ["mp4", "m4v", "mov", "qt"]

    private let defaults = UserDefaults.standard
    private let storageKey = "wallpaper.videoLibrary"

    init() {
        load()
        rescanFolders()
    }

    /// Every video the user can choose, de-duplicated by path, newest first.
    var allVideos: [SavedVideo] {
        var seen = Set<String>()
        return (savedVideos + folderVideos)
            .filter { seen.insert($0.path).inserted }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    func isSaved(path: String) -> Bool {
        savedVideos.contains { $0.path == path }
    }

    func addVideos(_ urls: [URL]) {
        for url in urls {
            guard !savedVideos.contains(where: { $0.path == url.path }) else { continue }
            savedVideos.insert(
                SavedVideo(name: url.deletingPathExtension().lastPathComponent,
                           path: url.path),
                at: 0)
        }
        save()
    }

    func removeVideo(_ video: SavedVideo) {
        savedVideos.removeAll { $0.id == video.id }
        save()
    }

    func addFolder(_ url: URL) {
        guard !folders.contains(where: { $0.path == url.path }) else { return }
        folders.append(WatchedFolder(path: url.path))
        save()
        rescanFolders()
    }

    func removeFolder(_ folder: WatchedFolder) {
        folders.removeAll { $0.id == folder.id }
        save()
        rescanFolders()
    }

    /// Walks every watched folder (recursively) collecting playable video files.
    func rescanFolders() {
        let fileManager = FileManager.default
        var discovered: [SavedVideo] = []
        for folder in folders {
            guard let enumerator = fileManager.enumerator(
                at: folder.url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let fileURL as URL in enumerator {
                guard Self.videoExtensions.contains(fileURL.pathExtension.lowercased())
                else { continue }
                discovered.append(
                    SavedVideo(name: fileURL.deletingPathExtension().lastPathComponent,
                               path: fileURL.path))
            }
        }
        folderVideos = discovered
    }

    // MARK: - Persistence

    private struct Stored: Codable {
        var videos: [SavedVideo]
        var folders: [WatchedFolder]
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode(Stored.self, from: data)
        else { return }
        savedVideos = stored.videos
        folders = stored.folders
    }

    private func save() {
        let stored = Stored(videos: savedVideos, folders: folders)
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
