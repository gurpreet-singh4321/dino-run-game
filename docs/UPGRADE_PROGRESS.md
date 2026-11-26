# Dino Run Epochs upgrade progress

Updated 6 October 2026. Current increment: Stage 0 fairness, Stage 1 character
prototype, and the user's requested menu/character corrections. The staged
roadmap is not complete; phone motion and performance acceptance remain open.

## Preservation and baseline

- HEAD at start: `7269a44`. The original uncommitted menu is preserved in
  `menu-before-upgrade.patch` and `baseline-menu.png`. The plan and handoff remain.
- Keep one Dino, `new_dino`. Saved coins, high score, upgrade levels, owned outfits
  and equipped slots retain their persistent keys. No extra character roster.
- Baseline: 47 passing tests and three short-landscape menu overflows. Previously
  print-only collision checks were replaced with meaningful assertions.
- The first plain-paper/skinny-leg revision was rejected by the user. Its screenshot
  `minimal-mobile-menu.png` is historical, not the current menu or accepted art.

## Stage 0 fairness changes

- Pickups remain collectible during damage and space-return immunity; solid player
  hitboxes catch pickups/hazards fully contained inside the player.
- Individually warned falling rocks carry their own moving circular hurtboxes.
  Clusters and empty gaps between rocks do not carry aggregate colliders.
- Spawn ownership/spacing/cleanup covers obstacles, rolling balls and falling
  rocks through launch, revive, reset and menu exit.
- Shield absorption records mission progress. Collection missions use lifetime
  gameplay pickups, independently of wallet grants, purchases and daily rewards.
- Version 2 saves add collection stats without guessing from old balances or
  revoking existing claimed missions. New wallets start at zero; old balances
  survive. Serialized flushes wait for pending writes and are requested on
  game-over, pause/background, exit and removal.
- Touch pause works during every space phase and resume retains the paused phase.
  Restart/revive/exit reset space and ground-hazard state.
- Haptics route through the enabled setting, without duplicate direct native calls.
- A 120 Hz fixed-step loop applies world time scaling once, while hit-stop and
  feedback envelopes use raw time. Run distance drives difficulty independently
  of collection bonuses. World units are 640×360; input maps through the viewport.
- Reset clears ground gaps/slides. Giant presentation maintains contact on resize
  and expiry; immune gap falls recover safely. Idle bobbing stays bounded.

Acceptance checks use actual collision dispatch and production simulation:
per-stone collision and empty space, damage/shield/recovery, 30/60/120 FPS plus a
long frame, viewport input, every space pause/reset, hazard cleanup, disabled
haptics, save migration, concurrent flushing and game-over persistence.

## Stage 1: current joint and idle revision

- Idle/run/jump/double-jump/fall/land/damage/rocket states, independent power state,
  bounded reactions and attached accessory follow-through.
- Legs now have a **single closed, tapered silhouette** from torso through knee
  into the painted foot cuff. The opaque thigh texture fills that silhouette;
  individually capped line segments and detached ankle blobs are gone. Roots
  overlap beneath the torso and the ankle overlaps the foot, with normal leg
  volume restored rather than merely thinning the old joints.
- A rendered alpha-connectivity test checks torso-to-foot continuity across
  16 run phases plus idle and yawn, using the actual artwork and painter.
- Menu and wardrobe previews stand and breathe rather than running in place.
  An 18-second idle cycle includes a three-second yawn/stretch, looking around,
  and a raised-hand greeting. Feet stay planted; starting play fades the gestures.
- The yawn closes the eye, tilts the head, replaces the painted smile with an open
  mouth/tongue and raises a hand. Gesture hands render in front of the head.
- Every preview owns its rig and clock; rendering does not mutate gameplay or
  shared template motion. Only the preview repaints each tick.
- `lib/motion_review.dart` offers normal/quarter speed, pause, frame-step, outfit
  toggle, the core movement poses and directly selectable yawn/look/wave poses.
  It is a separate entry point and never changes saved progress.

Evidence: `dino-stage1-poses.png` now contains thirteen movement/idle/outfit views;
`dino-normal-browser.png`, `dino-quarter-speed-browser.png`, and
`dino-yawn-browser.png` record browser samples of the current rig.

**Stage 1 is still a prototype.** Phone normal/slow-motion review and sustained
native profiling have not been completed; no Android phone was connected during
`device-audit.json`. Exact planted-foot/scenery matching at high running speeds
still needs tuning. Tests and browser samples do not claim that the phone motion
or measured 60 FPS gate passed.

## Cohesive scenic menus: user-requested correction

- Home uses the existing painted scenery for the selected Desert, Monsoon, Forest,
  Ice, Volcano or Cosmos epoch, with a brief crossfade. Scenery is also carried
  into wardrobe, upgrades, journal, settings and pause.
- One shared palette and shell (`menu_chrome.dart`, `AdventureTheme`) replace the
  mix of white home, cyan neon, dark glass and unrelated settings styles. Warm
  paper panels, forest-green actions, restrained brass edges and consistent
  typography/touch targets appear across the set. Expensive blur/glow was removed.
- A drawn stamped coin replaces the generic balance symbol. Price text stays
  readable even when a purchase is disabled; balances and ownership remain real.
- Upgrades show small illustrated magnet/bubble/rocket/coin art, current level,
  description and actual price. Wardrobe shows the same painted accessory art,
  idle Dino, ownership and equip/take-off controls.
- Journal keeps existing mission IDs/targets/rewards and actual pickup statistics;
  claims save once. Settings retains sound/vibration controls and immediate saves.
  Pause now shares the menu shell and safe continue/settings/exit controls.
- Home retains compact Play, wardrobe/upgrades/journal navigation, daily gift,
  settings, mouse/touch swipe and keyboard epoch selection. Dead legacy menu
  layouts and their unrelated repeating animation controllers were removed.
- Each screen fits 568×320, 640×360, 844×390 and 1024×600 with 1.3× text and safe
  areas. Tests scroll to the last wardrobe, upgrade and journal item, rather than
  merely asserting that the initial view has no overflow. Widget-level purchase,
  equip/take-off, upgrade and one-time claim flows survive a save/reload.

