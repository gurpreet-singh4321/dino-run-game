# Dino Run Epochs — five-agent design review

9 October 2026. Read-only evaluation of the current checkout, not a claim that these recommendations are implemented. Five distinct subagents reviewed level design, UI, game modes, character design, and overall visual appeal. They ran in two batches because the session allows three concurrent subagents. Existing gameplay, art, saves and purchases were preserved.

## Assessment

Dino and the painted environments are the strongest assets. The improved menu hierarchy, compact Pause, shared coin art, expressive idle rig, connected joints, hand/scarf layering and space painting are worth preserving. The biggest visible weakness is cohesion: rich scenery and textured Dino sit beside sparse geometric props, rigid accessories and some older interface/effect treatments. The biggest gameplay weakness is that beautiful epochs do not yet provide equally distinct experiences or a lasting discovery loop.

Visual polish is a reasonable investment in perceived quality; this audit does not establish a sales increase. Conversion and retention would need real player evidence. No ratings, revenue estimates or fabricated performance results are used here.

## 1. Level design reviewer

**Missing:** authored encounters, biome-correct ground gaps, coin-guided learning and stronger differences between Forest and Monsoon.

- Build one 60–90 second Desert trail: introduce a hazard, practice it, combine it with a coin route, offer a quiet discovery, then a finale. Keep the existing endless runner as a remix rather than replacing it.
- Render gaps as desert fissures, flooded channels, root trenches, ice crevasses, volcanic lava and alien fractures. Keep the shared gap collision rules. Ground currently invokes lava/geyser visuals for generic gaps across epochs.
- Join hazard, coins and landing space into encounter templates. The current random obstacle timer and independent coin timer prevent a clear route grammar; fixed obstacle clearance does not express every jump's landing needs.
- Paint three foreground silhouettes per epoch, with material, volume, texture and contact shadow. Begin with one rock and one log rather than producing a large unapproved atlas.
- Introduce rolling and overhead hazards in teaching segments with visible warnings; verify falling-pillar telegraphs live before calling them unfair.
- Give Forest roots/mushrooms and Monsoon waterlogged timber/splash routes. Their current hazard families and silhouettes largely match.
- Place one nonhazard landmark and one discoverable souvenir in the Desert slice.

Evidence: `lib/managers/spawn_manager.dart`, `lib/components/ground.dart`, `lib/components/obstacle.dart`, `lib/game/biome_manager.dart`; inspected `docs/epoch-obstacles-0.png` through `epoch-obstacles-5.png`. Scope: medium for authored templates/atlas, smaller for gap material correction. The captures' white HUD boxes are export-font artifacts and were excluded from visual findings.

## 2. UI design reviewer

**Missing:** useful outfit browsing, information about epoch choices, discovery presentation and consistent secondary-screen art.

- Add nonpersistent outfit try-on: select an item, preview the full dressed Dino, then choose Unlock/Wear. Cancel restores the actual outfit. Add Head/Neck/Back filters.
- Give each epoch postcard a truthful one-line gameplay descriptor and two painted weather/hazard symbols. Only show per-epoch records after those records exist.
- Turn Journal into illustrated epoch pages with encountered discoveries and locked silhouettes. Preserve current lifetime rewards and claim IDs; use stable IDs for future content.
- Show upgrade current → next benefits using actual gameplay values and a small illustrated demonstration. Show an insufficient-coins shortfall without concealing the price.
- Replace generic Journal outline icons and Home trophy with the existing painted object vocabulary. Refine enabled button rims using their fill colors; retain neutral disabled states and compact Pause sizing.
- Adjust desktop character/action placement independently of the already stronger phone composition.
- Keep browser and Flutter boot pose, size and crop consistent; assess cold/cached handoffs in motion rather than from still screenshots alone.

Evidence: `lib/components/ui/adventure_panels.dart`, `epoch_postcard.dart`, `minimal_home.dart`, `illustrated_menu.dart`, `splash_screen.dart`, `web/index.html`; eight saved screenshots including phone/desktop Home, Wardrobe, Journal, Pause and boot. Scope: small–medium except a persistent discovery collection.

## 3. Game modes reviewer

**Missing:** distinct objectives, meaningful run closure, renewable progression and a skill-based space excursion.

- Replace the older results presentation with run coins, distance, one accomplishment, selected-goal progress, and clear Retry/Home actions. Free repeated revives currently extend the same score attempt. Keep generous assistance if desired, but distinguish assisted and uninterrupted records before introducing competition.
- Correct the Star rocket promise: UI says longer space flights, while duration remains constant and the upgrade increases score. Fix the description or intentionally implement and test a duration benefit.
- Add one chosen discovery goal and three Desert discoveries before expanding the whole mission catalogue. Five permanent starter claims currently exhaust Journal's progression.
- Give space a visible three-ring objective, a safe steering introduction and a small completion reward. It currently cycles coin formations; the method named meteor spawning does not actually construct Meteor hazards. Add threats only after telegraph, collider and lifecycle validation.
- Give each epoch one taught interaction before introducing several new modes.
- After encounter templates support deterministic seeds, add an optional 60–90 second seeded Desert challenge with an honest personal best. Keep Endless as the primary action.
- Give eggs a fossil/discovery identity. Measure beginner earnings before tuning the first outfit unlock; avoid a complicated hatch roster or random paid rewards.

