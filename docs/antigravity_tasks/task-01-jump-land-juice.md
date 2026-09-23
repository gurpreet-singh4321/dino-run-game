# Task 01 — Jump & Land Juice

**Goal:** Make jumping feel responsive and weighty: variable jump height, coyote time,
jump buffering, squash & stretch, landing dust and a small camera nudge.

**Files:** `lib/components/player.dart`, `lib/components/particle.dart`, `lib/game/dino_game.dart`

## Context
- `player.dart` has `gravity = 800`, `jumpForce = -480`, double jump (`jumpsLeft = 2`), fixed impulse.
- Input release (`_handleInputEnd`) currently only affects space-mode thrust; holding jump does nothing.
- `particle.dart` already provides a pooled `emitDesertLandingImpact` / `emitJumpDust`.
- `dino_game.dart` provides `triggerShake()` for camera shake.

## Implementation
1. **Variable jump height** — on jump-input release while `velocity.y < 0` and not in space mode, multiply `velocity.y *= 0.5` once per jump (guard with a `_jumpCutApplied` flag reset on each jump/land).
2. **Coyote time** — when the player leaves the ground without jumping, keep ground-jump eligibility for 90 ms (`_coyoteTimer`). Consuming coyote jump must still allow the air jump afterwards (total max 2 jumps from ground run).
3. **Jump buffering** — if jump is pressed within 120 ms *before* landing, fire the ground jump immediately on landing (`_jumpBufferTimer`).
4. **Squash & stretch (visual only)** — add `squashX/squashY` fields animated in `update`:
   - Takeoff: scale (1.25, 0.75); Landing: (0.75, 1.25); ease back to (1, 1) over ~120 ms (simple exponential lerp).
   - Apply via `canvas.scale` in `render` around the dino's foot center point. **Must not affect the collision hitbox.**
   - Landing squash triggers when transitioning from airborne → grounded with downward speed > 200.
5. **Landing feedback** — on landing with downward speed > 400: emit existing landing-dust particles scaled to impact speed and call a light camera nudge (new small shake intensity 1.5, duration ~80 ms; do not reuse the big hit shake values).

## Acceptance criteria
- Tapping jump quickly produces a visibly lower jump than holding it.
- Jumping right after running off a ledge edge still works (coyote), and pressing jump slightly early before landing still fires on touchdown (buffer).
- Dino visibly squashes on landing and stretches on takeoff; hitboxes unchanged (verify obstacle collisions feel identical).
- Landing from a high double-jump produces a dust burst and a tiny screen nudge.
- `flutter analyze` clean; stable 60 fps.

## Do not break
- Double-jump count, space-mode thrust behavior, death physics (`-360` pop / `1100` fall), powerup physics.
