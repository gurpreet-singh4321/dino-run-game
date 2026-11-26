# Dino Run Epochs — obstacle, impact, cart and shop phases

9 October 2026. Implementation specification based on the current checkout and the five-agent review. This document defines the next bounded increments; the cart and shop changes are not implemented yet.

## Player promise

Small Dino bumps, stumbles and recovers. Giant Dino powers through solid obstacles. A cheerful explorer cart lets normal Dino smash three objects before it runs out of protection. Each epoch has recognizable materials and hazards, and the shop makes the actual dressed Dino/cart desirable to preview.

Keep one Dino, the current tap/double-jump controls, landscape runner, Flame simulation, heart system and saved ownership. The cart is a temporary pickup; buying a cart skin does not grant permanent protection. Its base appearance is usable without a cosmetic purchase.

## Rules to implement

| Contact/state | Outcome |
|---|---|
| Pickup in any supported ground state | Collect exactly once, independent of damage recovery. |
| Normal Dino, solid hazard | One heart lost, short visible stumble, then existing recovery protection. Surviving impact is not a death animation. |
| Normal Dino with shield | Shield absorbs hit, no heart lost; shield reaction and mission event remain correct. |
| Giant Dino, solid hazard | Object breaks/scatters exactly once; no heart or cart charge lost. |
| Cart, solid hazard, charges remaining | Smash object once, lose exactly one charge, no heart lost. |
| Cart third smash | Third object is still destroyed safely; Dino exits automatically; brief safe dismount protection prevents the same contact immediately damaging him. |
| Normal recovery protection | No additional damage from repeated overlap. Do not disable collectible handling. |
| Gap or lava | Terrain is not an object to smash. Preserve existing jump/rescue/giant-lava rules; no invisible bridge created by the cart. Cart terrain failures use the ordinary shield/heart rescue and clear the vehicle safely. |

"Smash everything" means all solid object hazards: cactus, rock, log, crystal, pillar, rolling boulder, individual falling rock and solid pipe. Plants scatter; birds flap away rather than producing violent fragments. Gaps remain navigational threats. Volcanic eruptions remain environmental hazards, preserving current giant protection/rescue behavior.

### Combination and lifecycle rules

- One canonical collision resolver decides outcome. Do not copy separate giant/cart/shield branches across obstacle classes.
- Resolve contact through the owning hazard ID, not every overlapping child hitbox. Claim destruction/contact before asynchronous removal. Reward once per object.
- Priority: collectible → giant solid smash → active cart solid smash → recovery protection → shield → normal damage/stumble. Environmental handling remains explicit. Preserve current shield+recovery behavior unless a focused test justifies changing it.
- Giant pickup temporarily parks/hides the cart, retaining its charges; giant impacts do not spend them. Restore the cart on giant expiry when grounded and safe.
- Space launch parks the cart with its remaining charges; restore after safe return. Cart pickups spawn on the ground, never during orbit.
- Shield/magnet can coexist with a cart. Cart handles solid hits first, leaving shield for later; magnet continues collecting coins.
- A duplicate cart pickup refreshes to three charges, never stacks above three or adds a second vehicle.
- Pause freezes all power, stumble, vehicle and debris timers. Death, retry, exit-to-menu and fresh run clear active cart/parked cart and impact state. Revival starts in normal form.
- Jump input remains responsive during a survivable stumble. Use the existing jump trajectory for the first cart prototype; avoid changing acceleration, touch controls and physics at the same time.
- Initial smash reward stays aligned with the existing giant knockout reward, awarded once. Tune rewards after actual run earnings are observed.

## Cart art and skin contract

Base concept: a compact honey-gold wooden explorer buggy, teal metal reinforcement, red rounded front bumper, dark rubber wheels and amber hubs. A low open seat leaves Dino's face visible. Three amber side lights mirror the three HUD charge pips. Facing right, with clear front bumper and two near-side wheels; no roof, weapons, spikes or busy exhaust.

The concept image is in `docs/concepts/cart-base-v1.png`. It is design reference, not a finished game sprite or implemented mechanic. The production sprite must be approved with Dino seated at phone size before adoption.

Use a 160×100 cart art space initially; fit it around the current Dino art rather than scaling the entire player or stretching his legs. Dino sits with bent knees, hands at the steering anchor and tail behind the seat. Collider/world dimensions are established from the prototype, not copied from concept-image pixels.

Split render parts: rear wheel/body → seated Dino/rear accessories → front body/bumper → front wheel/highlights. Define seat, hands/steering, tail clearance, front bumper and axle anchors. Wheel rotation follows traveled ground distance; suspension springs settle after landings and impacts. Wheelbase, seat and bumper anchors remain invariant for all skins.

Cart skins may change body material/color, wheel hub covers, bumper finish and badge/flag. They may not change collision bounds, charges, jump reach, speed or rewards. Starting skin ideas: Fossil Rover, Jungle Scout, Glacier Buggy and Star Scout; these are future designs, not catalog items to sell before their artwork is ready.

