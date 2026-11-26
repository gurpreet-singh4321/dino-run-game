import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/skin_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<DinoGame> game(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'dino_coins': 2000});
    final wallet = CoinManager();
    await wallet.load();
    await tester.runAsync(NewDinoSkin.preload);
    SkinRegistry.setCosmetics([]);
    return DinoGame(coinManager: wallet)
      ..player = (Player()..skin = NewDinoSkin())
      ..biomeManager = BiomeManager();
  }

  Widget app(Widget body) => MaterialApp(
    theme: AdventureTheme.data,
    home: Scaffold(body: body),
  );
  testWidgets(
    'Try-on never edits saved outfit and cart unlock requires Equip',
    (tester) async {
      final run = await game(tester);
      await run.coinManager.equipCosmetic('red_scarf');
      SkinRegistry.setCosmetics(run.coinManager.equippedCosmetics.values);
      await tester.pumpWidget(app(AdventureWardrobe(game: run)));
      await tester.tap(find.text('Winter beanie'));
      await tester.pump();
      expect(run.coinManager.equippedCosmetics, {
        CosmeticSlot.neck: 'red_scarf',
      });
      expect(SkinRegistry.defaultSkin.cosmetics.single.id, 'red_scarf');
      expect(run.coinManager.coins, 2000);
      await tester.tap(find.text('Carts'));
      await tester.pump();
      await tester.tap(find.text('Lagoon finish'));
      await tester.pump();
      expect(run.coinManager.equippedCartSkin, 'fossil_rover');
      await tester.tap(find.text('Unlock · 350 coins'));
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.coins, 1650);
      expect(run.coinManager.equippedCartSkin, 'fossil_rover');
      await tester.tap(find.text('Equip'));
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.equippedCartSkin, 'lagoon_rover');
      await tester.tap(find.text('Sunset finish'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      final restored = CoinManager();
      await restored.load();
      expect(restored.equippedCartSkin, 'lagoon_rover');
      expect(restored.coins, 1650);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Wardrobe purchase, equip and take-off persist through the actual controls',
    (tester) async {
      final run = await game(tester);
      await tester.pumpWidget(app(AdventureWardrobe(game: run)));
      expect(find.text('Powers'), findsNothing);
      await tester.tap(find.byTooltip('Next items'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Moon explorer').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Neck'));
      await tester.pump();
      expect(find.text('Red scarf'), findsWidgets);
      await tester.tap(find.text('Head'));
      await tester.pump();
      await tester.tap(find.text('Unlock · 250 coins'));
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.coins, 1750);
      expect(run.coinManager.equippedCosmetics[CosmeticSlot.head], isNull);
      await tester.tap(find.text('Equip'));
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(
        run.coinManager.equippedCosmetics[CosmeticSlot.head],
        'explorer_hat',
      );
      expect(find.text('Equipped'), findsOneWidget);
      final restored = CoinManager();
      await restored.load();
      expect(restored.ownsCosmetic('explorer_hat'), isTrue);
      expect(restored.equippedCosmetics[CosmeticSlot.head], 'explorer_hat');
      await tester.tap(find.text('Take off'));
      await tester.pump();
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.equippedCosmetics[CosmeticSlot.head], isNull);
      expect(run.coinManager.coins, 1750);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Upgrade and journal actions save purchases and claim rewards only once',
    (tester) async {
      final run = await game(tester);
      await tester.pumpWidget(app(AdventureUpgrades(game: run)));
      await tester.tap(find.text('500 coins').first);
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.getUpgradeLevel('magnet'), 1);
      expect(run.coinManager.coins, 1500);
      final restored = CoinManager();
      await restored.load();
      expect(restored.getUpgradeLevel('magnet'), 1);
      run.coinManager.collectCoins(50);
      await tester.pumpWidget(app(AdventureJournal(game: run)));
      await tester.tap(find.text('Claim\n50 coins'));
      await tester.pump(const Duration(milliseconds: 200));
      await run.coinManager.forceSave();
      await tester.pump();
      expect(run.coinManager.coins, 1600);
      expect(run.coinManager.collectedCoins, 50);
      expect(run.coinManager.isMissionClaimed(0), isTrue);
      await tester.tap(find.text('Collected'));
      await tester.pump();
      expect(run.coinManager.coins, 1600);
      final saved = CoinManager();
      await saved.load();
      expect(saved.isMissionClaimed(0), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Journal toast belongs to its dialog and disappears when closed',
    (tester) async {
      final run = await game(tester);
      run.coinManager.collectCoins(50);
      final rootMessenger = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: rootMessenger,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AdventureJournal(game: run),
                ),
                child: const Text('Open journal'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open journal'));
      await tester.pump(const Duration(milliseconds: 350));
      final claim = find.text('Claim\n50 coins');
      expect(
        ScaffoldMessenger.of(tester.element(claim)),
        isNot(same(rootMessenger.currentState)),
      );
      await tester.tap(claim);
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.descendant(
          of: find.byType(AdventurePanel),
          matching: find.byType(SnackBar),
        ),
        findsOneWidget,
      );
      expect(find.text('Discovery recorded · +50 coins'), findsOneWidget);
      await tester.tap(find.byTooltip('Close panel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AdventureJournal), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(run.coinManager.isMissionClaimed(0), isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
