import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/components/ui/animated_dino_preview.dart';
import 'package:dino_run_epochs/components/ui/dino_hill_top.dart';
import 'package:dino_run_epochs/components/ui/minimal_home.dart';
import 'package:dino_run_epochs/components/ui/splash_screen.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';

void main() {
  for (final size in [const Size(568, 320), const Size(1024, 600)]) {
    testWidgets('Startup and retry fit $size with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: SplashArtwork(
              progress: .5,
              error: 'Dino could not load. Try again.',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final viewport = tester.getSize(find.byType(Scaffold));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(find.byType(Scaffold)), viewport);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getSize(find.byType(Scaffold)), viewport);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .5,
      );
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Splash renders equipped clothes on Dino hilltop and glides into main menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'dino_owned_cosmetics': ['explorer_hat', 'red_scarf'],
      'dino_equipped_cosmetics': ['explorer_hat', 'red_scarf'],
    });
    AudioManager.setVolume(0);
    await tester.runAsync(NewDinoSkin.preload);
    final coins = CoinManager();
    await coins.load();

    final equippedSkin = NewDinoSkin()
      ..cosmetics = [
        CosmeticCatalog.find('explorer_hat')!,
        CosmeticCatalog.find('red_scarf')!,
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: SplashArtwork(
          skin: equippedSkin,
          progress: 0.6,
          ready: true,
          animateEntrance: false,
        ),
      ),
    );
    expect(find.byType(AnimatedDinoPreview), findsOneWidget);
    final preview = tester.widget<AnimatedDinoPreview>(
      find.byType(AnimatedDinoPreview),
    );
    expect(preview.template.cosmetics.map((c) => c.id).toSet(), {
      'explorer_hat',
      'red_scarf',
    });
    final hasHill = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is DinoHillTopPainter,
    );
    expect(hasHill, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(home: SplashScreen(coinManager: coins)));
    for (var i = 0; i < 60 && find.byType(MinimalHome).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(MinimalHome), findsOneWidget);
    // Let the 680ms zoom/glide handoff settle cleanly onto the menu Dino slot.
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(MinimalHome), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
