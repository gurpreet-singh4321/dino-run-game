# Dino Run Epochs — a living adventure

Planning handoff · 5 October 2026

This is an implementation roadmap, not a claim that the proposed features are already built. Start from the current checkout and verify the audit findings before editing. The first release should prove a complete, joyful Desert experience; then expand the same systems across the other epochs.

## 1. The game we are building

**A tiny, expressive dinosaur races through a world of moving toys, discovers beautiful moments, and brings souvenirs home.** The player returns because movement feels good, the worlds surprise them, and their Dino becomes more personal.

Keep the identity: a landscape-only, side-scrolling 2D runner, one cute Dino, six epochs, simple touch controls, and the existing space bonus. Add depth through layered environments, dimensional props, expressive animation, responsive sound, and interactions that have clear consequences.

The guiding promise is: **every action produces a satisfying response; every run creates a small story.** More particles alone will not deliver this. A falling stone must announce itself, cast a shadow, obey its visible collision shape, tumble after landing, and make Dino react.

### Five pillars

1. **Dino feels alive.** Weight, contact, expression, curiosity, excitement, recovery, and outfit movement work together.
2. **The world plays back.** Springy mushrooms, resonant crystals, moving cloud islands, rotating stones, splashy puddles, and giant distant creatures respond to the run.
3. **Challenge feels fair.** Coin paths teach timing; hazards are readable; patterns have safe solutions and optional skill routes.
4. **Progress changes something visible.** Outfits, journal discoveries, and a tiny home diorama reflect what the player accomplished.
5. **Joy stays readable.** Warm art, a clear silhouette, crisp controls, strong performance, and short celebrations support play.

## 2. Actual starting point and constraints

Repository: `C:/Users/gurpr/OneDrive/Desktop/Projects/Flutter/Work - Freelance/Games/dino_run_epochs`.

At this audit, HEAD is `7269a44`. `lib/components/ui/main_menu_overlay.dart` has existing uncommitted changes. Preserve them. History, asset names, and old documentation do not necessarily describe the current build.

The current project uses Flutter and Flame. `pubspec.yaml` permits Flame `^1.18.0`; `pubspec.lock` resolves Flame **1.38.0**. Inspect installed APIs before adopting examples. Current dependencies do not include a Rive runtime; Dino is a custom painted cutout rig.

Already present:

- One registered character: `NewDinoSkin`, persistent ID `new_dino`, display name **Dino**. Keep this ID to preserve saves.
- Double jump, variable jump height, approximately 90 ms of coyote time and 120 ms of input buffering.
- Hearts, damage recovery, shield, magnet, giant form, rocket/space entry, coins and double coins, egg collectibles.
- Six biomes: Desert, Monsoon, Forest, Ice, Volcano, Cosmos; score-driven transitions and speed increases.
- Ground gaps, several obstacles, rolling balls and falling-stone visuals; some near-miss and milestone feedback.
- Space launch, coin collection, and return phases; the audited durations are 2 s / 10 s / 2.8 s.
- Local coin balance, upgrades, wardrobe ownership/equipment, daily rewards and missions.
- Painted background assets, procedural weather, particles, mobile menu and panel code, existing tests.

**New skin variations mean looks and costumes for this same Dino.** Do not reintroduce the removed character roster. Preserve coins, purchases, upgrade levels, records, and wardrobe equipment through versioned migrations.

## 3. First fix the foundation

These are code-audit findings, not a device playtest. Reproduce each with a focused test or debug scene, then fix it before adding content.