Current screen evidence: `scenic-home-desert.png`, `scenic-home-monsoon.png`,
`scenic-wardrobe.png`, `scenic-upgrades.png`, `scenic-journal.png`,
`scenic-settings.png`. Earlier attempt logs/screenshots are historical.

## Current validation and playable artifacts

- Full Flutter suite: **76 passed**, `space-fix-tests.txt`.
- Static analysis: **no issues**, `space-fix-analyze.txt`.
- `git diff --check`: passed (only platform line-ending notices).
- Android debug APK: `build/app/outputs/flutter-apk/app-debug.apk`; build log
  `android-build.txt`. An installable debug build is not a performance measurement.
  Latest SHA-256: `0C4ED3569CF9E2524927C7212E3C408DC04C1B124B8D7444E9D0C75D9D538112`.
- JavaScript release web output: `build/web`; build log `web-build.txt`. Wasm was
  not validated. The obsolete generated Rive cache was refreshed without adding
  an animation dependency. Logs retain nonblocking upstream Kotlin/font warnings.
- Browser review checks current home and every redesigned panel at 568×320,
  verifies Desert/Monsoon scenery changes and samples normal/quarter-speed rig
  movement and the seeded yawn. Final release smoke passed Play/jump, revive,
  touch pause and safe menu exit. `release-gameplay-pause.png` records the current
  pause screen; this was browser testing, not a native phone performance run.

Current-session launch commands (verify ports again in a future session):

```powershell
# From build/web: release build, same origin preserves browser progress
python -m http.server 5180 --bind 127.0.0.1
flutter run --no-pub -d web-server --web-port 5181 --web-hostname 127.0.0.1 -t lib/motion_review.dart
# From build/web:
python -m http.server 5182 --bind 127.0.0.1
```

For a connected phone use `flutter devices`, `flutter run --profile -d <device-id>`
and the review entry point. Record device/model, frame timing/thermal results and
normal/quarter-speed contact review here before marking the phone gate passed.

## Next bounded roadmap work

1. Complete phone movement/contact/accessory review, address any visual problems
   and high-speed foot slip, and collect native frame timings.
2. After Stage 1 passes, build Stage 2's authored 45–90 second Desert route: safe
   pacing, guided coins, fossil boulder, bounce plant, pots, depth and core sounds,
   with reachability sampling before claiming route fairness.
3. Follow Stages 3–7 for playful interactions, journal/cosmetic goals, refined
   space, other epochs and replay/device polish. Those features are not marked
   implemented or accepted by this UI/animation correction.

## Ankle correction — 6 October 2026

The follow-up crop still showed the atlas foot's slanted ankle cuff meeting the
procedural calf at an awkward seam. The renderer now unions the leg and shaped
heel/toe silhouette before painting, and samples only the foot painting below
that old cuff. Both parts rotate around the same ankle. Union also prevents a
folded recovery calf from cutting a transparent wedge out of the joint.

The rendered joint regression now checks an opaque band through each rotating
ankle in addition to body-to-foot connectivity across 16 stride samples and
idle/yawn. All 72 tests pass (`ankle-fix-tests.txt`) and analysis is clean
(`ankle-fix-analyze.txt`). The regenerated `dino-stage1-poses.png` covers the
movement states and idle gestures. Actual browser review at normal and quarter
speed is recorded in `dino-ankle-idle.png`, `dino-ankle-quarter-speed.png` and the
close view `dino-ankle-detail.png`. This remains browser evidence; the phone gate
above is still pending. The existing paused main browser tab was preserved.

Web release and Android debug builds were rebuilt successfully after the ankle
correction (logs: ankle-fix-web-build.txt, ankle-fix-android-build.txt).
Latest APK SHA-256: 0C4ED3569CF9E2524927C7212E3C408DC04C1B124B8D7444E9D0C75D9D538112.



## Space load, scenery transitions and scarf layering — 6 October 2026

- Space coin groups now wait for the prior pattern's tail to clear a 72-unit
  gap. Pickups use passive hitboxes, so they collide with Dino rather than one
  another. A 48-pickup budget bounds the spawner; actual full-trip checks peaked
  at 22–25 instead of 44–62. Coin reward values and saved progress are unchanged.
- Static coin painting is shared in a cached picture. Orbit reuses the already
  loaded Cosmos image instead of decoding a duplicate. Sky art uses Flame's
  shared image cache; hidden ground skips drawing in orbit. Star/comet halos,
  jet exhaust and the flight timer avoid their former repeated blur passes.
- In the isolated desktop debug benchmark, mean simulation/update time changed
  from 915 to 297 microseconds at speed 200 and 264 to 128 at speed 450.
  These are debug test-runner results, not phone FPS. Median raster/readback was
  approximately unchanged; p95 readback timings varied and did not improve.
  Both raw reports are retained in space-performance-before.json and
  space-performance-after.json. Native phone profiling is still required.
- EpochScenery keeps an opaque current image until the incoming artwork is
  decoded. It queues rapid navigation with at most two layers, and uses a fixed
  resize cache and repaint boundary. Play fades the home into the chosen epoch
  for 260ms, then removes the overlay; gameplay input is not blocked by the fade.
- The front arm now draws after all neckwear, so yawning/waving hands cover the
  scarf. The rendered regression compares the same forearm with/without a scarf
  while allowing tiny texture antialiasing differences.
- A legacy debug bootstrap repeatedly invoked the Dart entrypoint while Flutter
  initialized. Removing it entirely left the extension-free motion review blank.
  It is now a guarded one-shot fallback after a four-second normal-boot window;
  a late debug launch shares the same latch. Three actual-source Node checks pass
  (web-bootstrap-tests.txt), and the delivered release page has no debug fallback
  invocation or console errors in its fresh-load check.

Full Flutter suite: 76 passed; analysis clean; web release and Android debug APK
rebuilt successfully (space-fix-tests.txt, space-fix-analyze.txt,
space-fix-web-build.txt, space-fix-android-build.txt). git diff --check passed.

