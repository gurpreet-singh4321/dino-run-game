import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/components/ui/adventure_panels.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/ui/animated_dino_preview.dart';
import 'package:dino_run_epochs/components/ui/main_menu_overlay.dart';
import 'package:dino_run_epochs/components/ui/run_results.dart';
import 'package:dino_run_epochs/components/ui/settings_dialog.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A spy keeps navigation tests focused on dispatch, without loading a Flame run.
class _RunSpy extends DinoGame {
  _RunSpy(CoinManager wallet) : super(coinManager: wallet);
  int starts = 0;
  int exits = 0;
  int revives = 0;
  int? startingEpoch;
  @override
  void startGame({
    int? startingStage,
    bool keepMenuOverlay = false,
    bool? authoredDesert,
  }) {
    starts++;
    startingEpoch = startingStage;
    state = GameState.playing;
  }

  @override
  void exitToMenu() {
    exits++;
    state = GameState.menu;
  }

  @override
  void reviveGame() {
    revives++;
    state = GameState.playing;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<_RunSpy> game(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'dino_audio_volume': 0.0,
      'dino_vibration_enabled': false,
    });
    return (await tester.runAsync(() async {
      await SettingsManager.load();
      final wallet = CoinManager();
      await wallet.load();
      await NewDinoSkin.preload();
      return _RunSpy(wallet)
        ..biomeManager = BiomeManager()
        ..player = (Player()..skin = NewDinoSkin());
    }))!;
  }

  Widget app(Widget body, {bool reduced = false}) => MaterialApp(
    theme: AdventureTheme.data,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(body: body),
    ),
  );

  VoidCallback action(WidgetTester tester, String label) => tester
      .widget<FilledButton>(
        find
            .ancestor(of: find.text(label), matching: find.byType(FilledButton))
            .first,
      )
      .onPressed!;

  testWidgets('Rapid panel requests open once and preserve the chosen epoch', (
    tester,
  ) async {
    final run = await game(tester);
    await tester.pumpWidget(app(MainMenuOverlay(game: run)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Next epoch'));
    await tester.pump();
    expect(run.biomeManager.currentStage, 1);
    final open = action(tester, 'Workshop');
    open();
    open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AdventureWardrobe, skipOffstage: false), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(run.biomeManager.currentStage, 1);
    expect(run.starts, 0);
    await tester.tap(find.byTooltip('Close panel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AdventureWardrobe, skipOffstage: false), findsNothing);
    expect(find.text('Jurassic Monsoon'), findsOneWidget);
    expect(run.biomeManager.currentStage, 1);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(run.starts, 1);
    expect(run.startingEpoch, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rapid Play and keyboard activation dispatch one run', (
    tester,
  ) async {
    final run = await game(tester);
    await tester.pumpWidget(app(MainMenuOverlay(game: run)));
    await tester.pump(const Duration(milliseconds: 400));
    final play = action(tester, 'Play');
    play();
    play();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(run.starts, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Repeated submenu and system Back navigation retains home context',
    (tester) async {
      final run = await game(tester);
      await tester.pumpWidget(app(MainMenuOverlay(game: run)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip('Next epoch'));
      await tester.pump();
      for (final label in [
        'Workshop',
        'Upgrades',
        'Journal',
        'Settings',
        'Workshop',
      ]) {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(AdventurePanel), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(run.starts, 0);
        expect(run.biomeManager.currentStage, 1);
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(AdventurePanel), findsNothing);
        expect(find.text('Jurassic Monsoon'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings controls persist their displayed state on reopen', (
    tester,
  ) async {
    await game(tester);
    await tester.pumpWidget(app(SettingsDialog(onClose: () {})));
    await tester.pump(const Duration(milliseconds: 400));
    tester.widget<Slider>(find.byType(Slider)).onChanged!(.35);
    final vibration = find.widgetWithText(SwitchListTile, 'Vibration');
    tester.widget<SwitchListTile>(vibration).onChanged!(true);
    final motion = find.widgetWithText(SwitchListTile, 'Reduced motion');
    tester.widget<SwitchListTile>(motion).onChanged!(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(SettingsManager.load);
    await tester.pumpWidget(app(SettingsDialog(onClose: () {})));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<Slider>(find.byType(Slider)).value, .35);
    expect(tester.widget<SwitchListTile>(vibration).value, isTrue);
    expect(tester.widget<SwitchListTile>(motion).value, isTrue);
    expect(SettingsManager.reduceMotion, isTrue);
    expect(find.text('35%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  for (final destination in ['Retry', 'Main menu', 'Revive']) {
    testWidgets('Run results dispatch $destination once under rapid taps', (
      tester,
    ) async {
      final run = (await game(tester))..state = GameState.gameOver;
      await tester.pumpWidget(app(RunResults(game: run)));
      await tester.pump(const Duration(milliseconds: 400));
      final go = destination == 'Revive'
          ? tester.widget<TextButton>(find.widgetWithText(
              TextButton, 'Revive · continue this run')).onPressed!
          : action(tester, destination);
      go();
      go();
      await tester.pump();
      expect(run.starts + run.exits + run.revives, 1);
      expect(run.starts, destination == 'Retry' ? 1 : 0);
      expect(run.exits, destination == 'Main menu' ? 1 : 0);
      expect(run.revives, destination == 'Revive' ? 1 : 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  NewDinoSkin previewSkin(WidgetTester tester) =>
      (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(AnimatedDinoPreview),
                          matching: find.byWidgetPredicate(
                            (widget) =>
                                widget is CustomPaint && widget.painter != null,
                          ),
                        ),
                      )
                      .painter
                  as dynamic)
              .skin
          as NewDinoSkin;

  testWidgets(
    'Reduced motion preview stays still and never changes the run rig',
    (tester) async {
      await tester.runAsync(NewDinoSkin.preload);
      final template = NewDinoSkin();
      await tester.pumpWidget(
        app(
          AnimatedDinoPreview(template: template, interactive: true),
          reduced: true,
        ),
      );
      final preview = previewSkin(tester);
      final before = preview.motion.time;
      await tester.pump(const Duration(seconds: 2));
      expect(preview.motion.time, before);
      expect(template.motion.time, 0);
      await tester.tap(find.byType(AnimatedDinoPreview));
      await tester.pump(const Duration(milliseconds: 400));
      expect(preview.motion.time, before);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Preview pauses across app lifecycle and resumes without catching up',
    (tester) async {
      await tester.runAsync(NewDinoSkin.preload);
      await tester.pumpWidget(
        app(AnimatedDinoPreview(template: NewDinoSkin())),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final preview = previewSkin(tester);
      final before = preview.motion.time;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 8));
      expect(preview.motion.time, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(preview.motion.time, greaterThan(before));
      expect(preview.motion.time - before, lessThanOrEqualTo(.11));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