| Finding | Why it matters | Required change |
|---|---|---|
| `Player.onCollision` checks damage invulnerability before handling collectibles | Pickups can be ignored after a hit or space return | Process pickups independently of damage immunity; test both together |
| Falling stones use an aggregate, stationary rectangle while individual stones visibly fall | A player cannot trust what they see | Give each dangerous stone its own moving collider and landing lifecycle |
| Rolling balls are excluded from some spawn bookkeeping | Spacing, cleanup and space transitions can leave hazards behind | Centralize hazard ownership and clearing |
| `recordShieldHit` has no gameplay caller in the audited code | A mission can be impossible to complete | Emit a shield-impact event and connect mission progress |
| The coin-collection mission reads wallet balance, including a development starting balance | A goal can complete without the player performing its action | Track collected coins through gameplay events; remove development grants from release initialization without changing existing saves |
| The touch pause hit test accepts ground play but excludes space | Phone players cannot interrupt every active mode consistently | Route pause through the same state-aware action for touch and keyboard; test every space phase |
| Some direct haptic calls bypass the vibration preference | Settings do not reliably control feedback | Route haptics through a shared, preference-aware feedback service |
| A Meteor component exists but is not spawned or handled as a player hazard | Decorative availability can be mistaken for a complete mechanic | Either finish the feature behind a gate or keep it decorative |
| World distances and positions depend on physical screen size | Jump clearance and reaction windows differ across devices | Establish a logical landscape playfield and screen-independent gameplay units |
| `dt` is clamped and clocks are scaled inconsistently | Low FPS, hit stop and slow motion can change game behavior | Use a consistent simulation clock, bounded substeps, and separate UI/effect clocks |
| Some bobbing directly adds offsets each frame | Motion can drift with frame rate | Calculate animation from a stable origin and elapsed time |
| Giant form immediately scales the player to 3× | It can exceed a short landscape screen | Define a safe power-form presentation, collision policy and camera framing |
| Progress flushes are not guaranteed at game over or app background | An earned reward can be lost | Flush durable progress at lifecycle boundaries; test migrations and recovery |
| A collision test prints instead of asserting outcomes | Passing tests can miss damage regressions | Assert pickups, damage, shields, gaps, hazards, respawn and transition behavior |

Separate distance, skill score and currency. Extra coins must not automatically accelerate difficulty. Keep a generous collision outline inside the visible dangerous surface, independent of bloom, clothing and shadows.

Use one authoritative simulation clock for physics, spawn scheduling and run progression. UI animations can continue during pause; damage hit stop must not silently advance a hazard schedule. Substep or carry elapsed time deliberately rather than discard it. Test 30/60/120 FPS and occasional long frames.

## 4. Give Dino a complete performance

### Animation direction

Dino should move like a small, enthusiastic animal carrying a large head: compact legs, a stable planted foot, a soft belly, a tail balancing the body, and eyes that communicate intent. The silhouette must remain cute when the animation is paused anywhere in its cycle.

The current rig already has continuous motion and IK. Its cadence is capped, but ground contact deliberately slides at world speed. Curved atlas pieces are stretched along bones, and an ankle oval bridges missing contact. These are starting points to investigate, not an animation-quality guarantee.

Create an explicit state graph with continuous blends:

| State | Body and limbs | Personality and secondary motion |
|---|---|---|
| Idle | Slow breathing, planted feet, tiny weight shifts | Eye darts, blink, curious head tilt, occasional toe tap |
| Run / faster run | Contact → compression → push-off → flight → recovery | Tail counterbalance, cheek/head lag, rhythmic arm opposition |
| First jump | Immediate launch response; gentle stretch and tuck | Focused eyes, lifted brows; hat and scarf trail |
| Double jump | Distinct compact recoil and renewed stretch | Delighted expression; small star puff |
| Fall | Feet prepare for contact; torso remains coherent | Concerned glance without fear; controlled tail motion |
| Land | One short compression and damped recovery | Dust or splash; accessories settle after the body |
| Roll / air stomp | Compact silhouette with a clearly smaller logical hurtbox | Playful tuck; expression readable at speed |
| Damage / recovery | Brief recoil, safe recovery, no limb teleport | Surprised squeak then determination |
| Power forms | Strong, readable variations on the normal pose | Shield curiosity, magnet excitement, rocket enthusiasm |
| Victory / unlock / menu interaction | Look, turn, hop, pose, wave | A small, authored performance rather than endless bobbing |