Cached sprites/pictures render static cart parts; animate transforms, wheels and three lights. Bound impact debris and avoid per-frame image decoding, blur layers or cloth simulation.

## Phase 0 — design lock and evidence scene

Deliver the behavior matrix, base cart concept, visual hierarchy and a review scene containing normal/giant/cart beside one hazard. Audit existing giant behavior first: it already destroys Obstacle, FallingRock and RollingBall, but uses generic break effects and checks recovery protection before giant logic. Normal damage already exists; it lacks a clearly authored stumble and currently removes the touched hazard.

Gate: concept reads as a drivable toy, Dino face remains visible, and the three-charge promise is clear. Capture normal, giant and seated cart at 568×320 and 1024×600. Label unfinished art/mechanics as prototypes.

## Phase 1 — reliable contact decisions

Introduce a hazard contact contract (identity, material, shape, destruction state) and centralized outcomes such as ignored, shielded, stumble and smashed. Route current obstacle, rolling and individual falling contacts through it before adding the cart.

Gate: focused tests for one damage/reward per contact, multiple hitboxes, adjacent hazards, giant during recovery, shield/recovery, collectible+hazard together, offscreen cleanup, pause, reset and space transitions. Preserve saves and current jump/coyote/buffer behavior. Test simulation at 30/60/120 updates.

Playable deliverable: same game with trustworthy existing small/giant rules, no new pickup yet.

## Phase 2 — stumble and satisfying giant smash

Create a 250–400 ms survivable stumble performance: torso recoil, planted/shuffling feet on ground (airborne hits retain the jump trajectory), concerned face, tail balance, attached outfit follow-through and damped return to gait. No input lock or logical hurtbox teleport. Keep the current recovery duration until testing supports a change. Use a separate harmless impact dust/spark effect instead of cute-death particles on every survivable hit.

Giant impacts use material-specific fragments: stone chips, wood pieces, frost shards, crystalline sparks, leaves. Mark colliders inactive immediately, play a short bounded effect, then remove the object. Cache shape variants, cap debris, and preserve the existing giant duration and physics.

Gate: normal hit loses exactly one heart; giant smash loses none; joint/scarf tests pass; normal and quarter-speed clips show no detached feet/accessories; collisions remain aligned; short effects never hide the next hazard. Device performance/motion review required before broad content expansion.

## Phase 3 — make the epochs recognizable

Polish and differentiate foreground families using existing mechanics first:

| Epoch | Prop family | Ground gap | Smash material |
|---|---|---|---|
| Desert | Rounded cactus, fossil boulder, cracked sandstone | Dusty fissure | Stone chips/plant pieces |
| Monsoon | Waterlogged timber, mossy ruined stone | Flooded channel | Wet wood/small splashes |
| Forest | Fallen log, roots, hollow stump | Root trench | Bark/leaves |
| Ice | Snow-covered boulder, clustered ice shard | Frosted crevasse | Frost shards |
| Volcano | Fractured basalt, solid vent rim | Lava | Basalt chips/embers |
| Cosmos | Alien crystal cluster, ancient space column | Luminous fracture | Crystal sparks |

Start with Desert's rock/cactus and Forest's log as the approved quality reference. Give each family at least three silhouettes over time; do not recolor one polygon and call it a new world. Keep upper-left light, painted texture, readable contact shadow, quiet ground lane and existing collider insets. Replace generic lava gap visuals outside Volcano while retaining gap physics. Teach moving hazards with visible warnings and safe landing zones.

Gate: art boards for all six themes at actual game scale; no obstacle blends into its background; visible danger matches collision; material matches impact fragments. Verify falling-rock crater remains compatible with destruction/cleanup.

## Phase 4 — three-smash cart prototype

Add cart pickup type, CartPowerState (active/parked/none, charges), seated Dino state, bumper sensor and HUD three pips. Keep a single owned player/collision system; do not add a second independently damaging character. Reset charges to three on pickup. The third smash launches a short safe dismount animation and restores normal running automatically.

Build a deterministic test lane: pickup → three well-spaced solids → fourth solid → gap → safe exit. This makes every rule inspectable without depending on random spawn rolls. Add ordinary seeded ground spawning only after that lane works.

Gate: first three impacts smash without heart loss; fourth follows normal damage rules after dismount grace; two hitboxes from one obstacle spend one pip; two distinct objects count separately even in one update; giant/space parking restores exact charges; shield is preserved on cart smash; pickups work during recovery; jump and pause work; all death/retry/menu/revive paths clear the state. Verify normal/quarter-speed motion, 30/60/120 simulation and device frame budget.

## Phase 5 — workshop shop redesign

