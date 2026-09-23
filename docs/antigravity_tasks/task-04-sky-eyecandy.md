# Task 04 — Sky & Background Eye-candy (+ big perf win)

**Goal:** Richer skies (bloom sun, god rays, cloud depth, twinkling stars, better lightning) while making the 3062-line `sky_background.dart` dramatically cheaper via layer caching.

**Files:** `lib/components/sky_background.dart` (primary), `lib/game/biome_manager.dart` (color hooks if needed)

## Context
- `sky_background.dart` (~3062 lines, ~174 canvas-draw calls per frame) renders 6 biomes with lerped colors, fog transitions, weather (rain/snow/ash/spores/lightning/pterodactyls/god rays), procedural desert parallax, and scrolling bg JPGs.
- Everything is currently redrawn every frame — the top perf cost in the game.

## Implementation
1. **Static-layer caching (do this first)** — audit every draw in the file and classify: *static per biome* (gradient sky, sun disc, distant silhouettes), *slow-scroll* (parallax layers), *dynamic* (weather, transitions, effects).
   - Render static layers once per biome into a `ui.Picture` (via `PictureRecorder`) or `ui.Image` and blit each frame. Rebuild only on biome change / resize.
   - Slow-scroll parallax layers: cache each layer tile as `ui.Image`, then draw with translate — path-drawing only happens on build.
   - Keep weather/effects fully dynamic. Target: ≥60% reduction in per-frame canvas calls. Measure before/after (count draw calls or use DevTools timeline) and note numbers in the PR description.
2. **Sun/moon bloom** — radial gradient glow around the sun (2 stacked radial gradients, alpha 0.35 and 0.15, radii 1.5× and 3× sun radius) with very slow breathing (±5% scale, 8 s period). Moon in night biomes gets a cool halo.
3. **God rays pass** — strengthen existing god rays (FOREST/RAIN): add slight rotation oscillation and animated alpha shafts; ensure they composite over cached layers correctly (rays must stay dynamic).
4. **Cloud depth** — clouds get 3 depth bands: far clouds drawn blurred (use `Paint..maskFilter = BlurMaskFilter` on the cached layer) at low alpha, mid band normal, near band slightly larger and faster. Parallax speed differs per band.
5. **COSMOS twinkling stars** — star field with per-star twinkle phase (`sin(t·speed + phase)` alpha 0.3–1.0); a couple of shooting stars per minute (fast streak + fade).
6. **Lightning flash** — on lightning strike: 2 quick fullscreen white flashes (alpha 0.18/0.10, 60 ms apart) then the bolt; slight sky-color brighten for 150 ms after.

## Acceptance criteria
- Measurable perf improvement (report draw-call count or frame-time before/after); stable 60 fps in all 6 biomes.
- Sun clearly glows with bloom; night biomes have haloed moon and twinkling stars.
- God rays and lightning feel dramatic but not seizure-inducing (keep flashes ≤ 0.2 alpha).
- Biome transitions (3.5 s fog cross-fade) still work correctly over cached layers — no popping when layers rebuild.
- `flutter analyze` clean.

## Do not break
- Biome color lerp and transition timing, weather systems, bg JPG scroll (`_bgScrollOffset`), space-mode background.
