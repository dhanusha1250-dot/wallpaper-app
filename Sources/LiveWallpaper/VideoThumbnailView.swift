import SwiftUI
import AVFoundation

/// Renders a poster frame for a video file, generated off the main thread.
struct VideoThumbnailView: View {
    let url: URL
    @State private var image: NSImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [Color(white: 0.16), Color(white: 0.08)],
                               startPoint: .top, endPoint: .bottom)
                Image(systemName: failed ? "film.slash" : "film")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .clipped()
        .task(id: url.path) {
            image = nil
            failed = false
            if let poster = await ThumbnailGenerator.poster(for: url) {
                image = poster
            } else {
                failed = true
            }
        }
    }
}

enum ThumbnailGenerator {
    static func poster(for url: URL) async -> NSImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 400)
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        guard let result = try? await generator.image(at: time) else { return nil }
        return NSImage(cgImage: result.image, size: .zero)
    }
}