The original address http://127.0.0.1:5180 now serves build/web in release mode,
which removes debug-mode overhead while retaining the origin's coins, best score
and outfit. A fresh separate tab verified the saved explorer outfit, best 7897
and wallet 140 without playing a run on that origin. The existing paused tab was
left intact; reload it to use the release build.

Browser evidence: space-launch-browser.png, space-orbit-browser.png,
yawn-scarf-layer.png, yawn-scarf-detail.png, menu-transition-browser.png,
menu-to-game-browser.png and release-space-fix-menu.png. The separate review at
5184 exercised launch, coin collection, re-entry and menu return, then rapid
Desert/Monsoon/Forest navigation and Play into Forest. Motion review at 5181
verified the scarf below the raised hand. Phone and Stage 2 gates remain pending.

## 8 October 2026 — colorful illustrated menus

Applied the Games workspace anti-ui-slop skill and recorded the current brief in
DESIGN_CONTRACT.md. Replaced the plain beige/forest controls with a coordinated
adventure palette: gold Play and coins, coral Wardrobe, violet Upgrades, blue
Journal, teal Settings. Added six painted object icons (safari hat, rocket,
journal, gift, gear, Play badge), gentle button gradients, rounded asymmetric
shapes, raised lower edges and section-colored panel headers. Inventories use
quiet tinted interiors and colorful icon wells, retaining existing data/actions.
Pause shares the same controls. No animation, rendering dependency or save schema
was added for this visual revision.

Visual review caught un-clipped gradient backgrounds and a test-font fallback;
rounded clipping and explicit button font inheritance were corrected before the
final browser inspection. Browser screenshots verify Home, Wardrobe, Upgrades,
Journal and Settings at 568x320 and 1024x600. The mobile pause screen was also
inspected. Evidence: colorful-*-mobile.png and colorful-*-desktop.png; the widget
export mobile-menu-review.png shows 844x390. Disabled upgrades, enabled journal
claims, owned outfit actions and the final wardrobe/journal rows were inspected
on desktop. Automated layouts cover 568x320, 640x360, 844x390 and 1024x600 with
1.3x text and safe-area padding, including scrolling to the last items.

The browser review briefly started a run after a scroll interaction and earned
3 coins (298 to 301); it was stopped. The Explorer hat was accidentally equipped
in that interaction and then removed, restoring the original scarf-only outfit.
No purchases or mission claims were made. Existing best score 8011 stayed intact.
The temporary review tab was closed and the viewport override reset.

Validation: 76 full regression tests passed (color-menu-all-tests.txt), six
focused mobile/transaction tests passed (color-menu-tests.txt), analysis clean
(color-menu-analyze.txt), web release and Android debug builds successful
(color-menu-web-build.txt, color-menu-android-build.txt), git diff --check clean.
APK SHA256: 56C4D8DDEEFF76D46C95B445D769359440C122104F594018EC8A23079035F70C.
The release build is served at http://127.0.0.1:5180 using Python bound to loopback.
Refresh the existing tab to load it. Phone motion/FPS and Stage 2 gates remain
pending; browser layout inspection does not certify those gates.

## 8 October 2026 — living home, compact panels and local reward feedback

Resolved Journal reward feedback escaping to the root/main menu messenger.
Each AdventurePanel now contains its own ScaffoldMessenger and transparent
Scaffold. Reward toasts are compact, centered, dark navy with a gold confirmation
badge, teal rim and dismiss control. Closing a dialog removes its toast; it
cannot linger on Home. Home gifts use the same toast above footer navigation.
The regression test confirms messenger isolation, in-panel rendering, reward
persistence and disappearance after the dialog's closing animation completes.

Pause is bounded to 440x290 and Settings to 640x350 rather than taking the full
inventory panel. The main title was removed and replaced by the saved best score
with a trophy badge; foot-level score text is removed. Epoch selection uses the
real painted epoch as a postcard, a contrast overlay, clear title, arrows and six
position markers. Home adds nine inexpensive drifting motes in a separate
repaint layer. Tapping Dino starts a wave on his independent preview clock;
it does not alter the gameplay rig. Existing yawns, glances and accessory layers
remain intact. No simulation, collision or save-schema changes.

Added six shared-slot cosmetics: Fern crown (150), Aviator cap (350), Moon
explorer helmet (450), Lagoon scarf (180), Forest cape (280), Starlight pack
(400). Ownership, purchases and equipment use existing save fields; the new
persistence test buys/equips all six and reloads the correct head/neck/back slots.
The motion evidence outfit now explicitly picks one item per slot rather than
accidentally rendering the entire expanded catalog on top of each other.

Rendered and inspected real Flutter widget fixtures at 568x320 and 1024x600:
Home, compact Pause, scrolled Wardrobe and Journal feedback. New-cosmetics-review
shows all six attachments on Dino's actual rig. These native exports use isolated
mock preferences, labelled as review fixtures in tool/living_menu_review_test.dart
and DESIGN_CONTRACT.md; they are not live player statistics. Evidence:
living-home-phone/desktop.png, living-pause-phone/desktop.png,
living-wardrobe-phone/desktop.png, living-journal-toast-phone.png and
new-cosmetics-review.png. Tests cover 1.3x text/safe areas at four landscape sizes,
last wardrobe/journal rows, compact Pause limits and isolated tap-to-wave.

A separate live release tab at 5180 verified the new phone-sized Home, saved
best 8011/wallet 311/scarf outfit and tap-to-wave with no console errors. No runs,
purchases or claims were performed in that live check. Browser evidence:
living-home-browser.png and living-wave-browser.png. Temporary tab closed and
viewport restored. Refresh the existing game tab to load the new web release.

Validation: 78 full tests passed (living-menu-tests.txt); analysis clean
(living-menu-analyze.txt); isolated export passed (living-menu-export.txt);
toast regression and transactions: 3 passed (living-menu-toast-tests.txt).
Web release and Android debug APK built successfully (living-menu-web-build.txt,
living-menu-android-build.txt); git diff --check clean.
APK SHA256: 56E07F30FA1E54F203068DB4D7947AE520499B01E58016F58C1473C5AC67A8FB.
Phone motion/FPS and Stage 2 gates remain pending.

