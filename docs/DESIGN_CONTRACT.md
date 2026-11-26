# Menu design contract

Dino Run Epochs serves casual mobile players, including children, in landscape. Home's primary action is Play; epoch selection and personalization remain secondary.

Retain the animated Dino, painted epoch scenery, concise labels and existing Roboto typography. Use a cohesive illustrated adventure style: gold Play/coins, coral Wardrobe, violet Upgrades, blue Journal, teal Settings. Rounded asymmetric buttons have gentle gradients, a raised lower edge and painted object icons. Panels share the same shapes, with section-colored headers and quiet readable interiors.

Keep the current compact layout, scrollable inventories, real wallet/progression data and save semantics. Touch targets remain at least 48 logical pixels. At 568x320 through desktop landscape, labels, arrows, footer actions and close controls must fit, including 1.3x text and safe areas. Disabled purchases stay visibly disabled; existing purchase, equip, claim and settings behavior must pass tests.

Acceptance: inspect rendered Home, Wardrobe, Upgrades, Journal and Settings at phone and desktop widths; verify readable text, clear Play hierarchy, no clipping/overlap, working navigation and preserved transaction tests. Build and analysis success alone do not prove visual quality. Phone performance verification remains a separate roadmap gate.

## Home and feedback refinement

Replace the title with the player's best score in the top bar; keep score text
away from Dino's feet. Epoch selection is an illustrated postcard with real
stage scenery, readable overlaid title, arrows and six position markers. Add
only nine low-cost drifting motes and a tap-to-wave response on Dino's independent
preview rig. Retain existing idle gestures and opaque scenery transitions.
Pause is bounded to 440x290 logical pixels; Settings to 640x350. Rewards use a
compact dark toast with gold confirmation badge, teal rim, dismiss button and
screen-reader feedback. Panel toasts belong to a nested messenger and disappear
with their dialog. Home gift feedback stays above navigation.

Six new accessories extend the existing catalog/save slots: Fern crown, Aviator
cap, Moon explorer helmet, Lagoon scarf, Forest cape and Starlight pack. No new
character, physics modifiers or save migration. Acceptance adds persisted
purchase/equip checks for new items, panel-local toast and close behavior,
compact Pause at 1.3x text, last inventory row visibility and isolated tap-to-wave.
Review fixture PNGs are generated using mock preferences and are not real player
statistics. Live browser screenshots are separately named living-home-browser.

## Artwork consistency and orbit

Use semantic action colors requested by the player: orange Settings, blue Main
menu, red close. Extend painted icons with a warm cabin icon. Coin art is one
cached stamped face across wallet, HUD and pickups. Space should read as orbit:
dark starfield, distant ringed planet, curved blue horizon, no rocky floor.
Cache static painting and retain launch/return fades. Phone FPS verification
remains separate from host diagnostic timings.

## Painted space, startup and impacts

Players on landscape phones should reach Play quickly and read threats clearly.
Startup uses the same sunny Dino and painted desert as the menu, cream Roboto
title, gold real-progress bar and a bounded horizontal composition. No minimum
loading delay; fatal rig failures show Retry. Optional scenery has native fallbacks.
Space uses a generated dark painting with planets and an open center; dynamic
stars and launch/return fades remain. Ground obstacles inherit the epoch at spawn
and preserve their existing collision bounds. A warned falling rock locks its
impact point ahead of Dino, leaves a scorched crater and becomes a scrolling
jumpable rock. Acceptance: compact and desktop loading/error layouts, all six
hazard palettes, ahead-of-Dino landing at 200/450, pause, and one crater per impact.

## Stable animated boot
Immediate browser-painted desert loader; explicit viewport before Flutter boot.
No fullscreen/orientation calls on web. Native and browser loading share cream
title/gold progress, animated Dino, compact horizontal composition and real
loading state. Entrance translates content only, never scales the viewport.
Honor reduced motion and retain accessible Retry. Inspect compact/desktop boot
and final menu; loading may finish without an artificial delay.