Implement the first seven states before roll/stomp or elaborate celebrations. Jump anticipation must never delay the input response. Facial animation, head motion and accessories are separate channels layered over locomotion; do not restart the whole body when a blink or reward happens.

### Art and rig work

- Inspect actual alpha bounds, paint clean overlapping joint areas, and define pivots consistently. Replace problematic thigh/shin pieces if needed; avoid endlessly tuning constants around unsuitable artwork.
- Prototype a cleaned cutout rig against an authored run sequence. Pick the approach after comparing real-time playback and slow motion; use sprite sequences where articulation cannot preserve the painted silhouette.
- Tune speed, world scale, stride length, stance duration and cadence together. Pass both anatomy and ground-contact review. A slower cycle that skates across the ground is not a finished solution.
- Add a ground-anchored contact shadow: tight and dark at contact, broader and lighter as Dino rises. It must not float with him or shift the collision plane.
- Let feet meet the floor at a shared world coordinate. Review planted contact across a complete cycle, all jump states, landing blends and power-form transitions.
- Give each menu/wardrobe preview its own animation instance and clock. A preview must animate independently without advancing or mutating the gameplay character.
- Use velocity-driven, damped motion for scarf tails, hat tilt and backpack straps. Bound all secondary motion so it cannot detach accessories.

Acceptance: 30 seconds of running looks coherent at normal speed; slow-motion inspection shows no popping, hollow joints, ankle gaps or reversed knees. The character reads at phone size and remains expressive with effects turned down.

## 5. A dimensional world built for a 2D runner

Keep the gameplay plane simple. Render dimensional objects with pre-rendered 3D sprite sequences or carefully shaded 2D art, contact shadows, perspective faces, occlusion and depth layers. This fits the existing renderer and supports mobile performance. A real-time 3D prop prototype can be a later experiment once the core release performs well.

### Shared art direction

Use a cohesive **storybook toy-adventure** style: rounded shapes, sculpted stone and wood, soft painted texture, warm highlights, readable shadow faces, friendly creatures and tactile collectibles. Dino remains the visual reference. Menus become an explorer's journal and dressing room with illustrated objects, not a competing cyberpunk aesthetic.

- Warm cream / ink blue / honey gold form the menu base; each epoch contributes one accent.
- Agree on one main light direction. Props, Dino, shadows and UI item illustrations should follow it.
- Coins and safe interactive objects are warm and inviting. Dangerous edges use consistent shape, motion and contrast cues, with color as an additional cue.
- Keep high-contrast foreground hazards readable against subdued distant layers.
- Clouds use distinct near/far shapes, gentle volume shading and independent drift. They must not obscure approaching hazards.

### Depth recipe

Start with six layers: sky, distant landmarks, midground scenery, interactive playfield, near-ground dressing, sparse foreground atmosphere. Author transparent layers instead of pretending a single flat panorama has independent depth.

Use depth-specific movement, scale and atmospheric contrast. Large landmarks move slowly; nearby leaves and dust move faster. A landing can produce a tiny camera response; a distant creature can create an optional subtle rumble. Cap camera movement and support reduced motion.

Dimensional props should have a front face, shaded side, base shadow and occasional rotation sequence. Use logical colliders that remain clear when the prop turns. A dangerous rock rotating in the air must not change into an invisible oversized box.

### Interactive prop catalogue