## 8 October 2026 — painted controls, shared coin and orbital space art

Pause has orange Settings and blue Main menu actions, using the painted gear
and a new illustrated cabin icon. Close controls across panels are red with a
painted white cross. The Home Settings shortcut and Settings panel share orange.
Retained compact sizes, labels and touch targets.

Moved the stamped gold paw coin into utils/coin_art.dart. Wallet, HUD and
spinning single/double pickups draw the same cached picture. Spin, edge depth,
glint, collection and colliders are unchanged. Removed the separate HUD circle
and old pickup face.

Space mode uses cached OrbitalScenery rather than the rocky Cosmos painting:
dark starfield/soft nebula, a shaded ringed gas giant and curved blue planetary
limb. Dynamic stars, comets, launch streaks and launch/return transitions stay.
Steady orbit uses no saveLayer or per-frame gradient creation; alpha layering
only occurs during a partial transition. Cosmos ground-epoch art is separate.
Removed unused older procedural fallback and redundant space image field.

Visual review: real Flutter widget exports at 568x320 and 1024x600 checked Pause
colors/red close. Live isolated browser at 5184 checked launch, full orbit,
coins and return to Desert, then menu return. Evidence: orbital-space-browser.png,
orbital-return-browser.png, living-pause-phone/desktop.png and
orbital-settings-release.png. Native space-review-200/450.png use test fonts and
are diagnostic; browser screenshots show real text. Release 5180 verified orange
Settings/red close and retained best 8011/wallet 388/Explorer hat plus scarf.
The live save was unchanged; only the isolated origin ran flights. Review tabs
closed and viewport restored.

Validation: 78 tests pass (orbit-art-tests.txt), menu export passes
(orbit-menu-export.txt), production space drawing/collision diagnostic passes at
speeds 200/450 (orbit-art-performance-test.txt), analysis clean
(orbit-art-analyze.txt), web release/Android debug builds successful
(orbit-art-web-build.txt, orbit-art-android-build.txt), git diff --check clean.
Diagnostic mean updates: 165/74 microseconds; median raster+readback: 8.25/8.42 ms;
peak pickups 25/26 below 48. These host debug measurements are not phone FPS or
a controlled same-session baseline comparison. Raw: space-performance-orbital-art.json.
APK SHA256: E49DBA47573C3906BFF42C310818384C60127C7D0497CB7BC7EBF70FAD5587E7.
Refresh http://127.0.0.1:5180 for the new release. Phone/Stage 2 gates still pending.

## 2026-10-09 — Painted space, faster startup, epoch hazards and impacts

Generated orbit_painted_v1.png with the built-in imagegen skill and copied it into
assets/images/biomes. The dark center, ringed planet and curved Earth horizon
replace the orbit fallback when loaded; native cached orbital art remains a
fallback. Dynamic stars, pickups and launch/return fades remain.

SceneryCache deduplicates concurrent startup/game decodes and caps scenery at
1280 pixels, disposing codecs immediately. Startup preloads rig and seven
scenes in parallel with actual completion progress; removed the mandatory 2.2s
animation delay and obsolete sprite/key-art loads. Music warms asynchronously.
Replaced neon splash with desert painting, animated Dino, cream/gold typography,
real progress and a retry state. Bounded text content scrolls at oversized text.

Non-desert ground hazards record their epoch painting once per spawned obstacle
and dispose the picture on removal: mossy logs/rocks in Forest and Monsoon,
frosted shards in Ice, cracked basalt in Volcano, alien crystals in Cosmos.
Collision sizes and entrance gating are retained. Fixed COSMOS selection (old
SPACE case fell through to desert cactus) and restricted metal pipe pairs to
Cosmos. Desert cacti and volcanic eruptions retain their original art.

Falling rocks now lock their warning/descent X ahead of Dino until landing,
then scroll with the ground. Landing creates exactly one scorched crater,
cracks, dust and impact shake. The crater is a visual ground scar; the landed
boulder remains jumpable, rather than turning the ground into an invisible pit.
Pause freezes the descent/scroll; group removal removes its crater.

Validation: 81 full tests pass, analysis clean, loading/menu exports pass,
bootstrap checks pass, web release and Android debug build successful. New
tests cover high/normal-speed ahead impact, one crater, scrolling and pause;
compact/desktop startup retry and 1.3x text; concurrent cache identity/resolution.
Production scenery/obstacle captures inspected at 640x360 for all six epochs,
meteor descent and crater. Splash loading/error captures inspected at 568x320
and 1024x600. Live isolated browser at 1280x720 confirmed full painted space
with real HUD text (painted-space-browser.png); release 5180 reaches menu
retaining best 8011, coins 388 and Explorer hat/scarf, without altering the save.

Host debug diagnostic: mean updates 208/95 microseconds and median raster plus
readback 9.21/8.82 ms at speeds 200/450; peak pickups 24/25. Raw evidence:
space-performance-painted.json. These numbers are not phone FPS or a controlled
baseline comparison; Stage 2 device performance/motion gates remain pending.
Logs: painted-space-analyze/tests/menu-export/performance-test/web-build/
android-build/bootstrap-tests.txt. Android SHA256:
9BFF36D64202D69A0D4DA2709AF9DAE724FD289C802FD283932AB5E5AB42E62B.
Final release server restarted at http://127.0.0.1:5180 (session 49435).
Isolated review server stopped; temporary successful review tabs closed.

## 2026-10-09 — Stable animated startup

Browser now declares its mobile viewport before Flutter initializes. Native
fullscreen/orientation setup runs only off web. An immediate HTML painted desert
loader uses a transparent PNG exported from the actual NewDinoSkin renderer,
with gentle bob and traveling gold bar, avoiding the older unrelated app icon.
The HTML loader stays until artwork loading completes (finishDinoBoot platform
handoff), then removes immediately to avoid overlapping title crossfades.
Flutter uses an 850ms content entrance, actual idle rig, real loading progress,
and a painted GameWidget loadingBuilder during world initialization. Reduced
motion disables entrance/bob. No artificial loading minimum was added.

