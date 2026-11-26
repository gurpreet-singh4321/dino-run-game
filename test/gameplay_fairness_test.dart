import 'package:dino_run_epochs/game/desert_journey.dart';
// Headless Flame mount bypasses GameWidget intentionally for deterministic steps.
// ignore_for_file: invalid_use_of_internal_member
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/game/dino_game.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/components/ground.dart';
import 'package:dino_run_epochs/components/collectible.dart';
import 'package:dino_run_epochs/components/falling_stone.dart';
import 'package:dino_run_epochs/components/obstacle.dart';
import 'package:dino_run_epochs/game/hazard_contact.dart';
import 'package:dino_run_epochs/game/cart_power.dart';
import 'package:dino_run_epochs/components/rolling_ball.dart';
import 'package:dino_run_epochs/components/particle.dart';
import 'package:dino_run_epochs/components/ui/hud.dart';
import 'package:dino_run_epochs/components/ui/combo_display.dart';
import 'package:dino_run_epochs/components/ui/milestone_overlay.dart';
import 'package:dino_run_epochs/managers/coin_manager.dart';
import 'package:dino_run_epochs/managers/spawn_manager.dart';
import 'package:dino_run_epochs/managers/speed_manager.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

// Exercise production physics, collision dispatch and lifecycle, without music
// or scenery decoding. No collision, reward or time formulas are duplicated.
class _Ground extends Ground {
  @override
  Future<void> onLoad() async {}
}

