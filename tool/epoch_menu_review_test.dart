import 'dart:io';
import 'dart:ui' as ui;
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/ui/main_menu_overlay.dart';
import 'package:dino_run_epochs/components/ui/menu_chrome.dart';
import 'package:dino_run_epochs/components/ui/pause_menu.dart';
import 'package:dino_run_epochs/components/ui/run_results.dart';
import 'package:dino_run_epochs/components/ui/settings_dialog.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/skin_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Render production widgets, fonts and assets using an isolated new-player save.
// Bounded frame pumps are intentional: the home scene has a continuous idle rig.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(568, 320),
    const Size(844, 390),
    const Size(1024, 600),
    const Size(390, 844),
  ]) {
    testWidgets('Export menu refresh review at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        for (final family in ['Fredoka', 'Nunito']) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        await NewDinoSkin.preload();
      });
      SharedPreferences.setMockInitialValues({
        'dino_audio_volume': 0.0,
        'dino_vibration_enabled': false,
      });
      await tester.runAsync(SettingsManager.load);
      final wallet = CoinManager();
      await wallet.load();
      SkinRegistry.setCosmetics([]);
      final game = DinoGame(coinManager: wallet)
        ..biomeManager = BiomeManager()
        ..player = (Player()..skin = NewDinoSkin());
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      const key = ValueKey('menu-refresh-capture');

      Future<void> capture(String panel) async {
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$panel at $tag');
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/menu-refresh-$panel-$tag.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> show(Widget body, {bool reduced = false}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AdventureTheme.data,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  padding: size.height > size.width
                      ? const EdgeInsets.only(top: 44, bottom: 24)
                      : const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  disableAnimations: reduced,
                ),
                child: child!,
              ),
              home: Scaffold(body: body),
            ),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            EpochScenery.imageFor(game.biomeManager.currentStage),
            tester.element(find.byType(Scaffold).first),
          ),
        );
        await tester.pump();
      }

      await show(MainMenuOverlay(game: game));
      await capture('home');
      await show(
        SettingsDialog(onClose: () {}, stage: game.biomeManager.currentStage),
      );
      await capture('settings');
      await tester.scrollUntilVisible(find.text('Reduced motion'), 160);
      await tester.pump(const Duration(milliseconds: 150));
      await capture('settings-more');
      if (const bool.fromEnvironment('ALL_PANELS')) {
        await show(AdventureWardrobe(game: game));
        await capture('workshop');
        await tester.tap(find.text('Carts'));
        await capture('carts');
        await show(AdventureUpgrades(game: game));
        await capture('upgrades');
        await show(AdventureJournal(game: game));
        await capture('journal');
        await show(PauseMenu(game: game));
        await capture('pause');
        game.state = GameState.gameOver;
        await show(RunResults(game: game));
        await capture('results');
        game.state = GameState.menu;
        game.biomeManager.currentStage = 5;
        await show(MainMenuOverlay(game: game));
        await capture('cosmic-home');
        await show(MainMenuOverlay(game: game), reduced: true);
        await capture('reduced-motion');
      }
      await tester.pumpWidget(const SizedBox());
      await wallet.forceSave();
      expect(tester.takeException(), isNull);
    });
  }
}
