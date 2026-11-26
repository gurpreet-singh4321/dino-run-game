import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/components/ui/main_menu_overlay.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/ui/menu_chrome.dart';
import 'package:dino_run_epochs/components/ui/pause_menu.dart';
import 'package:dino_run_epochs/components/ui/splash_screen.dart';
import 'package:dino_run_epochs/utils/scenery_cache.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';
import 'package:dino_run_epochs/skins/skin_registry.dart';

// Review fixtures use isolated mock preferences; no browser or real saves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Export living menu and new cosmetic review fixtures', (
    tester,
  ) async {
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
    });
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      NewDinoSkin().renderCharacter(canvas, const Size(240, 280), 0);
      final picture = recorder.endRecording();
      final image = await picture.toImage(240, 280);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'assets/images/boot_dino.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
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

    for (final size in [const Size(568, 320), const Size(1024, 600)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final tag = size.width == 568 ? 'phone' : 'desktop';
      ui.Image? splashScenery;
      await tester.runAsync(() async {
        splashScenery = await SceneryCache.load(SceneryCache.paths.first);
      });
      await show(
        SplashArtwork(scenery: splashScenery, ready: true, progress: .65),
      );
      await capture('painted-splash-$tag');
      await show(
        SplashArtwork(
          scenery: splashScenery,
          ready: true,
          progress: .5,
          error: 'Dino could not load. Try again.',
          onRetry: () {},
        ),
      );
      await capture('painted-splash-error-$tag');
      await show(MainMenuOverlay(game: game));
      await capture('living-home-$tag');
      await show(PauseMenu(game: game));
      await capture('living-pause-$tag');
      await show(AdventureWardrobe(game: game));
      await tester.scrollUntilVisible(find.text('Moon explorer'), 100);
      await capture('living-wardrobe-$tag');
      if (!wallet.isMissionClaimed(0)) wallet.collectCoins(50);
      await show(AdventureJournal(game: game));
      if (!wallet.isMissionClaimed(0)) {
        await tester.tap(find.text('Claim\n50 coins'));
        await tester.pump();
        await wallet.forceSave();
        await tester.pump();
        await capture('living-journal-toast-$tag');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFFF5F5EC), BlendMode.src);
      final items = CosmeticCatalog.items.skip(4).toList();
      for (var i = 0; i < items.length; i++) {
        final x = (i % 3) * 240.0, y = (i ~/ 3) * 280.0;
        canvas.save();
        canvas.translate(x + 30, y + 12);
        final skin = NewDinoSkin()..cosmetics = [items[i]];
        skin.advanceMotion(
          .1,
          speed: 200,
          velocityY: 0,
          grounded: true,
          idle: true,
        );
        skin.renderCharacter(canvas, const Size(180, 216), 0);
        canvas.restore();
        final text = TextPainter(
          text: TextSpan(
            text: items[i].name,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 17,
              color: MenuPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 230);
        text.paint(canvas, Offset(x + (240 - text.width) / 2, y + 240));
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(720, 560);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/new-cosmetics-review.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await wallet.forceSave();
  });
}