## Obstacle, impact, cart and workshop design

Next increments are specified in OBSTACLE_CART_SHOP_PHASES.md. Preserve one Dino
and current saves. Level hazards have distinct painted materials and matching
impact fragments. Small-Dino stumble, giant smash and three-charge cart share
one contact resolver. Workshop previews full outfits/cart skins without saving
until an explicit Unlock/Equip action. Compact split preview/catalog layout,
current semantic colors and Roboto; accessible scroll and local feedback.
Cart skins alter appearance only, never collider/charges/jump/speed. Validate
one phase at a time with the behavior matrix and real motion evidence.

## Painted gear acceptance

For mobile runner players, power gear must read clearly at gameplay size and match the warm painted Dino. Use a chunky wood/teal/brass buggy with a red bumper and a compact teal/ivory rocket pack. Preserve readable face, connected seated pose, ground contact and visible three-charge lamps. Cache startup decodes and reuse artwork for pickups. Gear art must not change colliders or power behavior. Inspect production 640x360 poses and flight; retain existing UI typography and density.

## 2026-10-10 — Workshop implementation contract

The Workshop serves mobile players selecting a look for their Dino or temporary cart. Primary flow is Try on → Unlock → Equip. Keep warm epoch scenery, coral header, cream catalog, illustrated item icons, Roboto and a compact 40/60 preview/catalog split. Use 44 px category/filter controls, 48 px contextual actions and independent catalog scrolling. Desktop expands the preview/catalog without stretching action height.

Selection changes only the preview instance. Ownership, wallet and saved equipment change only through explicit actions; unlocking does not auto-equip. Closing discards pending previews. The three cart catalog entries are the painted base plus Lagoon and Sunset color finishes, not new vehicle silhouettes. All share identical geometry, charges and physics. Show ownership, equipped, saving and exact coin shortfall states; feedback belongs to the panel. Cart pickup explanation remains visible. Preserve existing save keys and add version 3 cart ownership/equipment fields.

Acceptance: compact/desktop rendered categories, 1.3x text and reachable final items, preview isolation, concurrent duplicate purchase charge once, reload persistence and old progress retention. Browser and real-device performance remain separate evidence requirements.

## Authored Desert journey contract

Players learning the tap runner should understand the next action without stopping play. Home's Desert Play launches a 75-second authored route; retain all other epoch modes. Use spaced solids, coin arcs, a clear giant pickup beat, then cart pickup / three smash objects / fourth jump / terrain jump / safe exit. Keep current controls and colliders, fixed teaching pace and existing painted scenery. A small HUD instruction/progress marker stays above the lane. Results use warm cream, teal/gold/red semantic actions and compact Roboto, report actual run coins and smashed objects, and offer explicit Retry/Home plus existing revival on failed runs. Validate route/lifecycle at 30/60/120 updates, render gameplay/results, preserve wallet rewards and clear/reset route state.

## Control motion — 2026-10-10

Mobile runner controls retain painted art, existing colors and labels. Primary action remains Play. Use 150 ms content depression/spring-back, small hover/focus lift, brief painted-icon flourishes on arrival and interaction, 240 ms panel fade/slide and epoch-title crossfade. Keep hit rectangles fixed, disabled controls still, and respect platform reduced motion. No perpetual button tickers across shop lists. Narrow footer buttons stack icon and label; epoch indicators must fit the available width. Verify activation once, keyboard focus, disabled/reduced motion and portrait/landscape rendered layouts.

## Desert friendly interactions — 2026-10-11

