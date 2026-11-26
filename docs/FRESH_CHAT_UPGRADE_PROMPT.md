# Paste this into a fresh chat

We are continuing **Dino Run Epochs**, a Flutter/Flame landscape-only 2D runner. The repository is:

`C:/Users/gurpr/OneDrive/Desktop/Projects/Flutter/Work - Freelance/Games/dino_run_epochs`

Read `docs/GAME_EVOLUTION_PLAN.md` first, then audit the current code and applicable repository instructions. That file contains the full creative vision, current-state findings, feature proposals, architecture, asset pipeline, acceptance tests and delivery stages. Older conversation claims and older docs may be stale.

I want you to implement a major upgrade that makes the game expressive, beautiful, playful and rewarding to replay. You are authorized to improve character animation and artwork, world design, obstacles and interactions, power-ups, sound, menus, progression, outfits and 2.5D presentation. Make concrete, tested changes and playable builds. Continue autonomously through bounded stages; do not stop at another high-level plan.

The game currently has one character: **Dino**, implemented by `NewDinoSkin`, persistent ID `new_dino`. Keep one character and build additional skin variations as palettes/materials and costumes for the same Dino with shared accessory anchors. Preserve saved coins, upgrades, records and wardrobe ownership. Do not restore the old character roster.

Keep the simple landscape side-scrolling identity. Create dimensional scenery and props through pre-rendered 3D sprite sequences, painted volume, layered parallax, lighting, rotating props, shadows and clear 2D colliders. Use the current Flutter/Flame architecture as the starting point; prove the benefit before adding a new renderer or animation dependency.

Priorities in order:

1. **Fair, stable gameplay.** Reproduce and fix the audited pickup/invulnerability collision bug, falling-rock collider mismatch, incomplete rolling-hazard cleanup, missing shield mission events, wallet-based collection missions, unavailable touch pause in space, haptic-setting bypasses, inconsistent time scaling, device-dependent world units and save-flush gaps. Current jump buffering, coyote time and variable/double jump already exist; improve them rather than pretending they are new.
2. **Alive Dino.** Repair joint artwork and ground contact, then create coherent run, jump, double-jump, fall, land, idle, damage and power states with face reactions, tail balance and attached accessories. Give wardrobe/menu previews independent animation clocks. Review both normal speed and slow motion on a phone. Do not claim success from tests alone.
3. **A complete Desert vertical slice.** Build an authored 45–90 second loop with safe challenge/recovery pacing, coin-guided jumps, depth layers, a rolling fossil boulder, individually falling stones, a bounce plant, breakable treasure pots, convincing contact shadows, real SFX and a satisfying result/retry flow.
4. **Signature playful interactions.** Prototype the plan's Echo Trails and optional bonus gate. Evaluate one down action for roll/air-stomp and a friendly Bubble Bounce rescue power. Teach new actions safely and retain a tap-only assist path.
5. **Living menus and progression.** Make one cohesive illustrated explorer/journal style across every screen; ensure touch/mouse/arrow epoch navigation and unclipped scrolling. Add an Epoch Journal, a small souvenir diorama, chosen cosmetic goals and short try-on unlock celebrations. Use deterministic, attainable rewards and cosmetics that do not affect physics.
6. **Space and the remaining epochs.** Refine the existing space mode into a controllable ring/coin excursion with completed meteor handling and safe re-entry. Expand proven world systems into distinct Monsoon, Forest, Ice, Volcano and Cosmos interactions. Add same-Dino looks and, later, seeded challenges/personal ghosts if the core loop is already strong.

Start by checking `git status`, current instructions, dependencies and the plan's baseline. At the planning audit on 5 October 2026, HEAD was `7269a44` and `main_menu_overlay.dart` had uncommitted changes: preserve those if they remain. Do not overwrite unrelated work. Localhost ports mentioned in the old chat are historical, so verify the build and server before using them.

Keep 60 FPS on a representative midrange Android phone as a measured target. Validate simulation at 30/60/120 FPS, short landscape sizes, all collisions and power combinations, reward persistence and every space transition/reset. Existing green tests are not proof of visual quality, complete controls or correct collisions. Add meaningful coverage where those behaviors matter.

Produce reviewable increments. For each stage, show a playable build and relevant motion/visual evidence, summarize validation and limitations, update the progress log, then continue to the next stage when its gate passes. The first deliverable is the Stage 0 baseline/fairness patch and the first alive-Dino prototype—not a huge untested rewrite. Optimize for a child understanding the next action, enjoying movement, recovering from failure, and wanting to discover or personalize something new.
