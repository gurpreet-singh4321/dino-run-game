import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/components/ui/main_menu_overlay.dart';
import 'package:dino_run_epochs/components/ui/settings_dialog.dart';
import 'package:dino_run_epochs/components/ui/pause_menu.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/ui/menu_chrome.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(568, 320),
    const Size(640, 360),
    const Size(844, 390),
    const Size(1024, 600),
  ]) {
    testWidgets('Scenic menus and last journal/wardrobe items fit $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final coins = CoinManager();
      await coins.load();
      await tester.runAsync(NewDinoSkin.preload);
      final game = DinoGame(coinManager: coins);
      game.player = Player()..skin = NewDinoSkin();
      game.biomeManager = BiomeManager();
      Widget app(Widget body) => MaterialApp(
        theme: AdventureTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          ),
          child: child!,
        ),
        home: Scaffold(body: body),
      );
      await tester.pumpWidget(app(MainMenuOverlay(game: game)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      for (final stage in [1, 2, 3, 5, 4]) {
        await tester.tap(find.byTooltip('Next epoch'));
        await tester.pump();
        expect(game.biomeManager.currentStage, stage);
        expect(
          tester.widget<EpochScenery>(find.byType(EpochScenery)).stage,
          stage,
        );
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(game.biomeManager.currentStage, 5);
      await tester.drag(find.text('Cosmic Orbit'), const Offset(100, 0));
      await tester.pump();
      expect(game.biomeManager.currentStage, 3);
      expect(tester.takeException(), isNull);
      final beforeGift = coins.coins;
      await tester.tap(find.byTooltip('Daily gift'));
      await tester.pump();
      expect(coins.coins, beforeGift + 200);
      expect(coins.collectedCoins, 0);
      expect(find.byTooltip('Daily gift claimed'), findsOneWidget);
      // Dismiss the feedback toast before checking all of the footer actions.
      ScaffoldMessenger.of(
        tester.element(find.byType(MainMenuOverlay)),
      ).clearSnackBars();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Workshop'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AdventureWardrobe), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Starlight pack'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(GridView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Starlight pack'));
      await tester.pump();
      expect(find.text('Starlight pack').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close panel'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Upgrades'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AdventureUpgrades), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Lucky stars'), 100);
      await tester.pump();
      expect(find.text('Lucky stars').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close panel'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Journal'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(AdventureJournal), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Take a trip to space'), 100);
      await tester.pump();
      expect(find.text('Take a trip to space').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(SettingsDialog(onClose: () {}, stage: 3)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(PauseMenu(game: game)));
      await tester.pump();
      final panelSize = tester.getSize(find.byType(MenuPaper));
      expect(panelSize.width, lessThanOrEqualTo(440));
      expect(panelSize.height, lessThanOrEqualTo(290));
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      expect(find.text('Main menu').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await coins.forceSave();
    });
  }
}
