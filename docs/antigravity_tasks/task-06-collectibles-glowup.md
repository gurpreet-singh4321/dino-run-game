# Task 06 — Collectibles & Powerup Glow-up

**Goal:** Coins and powerups should sparkle and feel magnetic and alive; combo feedback should pop.

**Files:** `lib/components/collectible.dart`, `lib/components/player.dart`, `lib/components/ui/combo_display.dart`, `lib/components/particle.dart`

## Context
- `collectible.dart` (~532 lines): coins + powerups (shield, magnet, giant, invincible), pooled particles available.
- Magnet powerup currently attracts collectibles to the player.
- `combo_display.dart` renders the combo counter with a timer.

## Implementation
1. **Coin spin & glint** — coins get a 3D spin illusion: scale X with `sin(t)` (full → edge-on → full) plus slight Y bob. Add a specular glint: a white diagonal streak sweeping across the coin every ~2 s (rotating highlight gradient or clipped white sweep, alpha 0.5).
2. **Coin pickup burst** — on collect: 6–8 small gold sparkle particles + a quick expanding ring (1 frame stroke circle, radius 12→28, alpha fade). Coin count in HUD pulses (scale 1.0→1.25→1.0 over 150 ms).
3. **Magnet smoothing** — replace the current magnet attraction with a smoothed curve: accelerate collectibles toward the player with an ease-in velocity (lerp direction, ramp speed over 150 ms) so coins visibly curve in arcs instead of snapping. Range visualization: faint pulsing circle around the dino while magnet active (alpha 0.06).
4. **Powerup auras** — while a powerup is active, its aura on the player pulses at ~1.2 Hz (sin-based alpha/scale modulation of the existing aura visuals in player.dart). On powerup expiry: quick fade-out blink (3 blinks over 0.6 s before effect ends) so the player gets warning.
5. **Combo pops** — combo counter text does a scale pop (1.0→1.35→1.0, 180 ms) every time the combo increments, with color heat scaling: white → yellow → orange → red as combo tier rises (e.g. tiers at 5/10/20/40). On combo break: brief desaturate/gray flash of the counter.

## Acceptance criteria
- Coins visibly spin with a periodic glint sweep; pickups burst sparkles and pulse the HUD.
- Magnet pulls coins in smooth arcs with visible pickup radius hint.
- Active powerups pulse; expiry is telegraphed by blinking before it ends.
- Combo increments pop with heat colors; break is obvious.
- `flutter analyze` clean; no frame drops with 15+ coins on screen (pool discipline kept).

## Do not break
- Collectible collision/pickup logic, magnet radius/duration gameplay values, coin persistence, space-mode coin rain performance.
