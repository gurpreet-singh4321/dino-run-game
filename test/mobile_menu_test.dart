import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/components/ui/main_menu_overlay.dart';
import 'package:dino_run_epochs/components/ui/settings_dialog.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [const Size(568, 320), const Size(640, 360), const Size(844, 390)]) {
    testWidgets('Menus fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final coins = CoinManager();
      await coins.load();
      coins.setActiveSkin('new_dino');
      await coins.forceSave();
      await tester.runAsync(NewDinoSkin.preload);
      final game = DinoGame(coinManager: coins);
      game.player = Player()..skin = NewDinoSkin();
      await tester.pumpWidget(MaterialApp(theme: AdventureTheme.data,
        home: Scaffold(body: MainMenuOverlay(game: game))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Wardrobe'));
      await tester.tap(find.text('Wardrobe'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(theme: AdventureTheme.data,
        home: Scaffold(body: MainMenuOverlay(game: game))));
      await tester.pump();
      await tester.ensureVisible(find.text('Upgrades'));
      await tester.tap(find.text('Upgrades'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(theme: AdventureTheme.data,
        home: Scaffold(body: SettingsDialog(onClose: () {}))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
