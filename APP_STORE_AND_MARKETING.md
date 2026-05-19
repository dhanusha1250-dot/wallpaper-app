# Live Wallpaper Studio — Path to App Store & Marketing

This document covers what is needed to take the current prototype to a
shippable, App Store–worthy product, and how to market it.

---

## 1. Where the app is today

A working macOS prototype (Swift Package) with:

- Six animated, interactive wallpaper scenes.
- A looping video wallpaper with a persistent library (files + folders).
- A tabbed gallery UI, a menu-bar item, and multi-display support.

It is **not yet App Store ready**. The gaps below are the work remaining.

---

## 2. Engineering work required

### 2.1 App Sandbox & file access (critical)

The App Store requires the **App Sandbox** to be enabled. This breaks the
current design in one important way:

- Today the app stores **plain file paths** for videos. Inside the sandbox,
  a plain path grants no access — the app can only read files the user
  explicitly selected, and only for that launch.
- **Fix:** store **security-scoped bookmarks** instead of paths. When the
  user picks a file/folder via `NSOpenPanel`, call
  `url.bookmarkData(options: .withSecurityScope)`, persist the bookmark
  data, and resolve it with `URL(resolvingBookmarkData:options:.withSecurityScope...)`
  on launch. Wrap every access in `startAccessingSecurityScopedResource()` /
  `stopAccessingSecurityScopedResource()`.
- Required entitlements: `com.apple.security.app-sandbox`,
  `com.apple.security.files.user-selected.read-only`, and
  `com.apple.security.files.bookmarks.app-scope`.

### 2.2 Code signing, hardened runtime, notarization

- Enable the **Hardened Runtime**.
- Sign with an **Apple Distribution** certificate; for direct (non-store)
  builds, also **notarize** with `notarytool` and staple the ticket.
- Create an **App ID** and **provisioning profile** in the Apple Developer
  portal with the App Sandbox capability.

### 2.3 Project structure

- Convert from a bare Swift Package to a proper **Xcode app project**
  (or add an Xcode project wrapping the package). The App Store pipeline,
  asset catalogs, entitlements, and Info.plist management all expect this.
- Add an **asset catalog** with a full **app icon set** (16–1024 px) and an
  `AccentColor`.
- Add a **`PrivacyInfo.xcprivacy`** privacy manifest (the app collects no
  data, but the manifest is still required).

### 2.4 Desktop-window behavior (review risk)

The wallpaper window sits at the desktop-picture layer, *below* the desktop
icons, and interaction is driven by a **passive global mouse monitor**
(`NSEvent.addGlobalMonitorForEvents`) rather than by raising the window. This
keeps desktop icons fully visible and clickable, which removes the biggest
review concern. Remaining items to verify:

- Confirm the global monitor needs no special entitlement (mouse-only
  monitoring does not require Input Monitoring / Accessibility permission —
  unlike keyboard monitoring). Re-test under the App Sandbox.
- Keep interactive mode an explicit, clearly explained opt-in.
- Make sure the desktop-level window cooperates correctly with Stage Manager,
  Mission Control and multiple Spaces.

### 2.5 Energy & performance (a live wallpaper *must* get this right)

- **Pause rendering when the desktop is not visible** — observe
  `NSWindow.occlusionState`; when fully covered, stop the `TimelineView`
  animation and the `AVPlayer`.
- **Throttle on battery / Low Power Mode** — drop to a lower frame rate or
  pause video; check `ProcessInfo.processInfo.isLowPowerModeEnabled`.
- Respect **Reduce Motion** (`NSWorkspace.shared
  .accessibilityDisplayShouldReduceMotion`) — offer a static frame.
- Cap GPU cost: lower particle counts on small/integrated GPUs, and stop
  animation on locked screen / screensaver.

### 2.6 Robustness & UX polish

- Handle **missing files** (external drive unplugged, file moved) gracefully
  — already partly done; add re-link prompts.
- **Cache video thumbnails to disk** so the library loads instantly.
- Validate that a chosen file is actually a **playable** video (check
  `AVAsset.isPlayable`) and surface clear errors.
- Add a **first-run onboarding** screen explaining interactive mode and the
  menu-bar item.
- **Launch at login** via `SMAppService` (ServiceManagement) with a toggle.
- Persist per-display wallpaper choices if multi-monitor users want that.

### 2.7 Quality engineering

- **Unit tests** for the simulation/math helpers and `VideoLibrary`
  persistence; **UI smoke tests**.
- **Crash reporting** (e.g., MetricKit, or a privacy-respecting service).
- **Localization** — externalize all strings; ship at least English, and
  add languages based on demand.
- **Accessibility** — VoiceOver labels on every control, full keyboard
  navigation.
- Set up **CI** (build, test, sign, notarize, upload).

---

## 3. App Store submission checklist

