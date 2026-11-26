// Diagnostic benchmark of production components, not a phone FPS test.
// ignore_for_file: invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:dino_run_epochs/components/obstacle.dart';
import 'package:dino_run_epochs/components/falling_stone.dart';
import 'package:dino_run_epochs/utils/scenery_cache.dart';
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
import 'package:dino_run_epochs/utils/gear_assets.dart';

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
    ]);
    overlays.addEntry('PauseMenu', (_, _) => const SizedBox());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Render epoch obstacles, ahead impacts and shared scenery cache',
    () async {
      SharedPreferences.setMockInitialValues({});
      AudioManager.setVolume(0);
      await SettingsManager.setVibrationEnabled(false);
      await NewDinoSkin.preload();
      final font = FontLoader('Ahem')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final loads = await Future.wait([
        SceneryCache.load('orbit_painted_v1.png'),
        SceneryCache.load('orbit_painted_v1.png'),
      ]);
      expect(identical(loads[0], loads[1]), isTrue);
      expect(loads[0].width, lessThanOrEqualTo(1280));
      Future<void> capture(_ReviewGame game, String name) async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(640, 360);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }

      for (var stage = 0; stage < 6; stage++) {
        final coins = CoinManager();
        await coins.load();
        final game = _ReviewGame(coinManager: coins)
          ..onGameResize(Vector2(640, 360));
        await game.load();
        game.mount();
        await game.ready();
        game.biomeManager.currentStage = stage;
        game.state = GameState.playing;
        game.spawnManager.obstacleTimer = 999;
        game.spawnManager.coinTimer = 999;
        final types = stage == 0
            ? [
                ObstacleType.cactusSmall,
                ObstacleType.cactusTall,
                ObstacleType.rock,
              ]
            : [ObstacleType.rock, ObstacleType.bush, ObstacleType.pillar];
        for (var i = 0; i < types.length; i++) {
          final obstacle = Obstacle(type: types[i], speed: 200);
          await game.world.add(obstacle);
          await game.ready();
          obstacle.position = Vector2(
            250 + i * 115,
            game.ground.groundY - obstacle.size.y,
          );
          obstacle.entranceTimer = 1;
        }
        await capture(game, 'epochs-phase3-obstacles-$stage');
        for (final obstacle
            in game.world.children.whereType<Obstacle>().toList()) {
          obstacle.removeFromParent();
        }
        await game.ready();
        game.ground.addGap(320, 145);
        game.ground.gaps.last.eruptionTimer = .6;
        await capture(game, 'epochs-phase3-gap-$stage');
        game.ground.clearGaps();
        if (stage == 0) {
          game.spawnManager.reset();
          await game.ready();
          final cluster = FallingStone(initialSpeedX: 200);
          game.spawnManager.registerGroundHazard(cluster);
          await game.ready();
          final rock = cluster.children.whereType<FallingRock>().single;
          for (var i = 0; i < 180; i++) {
            rock.update(1 / 120);
          }
          await capture(game, 'meteor-ahead-descent');
          for (var i = 0; i < 150; i++) {
            rock.update(1 / 120);
          }
          await game.ready();
          expect(rock.phase, RockPhase.landed);
          await capture(game, 'meteor-impact-crater');
        }
        await coins.forceSave();
        game.onRemove();
      }
    },
  );
  test(
    'Export cart driver, charges and safe dismount from production rendering',
    () async {
      SharedPreferences.setMockInitialValues({});
      AudioManager.setVolume(0);
      await SettingsManager.setVibrationEnabled(false);
      await NewDinoSkin.preload();
      final coins = CoinManager();
      await coins.load();
      final game = _ReviewGame(coinManager: coins)
        ..onGameResize(Vector2(640, 360));
      await game.load();
      game.mount();
      await game.ready();
      game.state = GameState.playing;
      game.spawnManager.obstacleTimer = 999;
      game.spawnManager.coinTimer = 999;
      game.player.collectCart();
      for (var i = 0; i < 30; i++) {
        game.update(1 / 120);
      }
      for (var charge = 3; charge >= 0; charge--) {
        if (charge < 3) {
          final rock = Obstacle(type: ObstacleType.rock, speed: 200);
          game.spawnManager.registerGroundHazard(rock);
          await game.ready();
          rock.entranceTimer = 1;
          rock.position = game.player.position + Vector2(70, 45);
          game.player.onCollision({}, rock);
          game.hitStopTimer = 0;
          for (var i = 0; i < 10; i++) {
            game.update(1 / 120);
          }
          await game.ready();
        }
        expect(game.player.cart.charges, charge);
        expect(game.player.lives, 3);
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(640, 360);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/cart-phase4-charges-$charge.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
      await coins.forceSave();
      game.onRemove();
    },
  );

  test(
    'Export painted jetpack in production space flight and verify shared decode',
    () async {
      SharedPreferences.setMockInitialValues({});
      AudioManager.setVolume(0);
      await SettingsManager.setVibrationEnabled(false);
      await NewDinoSkin.preload();
      final warm = GearAssets.preload();
      expect(identical(warm, GearAssets.preload()), isTrue);
      await warm;
      expect(GearAssets.cart!.width, 384);
      expect(GearAssets.jetpack!.width, 192);
      final coins = CoinManager();
      await coins.load();
      final game = _ReviewGame(coinManager: coins)
        ..onGameResize(Vector2(640, 360));
      await game.load();
      game.mount();
      await game.ready();
      game.enterSpaceMode();
      for (var i = 0; i < 100; i++) {
        game.update(1 / 120);
      }
      await game.ready();
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(640, 360);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/painted-gear-space.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      await coins.forceSave();
      game.onRemove();
    },
  );

  test('Export deterministic normal and giant contact outcomes', () async {
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
    for (final giant in [false, true]) {
      final coins = CoinManager();
      await coins.load();
      final game = _ReviewGame(coinManager: coins)
        ..onGameResize(Vector2(640, 360));
      await game.load();
      game.mount();
      await game.ready();
      game.state = GameState.playing;
      game.spawnManager.obstacleTimer = 999;
      game.spawnManager.coinTimer = 999;
      if (giant) {
        game.player.activateGiant();
        game.player.giantTimer = 10;
        game.player.invincibleTimer = 2;
      }
      final obstacle = Obstacle(type: ObstacleType.rock, speed: 200);
      game.spawnManager.registerGroundHazard(obstacle);
      await game.ready();
      obstacle.entranceTimer = 1;
      obstacle.position = game.player.position + Vector2(25, 20);
      final score = game.score;
      game.update(1 / 60);
      await game.ready();
      expect(game.player.lives, giant ? 3 : 2);
      if (giant) expect(game.score - score, closeTo(50, 1));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.save();
      canvas.translate(0, -80);
      game.render(canvas);
      canvas.restore();
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 640, 32),
        ui.Paint()..color = const ui.Color(0xFF24334E),
      );
      final title = TextPainter(
        text: TextSpan(
          text:
              '${giant ? 'Giant + recovery smash' : 'Normal contact'} · ${game.player.lives} hearts · ${giant ? 'one +50 reward' : 'one heart lost'}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: ui.Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      title.paint(canvas, const ui.Offset(12, 7));
      final picture = recorder.endRecording();
      final image = await picture.toImage(640, 280);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/contact-phase1-${giant ? 'giant' : 'normal'}.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      await coins.forceSave();
      game.onRemove();
    }
  });
  test(
    'Measure full space trips with production drawing and collisions',
    () async {
      SharedPreferences.setMockInitialValues({});
      AudioManager.setVolume(0);
      await SettingsManager.setVibrationEnabled(false);
      await NewDinoSkin.preload();
      final rows = <Map<String, Object>>[];
      for (final speed in [200.0, 450.0]) {
        final coins = CoinManager();
        await coins.load();
        final game = _ReviewGame(coinManager: coins)
          ..onGameResize(Vector2(640, 360));
        await game.load();
        game.mount();
        await game.ready();
        game.speedManager.currentSpeed = speed;
        game.enterSpaceMode();
        game.spawnManager.coinTimer = 0;
        var peak = 0, updateUs = 0, frames = 0;
        final drawUs = <int>[];
        for (var i = 0; i < 885; i++) {
          final timer = Stopwatch()..start();
          game.update(1 / 60);
          updateUs += timer.elapsedMicroseconds;
          frames++;
          peak = peak > game.world.children.whereType<Collectible>().length
              ? peak
              : game.world.children.whereType<Collectible>().length;
          // Force rasterization, rather than timing only recorded draw commands.
          if (i % 15 == 0) {
            final recorder = ui.PictureRecorder();
            final drawTimer = Stopwatch()..start();
            game.render(ui.Canvas(recorder));
            final picture = recorder.endRecording();
            final image = await picture.toImage(640, 360);
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
            drawUs.add(drawTimer.elapsedMicroseconds);
            if (i == 450 && const bool.fromEnvironment('DINO_CAPTURE')) {
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'docs/space-review-${speed.toInt()}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
            }
            image.dispose();
            picture.dispose();
          }
        }
        drawUs.sort();
        rows.add({
          'speed': speed,
          'peakPickups': peak,
          'meanUpdateUs': updateUs / frames,
          'medianRasterAndReadbackUs': drawUs[drawUs.length ~/ 2],
          'p95RasterAndReadbackUs': drawUs[(drawUs.length * .95).floor()],
        });
        await coins.forceSave();
        game.onRemove();
      }
      const label = String.fromEnvironment('PERF_LABEL', defaultValue: 'after');
      await File('docs/space-performance-$label.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'environment':
              'Flutter debug test runner, 640x360, 60 updates/s; not phone FPS',
          'runs': rows,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test('Export themed passage and falling pillar variety', () async {
    SharedPreferences.setMockInitialValues({});
    AudioManager.setVolume(0);
    await SettingsManager.setVibrationEnabled(false);
    await NewDinoSkin.preload();
    for (var stage = 0; stage < 6; stage++) {
      final coins = CoinManager();
      await coins.load();
      final game = _ReviewGame(coinManager: coins)
        ..onGameResize(Vector2(640, 360));
      await game.load();
      game.mount();
      await game.ready();
      game.biomeManager.currentStage = stage;
      game.state = GameState.playing;
      game.spawnManager.cartLane = true;
      game.player.collectCart();
      game.update(.1);
      await game.ready();
      for (var i = 0; i < 3; i++) {
        final type = [
          ObstacleType.pillar,
          ObstacleType.ceilingPipe,
          ObstacleType.pipePair,
        ][i];
        final o = Obstacle(type: type, speed: 200)
          ..size = Vector2(60, i == 0 ? 85 : 300)
          ..position = Vector2(240 + i * 120, 0)
          ..entranceTimer = 1;
        if (i == 0) {
          o.isFallingFromSky = true;
          o.targetGroundY = game.ground.groundY - 85;
          o.position.y = 85;
        }
        if (i == 1) o.size.y = game.ground.groundY - 140;
        if (i == 2) {
          o.gapTopY = 60;
          o.gapBottomY = 235;
        }
        await game.world.add(o);
        await game.ready();
      }
      final recorder = ui.PictureRecorder();
      game.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(640, 360);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/passage-variety-$stage.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      await coins.forceSave();
      game.onRemove();
    }
  });
}
