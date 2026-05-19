# Live Wallpaper Studio

An animated, **interactive** live-wallpaper app for macOS. It renders a moving
scene on your desktop and ships a polished gallery for picking and tuning it.

![scene picker](https://placehold.co/900x520?text=Live+Wallpaper+Studio)

## Features

- **7 live wallpapers**, each fully interactive:
  - **Cosmic Drift** — parallax starfield; the cursor is a gravity well, clicks scatter the stars.
  - **Aurora** — northern-lights curtains that bend toward the cursor; clicks ripple the sky.
  - **Lava Lamp** — drifting metaball blobs the cursor pulls; clicks spawn new blobs.
  - **Synthwave** — a scrolling neon grid that lights up under the cursor.
  - **Bubbles** — rising soap bubbles you can push aside and pop with a click.
  - **Lumina** — soft morphing gradient orbs; drag the nearest one with the cursor.
  - **My Video** — play your own **MP4 / MOV / M4V** (or any QuickTime-readable
    format) as a seamless looping background, with Fill / Fit / Stretch scaling
    and an optional muted-audio toggle.
- **Tabbed gallery UI** — *Wallpapers*, *Video Library*, *Settings*, and
  *About* pages with a sidebar, and live, hover-interactive previews.
- **Video Library** — save individual video files or whole folders of MP4s,
  and switch to any saved clip at any time (also from the menu bar).
- Real-time controls: animation speed, dim, pause, and an interactive toggle.
- **Menu-bar item** (✦) for switching wallpapers without opening the window.
- Multi-display aware — one wallpaper window per screen.
- Choices persist across launches.

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+ / Xcode 15+ (to build)

## Build & run

```bash
./build.sh          # produces LiveWallpaper.app
open LiveWallpaper.app
```

Or during development:

```bash
swift run
```

The app lives in the menu bar (✦ icon). The gallery opens on first launch;
reopen it any time from the menu bar.

## How interaction works

The wallpaper window always sits at the desktop-picture layer, *below* the
desktop icons — so your icons, folders and mounted disk images are never
hidden.

When **interactive mode** is on, the app uses a passive global mouse monitor
(`NSEvent.addGlobalMonitorForEvents`) to feed cursor and click data to the
wallpaper. Because the monitor only *observes* events and never consumes them,
desktop clicks still reach Finder normally while the scene reacts to you.
When off, the wallpaper is a purely ambient background.

Toggle interactive mode in Settings or from the menu bar. The gallery previews
are always interactive — hover them to try a scene.

## Project layout

```
Sources/LiveWallpaper/
  main.swift / AppDelegate.swift     App entry & lifecycle
  AppSettings.swift                  Persisted, observable settings
  VideoLibrary.swift                 Saved videos + watched folders
  WallpaperKind.swift                Catalog of scenes
  WallpaperManager.swift             One desktop window per screen
  WallpaperWindow.swift              Desktop-level window + mouse relay
  InteractionModel.swift             Cursor / click state bridge
  WallpaperRootView.swift            Scene router
  MainView.swift                     Tabbed gallery shell (sidebar)
  WallpapersPage.swift               Scene gallery grid
  VideoLibraryPage.swift             Video library management
  SettingsPage.swift / AboutPage.swift   Settings & About tabs
  VideoThumbnailView.swift           Video poster-frame generation
  MenuBarController.swift            Menu-bar item
  Support.swift                      Shared animation helpers
  VideoWallpaper.swift               Looping video playback (AVFoundation)
  *Wallpaper.swift                   The animated scenes (SwiftUI Canvas)
```

See `APP_STORE_AND_MARKETING.md` for the roadmap to a shippable release.

Each scene is a SwiftUI `Canvas` driven by `TimelineView(.animation)`, with a
small simulation class stepped by elapsed time. To add a new wallpaper: add a
`WallpaperKind` case and a matching view, then a branch in `WallpaperRootView`.
