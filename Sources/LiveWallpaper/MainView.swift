import SwiftUI

/// Top-level navigation sections of the gallery window.
enum AppTab: String, CaseIterable, Identifiable {
    case wallpapers
    case videos
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wallpapers: return "Wallpapers"
        case .videos:     return "Video Library"
        case .settings:   return "Settings"
        case .about:      return "About"
        }
    }

    var symbol: String {
        switch self {
        case .wallpapers: return "sparkles"
        case .videos:     return "film.stack"
        case .settings:   return "gearshape"
        case .about:      return "info.circle"
        }
    }
}

/// The gallery window: a sidebar of tabs plus a detail page for each.
struct MainView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var library: VideoLibrary
    @State private var tab: AppTab? = .wallpapers

    var body: some View {
        NavigationSplitView {
            List(AppTab.allCases, id: \.self, selection: $tab) { item in
                Label(item.title, systemImage: item.symbol)
                    .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.tint)
                    Text("Live Wallpaper")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 4)
            }
        } detail: {
            detailPage
                .frame(minWidth: 660, minHeight: 560)
        }
    }

    @ViewBuilder
    private var detailPage: some View {
        switch tab ?? .wallpapers {
        case .wallpapers:
            WallpapersPage(settings: settings)
        case .videos:
            VideoLibraryPage(settings: settings, library: library)
        case .settings:
            SettingsPage(settings: settings)
        case .about:
            AboutPage()
        }
    }
}
