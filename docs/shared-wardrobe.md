# New Dino and shared wardrobe

New Dino (`new_dino`) is a free additional character. Original Dino and existing skin IDs remain unchanged. Loading old saves grants New Dino without changing the equipped character or balance.

The wardrobe owns cosmetic IDs independently of characters. One item can be equipped per `CosmeticSlot` (head, neck, back). Purchases, equipment and removal save immediately. Unknown catalog IDs and unowned equipment are rejected. A free red scarf and purchasable explorer hat, winter beanie and backpack demonstrate the system.

All menu, shop and player draws use `CharacterSkin.renderCharacter`. This draws back accessories, the character, then head/neck accessories. Each character can override `CosmeticFit` with normalized anchor coordinates and scale. Add new characters to `SkinRegistry` and calibrate these anchors; no duplicate accessory art or ownership is required. The original Rive Dino and New Dino have explicit fits. Legacy costumes inherit a generic fit and retain any built-in costume artwork; those baked accessories cannot be removed through the new slots. Complex future rigs should override pose handling/attachment fitting to follow their bones precisely.

New Dino now uses an articulated painted cutout rig with continuous run/jump/landing motion; see `new-dino-motion.md`. Collision bounds and movement remain unchanged. Accessories currently use lightweight vector artwork and follow the rig's head/torso motion.

## Art provenance

Built-in image generation tool. Output: `assets/images/new_dino.png` (RGBA). Reference: `docs/dino-cosmetics-concept.png`.

Prompt: Create ONE clean production character sprite on a genuinely transparent alpha background. Match the big base yellow dino in the reference exactly in personality and painterly quality: round giant head, cocoa eye glint, orange cheek blush, tiny single tooth friendly smile, cream belly, amber back plates, curved tail, chunky feet. Facing right in a near side view, standing balanced with feet separated, arms down, full body visible. Remove ALL accessories: no scarf, no hat, no backpack, no helmet, no clothing. Accessories will be rendered separately by game code. Single character ONLY, no text, no logo, no floor or cast shadow, no sheet, no duplicate poses. Fit entire character including tail in canvas with 4 percent transparent margin. Portrait 4:5 composition. Detailed soft painted shading but crisp alpha silhouette; expressive adorable premium game mascot. This is the neutral base for runtime animation and interchangeable cosmetics.

## Verification

`flutter test --no-pub test/shared_wardrobe_test.dart`: save migration, shared ownership across characters, no duplicate charge, persistence, independent slot replacement/removal, invalid/unowned item rejection and insufficient balance.

The wardrobe suite plus existing ground/obstacle and collision suites passed (17 tests). Analysis of changed runtime areas has no errors; existing unused menu helpers and Rive deprecation notices remain. Release web build succeeds. Browser inspection confirmed New Dino selection, accessory purchase/equip, shared shop previews and the New Dino main-menu preview.
