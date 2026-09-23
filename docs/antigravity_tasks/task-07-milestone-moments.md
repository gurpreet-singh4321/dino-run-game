# Task 07 — Milestone Moments

**Goal:** Memorable beats: biome-entry cinematics, score-milestone celebrations, live high-score banner.

**Files:** `lib/game/dino_game.dart`, `lib/game/biome_manager.dart`, `lib/components/ui/hud.dart`, `lib/components/particle.dart`, `lib/managers/audio_manager.dart`

## Context
- Biomes switch every 4500 score with a 3.5 s fog transition (biome_manager.dart).
- HUD shows score/combo/lives; high score persists via shared_preferences.
- Particle pool and AudioManager (title/gameplay/gameOver BGM + jump SFX) exist.

## Implementation
1. **Biome-entry cinematic** — when a biome transition begins:
   - Letterbox bars slide in (top/bottom black bars, ~12% height each, 300 ms ease).
   - A title card fades in centered: biome display name with era subtitle, e.g. "THE ICE AGE — Epoch IV", styled per biome color palette (bold font, subtle drop shadow). Shown ~1.6 s, fades out, letterbox retracts (300 ms).
   - Screen flash (biome accent color, alpha 0.15) + `emitBiomeTransition` particle burst + a rising musical sting SFX (add a short whoosh/impact asset to `assets/audio/` if none fits; if adding audio is not feasible, reuse pitch-shifted existing SFX).
   - **Gameplay must not pause or slow during the cinematic** — it is an overlay; the player still runs, jumps, and can die. Bars must never cover the ground line or incoming obstacles more than ~10% screen height.
2. **Score-milestone celebration** — every 1000 score: small firework burst at a random upper-third position (2 staggered bursts, mixed accent colors, reuse particle pool), HUD score counter does a scale pop (1.0→1.3→1.0, 250 ms) with a brief golden tint, and a short chime (respect mute settings). Every 5000 (biome multiple) make it bigger: 4 bursts + stronger HUD pulse.
3. **Live new-high-score banner** — the first time current score exceeds the stored high score during a run: a slim banner slides in under the HUD ("NEW HIGH SCORE!") with a shimmer sweep, stays ~2 s, slides out. Only once per run. If the player is on their first-ever run (high score 0), skip the banner.
4. All milestone UI must respect the existing pause/space-mode states (hide or freeze appropriately; never overlapping the space timer bar).

## Acceptance criteria
- Each biome change produces a readable, stylish title moment without interrupting play or hiding obstacles.
- Every 1000 score triggers celebration reliably (no double-fires, no drift with dt scaling from Task 02).
- High-score banner appears exactly once per run when applicable, and not on first-ever runs.
- All feedback respects audio mute settings and pause.
- `flutter analyze` clean; no jank during cinematics (particles pooled).

## Do not break
- Biome gameplay switching logic and fog transition; score accumulation; high-score persistence and game-over flow.
