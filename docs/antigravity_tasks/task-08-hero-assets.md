# Task 08 — Hero Asset Generation (hybrid art pass)

**Goal:** Replace the flat procedural far-backgrounds with gorgeous pre-rendered biome panoramas + title-screen key art, generated as images and integrated into the parallax.

**Files:** `pubspec.yaml`, `assets/images/` (new), `lib/components/sky_background.dart`, `lib/components/ui/start_screen.dart` / splash, plus a new loader step if needed.

## Context
- Current bg JPGs (`assets/images/` desert x6, rain, forest, ice, volcano, cosmos, space x4) are low-effort and several are unused/duplicated.
- `sky_background.dart` already scrolls a bg JPG with `_bgScrollOffset` (repeat width 2048).

## Implementation
1. **Generate 6 biome panoramas** — one wide seamless-scrollable panorama per biome (DESERT, RAIN, FOREST, ICE, VOLCANO, COSMOS), 16:9-ish but wide (recommend 2048×1024), painterly stylized game-art style matching the vector palette of each biome, horizon in the lower third so gameplay area stays readable. Use an image-generation tool (e.g. an AI image MCP/tool of your choice; alternatives: export high-quality gradient art from code). **Critical: left and right edges must tile seamlessly** — instruct the generator explicitly and verify; if a perfect tile is impossible, apply a mirrored-repeat draw so the seam is hidden.
2. **Title-screen key art** — one hero illustration (dino silhouette mid-jump over an epic multi-biome landscape, sunrise) for the start/splash screen background.
3. **Integration** — put files in `assets/images/biomes/`, declare in pubspec. In `sky_background.dart`, replace the current bg JPG per biome with the new panorama drawn as the *far* layer (slowest parallax), with the existing procedural mid/near layers on top so depth increases. Cross-fade 3.5 s between biome panoramas in sync with the existing transition.
4. **Preload & memory** — preload the next biome's panorama during gameplay (not at transition time) to avoid a hitch; downscale to device-appropriate resolution if >2048 wide. Total added asset size must stay under ~6 MB (use JPG quality ~85).
5. **Readability check** — verify contrast: dino, obstacles, and ground must remain clearly readable in front of every panorama; if not, add a subtle dark gradient scrim behind the gameplay band.

## Acceptance criteria
- All 6 biomes show distinct, beautiful panoramas scrolling seamlessly with correct parallax depth.
- No visible seam while scrolling for 60+ s in each biome; no hitch at biome transition.
- Title/splash screen uses the new key art.
- App size increase < 6 MB; load time unaffected (async preload).
- `flutter analyze` clean; 60 fps maintained.

## Do not break
- Existing transition/fog system, weather layers composited over the new panoramas, space-mode backgrounds (keep space-mode art as-is unless trivially improved).
