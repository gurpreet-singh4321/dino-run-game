import 'package:dino_run_epochs/components/ui/menu_chrome.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/utils/gear_assets.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/skin_registry.dart';

// Review fixtures use isolated mock preferences; no browser or real saves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Export Workshop layouts and preview isolation', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await NewDinoSkin.preload();
      await GearAssets.preload();
    });
    AudioManager.setVolume(0);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'dino_coins': 0});
    final wallet = CoinManager();
    await wallet.load();
    final game = DinoGame(coinManager: wallet)
      ..biomeManager = BiomeManager()
      ..player = (Player()..skin = NewDinoSkin());
    SkinRegistry.setCosmetics([]);
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')),
        );
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> show(Widget body) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AdventureTheme.data,
            home: Scaffold(body: body),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          EpochScenery.imageFor(0),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pump();
    }

    for (final size in [
      const Size(568, 320),
      const Size(640, 360),
      const Size(1024, 600),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final tag = size.width.toInt().toString();
      await show(AdventureWardrobe(game: game));
      await capture('workshop-outfits-$tag');
      await tester.tap(find.text('Carts'));
      await tester.pump();
      await tester.tap(find.text('Lagoon finish'));
      await tester.pump();
      await capture('workshop-cart-$tag');
      expect(wallet.equippedCartSkin, 'fossil_rover');
      await tester.tap(find.text('Powers'));
      await tester.pump();
      await capture('workshop-upgrades-$tag');
    }
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await wallet.forceSave();
  });
}
