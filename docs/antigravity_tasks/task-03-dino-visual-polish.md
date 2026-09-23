# Task 03 — Dino Visual Polish

**Goal:** Make the dino itself feel premium: rim-light, dynamic shadow, speed lean, blinking, afterimage trail.

**Files:** `lib/skins/default_dino_skin.dart`, `lib/skins/special_skins.dart`, `lib/components/player.dart`

## Context
- Dino is drawn as vector paths in `default_dino_skin.dart` (4-frame run cycle, 0.12 s/frame; frozen jump pose; death spin + dizzy stars).
- `special_skins.dart` (~404 lines, ~44 draw calls) contains unlockable skins drawn similarly.
- Skins implement the `Skin` interface: `renderRunning / renderJumping / renderSpace`.

## Implementation
1. **Ground shadow blob** — in `player.dart` render (under the dino, before skin render): an ellipse at ground level whose width/alpha shrink as the dino gets higher (e.g. scale = lerp(1.0 → 0.4, jumpHeight/300), alpha 0.30 → 0.10). Use a cached `Paint` with a radial gradient. Biome-aware tint optional (multiply toward biome ground color).
2. **Rim-light** — in the default skin, add a top-left light-direction rim: redraw the dino body silhouette clipped, offset 2–3 px down-right, in a warm highlight color at ~15% alpha, on top of the base fill. Keep it cheap (one extra clipped path pass).
3. **Speed lean** — rotate the dino slightly with horizontal speed: up to ~6° forward lean at max speed (visual-only transform; no hitbox change). Add slight extra lean during jump ascent and back-lean on descent for air dynamics.
4. **Eye blink** — a blink timer in the skin (every 2.5–5 s random, closed for 90 ms) that squashes the eye vertically. Skip blinking during death/space mode.
5. **Afterimage trail** — when speed > 70% max or giant/invincible powerup active: keep a ring buffer of the last ~5 positions (updated every ~40 ms) and render the dino silhouette at those positions with decaying alpha (12% → 2%), tinted with the current powerup color when active. Reuse one paint; no allocations per frame.
6. Apply 2, 4 to `special_skins.dart` where structurally feasible (at minimum: shadow blob + lean come free from player.dart; rim-light and blink for the 2–3 most-used special skins).

## Acceptance criteria
- Shadow visibly shrinks/fades on high jumps and anchors the dino when grounded.
- Subtle rim-light readable against both light (DESERT) and dark (COSMOS) backgrounds.
- Lean increases with speed and shifts with jump phase; hitboxes unchanged.
- Dino blinks naturally while running; no blinking artifacts in death animation.
- Trail appears only at high speed / powerups, smooth and non-distracting.
- `flutter analyze` clean; 60 fps with all skins.

## Do not break
- Skin interface contract, shop preview rendering, Rive skin (`rive_dino_skin.dart`) must still work (rim-light/blink are vector-skin-only; shadow/lean/trail are player-level and apply to all skins).