| Prop | What it does | Feedback that gives it life |
|---|---|---|
| Falling stone | Shadow and dust tell announce an impact zone; rock falls, lands, then rolls or breaks | Rotation, growing shadow, short impact sound, debris, local ground ripple |
| Rolling fossil boulder | Predictable rolling hazard with a safe hop or optional giant smash | Readable rotation, pebble trail, contact shadow, humorous Dino reaction |
| Bounce mushroom | Launches Dino along a designed safe arc | Compression, delayed wobble, tiny spores and musical boing |
| Resonant crystal | A safe collection or stomp interaction | Growing light, a tuned chime, a wave through nearby crystals |
| Breakable clay pot / crate | Optional reward; clearly distinguished from solid hazards | A few dimensional chunks and a quick treasure reveal |
| Puddle | Safe splash; a small reward interaction in a challenge | Ripple, droplets, surface highlight, matching foot sound |
| Cloud island | Temporary, obvious platform or space bounce surface | Squash, wispy pieces, shadow and gentle recovery |
| Wind ribbon | Teaches a temporary, consistent jump modifier | Directional particles, visible bend in grass and scarf |
| Friendly giant creature | Mostly scenic; occasionally creates a marked safe bounce event | A slow glance, distant footsteps and a memorable silhouette |

World actors need explicit states and lifetimes. Keep dangerous, interactive and decorative categories separate. Decorations near the collision plane should not look like unmarked hazards.

## 6. Redesign runs as playable stories

### Replace random clutter with authored chunks

Build a seeded chunk scheduler. Each chunk defines length, safe entry/exit, required action, difficulty, minimum telegraph time, compatible power-ups, coin routes and optional interaction. Validate reachability against the actual jump model and current speed. Randomness chooses compatible chunks; it does not improvise impossible combinations.

Use a repeating dramatic rhythm: **learn → perform → delight → recover → choose**. A short recovery section after a dense challenge is part of level design, not wasted space. Coin arcs show the intended jump without requiring text.

Target a first satisfying loop of 45–90 seconds, then tune from playtests. Design endless play as connected chapters; use distance or authored chapter progress rather than coin-inflated score for epoch transitions. Space can interrupt a chapter through a safe portal and return to a known recovery section.

### A signature mechanic: Echo Trails

Following a complete optional coin trail creates an **Echo**: a visible musical ripple passes through nearby props, lights a path, and advances a small adventure meter. Several clean interactions open a clearly signposted bonus gate. The gate offers an optional, short skill route and an attractive souvenir; the ordinary path remains valid.

This connects movement, music, scenery and progression. Build one Desert Echo Trail before generalizing it. Avoid filling the screen with score labels. A missed trail removes the current streak gently; it does not delete earned discoveries.

### Controls and new actions

- Retain tap/hold jump and second-tap double jump as the primary experience.
- Prototype **one additional down action**: swipe down on the ground rolls; swipe down in the air stomps. Add a large optional button and keyboard equivalent. Decide whether to ship both after playtesting.
- Stomp activates marked props and breakable items; roll opens low routes. Never make a new action mandatory before teaching it in a safe section.
- Keep a tap-only assist option with alternative compatible chunks.
- Defer separate dash, grappling and combat buttons until the first expanded loop proves it needs them.

Prototype short elevated platforms and crumbling bridges after ground movement is stable. They add route choice and anticipation to an otherwise flat run. This requires explicit one-way platform collision, moving-surface support, jump-through behavior and safe fall recovery; the current ground/gap logic must not be treated as sufficient. Start with a static low ledge, then a marked crumbling bridge, and only then moving roots or cloud islands. Validate giant form, bounce powers and space return against these surfaces.

### Six distinct epochs

| Epoch | Mechanical identity | Signature joyful moment |
|---|---|---|
| Desert | Fossil boulders, clay pots, small bounce plants, marked falling rocks | A distant long-neck dinosaur lifts its head as an Echo lights fossil ribs |
| Monsoon | Puddle splashes, leaf rafts, rain-reactive flowers, gentle telegraphed wind | A splash chain awakens glowing flowers and a brief rainbow |
| Forest | Bounce mushrooms, friendly firefly paths, moving root platforms | A mushroom sequence becomes a musical trampoline garden |
| Ice | Crystal timing, visible safe ice slides, frosty pads | A crystal trail rings in harmony and lights an aurora |
| Volcano | Warm stone platforms, vent tells, clearly timed eruptions, giant-smash sections | A giant-Dino stomp starts a harmless wave of glowing cracked stones |
| Cosmos | Floating stepping stones, soft gravity fields, star-ring timing | A comet companion circles Dino as a ring chain lights the sky |

