import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
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
  for (final size in [const Size(844, 390)]) {
    testWidgets('Menus fit $size', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File('C:/Windows/Fonts/arial.ttf').readAsBytesSync())));
        await font.load();
        final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
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
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('capture'), child: MaterialApp(debugShowCheckedModeBanner: false, theme: AdventureTheme.data,
        home: Scaffold(body: Stack(children: [Positioned.fill(child: Image.asset('assets/images/biomes/desert_fossil_canyon.png', fit: BoxFit.cover)), MainMenuOverlay(game: game)])))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MainMenuOverlay));
        await precacheImage(const AssetImage('assets/images/biomes/desert_fossil_canyon.png'), context);
        await precacheImage(const AssetImage('assets/images/app_icon.png'), context);
      });
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture')));
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/mobile-menu-review.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.ensureVisible(find.text('Wardrobe'));
      await tester.tap(find.text('Wardrobe'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(RepaintBoundary(key: const ValueKey('capture'), child: MaterialApp(debugShowCheckedModeBanner: false, theme: AdventureTheme.data,
        home: Scaffold(body: Stack(children: [Positioned.fill(child: Image.asset('assets/images/biomes/desert_fossil_canyon.png', fit: BoxFit.cover)), MainMenuOverlay(game: game)])))));
      await tester.pump();
      await tester.ensureVisible(find.text('Upgrades'));
      await tester.tap(find.text('Upgrades'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: AdventureTheme.data,
        home: Scaffold(body: SettingsDialog(onClose: () {}))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
