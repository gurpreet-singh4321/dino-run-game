# Task 11 — Custom Biome Panoramas (wide, multi-segment, non-repeating)

The previous asset pass replaced the game's characterful custom backgrounds with generic
single-image panoramas. That was a downgrade: each biome lost its landmarks and identity, and
a single 1376px image repeats every screen. This task restores and exceeds the old quality.

**Goal:** Each biome gets a WIDE panorama composed of 4 smaller generated segments stitched
into one continuous strip (~5500px wide). The strip repeats only once per ~4 screens of play,
and each segment has its own landmark content — restoring the custom feel the old
`desert_bg_v3.jpg` etc. had, with more variety than before.

## Part A — Generate 24 segments (4 per biome)

For each biome, generate 4 segments in ONE consistent painterly style (match the existing
`biomes/*_panorama.jpg` style, 1376×768, horizon fixed in the lower third at the SAME height
in every segment of a biome, clean sky gradient):

- **DESERT** — seg1: great pyramids + sphinx; seg2: lost oasis with palm trees and ruins;
  seg3: canyon with natural rock arches; seg4: ancient desert citadel + camel caravan.
- **RAIN** — seg1: monsoon temple ruins; seg2: stormy cliffside with lightning; seg3: flooded
  jungle shrines; seg4: waterfall gorge in heavy rain.
- **FOREST** — seg1: colossal ancient trees; seg2: mossy stone ruins overgrown with vines;
  seg3: glowing firefly grove; seg4: forest waterfall ravine.
- **ICE** — seg1: jagged glacier field; seg2: frozen citadel/palace; seg3: aurora-lit ice
  peaks; seg4: frozen waterfall and scattered mammoth-like silhouettes.
- **VOLCANO** — seg1: erupting caldera with lava fountains; seg2: basalt columns and lava
  river; seg3: obsidian wasteland with ember storms; seg4: charred citadel on volcanic cliffs.
- **COSMOS** — seg1: ringed planet rising; seg2: nebula corridor with drifting asteroids;
  seg3: alien monolith field; seg4: distant galaxy + comet.

Rules per segment:
- Same horizon line height as the biome's other segments (state the pixel row in your report).
- Left/right edges prepared for stitching: end terrain naturally (no cut-off landmark at an edge).
- Name files `assets/images/biomes/<biome>_seg1.jpg` … `_seg4.jpg` (keep the current 6
  `*_panorama.jpg` files untouched until Part C is approved).

## Part B — Stitch verification (scripted)

Write/reuse the Python stitch script to:
1. Verify all 4 segments of a biome have identical dimensions and near-identical horizon rows.
2. Verify style continuity per biome (mean color difference between adjacent segments within a
   tolerance; regenerate outliers).
3. Produce the final stitched strips by cross-fading adjacent edges (100px blend). Export
   BOTH: the 4 individual segments AND optionally a stitched preview PNG per biome for review.
4. Report the metrics per biome (horizon row, inter-segment color delta, seam blend width).

## ⏸ CHECKPOINT — do not integrate yet

After generating and stitching, STOP and report. The master reviewer will visually inspect the
segments (at least 2 per biome) and the seam metrics. Only after approval, proceed to Part C.

## Part C — Integration (after approval)

- Load per biome: the 4 segments for the CURRENT biome, drawn in sequence with the existing
  `_drawTiledParallaxImage` (blit 4 tiles back-to-back; use `mirrorTiling: false`; the 100px
  cross-fades make seams invisible; a perfect loop requires seg4's right edge cross-faded into
  seg1's left edge — apply that final wrap blend).
- Memory: do NOT decode all 6 biomes at once (~100MB decoded would be too heavy). Decode the
  current biome's 4 segments; preload the next biome's segments in the background during
  gameplay; release the previous biome's segments after its transition ends. Verify no hitch at
  biome change (decode in < 1 frame budget or decode async before transition starts).
- Fallback: if any biome's segments fail to load, fall back to that biome's existing
  `*_panorama.jpg` — never to a blank sky.
- Keep procedural mid/near layers (warm-tinted dunes etc.) ON TOP as today.
- Space mode assets stay untouched.

## Acceptance criteria
- Each biome reads as a custom, landmark-rich world; variety visible across ~4 screens.
- No visible seam within a strip or at the strip loop point during a 2-minute scroll test per biome.
- No hitch when a biome transition triggers; memory stays within reasonable bounds (report
  decoded-image MB before/after).
- `flutter analyze` no new issues; `flutter test` all pass.

## Do not break
- Existing biome transitions, weather, sky caching (task-04), space mode, gameplay constants.
- Do NOT delete any existing asset in this task.