For tap-runner players, warm clay treasure pots and yellow-capped spring plants make normal Desert runs playful. Plants automatically bounce grounded/descending Dino and leave one air jump; no new input required. Pots break on touch for eight gameplay coins once, without heart damage or cart-charge use. Keep introductory route unchanged. Register props with existing spawn spacing/reset lifecycle; paused/space states stop interaction. Inspect actual 640x360 art and verify real collision dispatch at 30/60/120, power coexistence, reward persistence and reset. These are procedural painted-volume prototypes; bespoke assets and bespoke sounds are later polish.

## Tactile explorer controls — 2026-10-11

Audience: mobile runner players choosing their next run or personalizing Dino. Primary action: Play, with a prominent green raised surface and warm painted play badge. Retain scenery, Dino, compact Roboto and real scores/wallet. Secondary actions use sculpted colorful toy surfaces, inset rims, edge grain/studs and cream icon medallions. Preserve 48px controls, labels, press/focus motion and reduced motion. Compact layouts stack icon/label. Acceptance: controls look like game objects, Play leads hierarchy, all destinations work, no overflow at portrait/short landscape or 1.3x text. Research: Apple game-controls guidance on tactile press feedback and readable controls.

## Workshop clarity and playful type — 2026-10-11

Apply Impeccable typeset/distill within the painted explorer identity. Bundle licensed Fredoka for headings, action labels and item names; Nunito for readable body copy. Share one upgrade list between Home Upgrades and Workshop Powers. Use separated rows with icon, name/effect, five discrete level markers plus numeric/semantic level, and one price action. Remove oversized repeated cards and left accent borders from upgrade layout. Preserve actual upgrade formulas, costs, max-level, shortfall and saving states. Allow larger text/narrow widths to move price action beneath content; keep48px targets and reachable last item. Validate real bundled fonts in portrait/landscape renders plus upgrade activation/persistence and existing menu tests.
`nWorkshop browsing revision: cosmetics shoppers should choose Outfits or Carts, then a clearly highlighted Head / Neck / Back filter. Preserve the live try-on and one purchase/equip action. Use horizontally swipeable two-by-two item pages with page count and explicit arrows; Powers remains in its separate Upgrades panel. Fredoka headings and Nunito detail text retain the painted adventure identity. Verify portrait/landscape fit, category changes, paging and saved purchases.

## 2026-10-12 — Living trailhead refinement
Audience: children and adults choosing a run, trying an outfit or adjusting comfort. Home's job is to reveal the selected epoch and make Play unmistakable. Two directions compared: an expedition atlas (map-led, smaller character, editorial page navigation) and a living trailhead (world-led, character companion, destination beside Play). Chosen: living trailhead. It preserves the established scenery and expressive dinosaur, asks less reading of children, and keeps adult tools immediately findable. The atlas would obscure the game's strongest assets and add navigation.

Retain painted environment/character/object art, Fredoka headings/actions and Nunito explanations. Spacious character/destination split in landscape, vertical composition in portrait fallback; labeled Gift and Settings, real Best/wallet, a larger green Play, and three secondary destinations. Epoch descriptions name actual environment content without invented records. Panels use warm field-note surfaces, visible Back, shared painted objects and contextual action states. No new art family, currency, achievements or save migration.

Motion: fixed hit areas, 150ms press response, 220–260ms fade/short travel, quiet owned Dino idle and explicit hello/equip reaction. Main Play dispatches immediately once; its departing overlay absorbs game input until removed. Modal routes own keyboard/back and serialize opens. Platform reduced motion and saved Reduced motion preference freeze decorative preview/atmosphere and remove transition travel. Running/jumps stay unchanged. Sound uses existing tracks and optional haptics obey preferences.

Acceptance: rendered Home and Settings first, then Workshop/Upgrades/Journal/Pause/results at 568x320,844x390,1024x600 and portrait fallback; 1.3 text with simulated safe areas. Bounded-pump tests for rapid taps, modal keyboard isolation, persistence, reduced motion and lifecycle; production browser gameplay, restart and menu return. Capture layout PNGs and motion clips, inspect and recapture highest-impact defects. No physical-phone performance claims without a connected target.