Make one mechanic and one landmark moment recognizable in each epoch. Build hazards and timing for the biome, not merely recolor the same cactus. Preview new mechanics before enabling dense combinations.

## 7. Space becomes a highlight

Preserve the existing launch / collection / return structure, but author it as a compact excursion:

1. A rocket pickup produces an immediate character reaction and a readable departure cue.
2. Launch remains controllable where practical; avoid a long empty cutscene.
3. Existing space movement includes hold-to-thrust and keyboard/touch positioning. Audit the direct vertical drag path for conflicts with thrust, then refine both into one consistent steering model with bounded screen movement. Teach that model in a safe ring sequence.
4. Star rings and gentle slalom coin paths reward skill. Add a small number of moving, well-telegraphed meteor hazards only after the collider and lifecycle work is complete.
5. A short cloud/asteroid bounce sequence creates one memorable set piece.
6. A countdown and matching audiovisual cue prepare the player for re-entry. Return to a safe ground chunk with an authored landing animation.

Prototype a 12–18 second total excursion, retaining configurable timings. Camera scale changes must not confuse control distances or alter collision fairness. Space score and souvenirs should be presented clearly at the next natural pause.

Keep launch, timers, hazards, particles, music and power-up state resettable. Test normal completion, damage, pause, background, revive and restart in every phase.

## 8. Powers with character and meaningful choices

Improve existing powers before inventing more:

- **Magnet:** give it a visible field and curved attraction paths; satisfyingly collect a trail without jitter. Sound pitch rises through a short chain, then resets.
- **Shield:** a round, readable bubble with two or three authored responses: equip, absorb, break. Show durability or duration unambiguously. Dino can look at it curiously.
- **Giant:** a framed, chunky stomp form with a safe visual size and explicit crush rules. Mark smashable objects; show invulnerability with a clear outline, not flashing invisibility.
- **Rocket:** personalize the launch and space performance; use the same outfit anchors.
- **Coin multiplier:** make doubled treasure visually distinct and easy to understand.

Add **Bubble Bounce** as the first candidate new power: an automatic soft rescue from one fall, with a brief bounce and clear consumption. It provides a friendly recovery moment without adding a button.

Consider a later **Echo Burst** earned through skilled play: a short, readable reward section with an attractive route and temporary effects. It must not hide hazards or stack uncontrollably with giant, shield and rocket.

Define a power interaction matrix and priority rules. Prefer at most two active visual layers. Upgrades can improve duration or convenience, but early content must remain beatable without buying them. Cosmetic ownership must not secretly change physics.

## 9. Progression: bring the adventure home

Build an **Epoch Journal** and a small **Dino home diorama**. Completing trail challenges reveals illustrated stamps, fossil pieces and tiny scenery objects. The diorama changes visibly as the player discovers worlds. Dino notices a newly placed souvenir with a short reaction.

Give the existing egg collectible a discovery purpose: reveal an illustrated creature fact, journal stamp or collectible souvenir through a clear earned sequence. It currently grants score and coins; a hatch or companion system is new work, with its own art, persistence and reward rules. Introduce it only after the journal loop works.

The reward loop:

`play a good section → notice an accomplishment → choose a reward → personalize Dino or home → discover a new challenge`.

