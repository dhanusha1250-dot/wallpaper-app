import SwiftUI
import AppKit

/// App information and a short usage guide.
struct AboutPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Live Wallpaper Studio")
                    .font(.largeTitle.bold())
                Text("Version 1.0")
                    .foregroundStyle(.secondary)

                Text("Animated, interactive wallpapers and looping video backgrounds for macOS.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
                    .foregroundStyle(.secondary)

                Divider().frame(maxWidth: 440)

                VStack(alignment: .leading, spacing: 10) {
                    guideRow("sparkles", "Wallpapers",
                             "Pick from six animated scenes. Each reacts to your cursor and clicks.")
                    guideRow("film.stack", "Video Library",
                             "Add MP4 / MOV files or whole folders, then set any clip as your wallpaper.")
                    guideRow("hand.point.up.left.fill", "Interaction",
                             "Toggle interactive mode in Settings. Interactive wallpapers draw above desktop icons.")
                    guideRow("menubar.arrow.up.rectangle", "Menu bar",
                             "The ✦ menu-bar icon switches wallpapers and videos without opening this window.")
                }
                .frame(maxWidth: 440, alignment: .leading)

                Divider().frame(maxWidth: 440)

                Text("See APP_STORE_AND_MARKETING.md in the project for the release roadmap.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Button("Quit Live Wallpaper") {
                    NSApp.terminate(nil)
                }
                .padding(.top, 4)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About")
    }

    private func guideRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
