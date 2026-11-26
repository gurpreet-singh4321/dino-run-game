import 'dart:math';
import 'package:dino_run_epochs/game/desert_journey.dart';
import 'package:dino_run_epochs/components/ui/game_over_screen.dart';
// Diagnostic benchmark of production components, not a phone FPS test.
// ignore_for_file: invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/components/sky_background.dart';
import 'package:dino_run_epochs/components/ground.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/components/collectible.dart';
import 'package:dino_run_epochs/components/particle.dart';
import 'package:dino_run_epochs/components/ui/hud.dart';
import 'package:dino_run_epochs/components/ui/combo_display.dart';
import 'package:dino_run_epochs/components/ui/milestone_overlay.dart';
import 'package:dino_run_epochs/components/ui/space_timer_bar.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/spawn_manager.dart';
import 'package:dino_run_epochs/managers/speed_manager.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

class _ReviewGame extends DinoGame {
  _ReviewGame({required super.coinManager});
  @override
  Future<void> onLoad() async {
    ground = Ground();
    player = Player();
    spawnManager = SpawnManager();
    speedManager = SpeedManager();
    biomeManager = BiomeManager();
    particlePool = ParticlePool();
    comboDisplay = ComboDisplay();
    hud = Hud();
    milestoneOverlay = MilestoneOverlay();
    await world.addAll([
      SkyBackground(),
      ground,
      player,
      spawnManager,
      speedManager,
      biomeManager,
      particlePool,
    ]);
    await camera.viewport.addAll([
      hud,
      comboDisplay,
      milestoneOverlay,
      SpaceTimerBar(),
      GameOverScreen(),
    ]);
    for (final name in ['PauseMenu', 'MainMenuOverlay', 'SettingsDialog']) {
      overlays.addEntry(name, (_, _) => const SizedBox());
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Export production authored Desert journey and results', () async {
    SharedPreferences.setMockInitialValues({});
    AudioManager.setVolume(0);
    await SettingsManager.setVibrationEnabled(false);
    await NewDinoSkin.preload();
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
          ),
        ),
      );
    await font.load();
    final wallet = CoinManager();
    await wallet.load();
    final game = _ReviewGame(coinManager: wallet)
      ..onGameResize(Vector2(640, 360));
    await game.load();
    game.mount();
    await game.ready();
    Future<void> capture(
      _ReviewGame run,
      String name, {
      int width = 640,
      int height = 360,
    }) async {
      final recorder = ui.PictureRecorder();
      run.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('docs/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    game.startGame(startingStage: 0, authoredDesert: true);
    await game.ready();
    const fps = 60;
    var sawGiant = false, sawCart = false, maxActors = 0;
    double? secondTapAt, releaseAt;
    final jumped = <Object>{};
    final losses = <double>[];
    var lives = 3;
    var captureIndex = 0;
    final captures = [1200.0, 5200.0, 8800.0, 10400.0, 12200.0];
    for (
      var i = 0;
      i < fps * 90 &&
          game.state == GameState.playing &&
          !game.desertJourney.completed;
      i++
    ) {
      final player = game.player;
      for (final hazard in game.spawnManager.groundHazards) {
        final delta = hazard.position.x - player.position.x;
        if (delta < 110 &&
            delta > 0 &&
            player.isOnGround &&
            player.giantTimer <= 0 &&
            !player.cartActive &&
            jumped.add(hazard)) {
          player.jump();
          releaseAt = game.runDistance + 24;
        }
      }
      for (final gap in game.ground.gaps) {
        final delta = gap.x - player.position.x;
        if (delta < 80 && delta > 0 && player.isOnGround && jumped.add(gap)) {
          player.jump();
          releaseAt = game.runDistance + 24;
          secondTapAt = game.runDistance + 55;
        }
      }
      if (secondTapAt != null && game.runDistance >= secondTapAt) {
        player.jump();
        releaseAt = game.runDistance + 24;
        secondTapAt = null;
      }
      if (releaseAt != null && game.runDistance >= releaseAt) {
        player.onJumpRelease();
        releaseAt = null;
      }
      game.update(1 / fps);
      await game.ready();
      if (player.lives < lives) {
        losses.add(game.runDistance);
        lives = player.lives;
      }
      if (captureIndex < captures.length &&
          game.runDistance >= captures[captureIndex]) {
        await capture(game, 'desert-journey-${captures[captureIndex].toInt()}');
        captureIndex++;
      }
      sawGiant |= player.giantTimer > 0;
      sawCart |= player.cart.charges == 3;
      maxActors = max(
        maxActors,
        game.world.children.whereType<Collectible>().length +
            game.spawnManager.groundHazards.length,
      );
    }

    expect(game.desertJourney.completed, isTrue);
    expect(sawGiant && sawCart, isTrue);
    expect(maxActors, lessThan(25));
    expect(losses, isEmpty);
    expect(game.smashedObjects, 6);
    expect(game.runDistance, closeTo(DesertJourney.length, 15));
    await capture(game, 'desert-journey-results');
    for (final size in [Vector2(568, 320), Vector2(1024, 600)]) {
      game.onGameResize(size);
      await game.ready();
      await capture(
        game,
        'desert-journey-results-${size.x.toInt()}',
        width: size.x.toInt(),
        height: size.y.toInt(),
      );
    }
    game.onGameResize(Vector2(640, 360));
    await game.ready();
    game.startGame(startingStage: 0, authoredDesert: true);
    await game.ready();
    for (var i = 0; i < 60 * 30 && game.state == GameState.playing; i++) {
      game.update(1 / 60);
      await game.ready();
    }
    expect(game.state, GameState.gameOver);
    expect(game.desertJourney.completed, isFalse);
    await capture(game, 'desert-journey-failed');
    game.onGameResize(Vector2(568, 320));
    await game.ready();
    await capture(game, 'desert-journey-failed-568', width: 568, height: 320);
    expect(game.handleResultsTap(Vector2(436, 250)), isTrue);
    expect(game.state, GameState.playing);
    expect(game.player.lives, 3);
    expect(game.desertJourney.active, isTrue);
    expect(game.player.cart.charges, 0);
    await wallet.forceSave();
    game.onRemove();
  });
}
