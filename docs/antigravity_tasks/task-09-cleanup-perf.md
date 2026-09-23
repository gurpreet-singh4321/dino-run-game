# Task 09 — Cleanup & Performance Verification (final pass)

**Goal:** Trim dead weight, fix asset declarations, and verify the whole overhaul runs clean and fast.

**Files:** `pubspec.yaml`, `assets/` (pruning), final report only elsewhere.

## Implementation
1. **Asset audit** — list every file in `assets/images/` and grep the codebase for usage. Delete background JPGs that are no longer referenced after Task 08 (keep any used by space mode or skins). Remove duplicate desert variants. Update pubspec asset declarations to match reality (no orphan entries, no missing entries).
2. **Fonts** — `assets/fonts/font_combo.fnt` and `font_score.fnt` exist but are not declared in pubspec. Either declare and use them in the combo display / HUD score, or delete them — pick one, don't leave them limbo. If used, ensure they render correctly (bitmap font + texture page present).
3. **Static analysis** — run `flutter analyze`; fix every warning/info that the overhaul tasks introduced. Pre-existing issues: fix only if trivial, otherwise list them in the report.
4. **Performance smoke test** — run a debug (or better, profile) build and verify with DevTools timeline:
   - 60 fps in all 6 biomes, during biome transitions, in space mode, and with 15+ collectibles + multiple obstacles on screen.
   - No frame > 20 ms in a 2-minute automated/manual run.
   - Report average frame time per scenario in the task summary.
5. **Regression checklist** — manually verify: double jump + variable height, coyote/buffer, squash & stretch, hit-stop, near-miss slow-mo, shakes, milestone celebrations, biome cinematics, high-score banner, shop + all skins render, persistence (score/coins/settings survive restart), pause/resume, revive, space mode end-to-end.
6. **Update README** — add a short "graphics & feel overhaul" changelog section to the project README noting the new features.

## Acceptance criteria
- Zero unused image assets; pubspec exactly matches assets on disk.
- Font situation resolved (used or removed).
- `flutter analyze` clean (or pre-existing-only issues listed).
- Perf report included with numbers; all regression checklist items pass.
- Final sign-off from the master reviewer.

## Do not break
- Anything listed in the regression checklist — that is the point of this task.