Validation: final analysis clean; two responsive startup/retry/constant-viewport
tests pass; four Node bootstrap and idempotent artwork-handoff tests pass; real
widget exports pass; final web release and Android debug builds successful.
Browser reviewed immediate boot and menu at 568x320 and 1280x720; phone viewport
remained 568x320 and boot DOM disappeared correctly. Best 8011, coins 388 and
Explorer hat/scarf unchanged. Screens: animated-boot-phone-browser.png and
animated-boot-browser.png. Logs: animated-boot-final-analyze/tests/bootstrap-tests/
export/delivery-web-build/delivery-android-build.txt. Android SHA256:
BB2A0513DD1947A08165D626307DE23906283ABF8ACACC8D013F2A7C006DCD99.

## 2026-10-09 — Five-agent design evaluation

At user request, five distinct read-only reviewers evaluated level design, UI,
game modes, character design and overall visual appeal, in two capacity-limited
batches. Consolidated findings and staged acceptance criteria are saved in
FIVE_AGENT_DESIGN_REVIEW.md. No product or player-save changes were made for
this audit. Highest shared priorities: cohesive painted foreground/costumes,
biome-specific gap/prop identity, authored Desert encounters, outfit try-on,
truthful upgrades/run results, persistent discoveries and a ring-based space
objective. Sales lift remains unproven; device motion/FPS gates stay pending.

## 2026-10-09 — Obstacle/cart/workshop phased specification

User requested design phases before step-by-step implementation. Audited existing
small/giant collision branches and documented explicit stumble, smash, terrain,
shield, three-charge cart, duplicate contact and lifecycle rules. Generated a
painted base cart concept via imagegen and copied it to docs/concepts/cart-base-v1.png;
it is reference artwork, not an implemented pickup or production sprite.
OBSTACLE_CART_SHOP_PHASES.md defines Phase 0 design/evidence, Phase 1 contacts,
Phase 2 small/giant reactions, Phase 3 epoch hazards, Phase 4 cart prototype,
Phase 5 Workshop and cosmetic cart skins, Phase 6 integrated Desert verification.
Each stage has playable/test/visual gates. Existing product and saves unchanged.

## 2026-10-09 — Cart roadmap Phase 1: shared hazard contacts

Implemented game/hazard_contact.dart with owner identity, material metadata,
readiness and atomic claim/deactivation of owned child hitboxes. Obstacle,
RollingBall and individual FallingRock implement the contract. Player delegates
solid contact decisions to one resolver, then applies existing damage/shield/
knockout behavior. Collectibles remain independent of damage protection.
Giant now smashes even during recovery immunity; duplicates cannot grant a
second reward or hit. Warning rocks/entrance objects are not claimable. Nested
falling-rock impact effects now use world coordinates rather than child-local
position. Material is frozen at obstacle spawn for the later fragment pass.

Phase 1 intentionally retains current normal-hit obstacle removal, damage art,
shield duration and jump physics. Authored stumble/material smash effects are
Phase 2; cart pickup and shop are not yet implemented. Terrain/lava rescue is
still its existing explicit path rather than a destructible object.

Validation: 17 focused fairness tests pass and 85 full tests pass. Final analysis
clean; real normal/giant scene export passes; web release and Android debug
builds successful; git diff --check clean. New checks cover multi-hitbox identity,
once-only rewards, giant+immunity+shield, recovery/shield preservation, pause,
warning and sibling rocks, fresh-run reset and actual giant collisions at
30/60/120 updates. Existing suite covers jump, pickups, cleanup and space phases.
Evidence: contact-phase1-normal.png, contact-phase1-giant.png (actual production
components, isolated mock wallet, caption values asserted by tests). Browser
release at 1280x720 reaches menu with current best 8011, coins 435 and Explorer
hat/scarf; no purchases/rewards/run actions performed during verification.
Screenshot: contact-phase1-release.png. Final logs: contact-phase1-focused-tests,
final-analyze, tests, visual-export, final-web-build, final-android-build.txt.
Android SHA256: A96240B2288E38EA71044A42441A8E32F6CDF00CC8D637E7FC9E475DA200CDD2.
Local preview restarted on 5180 (session 52750). Physical-device motion/FPS
review remains pending. Next: Phase 2 stumble and material-specific giant smash.


## 2026-10-10 — Phase 2: small/giant reactions

- Preserved the uncommitted checkout and existing saves. Implemented a 360 ms rig-based small-Dino reaction: bracing feet, body compression, head recoil, concerned mouth/brow, raised arms and tail counterbalance. Scarf remains behind the hand; headwear follows the head. Airborne foot tucking and logical jump velocity stay intact.
- Surviving hits emit six short dust particles; cute-death effects now occur only on fatal solid impacts. Shield absorption no longer triggers the hurt expression. Existing heart loss, hit stop and recovery duration retained.
- Giant contact emits stone/wood/ice/crystal/plant/metal/fire-colored fragments and an upward-flapping bird escape, preserving the Phase 1 single-contact reward and collider rules.
- All particle emission paths are capped at 192 live particles. Effects expire on simulation time, freeze with pause and clear on fresh run/menu reset.
- Validation: 89 full tests passed; analyzer clean; release web and debug Android builds succeeded. Added production-contact assertions for jump input during recovery and unchanged airborne velocity; bounded burst/pause/expiry/reset test; motion recovery across 30/60/120 FPS. Existing leg connectivity and scarf gesture regression tests passed.
- Inspected actual rendered ground and airborne progression (8/83/158/233/308/383 ms) plus all material effects in reactions-phase2-poses.png, and the 1280x720 live web build from startup through Play and game-over. Browser screenshot captures game-over, not the brief stumble. This phase does not change menu layouts.
- Limitations: pose strip is static evidence; normal/quarter-speed clip review and real-phone motion/frame-budget measurement are still pending. No device performance certification. Next content phase: Phase 3 themed obstacle artwork, then the three-charge cart in Phase 4.
- Android debug SHA256: B2AC110F36E80073FE1BE13DC35776B7EB51355C95C8B183083A57638A56FD46.