- Every run summary names one achievement and shows progress toward one selected goal.
- Offer a first meaningful cosmetic within roughly 2–3 beginner runs; tune prices and earnings through observed play, not arbitrary large coin numbers.
- Let players choose their next outfit or journal goal. Show the requirement and progress before play.
- Ship a small, deterministic mission catalogue with multiple attainable goals, including clean landings, trail completion, prop interactions and space ring chains.
- Add a local seeded challenge and, later, a personal-best ghost. Version seeds and simulation rules so ghosts replay correctly.
- Use accessible, deterministic rewards. Avoid paid random rewards, punitive lost streaks, pressure timers and endless modal celebration chains.
- Offline play should earn and save progress. Cloud sync, public rankings and live events are later projects with their own scope.

### One Dino, many looks

Create a palette/material layer plus existing accessory slots. A first collection can contain:

| Look | Palette and outfit | Unlock idea |
|---|---|---|
| Sunshine | Current yellow Dino | Available from the start |
| Mint Explorer | Mint body, warm plates, explorer hat | Complete the first Desert chapter |
| Berry Scout | Peach-pink body and berry scarf | Finish a beginner trail collection |
| Raincoat Ranger | Yellow rain hood and little boots | Discover Monsoon splashes |
| Snow Puff | Pale blue body, cream belly, beanie | Complete a crystal challenge |
| Ember Buddy | Warm coral body with luminous plate accents | First safe volcano adventure |
| Moonbeam | Deep blue body, subtle stars, bubble helmet | Complete a space ring sequence |
| Rainbow Celebration | Soft multicolor accents | Fill the starter journal page |

Produce material-aware variants or dedicated atlas variants; a whole-image color filter would also recolor eyes, teeth and belly. Cosmetics share stable anchors and have documented coverage rules. Preview every outfit through run, jump, roll, landing and space. Trails and small companions are optional cosmetic extensions after clothing fits reliably.

## 10. Menus should belong to Dino’s world

Use one design system across home, epoch selection, dressing room, boosts, journal, settings, pause, results, tutorial and unlocks. Retire duplicate legacy layouts after preserving necessary behavior.

- **Home:** animated Dino on the left, world cards and primary actions on the right, one large Play action. Show a selected goal and a compact journal/reward indicator.
- **Epoch selection:** visible left/right buttons, touch and mouse dragging, a scrollbar or edge cue, clear selected state. The last world must be reachable at every supported width.
- **Dressing room:** a live, independently animated Dino preview; tabs for looks, clothing and optional trails. Illustrated item cards, honest costs, try-on previews, Wear / Take off actions, and no removed-character cards.
- **Boosts:** a small collection of illustrated physical objects, compact descriptions, clear levels and one purchase action. A header never becomes a second overflowing row.
- **Journal:** one scrolling content area, clear attainable tasks, and an illustrated discovery grid. Claiming a reward updates the visible balance once.
- **Results:** Dino reacts to the run; show distance, best improvement, one discovery and one goal. Retry is immediately available; saving completes before leaving.
- **Pause/settings:** shared panel style, sound and haptic controls, reduced motion/effects, high-contrast option and restart confirmation where progress would be discarded.
- **Unlock:** a short reveal, item close-up, Dino try-on, and clear Equip / Later actions. Allow skipping or shortening celebrations.

Use comfortably sized touch targets, short labels, tested safe areas, text scaling, and left/right hand layouts where appropriate. There should be one visible scroll responsibility per section. Maintain the landscape-only orientation decision.

## 11. Sound, response and little stories

The audit suggests several audio helpers currently provide BGM/haptics rather than distinct gameplay sound effects. Wire a real SFX system before claiming audio polish.

Add a small, cohesive sound palette: soft foot contacts by surface, launch/pop, double-jump chirp, landing, splash, collection, shield absorption/break, rock impact, mushroom boing, rocket ignition, menu tap and reward reveal. Use limited variations and bounded pitch chains, pool voices, cap simultaneous sounds, and honor volume/mute immediately.

Music can gain a light percussion layer during a clean trail and relax during recovery. Keep timing independent of audio latency; a visual tell always works with sound off.

