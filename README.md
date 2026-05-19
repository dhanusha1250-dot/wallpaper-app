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
- **Gallery UI** with *live, hover-interactive previews* — try a wallpaper before you apply it.
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

macOS draws desktop icons in a full-screen Finder window, so a wallpaper sitting
*behind* the icons cannot receive clicks. The app handles this with two modes:

- **Interactive ON** — the wallpaper is drawn just above the desktop icons so it
  receives cursor and click events. (Trade-off: it covers the icons.)
- **Interactive OFF** — the wallpaper sits behind the icons as a pure ambient
  background.

Toggle this in the gallery or from the menu bar. The gallery previews are always
interactive — hover and click them regardless of the mode.

## Project layout

```
Sources/LiveWallpaper/
  main.swift / AppDelegate.swift     App entry & lifecycle
  AppSettings.swift                  Persisted, observable settings
  WallpaperKind.swift                Catalog of scenes
  WallpaperManager.swift             One desktop window per screen
  WallpaperWindow.swift              Desktop-level window + mouse relay
  InteractionModel.swift             Cursor / click state bridge
  WallpaperRootView.swift            Scene router
  PickerView.swift                   Gallery UI
  MenuBarController.swift            Menu-bar item
  Support.swift                      Shared animation helpers
  VideoWallpaper.swift               Looping video playback (AVFoundation)
  *Wallpaper.swift                   The animated scenes (SwiftUI Canvas)
```

Each scene is a SwiftUI `Canvas` driven by `TimelineView(.animation)`, with a
small simulation class stepped by elapsed time. To add a new wallpaper: add a
`WallpaperKind` case and a matching view, then a branch in `WallpaperRootView`.