class _Game extends DinoGame {
  _Game(CoinManager coins) : super(coinManager: coins);
  @override
  Future<void> onLoad() async {
    ground = _Ground();
    player = Player();
    speedManager = SpeedManager();
    biomeManager = BiomeManager();
    spawnManager = SpawnManager();
    particlePool = ParticlePool();
    hud = Hud();
    comboDisplay = ComboDisplay();
    milestoneOverlay = MilestoneOverlay();
    await world.addAll([
      ground,
      player,
      speedManager,
      biomeManager,
      spawnManager,
      particlePool,
    ]);
    await camera.viewport.addAll([hud, comboDisplay, milestoneOverlay]);
    for (final name in ['PauseMenu', 'MainMenuOverlay', 'SettingsDialog']) {
      overlays.addEntry(name, (_, _) => const SizedBox());
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(NewDinoSkin.preload);
  late _Game game;
  setUp(() async {
    AudioManager.setVolume(0);
    SharedPreferences.setMockInitialValues({});
    await SettingsManager.setVibrationEnabled(false);
    final coins = CoinManager();
    await coins.load();
    game = _Game(coins)..onGameResize(Vector2(640, 360));
    await game.load();
    game.mount();
    await game.ready();
    game.state = GameState.playing;
    game.spawnManager.obstacleTimer = 999;
    game.spawnManager.coinTimer = 999;
  });
  tearDown(() async {
    await game.coinManager.forceSave();
    game.onRemove();
  });

  test(
    'Authored Desert is completable with real taps at 30/60/120 FPS',
    () async {
      for (final fps in [30, 60, 120]) {
        game.startGame(startingStage: 0, authoredDesert: true);
        await game.ready();
        var sawGiant = false, sawCart = false, maxActors = 0;
        double? secondTapAt, releaseAt;
        final jumped = <Object>{};
        final losses = <double>[];
        var lives = 3;
        for (
          var i = 0;
          i < fps * 90 &&
              game.state == GameState.playing &&
              !game.desertJourney.completed;
          i++
        ) {
          final player = game.player;
          for (final hazard in game.spawnManager.groundHazards) {
            if (hazard is Obstacle && hazard.type == ObstacleType.ceilingPipe) {
              continue;
            }
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
            if (delta < 80 &&
                delta > 0 &&
                player.isOnGround &&
                jumped.add(gap)) {
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
          sawGiant |= player.giantTimer > 0;
          sawCart |= player.cart.charges == 3;
          maxActors = max(
            maxActors,
            game.world.children.whereType<Collectible>().length +
                game.spawnManager.groundHazards.length,
          );
        }
        expect(
          game.desertJourney.completed,
          isTrue,
          reason:
              'fps=$fps distance=${game.runDistance} lives=${game.player.lives}',
        );
        expect(game.state, GameState.playing);
        expect(game.player.lives, 3, reason: 'lost hearts at $losses');
        expect(sawGiant, isTrue);
        expect(sawCart, isTrue);
        expect(game.smashedObjects, 6);
        expect(game.player.cart.charges, 0);
        expect(maxActors, lessThan(25));
        expect(game.coinManager.runCoins, greaterThan(0));
        expect(game.runDistance, closeTo(DesertJourney.length, 15));
        expect(game.desertJourney.active, isFalse);
        expect(
          game.speedManager.currentSpeed,
          greaterThanOrEqualTo(DesertJourney.speed),
        );
        final distance = game.runDistance;
        game.spawnManager.coinTimer =
            999; // Isolate resumed hazards from random rocket pickups.
        var sawEndlessHazard = false;
        for (var j = 0; j < fps * 3; j++) {
          game.update(1 / fps);
          await game.ready();
          sawEndlessHazard |=
              game.spawnManager.groundHazards.isNotEmpty ||
              game.ground.gaps.isNotEmpty ||
              game.world.children.whereType<FallingStone>().isNotEmpty;
        }
        expect(game.state, GameState.playing);
        expect(game.runDistance, greaterThan(distance));
        expect(sawEndlessHazard, isTrue);
        game.exitToMenu();
      }
    },
  );

  test(
    'Journey pauses then retry enters ordinary play without retaining beats or rewards',
    () async {
      game.startGame(startingStage: 0, authoredDesert: true);
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
        await game.ready();
      }
      final distance = game.runDistance, beat = game.desertJourney.nextBeat;
      game.pauseGame();
      game.update(1);
      expect(game.runDistance, distance);
      expect(game.desertJourney.nextBeat, beat);
      game.resumeGame();
      game.update(1 / 60);
      expect(game.runDistance, greaterThan(distance));
      game.gameOver();
      expect(game.handleResultsTap(Vector2(204, 250)), isTrue);
      await game.ready();
      expect(game.state, GameState.playing);
      expect(game.desertJourney.active, isFalse);
      expect(game.coinManager.hasSeenTutorial, isTrue);
      expect(game.desertJourney.nextBeat, 0);
      expect(game.coinManager.runCoins, 0);
      expect(game.smashedObjects, 0);
      game.gameOver();
      expect(game.handleResultsTap(Vector2(320, 250)), isTrue);
      expect(game.state, GameState.menu);
      expect(game.desertJourney.active, isFalse);
      game.startGame(startingStage: 2, authoredDesert: false);
      expect(game.desertJourney.active, isFalse);
    },
  );

  test(
    'Smash bursts are bounded, expire, pause together and clear on reset',
    () {
      for (final material in HazardMaterial.values) {
        game.particlePool.emitSmash(Vector2(250, 250), material);
      }
      expect(game.particlePool.activeParticleCount, 85);
      game.pauseGame();
      game.update(.5);
      expect(game.particlePool.activeParticleCount, 85);
      game.resumeGame();
      for (var i = 0; i < 100; i++) {
        game.particlePool.emitSmash(Vector2(250, 250), HazardMaterial.stone);
      }
      expect(game.particlePool.activeParticleCount, ParticlePool.maxParticles);
      game.particlePool.update(1);
      expect(game.particlePool.activeParticleCount, 0);
      game.particlePool.emitStumble(Vector2(100, 250));
      game.startGame();
      expect(game.particlePool.activeParticleCount, 0);
    },
  );

  test(
    'Epoch gap artwork keeps the same terrain and eruption contact rules',
    () {
      for (var stage = 0; stage < 6; stage++) {
        game.biomeManager.currentStage = stage;
        game.ground.addGap(200, 160);
        game.ground.gaps.last.eruptionTimer = 1;
        final floor = game.ground.groundY;
        expect(game.ground.isOverGap(230, 40), isTrue);
        expect(game.ground.hitsLavaSprout(210, floor - 25, 40, 40), isTrue);
        expect(game.ground.hitsLavaSprout(210, floor - 240, 40, 40), isFalse);
        game.ground.clearGaps();
        expect(game.ground.isOverGap(230, 40), isFalse);
      }
    },
  );

  test('Menu reveal can finish its fade while a fresh run begins', () {
    game.overlays.add('MainMenuOverlay');
    game.startGame(keepMenuOverlay: true);
    expect(game.overlays.isActive('MainMenuOverlay'), isTrue);
    expect(game.state, GameState.playing);
    game.startGame();
    expect(game.overlays.isActive('MainMenuOverlay'), isFalse);
  });

  Future<RollingBall> ballAtPlayer() async {
    final ball = RollingBall(isIce: false);
    game.spawnManager.registerGroundHazard(ball);
    await game.ready();
    ball.position.setFrom(game.player.position + Vector2(15, 35));
    return ball;
  }

  test(
    'Cart spends once per object, preserves shield and safely dismounts',
    () async {
      game.player.collectCart();
      game.player.invincibleTimer = 2;
      game.player.shieldTimer = 8;
      final score = game.score;
      for (var hit = 0; hit < 3; hit++) {
        final pipe = Obstacle(type: ObstacleType.pipePair, speed: 200);
        game.spawnManager.registerGroundHazard(pipe);
        await game.ready();
        pipe.entranceTimer = 1;
        for (final shape in pipe.children.whereType<ShapeHitbox>()) {
          game.player.onCollision({}, shape);
          game.player.onCollision({}, shape);
        }
        expect(game.player.cart.charges, 2 - hit);
      }
      expect(game.player.lives, 3);
      expect(game.player.shieldTimer, 8);
      expect(game.score - score, 150);
      final fourth = await ballAtPlayer();
      game.player.invincibleTimer = 0;
      game.player.onCollision({}, fourth);
      expect(fourth.impactClaimed, isFalse);
      game.player.cart.update(.4);
      game.player.onCollision({}, fourth);
      expect(game.player.shieldTimer, 0);
      expect(game.player.lives, 3);
    },
  );

  test(
    'Cart pickup refreshes, giant and space park exact remaining charges',
    () async {
      game.player.collectCart();
      game.player.cart.spend();
      game.player.giantTimer = 10;
      game.player.activateGiant();
      expect(game.player.cartState, CartPowerState.parked);
      final ball = await ballAtPlayer();
      game.player.onCollision({}, ball);
      expect(game.player.cart.charges, 2);
      game.player.giantTimer = 0;
      game.player.isOnGround = true;
      game.player.update(1 / 120);
      expect(game.player.cartActive, isTrue);
      game.enterSpaceMode();
      expect(game.player.cartState, CartPowerState.parked);
      game.player.update(1 / 120);
      expect(game.player.cart.charges, 2);
      game.player.inSpaceMode = false;
      game.state = GameState.playing;
      game.player.isOnGround = false;
      game.player.update(1 / 120);
      expect(game.player.cartState, CartPowerState.parked);
      final pickup = Collectible(
        collectType: CollectibleType.cart,
        position: Vector2(400, 200),
      );
      await game.world.add(pickup);
      await game.ready();
      pickup.onCollect();
      pickup.onCollect();
      expect(game.player.cart.charges, 3);
      game.player.die();
      expect(game.player.cart.charges, 0);
      game.player.revive();
      expect(game.player.cartState, CartPowerState.none);
    },
  );

  test('Actual giant expiry and full space return restore the parked cart', () {
    game.player.collectCart();
    game.player.cart.spend();
    game.player.giantTimer = .05;
    game.player.activateGiant();
    for (var i = 0; i < 12; i++) {
      game.update(1 / 120);
    }
    expect(game.player.cartActive, isTrue);
    expect(game.player.cart.charges, 2);
    expect(game.player.scale.x, 1);
    game.enterSpaceMode();
    for (var i = 0; i < 2000 && game.state == GameState.spaceMode; i++) {
      game.update(1 / 120);
      if (game.state == GameState.spaceMode) {
        expect(game.player.cartState, CartPowerState.parked);
      }
    }
    game.update(1 / 60);
    expect(game.state, GameState.playing);
    expect(game.player.cartActive, isTrue);
    expect(game.player.cart.charges, 2);
  });

  test(
    'Cart dismount clock freezes on pause, jumping works, reset clears it',
    () {
      game.player.collectCart();
      game.player.jump();
      expect(game.player.velocityY, lessThan(0));
      game.player.cart.spend();
      game.player.cart.spend();
      game.player.cart.spend();
      game.pauseGame();
      game.update(.2);
      expect(game.player.cart.dismountRemaining, .35);
      game.resumeGame();
      game.update(.1);
      expect(game.player.cart.dismountRemaining, lessThan(.3));
      game.startGame();
      expect(game.player.cart.charges, 0);
      expect(game.player.cart.dismountRemaining, 0);
    },
  );

  test(
    'Cart terrain failure spends a heart and clears the vehicle, not a charge',
    () {
      game.player.collectCart();
      game.ground.addGap(game.player.position.x - 20, 200);
      game.ground.gaps.last.eruptionTimer = 1;
      game.player.update(1 / 120);
      expect(game.player.lives, 2);
      expect(game.player.cart.charges, 0);
      expect(game.player.cart.dismountRemaining, 0);
    },
  );

  test('Cart lane real contacts agree at 30/60/120 FPS', () async {
    for (final fps in [30, 60, 120]) {
      game.startGame();
      game.spawnManager.startCartLane();
      await game.ready();
      for (var i = 0; i < fps * 6; i++) {
        game.update(1 / fps);
        await game.ready();
      }
      expect(game.player.cart.charges, 0);
      expect(game.player.lives, 2);
      expect(game.spawnManager.groundHazards, isEmpty);
      expect(game.ground.gaps, hasLength(1));
    }
  });

  test(
    'Cart bumper smashes before the original body collider reaches a rock',
    () async {
      game.player.collectCart();
      final rock = Obstacle(type: ObstacleType.rock, speed: 200)
        ..size = Vector2(40, 30);
      game.spawnManager.registerGroundHazard(rock);
      await game.ready();
      rock.entranceTimer = 1;
      rock.position = game.player.position + Vector2(84, 63);
      final score = game.score;
      game.update(1 / 120);
      await game.ready();
      expect(game.player.cart.charges, 2);
      expect(game.score - score, closeTo(50, 1));
      expect(game.player.lives, 3);
      expect(rock.parent, isNull);
    },
  );

  test(
    'Surviving contact leaves jump input and airborne velocity responsive',
    () async {
      final ball = await ballAtPlayer();
      game.player.onCollision({ball.position.clone()}, ball);
      expect(game.player.lives, 2);
      expect(game.particlePool.activeParticleCount, 6);
      game.player.jump();
      expect(game.player.velocityY, lessThan(0));
      expect(game.player.isOnGround, isFalse);
      game.player.invincibleTimer = 0;
      final airBall = await ballAtPlayer();
      final velocity = game.player.velocityY;
      game.player.onCollision({airBall.position.clone()}, airBall);
      expect(game.player.lives, 1);
      expect(game.player.velocityY, velocity);
    },
  );

  test(
    'Actual collision collects once during damage and space-return immunity',
    () async {
      for (final type in [
        CollectibleType.coin,
        CollectibleType.doubleCoin,
        CollectibleType.shield,
        CollectibleType.magnet,
      ]) {
        game.player.invincibleTimer = 3;
        final coin = Collectible(
          collectType: type,
          position: game.player.position + Vector2(15, 35),
        );
        await game.world.add(coin);
        await game.ready();
        game.update(1 / 60);
        expect(
          coin.parent,
          isNull,
          reason: 'pickup $type: balance=${game.coinManager.coins}',
        );
        expect(game.player.lives, 3);
      }
      expect(game.coinManager.collectedCoins, 3);
      expect(game.coinManager.runCoins, 3);
      expect(game.player.shieldTimer, greaterThan(7));
      expect(game.player.magnetTimer, greaterThan(7));
    },
  );

  test(
    'Damage, shield absorption, recovery and giant crush assert real outcomes',
    () async {
      await ballAtPlayer();
      game.update(1 / 60);
      expect(game.player.lives, 2);
      await ballAtPlayer();
      game.update(1 / 60);
      expect(game.player.lives, 2);
      game.hitStopTimer = 0;
      game.player.invincibleTimer = 0;
      game.player.shieldTimer = 8;
      await ballAtPlayer();
      game.update(1 / 60);
      expect(game.player.lives, 2);
      expect(game.player.shieldTimer, 0);
      expect(game.coinManager.shieldHits, 1);
      game.hitStopTimer = 0;
      game.player.invincibleTimer = 0;
      game.player.giantTimer = 10;
      final ball = await ballAtPlayer();
      game.update(1 / 60);
      expect(game.player.lives, 2);
      expect(ball.parent, isNull);
    },
  );

  test(
    'A multi-hitbox hazard smashes once during giant recovery and preserves shield',
    () async {
      final pipe = Obstacle(type: ObstacleType.pipePair, speed: 200);
      game.spawnManager.registerGroundHazard(pipe);
      await game.ready();
      pipe.entranceTimer = 1;
      final shapes = pipe.children.whereType<ShapeHitbox>().toList();
      expect(shapes, hasLength(2));
      expect(pipe.impactMaterial, HazardMaterial.stone);
      expect(HazardContactResolver.ownerOf(shapes.first), same(pipe));
      game.player.giantTimer = 10;
      game.player.invincibleTimer = 3;
      game.player.shieldTimer = 8;
      final score = game.score;
      for (final shape in [...shapes, ...shapes]) {
        game.player.onCollision({}, shape);
      }
      expect(game.score - score, 50);
      expect(game.player.lives, 3);
      expect(game.player.shieldTimer, 8);
      expect(game.coinManager.shieldHits, 0);
      expect(pipe.impactClaimed, isTrue);
      expect(
        shapes.every((shape) => shape.collisionType == CollisionType.inactive),
        isTrue,
      );
      await game.ready();
      expect(pipe.parent, isNull);
    },
  );

  test(
    'Recovery does not spend shield or claim an untouched hazard; normal contact claims once',
    () async {
      final rock = Obstacle(type: ObstacleType.rock, speed: 200);
      game.spawnManager.registerGroundHazard(rock);
      await game.ready();
      rock.entranceTimer = 1;
      game.player.shieldTimer = 8;
      game.player.invincibleTimer = 2;
      game.player.onCollision({}, rock);
      expect(rock.impactClaimed, isFalse);
      expect(game.player.shieldTimer, 8);
      game.player.invincibleTimer = 0;
      game.player.onCollision({}, rock);
      game.player.onCollision({}, rock);
      expect(game.player.lives, 3);
      expect(game.player.shieldTimer, 0);
      expect(game.coinManager.shieldHits, 1);
      expect(rock.impactClaimed, isTrue);
    },
  );

  test(
    'Paused and entrance contacts stay unclaimed; sibling falling rocks own separate impacts',
    () async {
      final cluster = FallingStone(
        initialSpeedX: 200,
        stoneCount: 2,
        random: Random(1),
      );
      game.spawnManager.registerGroundHazard(cluster);
      await game.ready();
      final rocks = cluster.children.whereType<FallingRock>().toList();
      game.player.giantTimer = 10;
      game.player.onCollision({}, rocks.first.hurtbox);
      expect(rocks.first.impactClaimed, isFalse);
      rocks.first.phase = RockPhase.falling;
      game.state = GameState.paused;
      game.player.onCollision({}, rocks.first.hurtbox);
      expect(rocks.first.impactClaimed, isFalse);
      game.state = GameState.playing;
      final score = game.score;
      game.player.onCollision({}, rocks.first.hurtbox);
      game.player.onCollision({}, rocks.first);
      expect(game.score - score, 50);
      expect(rocks.last.impactClaimed, isFalse);
      expect(rocks.last.parent, same(cluster));
    },
  );

  test(
    'Real giant collisions score once at 30, 60 and 120 updates during immunity',
    () async {
      for (final fps in [30, 60, 120]) {
        game.player.giantTimer = 10;
        game.player.invincibleTimer = 2;
        game.hitStopTimer = 0;
        final score = game.score;
        final ball = await ballAtPlayer();
        game.update(1 / fps);
        expect(game.score - score, closeTo(50, 1), reason: 'score at $fps');
        await game.ready();
        expect(ball.parent, isNull);
        expect(game.player.lives, 3);
      }
      game.startGame();
      game.spawnManager.obstacleTimer = 999;
      game.spawnManager.coinTimer = 999;
      expect(game.player.giantTimer, 0);
      expect(game.player.invincibleTimer, 0);
      final fresh = await ballAtPlayer();
      expect(fresh.impactClaimed, isFalse);
      game.update(1 / 60);
      expect(game.player.lives, 2);
    },
  );

  test(
    'Meteor impact stays ahead at both speeds and leaves one scrolling crater',
    () async {
      for (final speed in [200.0, 450.0]) {
        game.speedManager.currentSpeed = speed;
        final cluster = FallingStone(initialSpeedX: speed, random: Random(2));
        game.spawnManager.registerGroundHazard(cluster);
        await game.ready();
        final initialX = cluster.position.x;
        expect(
          initialX,
          greaterThan(game.player.position.x + game.player.size.x),
        );
        final rock = cluster.children.whereType<FallingRock>().single;
        for (var i = 0; i < 240 && rock.phase != RockPhase.landed; i++) {
          rock.update(1 / 120);
          expect(cluster.position.x, closeTo(initialX, 0.001));
        }
        await game.ready();
        expect(rock.phase, RockPhase.landed);
        expect(cluster.children.whereType<ImpactCrater>(), hasLength(1));
        game.state = GameState.paused;
        cluster.update(.2);
        expect(cluster.position.x, initialX);
        game.state = GameState.playing;
        cluster.update(.1);
        expect(cluster.position.x, closeTo(initialX - speed * .1, .001));
        expect(cluster.children.whereType<ImpactCrater>(), hasLength(1));
        cluster.removeFromParent();
        await game.ready();
      }
    },
  );

  test(
    'Each falling stone owns a moving collider; empty cluster space is safe',
    () async {
      final cluster = FallingStone(
        initialSpeedX: 200,
        stoneCount: 2,
        random: Random(1),
      );
      game.spawnManager.registerGroundHazard(cluster);
      await game.ready();
      expect(cluster.children.whereType<ShapeHitbox>(), isEmpty);
      final rocks = cluster.children.whereType<FallingRock>().toList();
      expect(rocks, hasLength(2));
      cluster.position.x = 80;
      game.update(.2);
      expect(game.player.lives, 3);
      final rock = rocks.first;
      expect(rock.phase, RockPhase.warning);
      expect(rock.hurtbox.collisionType, CollisionType.inactive);
      game.update(.7);
      expect(rock.phase, RockPhase.falling);
      expect(rock.position.y, greaterThan(-rock.diameter));
      expect(
        rock.hurtbox.absolutePosition.y,
        closeTo(rock.absolutePosition.y + rock.diameter * .14, .01),
      );
      cluster.position.x = game.player.position.x;
      rock.position.setValues(10, game.player.position.y + 25);
      game.update(1 / 60);
      expect(game.player.lives, 2);
      expect(rocks.last.isRemoving, isFalse);
    },
  );

  test(
    'Every space phase pauses by touch and keeps its timer and physics frozen',
    () {
      for (final phase in [
        SpacePhase.launch,
        SpacePhase.coinRain,
        SpacePhase.returning,
      ]) {
        game.state = GameState.spaceMode;
        game.spacePhase = phase;
        game.spacePhaseTimer = 1;
        final position = game.player.position.clone();
        expect(game.tryPauseAt(Vector2(320, 30)), isTrue);
        game.update(.5);
        expect(game.spacePhaseTimer, 1);
        expect(game.player.position, position);
        game.resumeGame();
        expect(game.state, GameState.spaceMode);
        expect(game.spacePhase, phase);
      }
    },
  );

  test(
    'Rolling hazards clear on launch, revive, restart and menu exit',
    () async {
      for (final action in [
        game.enterSpaceMode,
        game.reviveGame,
        game.startGame,
        game.exitToMenu,
      ]) {
        final ball = await ballAtPlayer();
        action();
        await game.ready();
        expect(game.spawnManager.groundHazards, isEmpty);
        expect(ball.parent, isNull);
      }
      expect(game.spacePhase, SpacePhase.none);
      expect(game.player.inSpaceMode, isFalse);
    },
  );

  test(
    'Space trails stay bounded, passive, collectable and clear on return',
    () async {
      for (final speed in [200.0, 450.0]) {
        game.enterSpaceMode();
        game.spawnManager.coinTimer = 0;
        game.speedManager.currentSpeed = speed;
        var peak = 0;
        for (var frame = 0; frame < 880; frame++) {
          game.player.isThrusting = (frame % 90) < 45;
          game.update(1 / 60);
          if (frame % 15 == 0) await game.ready();
          final pickups = game.world.children.whereType<Collectible>().toList();
          peak = max(peak, pickups.length);
          expect(
            pickups.length,
            lessThanOrEqualTo(SpawnManager.maxSpacePickups),
          );
          for (final pickup in pickups) {
            for (final hitbox in pickup.children.whereType<ShapeHitbox>()) {
              expect(hitbox.collisionType, CollisionType.passive);
            }
          }
        }
        expect(
          peak,
          greaterThan(12),
          reason: 'Keep rewarding coin trails at $speed',
        );
        expect(game.world.children.whereType<Collectible>(), isEmpty);
        game.spawnManager.obstacleTimer = 999;
        game.spawnManager.coinTimer = 999;
        game.update(.2);
        expect(game.state, GameState.playing);
        expect(game.player.inSpaceMode, isFalse);
        expect(game.player.lives, 3);
      }
    },
  );

  test(
    'Hit stop freezes hazard schedule, distance and power duration together',
    () async {
      final ball = await ballAtPlayer();
      ball.position.x = 500;
      final x = ball.position.x;
      game.player.shieldTimer = 8;
      game.triggerHitStop();
      final timer = game.spawnManager.obstacleTimer;
      game.update(.05);
      expect(ball.position.x, x);
      expect(game.spawnManager.obstacleTimer, timer);
      expect(game.player.shieldTimer, 8);
      expect(game.runDistance, 0);
    },
  );

  test(
    'Immunity rescues a gap fall and giant changes preserve floor contact',
    () {
      final player = game.player;
      player.activateGiant();
      expect(
        player.position.y + player.size.y * player.scale.y,
        closeTo(game.ground.groundY, .001),
      );
      player.giantTimer = .01;
      game.update(.02);
      expect(player.scale.x, 1);
      expect(
        player.position.y + player.size.y,
        closeTo(game.ground.groundY, .1),
      );
      game.ground.addGap(60, 300);
      player.invincibleTimer = 3;
      game.update(.4);
      expect(player.lives, 3);
      expect(player.velocityY, lessThan(0));
      expect(player.position.y, lessThan(game.ground.groundY));
    },
  );

  test(
    'Viewport mapping preserves logical physics at every landscape size',
    () {
      for (final dimensions in [
        Vector2(568, 320),
        Vector2(844, 390),
        Vector2(1280, 800),
      ]) {
        game.onGameResize(dimensions);
        expect(game.size, Vector2(640, 360));
        final canvas = game.camera.viewport.localToGlobal(Vector2(320, 30));
        expect(
          game.canvasToPlayfield(canvas).distanceTo(Vector2(320, 30)),
          lessThan(.001),
        );
      }
    },
  );

  test(
    'Game over flushes earned rewards and stats before a fresh manager reload',
    () async {
      game.coinManager.collectCoins(7);
      game.score = 800;
      game.gameOver();
      await game.coinManager.forceSave();
      final restored = CoinManager();
      await restored.load();
      expect(restored.coins, 7);
      expect(restored.collectedCoins, 7);
      expect(restored.highScore, 800);
    },
  );

  test(
    'Production jump and progression agree at 30/60/120 FPS and long frames',
    () {
      final samples = <List<double>>[];
      for (final fps in [30, 60, 120]) {
        game.startGame();
        game.spawnManager.obstacleTimer = 999;
        game.spawnManager.coinTimer = 999;
        game.player.jump();
        for (var i = 0; i < fps; i++) {
          game.update(1 / fps);
        }
        samples.add([
          game.player.position.y,
          game.player.velocityY,
          game.runDistance,
          game.speedManager.currentSpeed,
        ]);
      }
      game.startGame();
      game.spawnManager.obstacleTimer = 999;
      game.spawnManager.coinTimer = 999;
      game.player.jump();
      for (var i = 0; i < 5; i++) {
        game.update(.2);
      }
      samples.add([
        game.player.position.y,
        game.player.velocityY,
        game.runDistance,
        game.speedManager.currentSpeed,
      ]);
      for (final sample in samples.skip(1)) {
        for (var i = 0; i < sample.length; i++) {
          expect(sample[i], closeTo(samples.first[i], .0001));
        }
      }
      final speed = game.speedManager.currentSpeed;
      game.score += 10000;
      game.update(1 / 120);
      expect(game.speedManager.currentSpeed - speed, lessThan(.1));
      expect(game.biomeManager.currentStage, 0);
    },
  );
}