Build occasional authored personality moments: Dino peers at a frog, shakes rain off his head, notices a firefly, shivers in snow, proudly poses in a new hat, or waves at a huge creature. Give these cooldowns and interrupt them cleanly for gameplay.

Use concise feedback contracts per interaction: anticipation, response, sound, haptic, camera amount, reward and recovery. Haptic events should be short and optional; screen shake should be bounded and rare.

## 12. Architecture and asset pipeline

Introduce systems incrementally behind a playable slice:

- `RunSimulation`: consistent clock, world units, run distance, deterministic RNG and replay version.
- `RunDirector` / `ChunkDefinition`: compatible chunk selection, rhythm, difficulty bands, safe handoffs and test seeds.
- `HazardRegistry`: spawn ownership, collision rules, transition cleanup, pooling and lifecycle.
- `DinoAnimator` / `DinoRigDefinition`: state graph, poses, joints, expression channels and preview instances.
- `FeedbackDirector`: short, bounded audio/visual/haptic responses driven by events.
- `EpochScene`: depth layers, local world actors, lighting palette and quality settings.
- `ProgressionService`: journal, goals, cosmetic looks, reward transactions, save versioning and migrations.
- Shared `GameMenuShell` and illustrated card components: consistent style, input, sizing and focus behavior.

These are proposed responsibilities, not a requirement to create eight large frameworks before gameplay. Move one responsibility when the slice needs it. Reuse existing Flame components and the current renderer wherever they already work.

Asset contracts must include canvas size, alpha, trim bounds, pivot, anchor locations, light direction, facing direction, scale and collider reference. Keep source files, generation prompts or Blender scenes, licenses, and exported atlases in documented locations. Validate alpha and atlas gutters; do not accept painted checkerboards as transparency.

First asset batch: repaired Dino joints and several face poses; complete Desert layer set; one rotating fossil boulder; one independent falling rock; one bounce plant; one breakable pot; one illustrated magnet and shield; one wardrobe outfit; core SFX. Produce biome-specific sets only after this batch passes in game.

## 13. Performance and verification

Target a sustained 60 FPS on a representative midrange Android phone; frame work must fit the device budget. This is an acceptance target, not a measured result. Test a minimum-supported phone and thermal behavior in a sustained 10-minute session. Use native profile/release builds for profiling, and the browser for complementary input/layout checks.

- Decode and cache background textures once. Current/next-epoch preloading and a shared Cosmos/space texture should be evaluated; avoid retaining duplicate full-resolution decodes without need.
- Cache static art/text; avoid rebuilding the entire menu each tick. Repaint only animated previews or balances that changed.
- Limit dynamic blur, full-screen glow, opacity layers and repeated `saveLayer` calls. Prefer pre-rendered highlights and reusable textures where suitable.
- Pool frequently spawned actors and particles; verify no stale state leaks between runs.
- Bound debris, weather, glow and SFX voices. Quality levels can reduce decoration while leaving physics and challenge unchanged.
- Preload upcoming assets off the critical gameplay path and show an intentional loading state when required.

Required validation includes: actual pickup/damage assertions; per-stone collision; seeded chunk reachability; at least thousands of automated generated-chunk samples; speed/viewport consistency; 30/60/120 FPS simulation parity; jump/land animation contact; save migrations; each space phase reset; power combinations; epoch swipe/mouse/arrow navigation; last journal item reachable; wardrobe preview continuously animating; equip/restart/persistence; UI overflow at 568×320, 640×360, 844×390 and tablet landscape, with safe areas and text scaling.

Record normal-speed motion clips and inspect paused frames. Unit tests cannot judge whether a dinosaur feels charming. Run brief supervised playtests with the intended age range: can they understand the next action, recover from failure, notice a reward and explain what they want to try next? Measure these behaviors rather than promising that visual polish will make the game addictive.

## 14. Delivery roadmap and gates

