# Live Wallpaper Studio — TODO

Tracked checklist on the road from prototype to shippable product.
See `APP_STORE_AND_MARKETING.md` for the full rationale behind §3–§4.

## 1. Build & verify (do this first)

- [ ] `swift build` on macOS 13+ / Xcode 15+ — fix all compiler errors
- [ ] `./build.sh` produces a launchable `LiveWallpaper.app`
- [ ] App launches, menu-bar icon appears, gallery window opens

## 2. Functional testing

- [ ] All 6 animated scenes render and react to cursor + clicks
- [ ] Video wallpaper plays, loops seamlessly, honors Fill / Fit / Stretch
- [ ] Mute toggle works; audio behaves as expected (see note below)
- [ ] Video library: add files, add folder (recursive), remove, rescan
- [ ] Library persists across relaunch
- [ ] Thumbnails generate for each clip; "Missing" badge for moved files
- [ ] Interactive ON → desktop icons / folders / disk images stay visible
      *and* the scene reacts to the cursor
- [ ] Interactive OFF → ambient only, no cursor reaction
- [ ] Menu bar: switch scenes, switch videos, toggle interactive / pause
- [ ] Settings persist; Restore Defaults works
- [ ] Multi-display: one wallpaper per screen; plug / unplug a monitor

## 3. Known gaps & likely bugs

- [ ] Verify global-monitor cursor mapping on Retina + mixed-scaling monitors
- [ ] Behavior across Spaces / Mission Control / Stage Manager
- [ ] Energy: pause rendering when the desktop is fully occluded
      (`NSWindow.occlusionState`)
- [ ] Energy: throttle / pause on battery & Low Power Mode
- [ ] Respect Reduce Motion accessibility setting
- [ ] Gallery runs 6+ live `Canvas` previews at once — confirm it's smooth
- [ ] Handle video files on external / network drives that disappear

## 4. App Store engineering blockers

- [ ] Enable App Sandbox + entitlements
- [ ] Replace plain file paths with **security-scoped bookmarks**
      (current persistence breaks under the sandbox)
- [ ] Hardened Runtime, code signing, notarization
- [ ] Convert to / wrap in a proper Xcode project
- [ ] App icon set (16–1024 px) + asset catalog + accent color
- [ ] `PrivacyInfo.xcprivacy` privacy manifest
- [ ] Launch at login via `SMAppService`
- [ ] First-run onboarding screen
- [ ] Disk thumbnail cache
- [ ] Validate chosen files are playable (`AVAsset.isPlayable`)
- [ ] Localization (externalize strings)
- [ ] Accessibility: VoiceOver labels, keyboard navigation
- [ ] Unit tests (simulation math, `VideoLibrary` persistence) + CI

## 5. App Store submission

- [ ] Apple Developer Program enrollment
- [ ] App Store Connect record
- [ ] Screenshots + App Preview video
- [ ] Metadata: name, subtitle, description, keywords, category
- [ ] Privacy policy URL, support URL
- [ ] Age rating + export compliance
- [ ] Pricing & availability

## Notes

- **Audio:** MP4 audio *will* play if the user turns off "Mute video audio"
  in Settings. It defaults to muted, which is the right default for a
  wallpaper — keep it that way.