Audience: mobile players choosing a desirable cosmetic for the same Dino or cart. Primary actions: Try on → Unlock with earned coins / Equip. Visual direction: illustrated explorer workshop, current semantic action colors, warm cream surfaces, painted icons and materials; Roboto with compact readable type. Keep the scenery, one strong preview, wallet and explicit action hierarchy. Do not create another unrelated UI theme.

- Keep access from Home, changing the Wardrobe destination to a broader Workshop when the cart category exists.
- Tabs: Dino outfits / Cart skins / Power upgrades. Inside Dino outfits: Head / Neck / Back filters. Cart skins show complete assembled cart with seated Dino.
- Phone landscape: compact header, roughly 40% preview / 60% catalog; accessible scrolling; one contextual footer action. Desktop expands the inventory area without making buttons enormous.
- Tap an item to preview temporarily. Show item name, actual ownership/price and Buy/Equip/Equipped state. Leaving preview restores saved equipment; only explicit purchase/equip writes the save.
- Explain the cart pickup separately from its skins: “Smashes 3 objects. Skins change appearance.” No purchasable stat advantage in this phase.
- Purchase uses existing coins and persistence; preserve all current cosmetic IDs, upgrades, claimed missions and equipped outfit. Add stable cart skin IDs and an additive versioned save field. Never reset current saves.
- One short proud equip reaction and a local bottom toast; errors, insufficient coins, disabled, owned and loading states use the same theme. Show the actual coin shortfall.
- Correct existing Star rocket copy to its implemented effect before advertising any new upgrade benefits.

Gate: preview isolation, single purchase charge, equipment persistence after reload, cancel restoration, last item reachable, 44–48px touch targets, 1.3x text, 568×320/640×360/1024×600, readable disabled states, panel-local toast and keyboard navigation. Cart skin appearance never changes gameplay parameters.

## Phase 6 — integrated Desert journey and release check

Create one authored 60–90 second Desert sequence that teaches normal jump/stumble, offers a safe giant smash beat, then introduces the cart's three charges. Coin routes indicate safe arcs and landing space; avoid stacking unrelated powers during the first lesson. Results show run coins, smashed objects and actual selected-goal progress, with clear Retry/Home actions.

Gate: play through cold/cached startup, normal run, giant, cart, third smash/dismount, terrain failure, space park/return, pause/settings, death/retry, purchases and reload. Inspect real mobile device motion and measure performance; browser screenshots and desktop debug timings are not device certification. Run full project checks, export visual/motion evidence, build web/Android, update progress and preserve existing saves.

## Delivery rhythm

Implement one phase at a time. Each phase ends with a playable build, focused meaningful tests, phone/desktop visual or motion evidence, a short findings/limitations note and an updated progress log. Do not ship the whole cart/shop/obstacle rewrite as one unverified change. If a gate fails, fix that phase before expanding its content.

Phase 1 contact contract is implemented and verified (85 full tests; see UPGRADE_PROGRESS.md). Phase 2's small/giant reactions are implemented with deterministic pose and interaction checks (89 tests). Real-phone motion/FPS and normal/quarter-speed clip review remain open; the next content phase is Phase 3's themed obstacle artwork. Phase 0's base cart image should be reviewed as reference, not treated as production-ready art.


Phase 3 foreground pass implemented: six themed obstacle/gap boards exported and inspected; 90 regression tests passed. Contact/spawn rules preserved. Procedural art remains below the painted-background fidelity; moving-hazard artwork and physical-device gates remain open. Next implementation phase: Phase 4 three-charge cart prototype.


Phase 4 cart prototype implemented with 97 passing regression tests and production driver/charge/dismount renders. Review lane: /?cart=1 then Play. Native review: --dart-define=CART_REVIEW=true. Vehicle motion/suspension and physical-device gates remain open; current cart art is a procedural prototype. Next planned content phase: Phase 5 Workshop/try-on/cart skin foundation.

Phase 5 Workshop foundation implemented: isolated try-on, explicit Unlock/Equip, three cosmetic cart finishes, version 3 additive save fields and corrected Star rocket copy. 99 tests pass; analyzer clean; web/Android builds succeeded. Native rendered layouts and enlarged text pass; live-browser connection and physical-device gates remain open. Next planned implementation: Phase 6 authored Desert journey.

Phase 6 authored Desert teaching loop implemented: about 75 seconds, short-press rock jumps, two quiet navigational gaps, three giant smashes, three cart smashes and safe finish. Other epochs keep endless spawning. Actual route passes at 30/60/120 updates; 101 full tests and final focused gameplay checks pass. Rendered gameplay/results reviewed. Broader manual/browser/real-device release checks and normal/quarter-speed motion gates remain open; this is not a release certification.

User correction: the authored Desert route now teaches the opening and hands off to ordinary endless play; it no longer ends the run. Tail is hidden in the cart and painted wheels rotate. Prior finite-completion notes/screenshots are historical. Current full suite: 101 passing tests; final web build succeeds.