| Stage | Deliverable | Gate before proceeding |
|---|---|---|
| 0 — Baseline and fairness | Reproduce/fix audited collisions, pickups, time, lifecycle, saves and screen scaling; preserve current work | A repeatable baseline with meaningful tests and no known blocking fairness bug |
| 1 — Alive Dino | Clean rig/art, complete core movement, face states, accessory follow-through, independent previews | Normal-speed and slow-motion review pass on a phone; no broken contact |
| 2 — Desert vertical slice | 45–90 s authored route, depth layers, rotating boulder, falling rock, bounce plant, pot, coin guidance, core sound | An enjoyable complete loop: start → learn → challenge → discovery → results → retry |
| 3 — First new interactions | Prototype roll/stomp, Echo Trail, optional bonus gate and Bubble Bounce | Controls remain understandable; all new paths are reachable and taught safely |
| 4 — Living menus and progression | Shared menu system, journal, first diorama page, four cosmetic looks, reliable rewards | Every purchase/equip/claim is clear, saved and animated; all screens scroll correctly |
| 5 — Space highlight | Ring/slalom route, complete meteor handling, cloud/asteroid set piece, polished return | Safe re-entry and complete reset behavior at all interruption points |
| 6 — Epoch expansion | One distinct interaction and landmark sequence per remaining epoch | Each epoch changes play; content shares the proven collision/art contracts |
| 7 — Replay and polish | More looks, optional personal ghost, seeded challenges, accessibility, quality levels and device profiling | Device targets, migration tests and child playtests pass; scope cuts resolve remaining jank |

Do not assign a confident calendar estimate before the animation/asset slice reveals production cost. At each gate, provide a playable build, a short video or screenshots, relevant test results, current limitations and the next bounded task.

**If only the first three stages ship, the game should already feel substantially better.** Further features earn their place through the quality of that loop.

## 15. First session in the fresh chat

1. Read this plan, inspect current status/instructions, and preserve local changes. Re-check the audit against the latest code.
2. Launch the actual current build on a landscape phone-sized viewport and obtain a reliable native profiling path.
3. Record the existing Dino run/jump/land, epoch scrolling, wardrobe, falling-rock collision and space sequence. Add a small debug scene if it makes reproduction easier.
4. Establish Stage 0 acceptance cases and fix the highest-impact fairness bugs in a bounded first patch.
5. Begin Stage 1 with a cleaned animation prototype and a playback review tool. Do not proceed by simply adding more sinusoidal offsets to the existing model.
6. Continue into the Desert slice after the movement gate passes. Maintain a progress log and finish reviewable increments autonomously.

### Evidence and technical references

Primary source locations for this audit: `lib/components/player.dart`, `lib/components/falling_stone.dart`, `lib/components/rolling_ball.dart`, `lib/managers/spawn_manager.dart`, `lib/game/dino_game.dart`, `lib/game/biome_manager.dart`, `lib/managers/speed_manager.dart`, `lib/managers/coin_manager.dart`, `lib/managers/audio_manager.dart`, `lib/skins/dino_motion.dart`, `lib/skins/new_dino_skin.dart`, `lib/components/sky_background.dart`, and `lib/components/ui/`.

Official references checked on 5 October 2026:

- [Flame parallax documentation](https://docs.flame-engine.org/latest/flame/components/parallax_component.html): independently moving layers create the depth effect used in this plan. Check compatibility with the lockfile; the page currently displays a version warning.
- [Flame effects documentation](https://docs.flame-engine.org/latest/flame/effects/effects.html): component effects support bounded time-based visual responses. They do not replace locomotion or physics design.
- [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices): avoid excessive offscreen layers and large rebuilds; profile before expanding expensive visual effects.
- [Flutter Performance view](https://docs.flutter.dev/tools/devtools/performance): use measured frame timings for the 60 FPS target.

Past documents and screenshots remain useful references, but some still describe removed characters, earlier assets or older UI. The current code, actual playback and this dated handoff take precedence.
