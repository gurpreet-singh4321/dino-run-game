# New Dino articulated animation

The previous single PNG with four-frame bobbing is replaced by a painted cutout rig rendered directly in Flame. This is not a Rive `.riv` asset. Original Dino and its Rive renderer remain available.

## Motion

- Eight atlas regions: head, torso, tail, arm, thigh, shin, foot, closed-eye head reference. Only the eye area uses the closed-eye reference, preserving the head silhouette.
- Motion advances continuously from delta time; rendering does not advance animation. Gait cadence responds to world speed and character scale.
- Foot stance moves backwards at constant speed; the swing curve matches contact velocity and lifts with zero vertical velocity at its endpoints.
- Two-bone leg solving keeps the hip, knee and ankle connected. Far limbs are tinted for depth.
- Running blends into leg tuck on ascent and extension on descent. A short landing compression moves the hips/head while feet stay anchored. Double jumps retrigger the launch envelope without delaying physics.
- Idle breathing, gentle tail sway, opposing arm swing, delayed head/tail motion and an eyelid blend add secondary motion.
- Head cosmetics follow the head transform. Back and neck items follow their respective body motion. Player-level squash and lean are bypassed only for this rig to avoid stacking two conflicting animation systems.

## Review

`tool/new_dino_motion_preview.dart` is a separate review app with run/idle, jump/double jump, pause, quarter-speed playback, a speed slider and cosmetic toggle. Build it with:

```
flutter build web --release --no-pub --no-wasm-dry-run --target tool/new_dino_motion_preview.dart --output build/motion_preview
```

Build the main game normally afterward when making runtime changes. The review harness exaggerates display size and compresses jump height to keep the character on screen; gameplay uses unchanged physics and hitboxes.

Tests cover planted-foot motion, position/velocity continuity at cycle boundaries, 30/60/120 FPS consistency, tuck/reach/landing transitions and leg lengths. Browser checks cover enlarged run and airborne poses, cosmetic placement, and actual game jumping. Device profiling and subjective animation review across all speeds are still useful before release.

Validation: all 8 motion tests passed, including bounded cadence at 150–1200 pixels/second and continuous landing phase. The existing 17 wardrobe, collision and ground/obstacle checks also passed. Focused analysis of the motion model, rig, player integration and review tool reports no issues. Main game and review page release builds succeed; the pre-existing Cupertino font warning remains.

## Art provenance

Built-in imagegen output: `assets/images/new_dino_rig.png` (1774 x 887 RGBA). The atlas is rendered using measured source rectangles; the generated pieces did not obey equal cell boundaries exactly. The original `new_dino.png` remains available.

Generation prompt: Production 2D skeletal animation PARTS ATLAS of this exact adorable yellow dinosaur. Genuinely transparent background. ONE landscape image, exactly 4 columns by 2 rows of equally sized square cells, each separate part centered in its cell with generous transparent gutter. No grid lines no labels no text no assembled dinosaur. Preserve reference painted style, golden yellow skin, cream belly, orange plates and soft highlights. Parts MUST be separate detached clean cutouts, complete rounded hidden joints, no shadows. TOP ROW left to right: (1) entire large expressive HEAD ONLY facing right, with eye, snout, smile, cheek, tooth and head plates, NO neck or body; (2) oval pear-shaped TORSO ONLY with cream belly, no head arms legs or tail; (3) long curved TAIL ONLY pointing LEFT, thick rounded root at RIGHT, taper tip at left, orange plates above; (4) one short ARM with rounded shoulder at TOP and little hand at BOTTOM. BOTTOM ROW left to right: (5) plump UPPER LEG THIGH ONLY vertical, round hip TOP round knee BOTTOM, no foot; (6) short LOWER LEG SHIN ONLY vertical, rounded knee TOP and ankle BOTTOM, no foot; (7) one chunky FOOT pointing RIGHT with three cream toes, ankle attachment toward upper left, flat sole; (8) second copy of HEAD same silhouette as cell1 but eyelid CLOSED for blink. Fill most of each cell but never cross cell borders. Head and torso etc independently scaled to fit respective square cells, game code will set final sizes. Fully transparent RGBA behind all eight pieces. This is a rigging texture atlas not a concept sheet.

Transparency correction prompt: Remove the entire gray checkerboard background from this parts atlas. Return genuine transparent ALPHA PNG, NOT a drawn checkerboard, NOT white, NOT black. Preserve all eight golden dinosaur body parts at EXACTLY the same positions and sizes and preserve image aspect ratio. Do not repaint, add, remove or reposition any part. The gray squares must become fully transparent pixels. Keep cream toes, belly, white tooth and eye glints intact. This is background extraction for game sprites.

## Compact leg revision

Shortened the two leg segments to 14 design units each, lowered the torso by 8 units, and reduced foot travel to a 26-unit stance with a 6-unit swing lift. Smaller overlaps keep the painted joint pieces from bulging sideways. Jump tuck is shallower so ankles remain below the hips. Cadence is now art-directed (see below); the extra test checks both legs remain reachable throughout the stride. Enlarged browser checks covered running and takeoff.

## Readable run rhythm

The previous exact ground-speed mapping produced nearly 20 steps per second at 650 px/s after shortening the legs. Cadence now stays between 1.8 and 3.2 full cycles per second, independent of display size. This deliberately allows stylized foot sliding at high scenery speeds to preserve readable poses. Head and scarf follow the torso more closely, foot recovery has a small continuous toe roll, far limbs use a warmer tint, and landing preserves stride phase.

Current validation: eight motion tests pass; `tool/export_dino_stride_test.dart` exports eight enlarged cycle poses to `docs/new-dino-stride-review.png`. This checks silhouettes and joints; it does not replace subjective playback review with children.