## 2026-10-10 — Phase 3: epoch foreground pass

- Kept the same obstacle dimensions, collider insets, entrance gates, spawn timing and terrain damage rules. Obstacle art is recorded once per instance and disposed on removal; Desert rock now uses that cache too.
- Added rounded Desert fossil boulders, Monsoon ruin stone and waterlogged cut timber, Forest logs with cut-end growth rings, snow-capped Ice stone, cracked Volcanic basalt and Cosmos crystal clusters/flat-topped columns. Added small recorded grain and retained ground contact shadows and upper-left light.
- Non-volcanic gaps now show dusty fissures, flooded channels, root trenches, ice fractures or luminous fractures. Their six visible danger sprouts use the exact existing contact positions/heights/timer. Volcano keeps lava. Removed ambient lava embers from the other five epochs.
- Inspected all six obstacle art boards and gap boards at the actual 640x360 logical gameplay scale. The export uses the production scenery, player and rendering; native test HUD lettering still has Ahem block artifacts and is not menu evidence. Removed obstacles from gap boards after noticing they obscured the hazard edges.
- Added six-epoch terrain/contact regression assertions. 90 full tests passed, analyzer clean, art/crater/cache export test passed. Web/Android delivery builds recorded in epochs-phase3 build logs.
- This is a procedural foreground pass, not final painted asset parity: cactus/flight/pipe art remains established art; richer moving-hazard designs and physical-phone motion/FPS review are still pending. Next playable mechanics phase is the three-smash cart prototype (Phase 4).


## 2026-10-10 — Phase 4: three-smash cart prototype

- Added CartPower with three charges, active/parked/none presentation, 350 ms safe solid-contact dismount and run-local cleanup. Existing player owns both body and front bumper sensors; hazard latch still guarantees one reward/charge per object. Giant > cart > recovery > shield > damage; terrain is handled separately.
- Cart pickups refresh to three rather than stack. Giant/space park the exact remaining charges; restoration waits for ground contact. Ordinary terrain failure uses existing shield/heart rescue and clears the vehicle. Death, reset, menu and revive clear cart state. Dismount grace does not grant terrain immunity.
- Added a shared recorded wooden/teal chassis with red bumper, rotating wheel spokes, side charge lights and HUD pips. Driver rig bends/tucks the feet, raises the body slightly within its unchanged world collider and positions the hand near steering; outfits retain established rendering/layering. Third smash rolls the empty cart back while Dino returns to gait.
- Deterministic lane: cart pickup, four separated rocks, gap and clear exit. Web review URL: http://127.0.0.1:5180/?cart=1, then Play. Native review builds can use --dart-define=CART_REVIEW=true. Normal ground spawning includes the cart after lane tests passed, and SpawnManager accepts an optional random seed. No cart pickups are added to orbit patterns.
- 97 full tests passed, including actual lane at 30/60/120 FPS, single charge/reward across multiple hitboxes, fourth-contact behavior, bumper leading the body, jump responsiveness, pause/reset/death/revive cleanup, terrain failure, duplicate pickup and real giant expiry/full space trip retaining charges. Analyzer clean. Production native art export passed and 640x360 charge/driver/dismount scenes inspected; Ahem test-font blocks are not production HUD text.
- Browser review initially revealed that the query did not select the lane through Uri.base. Changed review routing to read window.location.search via the existing conditional web interop pattern. Delivery build logs: cart-phase4-web-build.txt and cart-phase4-android-build.txt.
- Limitations: this is a procedural playable vehicle prototype, not finished painted cart art or a skin catalog. Suspension polish, normal/quarter-speed clip review and real-phone performance certification remain pending. Next content phase is the Workshop shop/try-on/skin foundation, after reviewing the cart prototype.

- Final browser check: corrected review URL successfully starts the deterministic lane with dressed Dino in the cart, three HUD/body lights, three full hearts and the authored fossil rocks. Inspected the live 1280x720 build as well as 640x360 native art captures. Final release web and debug Android builds succeeded after the routing fix; analyzer clean. Real-device and slow-motion gates remain pending.

## 2026-10-10 — Painted cart and jetpack upgrade

- Replaced the procedural gear presentation with transparent painted assets: a wooden explorer buggy with teal bands, brass hubs and red bumper, and a twin-tank rocket pack. Cart rear/front layers keep Dino seated inside; charge lamps remain tied to actual charges. Corrected transparent-padding crop so tires meet the ground.
- Splash preloads shared decoded images at 384 px cart / 192 px jetpack widths. Pickup and player rendering reuse the same images; no decoding in render. Failed preloads reset their future so Retry can recover. Existing collisions, three-smash rules and flight physics are preserved.
- Validation: 97 full tests passed, final analyzer clean, updated production cart export passed, jetpack space-flight/shared-decode export passed. Release web and debug Android builds succeeded (painted-gear build logs).
- Inspected production gameplay exports at 640x360: cart driver/charges/ground contact and rocket pack in space flight. Native export HUD has test-font Ahem artifacts. Physical-phone frame budgets and normal/quarter-speed motion review remain pending; this is not performance certification.
- Active assets: cart_painted_v1.png and jetpack_painted_v2.png. Earlier jetpack v1 retained as source artwork. The cart-phase4 charge captures now show the painted upgrade. Next roadmap implementation is Phase 5 Workshop try-on, explicit Unlock/Equip and cosmetic cart-skin foundation; that phase is not implemented by this upgrade.

## 2026-10-10 — Phase 5: Workshop and cart finish foundation

