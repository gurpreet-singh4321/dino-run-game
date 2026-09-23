# Antigravity Task Queue — Graphics & Game Feel Overhaul

Dino Run Epochs is a Flutter/Flame 2D runner rendered almost entirely with Canvas vector
drawing. These tasks turn it into eye-candy and give it a juicy game feel.

**Workflow per task:**
1. Copy the task file contents into Antigravity.
2. Let Antigravity implement it fully (it must run `flutter analyze` and fix all issues it introduces).
3. Manually run the game and check the task's **Acceptance criteria**.
4. Bring the result back to the master reviewer (ZCode) for confirmation before starting the next task.

**Execution order (feel first, then visuals, then assets/cleanup):**
1. `task-01-jump-land-juice.md`
2. `task-02-impact-feedback.md`
3. `task-07-milestone-moments.md`
4. `task-03-dino-visual-polish.md`
5. `task-06-collectibles-glowup.md`
6. `task-04-sky-eyecandy.md`
7. `task-05-ground-obstacle-polish.md`
8. `task-08-hero-assets.md`
9. `task-09-cleanup-perf.md`

**Global "do not break" constraints (apply to every task):**
- Collision hitboxes and gameplay difficulty must not change (visual/squash scaling must not affect hitboxes).
- Score, coins, high score, skins, and settings persistence (shared_preferences) must keep working.
- All existing biomes (DESERT→RAIN→FOREST→ICE→VOLCANO→COSMOS), space mode, powerups, and the shop must remain functional.
- Target 60 fps: no new per-frame allocations in hot loops; reuse pools; cache static layers to `ui.Picture`/`ui.Image` where possible.
- After each task: `flutter analyze` must report zero new issues and the game must run on Windows debug without exceptions.

**Key files reference:**
- `lib/game/dino_game.dart` — game states, screen shake (`triggerShake()`), space mode
- `lib/components/player.dart` — physics (`gravity = 800`, `jumpForce = -480`, double jump), powerup visuals
- `lib/components/ground.dart`, `obstacle.dart`, `collectible.dart`, `sky_background.dart`, `particle.dart`
- `lib/skins/default_dino_skin.dart`, `special_skins.dart` — dino rendering
- `lib/components/ui/` — hud, combo_display, start/game-over screens
- `lib/managers/` — speed_manager, spawn_manager, coin_manager, audio_manager
