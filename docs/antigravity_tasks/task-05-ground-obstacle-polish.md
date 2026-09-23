# Task 05 — Ground & Obstacle Polish

**Goal:** The ground should read as terrain (not a flat band) and obstacles should feel physical and telegraphed.

**Files:** `lib/components/ground.dart` (~1377 lines), `lib/components/obstacle.dart` (~1039 lines)

## Context
- `ground.dart`: scrolling ground, lava gaps/geysers with pre-eruption shake (400 px ahead, intensity 6.5).
- `obstacle.dart`: 9 obstacle types including flappy-style pipe pairs; all vector-drawn.
- Biome system changes ground colors per biome.

## Implementation
1. **Ground texture detail** — scrolling surface detail layer per biome, generated deterministically from x-position (seeded pseudo-random from `floor(worldX / tilePeriod)` so it scrolls consistently): DESERT pebbles + ripples, FOREST grass tufts + roots, ICE cracks + sparkle dots, VOLCANO glowing fissures, RAIN puddle shine ellipses, COSMOS dust specks. Cache one repeating tile strip per biome as `ui.Image` and blit scrolled — no per-frame path drawing.
2. **Obstacle shadows** — each obstacle renders a soft elliptical shadow at ground level (cached radial-gradient paint, alpha ~0.25). Slight horizontal offset gives light direction consistent with Task 03's rim-light (top-left).
3. **Lava emissive pulse** — lava in gaps/geysers gets a sin-based emissive pulse (inner glow gradient alpha 0.2–0.45, ~0.7 Hz) plus rising ember particles (2/s per gap, reuse particle pool) and heat-shimmer suggestion (slight vertical sin offset on the lava surface line).
4. **Spawn entrance animations** — obstacles animate in over ~200 ms instead of appearing: ground obstacles rise from the ground (offset +20 px, clipped by ground), aerial obstacles (birds/pterodactyls) fly in from offscreen with a swoop (slight y-curve), pipes slide in from top/bottom edges. **Entrance animation must not change effective hitbox timing** — hitbox activates only when the obstacle reaches its final pose, and animation must complete before the obstacle can be reached at max speed (verify with spawn distance at max speed).
5. **Pipe edge glow** — flappy pipe pairs get rim highlights on the gap-facing edges (bright edge stroke + subtle glow) so the safe gap reads instantly.

## Acceptance criteria
- Each biome's ground has distinct scrolling detail; no visible seam at tile repeat; zero per-frame allocations.
- Obstacles cast shadows; light direction matches the dino's rim-light.
- Lava pulses with embers; heat shimmer visible.
- Obstacles animate in smoothly; no unfair hits from animation (test at max speed with each obstacle type).
- Pipe gaps visually pop.
- `flutter analyze` clean; 60 fps with many obstacles on screen.

## Do not break
- Lava gap / geyser timing and pre-eruption telegraph (400 px shake warning), spawn_manager intervals, collision fairness, space mode.