- Home Wardrobe destination is now Workshop. Added Dino outfits / Cart skins / Power upgrades tabs with Head / Neck / Back filters, one isolated animated preview and a contextual Unlock/Equip action. Try-on selection never changes shared outfit state or saved equipment; unlocking and equipping are separate. Saved accessory take-off remains available. Equip triggers Dino's short greeting gesture.
- Added stable fossil_rover, lagoon_rover and sunset_rover IDs: painted base and two cosmetic color finishes using the same cached image and anchors. These are finishes, not newly painted vehicle silhouettes. Saved finish is used by player and cart pickup. No collision, charge, speed or jump parameters change.
- Added version 3 cart ownership/equipment fields without replacing existing keys. Unknown/unowned cart IDs cannot equip. Concurrent duplicate purchases subtract only once; existing coins, wardrobe, missions, records and upgrades survive migration/reload. Corrected Star rocket copy to score/pickup rewards, matching its implemented effect rather than advertising extended flight.
- UI shows owned/equipped/saving and exact coin shortfalls, scrollable catalog, local toast and illustrated upgrade icons. Fixed compact 1.3x-text crowding by moving take-off beside the preview and putting insufficient funds in the action label.
- Validation: 99 full tests passed, analyzer clean, production Widget exports passed. Inspected outfit/cart/upgrade renders at 568x320, 640x360 and 1024x600; enlarged-text/control scrolling checks cover 568x320, 640x360, 844x390 and 1024x600. Evidence: workshop-*.png and workshop test/build logs.
- Live browser verification could not connect to localhost (connection refused/timeouts), so browser validation remains incomplete. Real-phone motion/frame-budget and normal/quarter-speed review remain open. The next planned gameplay phase is the authored Desert journey (Phase 6).
- Final release web and debug Android builds succeeded after the equip gesture, upgrade-icon and pickup-finish changes. Logs: workshop-web-build.txt and workshop-android-build.txt.

## 2026-10-10 — Phase 6: authored Desert teaching journey

- Home's Desert Play now starts a bounded 15,000-world-unit route (about 75 simulation seconds at 200 units/sec). Other epoch selections retain random endless spawning. Retry keeps the current journey mode; Home clears it; the cart review URL still takes precedence.
- Authored nearby events only: introductory coin line, two separated rock jumps, coin-guided fissure, giant pickup with three spaced smash objects, a breather, cart pickup with three smash objects, fourth rock requiring a jump, second gap, final cactus jump and safe finish. HUD supplies short instructions and distance progress. No random hazards/powers are mixed into this lesson.
- Short touch testing initially exposed the inherited tall eruption sprouts on the gaps. Added an optional erupts flag, default true for all existing gaps; the two authored teaching fissures use false. Existing terrain damage/jump/rescue behavior remains active and there is no invisible bridge. Tested 120 ms presses/releases and a second tap over gaps; ordinary eruption behavior remains covered by prior tests.
- Added run-local smash count through the existing one-contact knockout path. Results show actual run coins, smashed objects, score/best and existing Journal collection progress, with warm explorer styling. Completed journey offers Retry/Home; failed runs retain Revive. Input hit rectangles match rendered buttons and stay large at compact landscape scale. Completion plays a cheerful cue and title music. Results hide the duplicate gameplay HUD.
- Validation: 101 full tests passed, then 29 final gameplay tests passed after result control refinements; final analyzer clean. Actual production route completed at 30/60/120 updates with three hearts, six single-reward smashes, normal jump controls, parked/reset-safe cart and bounded mounted entities. Pause, retry, exit and non-Desert lifecycle tests passed. Production render/export test passed.
- Inspected gameplay stages at 640x360 and results at 568x320, 640x360 and 1024x600. Corrected a long teaching label spilling outside its background and used explicit Roboto for readable HUD export. Evidence: desert-journey-*.png. Native test exports use Arial under the Roboto alias; live-browser and physical-phone verification remain open. Normal/quarter-speed clips and real-device frame-budget gates are not certified by these screenshots/tests.
- This delivers the authored teaching loop, not the complete later vertical-slice content: moving landmark hazards, bounce plants/treasure pots and richer result celebrations remain future work. The roadmap's broader release gate (real device, motion, cold/cached startup and full manual space/purchase flow) remains open.
- Final release web and debug Android builds succeeded. Also exported actual failed-run results at 640x360/568x320 and verified Revive restores three hearts, keeps route progress and grants no cart. Final production export and analyzer pass. Delivery logs: desert-journey-web-build.txt / desert-journey-android-build.txt.

## 2026-10-10 — cart seat alignment correction

- Shifted Workshop Dino nine art units left to center his torso over the seat. Disabled standing idle gestures in the cart preview so waving/yawning no longer disrupts the driving pose. Tucked the driving tail with a smooth rotation/scale, preserving ordinary Dino tail geometry. Clip seated feet to the chassis in the preview to prevent a yellow foot showing through the wheel gap. Gameplay colliders and saves are unchanged.
- Seven focused preview/joint/gesture/purchase tests passed; analyzer clean; Workshop render export passed and desktop cart placement inspected. Final web build served on localhost 5181 after completion; refresh the existing browser to load it.

## 2026-10-10 — continuous run and cart corrections

- User correction supersedes the finite Desert ending: completing the teaching route now resumes ordinary spawning and speed progression in the same run. Score, earned coins, hearts and powers are preserved; no results screen or forced cart removal at the handoff. Normal failed-run results retain Retry/Home/Revive, including after the tutorial.
- Completely hide the Dino tail while driving (and during seated blend-out). Painted wheel regions now rotate with travel distance in gameplay; Workshop's independent preview clock also drives wheel rotation. Shared skin anchors/colliders remain unchanged. Workshop desktop render inspected with no tail protruding from the seat.
- Validation: 101 full tests passed, analyzer clean, Workshop export passed, final web build succeeded. Actual short-press tutorial plus continued world scrolling/random hazards verified at 30/60/120 updates. The transition test observes hazards while they are present, rather than assuming a particular randomly spawned object remains onscreen at the final frame. Refresh localhost 5181 for the updated build. Device performance and motion review remain pending.

## 2026-10-10 — jetpack back attachment

- Added an optional rear-equipment paint hook between tail and body in the articulated Dino rig. Player's painted jetpack uses that hook in space: tail → jetpack → Dino torso/arms. Pack now shares the rig's body offset and torso bob rather than staying at a detached player-space position. Adjusted its anchor inward and made the pack slightly more compact so its inner edge sits beneath the back silhouette. Generic skin rendering fallback remains intact.
- 31 joint/gesture/gameplay regressions passed; production space-flight asset export passed and rendered placement inspected; analyzer clean. Web delivery log: jetpack-attachment-web-build.txt. Real-device motion review remains open.

