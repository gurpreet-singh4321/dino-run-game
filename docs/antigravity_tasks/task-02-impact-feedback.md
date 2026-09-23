# Task 02 — Impact Feedback (hit-stop, near-miss slow-mo, shake tuning, speed streaks)

**Goal:** Every collision, near-miss, and high-speed moment should hit with weight.

**Files:** `lib/game/dino_game.dart`, `lib/components/obstacle.dart`, `lib/components/ui/hud.dart`, `lib/components/particle.dart`

## Context
- `dino_game.dart` already has `triggerShake()` moving `camera.viewfinder` randomly.
- `obstacle.dart` has 9 obstacle types with collision handling; `particle.dart` has `emitNearMiss`.
- `speed_manager.dart`: base speed 200 up to +250 asymptotically (`1 - exp(-score/600)`).

## Implementation
1. **Hit-stop** — add a `hitStopTimer` to the game; while active, scale `dt` passed to all world components by 0 (or ~0.05) for 90 ms. Trigger on: obstacle hit that costs a life, shield break, and revive. UI/HUD keeps updating with real dt. Ensure hit-stop doesn't re-trigger from the same collision.
2. **Near-miss upgrade** — when `emitNearMiss` fires: apply a global time-scale of 0.85 for 200 ms (lerp back), spawn 4–6 horizontal white speed-line particles at the dino, and flash a brief soft vignette (new lightweight fullscreen component or HUD overlay, alpha 0.25 → 0 over 250 ms).
3. **Screen-shake retune** — per-event presets instead of one magnitude: side-hit → directional shake (offset biased away from obstacle x), top-hit → vertical bias, shield break → high-frequency low-amplitude, meteor/lava geyser → rumble (low frequency). Add exponential decay so shakes settle smoothly rather than stopping abruptly.
4. **High-speed streaks** — when current speed > 60% of max speed, draw 2–4 subtle horizontal motion-blur streak lines (low alpha, long thin rects at random y, fast leftward motion, recycled — no per-frame allocation). Intensity scales with speed.

## Acceptance criteria
- Getting hit produces a perceptible 1–2 frame freeze followed by a directional shake.
- Near-misses give a subtle slow-mo blip with speed lines and vignette flash.
- Shakes feel distinct per event type and decay smoothly (no snap-back).
- At max speed the world has visible but subtle streaks; nothing at low speed.
- `flutter analyze` clean; no frame drops; collisions and lives logic unchanged.

## Do not break
- Hit-stop/slow-mo must not desync score accumulation (score = speed·dt·0.05 — decide deliberately whether scaled dt reduces score during slow-mo and keep it consistent).
- Space mode and pause must suspend these effects correctly (no stuck time-scale — always reset time-scale in state transitions).