Evidence: `lib/game/dino_game.dart`, `game_state.dart`, `lib/components/ui/game_over_screen.dart`, `adventure_panels.dart`, `lib/managers/coin_manager.dart`, `spawn_manager.dart`, `lib/components/collectible.dart`. Scope: small for truthful copy/results, medium for selected goals/space rings, larger for deterministic challenges.

## 4. Character design reviewer

**Missing:** painted accessory integration, state-specific expressions, proven foot contact and costume secondary motion.

- Preserve current connected joints and correct yawn hand/scarf layering. Current reviewed images do not establish a renewed joint defect.
- Paint three hero outfits with Dino's warm light direction, shaded underside, material thickness, highlights and restrained texture. Start with Explorer hat, Aviator cap and Moon explorer.
- Add distinct readable faces for falling concern, damage surprise, recovery determination and rocket joy. Preserve immediate controls and the same logical physics.
- Verify foot contact at 200/450 logical speed in normal and quarter-speed clips on a device. Static silhouettes prove connectivity, not absence of skating.
- Add bounded damped scarf-tail, cape and pack motion; avoid expensive cloth simulation and honor reduced motion.
- Add one short proud equip pose and one genuine discovery/personal-best celebration rather than more random idle loops.
- Simplify overlapping power rings/jetpack hardware to keep Dino's face and feet visible.
- Create coordinated epoch outfit sets from compatible pieces, retaining the same Dino and existing catalog IDs/ownership schema.

Evidence: `lib/skins/new_dino_skin.dart`, `dino_motion.dart`, `cosmetics.dart`, `lib/components/player.dart`, joint/gesture tests; inspected pose sheet, six-costume sheet, yawn detail, phone Home and live space evidence. Scope: medium art/motion passes; small–medium equip celebration and approval tooling.

## 5. Overall visual appeal reviewer

**Missing:** one consistent foreground art finish, distinctive prop silhouettes, integrated costumes and a clearer focal hierarchy in space.

- Match foreground obstacle detail to the painted character: rounded volume, upper-left light, edge variation, texture and grounded shadows. Approve two props at phone size before expanding the atlas.
- Give epoch families distinct silhouettes rather than recoloring the same polygon/stump pattern.
- Finish costume materials before adding many more catalogue entries.
- Quiet the bright planet behind the score and reduce competing halos, particles and orbital rings. The space painting is more realistic than the ground environments; unify its detail/color treatment without sacrificing the open center.
- Let Home visibly reflect one real souvenir or acquired outfit detail, with a contextual Dino gesture.
- Evolve boot from a bobbing static PNG to a short blink/look/tail-settle performance when the matched handoff is proven. Do not introduce a forced loading delay.
- Establish a single reference sheet for foreground light, outline, texture, icons, contact shadows and ground edge treatment. Avoid another wholesale menu theme change.

Evidence: current phone/desktop boot and Home, Pause, six epoch boards, `docs/painted-space-browser.png`, `docs/new-cosmetics-review.png`, foreground/effect source. Scope: medium art pass, small first souvenir/composition pass.

## Recommended implementation order

| Order | Deliverable | Observable acceptance |
|---|---|---|
| 1 | Two approved painted props, three polished hero accessories, biome-correct gaps | Readable silhouettes and consistent materials at 568×320; existing collision bounds retained; no lava imagery outside Volcano unless explicitly intended. |
| 2 | One authored Desert slice with joined hazard/coin/landing templates | Reachable routes at 200/450 and 30/60/120 updates; teaching and recovery beats; one landmark and discovery. |
| 3 | Outfit try-on, slot filters and informative epoch postcards | Preview never changes saves; purchase/equip is explicit; last inventory item reachable; each epoch communicates its actual challenge. |
| 4 | Truthful upgrade benefits, clear run summary and three persistent discoveries | UI matches formulas; current saves/claims preserved; progress visible on results and Home; revival record policy explicit. |
| 5 | Space ring challenge and effect hierarchy | Safe introduction, visible objective, return reward, readable HUD and Dino; bounded effects; pause/reset/return lifecycle tests. |
| 6 | State expressions, contact tuning and coordinated epoch sets | Normal/quarter-speed phone motion review passes; head/neck/back layering works through run, jump, yawn and rocket. |

Respect the existing Stage 1/Stage 2 device motion and performance gates before broadening interactive content. Desktop raster diagnostics and browser size checks are not phone FPS certification.

## Review limits

This is a source and saved-image audit. Agents did not conduct new physical-device playtests, modify code, alter player saves or measure store conversion. Existing startup work was separately finished and validated before this synthesis; suggestions here are future improvements, not delivered features. User approval of priorities is not required to preserve or inspect work, but implementation should follow the staged roadmap and its acceptance gates.