## Cart seat and epoch passage variety — 2026-10-10

- Shifted the seated gameplay character 9 logical pixels left to match the Workshop cockpit placement; collision geometry remains unchanged.
- Restored ceiling passages to ordinary spawn pools in every epoch after 150 difficulty progress, and paired passages after 550. Falling pillars remain available.
- Passages now use fossil sandstone, mossy masonry, bark, ice, basalt, and crystal palettes/details with existing opening geometry. Added a falling pillar to the Desert giant lesson and a hanging passage to its later low-clearance segment.
- Validation: all 101 tests pass; Flutter analyzer reports no issues. Production render exports cover all six epochs; Desert and Cosmos inspected for seating and passage materials. Native export HUD font blocks are fixture limitations. Real-phone motion/performance validation remains open.

## Animated controls and menu transitions — 2026-10-10

- Shared Filled/Outlined/Text/Icon button content now depresses and springs back, with hover/focus lift. Painted menu icons flourish on entry and interaction; disabled and reduced-motion controls remain still. Shop selection rows use the same state feedback.
- Panels enter with fade/slide; Workshop/Journal routes also animate on dismissal. Epoch titles crossfade. Canvas pause and results controls have brief arrival flourishes without changing their input geometry.
- Fixed observed 390 px portrait footer/epoch-indicator fit: stacked icon/label on narrow footer controls and constrained indicator scaling.
- Validation: 105 tests pass, including activation exactly once, stable hit rectangles, disabled controls and reduced motion. Analyzer clean. Native 390x844 and 844x390 render exports inspected and export checks passed. Real-device motion/performance remains unverified.
- Browser verification: reloaded the local release build and opened Workshop; inspected Home and Workshop at the browser's approximately 690x668 viewport. Both render with reachable controls and no visible clipping. Native preview exports cover portrait and landscape; automated state tests verify motion targets and activation.

## Tutorial once per player — 2026-10-11

Home now requests the authored Desert introduction only when `dino_tutorial_seen` is false. Starting the introduction immediately marks it seen in memory and saves it, so death/Retry and later Home runs do not restart it. Existing profiles with a saved high score skip onboarding when migrating. Explicit authored-route requests remain available to internal review tooling. Wallet, score and other progress keys are preserved. Regression checks cover fresh profiles, reload persistence, old-profile migration and tutorial Retry returning to ordinary play.
- Validation: all 107 tests pass; Flutter analyzer clean. Local server responds successfully at port 5181.

## Desert interaction increment — 2026-10-11

Added friendly bounce plants and breakable clay treasure pots to ordinary Desert spawn slots. Existing spacing, other epoch pools and authored onboarding remain unchanged. Plants animate compression/rebound and launch Dino automatically while preserving one air jump; release of an old tap does not shorten the launch. Pots break once for eight gameplay coins, update collection missions, persist rewards and reuse smash/coin effects. Neither friendly prop damages Dino or spends cart charges. Props clear through existing ground cleanup and freeze outside normal play.

Validation: 113 full tests pass, including actual collision dispatch at 30/60/120 for plants, normal/cart/giant pot contacts, one-use rewards, persistence and pause/reset. Production 640x360 art export inspected: plant arrows, leaves, clay vessel, coin emblem and ground shadows read against Desert scenery. Native HUD font blocks are fixture limitations. Props use procedural artwork and existing jump/coin sounds; dedicated painted assets, phone motion/performance checks and richer authored interaction sequences remain future work.

## User-directed removal and tactile menu revision — 2026-10-11

Removed the bounce plant / treasure pot component, spawn branch, automatic bounce method and their dedicated tests/export, as requested. The earlier friendly-props increment is superseded; ordinary Desert hazards and existing save data remain.

Researched mobile game control guidance (https://developer.apple.com/design/human-interface-guidelines/game-controls). Replaced flat button faces with raised toy-like faces, dark lower edges, inset rims, shallow edge grain and brass studs. Illustrated action icons sit in cream medallions; Home Play is green and visually primary. The same face treatment applies to menu/panel actions and tools; state feedback, accessible labels and reduced-motion behavior remain.

Validation: all 107 tests pass; analyzer clean; portrait 390x844 and landscape 844x390 exports inspected, with no control/text overflow. Enlarged-text tests cover short landscape and desktop. Real-device feel/performance is still pending.

## Workshop typography and clarity — 2026-10-11

Applied Impeccable typography and simplification guidance. Bundled licensed Fredoka and Nunito locally; playful display type now covers panel titles, item names and actions while descriptions use readable body type. Both upgrade entry points share a compact list with illustrated powers, five level markers, concise effects and price buttons. Short Outfits / Carts / Powers tabs fit portrait screens. Affordability, saving, maximum level, purchase persistence and accessible touch targets remain supported.

Validation: 107 tests pass; native production-widget exports at 390x844 and 844x390 inspected, including outfits and power upgrades. Portrait tabs fit and all four upgrade rows are visible; landscape lists scroll. Real phone performance remains unverified.
Final checks: analyzer clean; release web build succeeded. Local server restarted on 127.0.0.1:5181 and returned HTTP 200. Automated browser refresh was blocked by the browser tool after its connection-error page; visual verification above uses production widget exports.

## Workshop swipeable cosmetics — 2026-10-11

Removed Powers from Workshop; the standalone Upgrades entry remains. Outfits and Carts use horizontal pages of up to four items in a two-by-two grid, with explicit previous/next controls and page count. Head / Neck / Back now have contrasting selected buttons and selected semantics. Item cards show artwork, name, ownership/price and selected checkmark. Try-on, unlock, equip and take-off behavior is preserved. Short screens and enlarged text can scroll the catalog area vertically.

Validation: 107 tests pass, including paging to Moon explorer, category reset and purchase persistence; analyzer clean. Production renders inspected at 390x844, 844x390 and 690x668. Four cards fit portrait and desktop; short landscape supports vertical scrolling. Real-device testing remains pending.
Release web build succeeded for this revision.