- [ ] Apple Developer Program membership ($99/year).
- [ ] App record created in **App Store Connect**.
- [ ] Bundle ID, version, and build number finalized.
- [ ] App Sandbox + entitlements + hardened runtime configured.
- [ ] App icon (all sizes) and screenshots for required display sizes.
- [ ] **App preview video** (wallpapers are visual — this matters a lot).
- [ ] App name, subtitle (30 chars), promotional text, description, keywords.
- [ ] **Category:** primary *Graphics & Design* (or *Lifestyle*); secondary
      *Entertainment*.
- [ ] Privacy policy URL, support URL, marketing URL.
- [ ] Privacy "Nutrition Label" — declare **no data collection**.
- [ ] Age rating questionnaire (likely 4+).
- [ ] Export-compliance answer (no non-exempt encryption).
- [ ] Pricing and territory availability.
- [ ] Pass internal review against the **App Review Guidelines**.

---

## 4. Monetization options

| Model | Pros | Cons |
|---|---|---|
| Paid upfront | Simple, no IAP code | Higher friction; no trial |
| Freemium + IAP packs | Try before buy; recurring sales of wallpaper packs | Needs StoreKit work |
| Subscription | Predictable revenue | Users resist subscriptions for "a wallpaper app" |

**Recommendation:** *freemium*. Ship the six scenes + basic video playback
free; sell **themed wallpaper packs** and "Pro" features (multi-display
per-screen wallpapers, 4K/ProMotion scenes, scheduling, audio-reactive
scenes) as one-time **IAPs**. Optionally a low-cost yearly "all packs"
unlock. This converts the visual nature of the product into repeat
purchases without subscription fatigue.

---

## 5. Marketing plan

### 5.1 Positioning

"**Your desktop, alive.** Beautiful interactive wallpapers and your own
looping videos — gentle, gorgeous, and battery-aware." Lead with the
*interactive* angle: it is the differentiator versus static or video-only
wallpaper apps.

### 5.2 App Store Optimization (ASO)

- **Title:** `Live Wallpaper Studio` — include a keyword in the 30-char
  **subtitle**, e.g. *"Interactive animated backgrounds"*.
- **Keywords:** live wallpaper, animated, desktop, background, video
  wallpaper, dynamic, screensaver, menu bar, aesthetic, 4K.
- Iterate keywords using App Store Connect impressions/conversion data.

### 5.3 Assets that sell a visual app

- A crisp **App Preview video** (15–30 s) showing scenes reacting to the
  cursor — motion sells this product far better than stills.
- Screenshots with short captions ("Reacts to your cursor", "Play your own
  videos", "Six animated scenes").
- A **press kit**: logo, screenshots, preview clips, one-paragraph pitch,
  contact — hosted on the landing page.

### 5.4 Launch channels

- **Product Hunt** launch (visual products do well; prepare a GIF-heavy
  post and rally early supporters).
- **Reddit:** r/macapps, r/apple, r/MacOS, r/desktops (read each sub's
  self-promotion rules first).
- **Hacker News** ("Show HN") — works if there is a genuine technical angle
  (the interaction engine, energy-aware rendering).
- **X/Twitter, Threads, Mastodon** — post short wallpaper loops regularly.
- **TikTok / Instagram Reels / YouTube Shorts** — desktop-customization
  content performs extremely well; loops are made for these platforms.
- **Mac press outreach:** 9to5Mac, MacStories, The Sweet Setup, Cult of
  Mac, MacRumors forums — send the press kit before launch day.

### 5.5 Ongoing growth

- **Content cadence:** release seasonal/holiday wallpaper packs — each is a
  marketing moment and an IAP.
- **Creator collaborations:** partner with motion designers; revenue-share
  on their wallpaper packs.
- **Setapp:** apply for inclusion for steady non-store distribution and
  recurring revenue.
- **Reviews:** prompt happy users for ratings at a good moment (e.g., after
  they have switched wallpapers a few times) using `SKStoreReviewController`.
- **Community:** a small Discord/subreddit for wallpaper requests and beta
  feedback.
- **Analytics:** privacy-respecting funnel metrics to see where users drop
  off, and iterate.

### 5.6 Suggested timeline

1. **Weeks 1–3** — Sandbox + bookmarks, energy/occlusion handling, Xcode
   project, app icon.
2. **Weeks 4–5** — Onboarding, launch-at-login, accessibility, tests, CI.
3. **Week 6** — Signing, notarization, App Store Connect setup, assets.
4. **Week 7** — TestFlight beta, fix review-risk items.
5. **Week 8** — Submit; prepare Product Hunt + press kit for launch day.

---

*Bottom line:* the product concept is strong and visually marketable. The
critical engineering blockers are **the sandbox/bookmark migration** and
**energy-aware rendering**; the critical marketing investment is
**high-quality motion assets**, because this app sells on how it looks
moving.
