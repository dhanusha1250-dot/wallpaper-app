# Live Wallpaper Studio — Roadmap

A phased plan from the current prototype to a mature product. See
`TODO.md` for the granular checklist and `APP_STORE_AND_MARKETING.md`
for go-to-market detail.

---

## Phase 1 — Ship v1.0 (App Store ready)

The goal: a stable, sandboxed, store-approved release of what exists today
(6 animated scenes + video wallpapers + video library).

- App Sandbox + entitlements.
- Replace plain file paths with **security-scoped bookmarks** (current
  persistence breaks under the sandbox).
- Hardened Runtime, code signing, notarization.
- Proper Xcode project, app icon set, `PrivacyInfo.xcprivacy`.
- **Energy:** pause rendering when the desktop is occluded; throttle on
  battery / Low Power Mode; respect Reduce Motion.
- First-run onboarding; launch-at-login (`SMAppService`).
- Disk thumbnail cache; validate files are playable.
- Tests + CI; accessibility labels; localized strings.

*Exit criterion: approved on the App Store.*

---

## Phase 2 — v1.x feature releases

Moderate-effort features that are highly demoable in marketing clips.

### 2.1 Weather-reactive scenes
- Use Apple's **WeatherKit** (free up to 500k calls/month with the
  Developer Program).
- Map current conditions to scene parameters: rain streaks, snow, cloud
  cover, fog, and light warmth by temperature / time of day.
- Add a manual override and a "use my location" privacy prompt.

### 2.2 Parallax wallpapers
- **Done:** the procedural "Parallax Vista" scene — layered scenery whose
  depth layers shift with the cursor (and drift on their own).
- **Next:** photo → parallax — generate a depth map from a user's photo via
  the Vision framework or a bundled Core ML depth model, then displace the
  image layers the same way.

### 2.3 Quality-of-life
- Scheduling / playlists — rotate wallpapers on a timer or by time of day.
- Per-display and per-Space wallpapers.
- Crossfade transitions when switching.
- Accent-color extraction to tint the app UI.

---

## Phase 3 — v2 content platform

The strategic bet: turn the app from a tool into a content destination.

### 3.1 Curated wallpaper library
- A browsable in-app catalog of animated scenes and video loops, delivered
  from a CDN, gated behind IAP packs.
- **Content must be original or commissioned** — see Licensing below.

### 3.2 Stock integration (browse, don't bundle)
- Optional API integrations (e.g. Pexels) where the **user** fetches
  content live, with required attribution — never bundled or resold.

### 3.3 Stretch goals
- Interactive 3D models (SceneKit / USDZ) with cursor-driven spin and
  camera pans — start with a bundled, licensed pack.
- A simple scene editor so users can tweak and save presets.
- iOS companion app.

---

## Content & licensing (read before sourcing anything)

Images and video are copyrighted by default. To curate and distribute a
wallpaper catalog you need a license that **explicitly permits** your use:
reproducing the content, bundling it in a paid app, as a primary value,
where users can select it.

**Most free-stock licenses do NOT permit this.** Notably:
- **Pexels** forbids selling/redistributing content on "wallpaper
  platforms" — i.e. exactly this product.
- **Unsplash** forbids replicating a "similar or competing service."
- Pixabay, Envato, Motion Array, etc. restrict uses where the asset *is*
  the product being sold.

**Legal ways to source a catalog:**
1. **Create it yourself** — original animated scenes and footage. Cleanest.
2. **Commission artists** — with a written commercial license or full
   copyright assignment (work-for-hire). Get it in writing.
3. **True public-domain / CC0** content — verify each item individually.
4. **Negotiated extended / enterprise stock licenses** that explicitly
   allow in-app redistribution as wallpapers (rare, usually bespoke).
5. **Live API fetch by the user** (e.g. Pexels API for browsing, with
   attribution) — more defensible than bundling, but still subject to the
   no-competing-service clauses.

**Always:** avoid logos, trademarks, and recognizable people/places
without releases. Read the exact license text — "free to use" is not
"free for any use."

> This document is not legal advice. Have an IP lawyer review the content
> pipeline before commercializing.

---

## Suggested sequencing

1. **Phase 1** — non-negotiable; this is what makes a sellable product.
2. **Weather-reactive** first in Phase 2 — biggest wow per unit effort.
3. **Parallax** next — strong differentiator, self-contained.
4. **Phase 3** only once content licensing and a backend are sorted.
