# Task 10 — Regression Fixes (visual bugs + sluggish jump + perf)

Playtesting found 5 regressions introduced by tasks 01–07. Fix ALL of them. These are bugs,
not new features — fix them precisely, no refactors beyond what each fix requires.

## Bug 1 — Stacked dino afterimages (CRITICAL, ugly + kills fps)
`lib/components/player.dart`
- Trail entries record `position.x/y`, but in a runner the dino's screen x never changes, so
  `entry.dx - position.x` is always 0 and entries stack at the same x; past jump y-values make
  them stack VERTICALLY. Screenshot shows 5+ dinos piled up.
- Fix: render each trail entry offset RIGHT by `speed * age` (world scrolls left, so past
  positions appear to the right). Track `age` per entry in `update()` (entry.age += dt; invalidate
  when age > ~0.25s). Ghost i renders at `position.x + speed * entry.age`, same y as recorded.
  Remove the bogus `entry.dx - position.x` translate math.
- The speed gate is also wrong: `speed > 840 // 70% of 1200` — max speed is 450 (200+250).
  Use `currentSpeed / maxSpeed > 0.7` (ratio), same as HighSpeedStreaks does.
- Perf: rendering 5 color-filtered sprites per frame is expensive. Reduce to 3 entries max,
  and render them as simple silhouettes (single cached Paint with colorFilter, no saveLayer,
  no per-entry Paint allocation).

## Bug 2 — Harsh white horizontal lines in the sky ("random stuff on top")
`lib/components/particle.dart` — `HighSpeedStreaks`
- Streaks use `0x66FFFFFF` (40% alpha white), 150–450px long, anywhere on screen — far too
  visible; they look like glitches over the panorama.
- Fix: alpha ≤ 0x20 with a horizontal gradient that fades both ends (cache the shader),
  max 3 streaks, length 120–260px, and skip streaks in the bottom 25% of the screen (keep the
  gameplay band clean). They must read as speed, not as objects.

## Bug 3 — Procedural dune blobs clash with the desert panorama
`lib/components/sky_background.dart`
- The cached far/mid dune tiles (`0xFFD7B29B`, `0xFFD6A16B` greys) were designed for the old
  flat gradient sky. Over `desert_bg_v3.jpg` they render as flat grey-lavender slabs on top of
  the nice panorama.
- Fix (when `_desertBgImage != null`, DESERT biome only): recolor the far dune layer to a
  warm hazy sand tone that blends with the panorama (e.g. `0xFFE2BC8A` at ~35% alpha) and the
  mid layer to warm sand (e.g. `0xFFE8C48E` at ~70% alpha), removing the hard stroke highlight
  on the mid layer. The tiles are cached — rebuild them with the new palette when the image is
  present. Without the image (fallback), keep the original palette.

## Bug 4 — Sluggish jump (tap jumps feel cut short)
`lib/components/player.dart` — `onJumpRelease()`
- The jump-cut (`velocityY *= 0.5`) applies on every quick tap because release fires
  immediately after press, so tap jumps are always halved.
- Fix: only apply the jump-cut if the jump was held ≥ 90 ms (track hold time), and soften the
  cut to `velocityY *= 0.6`. Taps must produce (nearly) full-height jumps; holds must produce
  visibly higher jumps. Do not change `gravity`, `jumpForce`, or jump count.

## Bug 5 — Per-frame allocations breaking the 60fps budget (unoptimised feel)
Fix every hot-loop allocation introduced by the overhaul:
- `player.dart` ground shadow: `ui.Gradient.radial(...)` is rebuilt EVERY frame → quantize
  `shadowAlpha` to 8 buckets and cache one Paint+shader per bucket; or use a single cached
  Paint with a fixed shader and modulate via `paint.color`.
- `player.dart` magnet radius ring: 2 `Paint()` allocations per frame → preallocate both.
- `sky_background.dart` `_drawGodRays`: builds 5 `Path` + 5 `LinearGradient` shaders per frame
  → preallocate the 5 paths (update vertices in place is fine) and cache one shader per biome
  (drive the animation purely through `paint.color` alpha and `canvas.translate/rotate`).
- `sky_background.dart` `_drawCloud`: verify no Paint/gradient allocations per cloud per frame.
- Audit with DevTools: no steady-state allocation churn in `render()` paths.

## Acceptance criteria
- Jumping: tap = full-ish jump, hold = higher jump; no vertical dino stacking ever; trail is 3
  subtle horizontal ghosts at high speed/powerups.
- Sky streaks are subtle speed cues; nothing reads as a glitch line.
- Desert: panorama + dunes look like one coherent warm scene.
- Debug build holds ~60 fps on a mid-range phone (portrait!) — verify in profile mode.
- `flutter analyze`: no new issues. `flutter test`: all pass (update the trail/streak tests
  that asserted the old wrong math).

## Do not break
- Hitbox gating (task-05), lava telegraph values, milestone systems, hit-stop/slow-mo,
  gameplay constants (gravity, jumpForce, magnet radius/duration, speeds).
