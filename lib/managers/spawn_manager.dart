import 'dart:math' as math;
import 'package:flame/components.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
// SpacePhase is exported from dino_game.dart
import '../components/obstacle.dart';
import '../components/collectible.dart';
import '../components/meteor.dart';
import '../components/falling_stone.dart';
import '../components/rolling_ball.dart';

class SpawnManager extends Component with HasGameReference<DinoGame> {
  double obstacleTimer = 0;
  double coinTimer = 0;
  double meteorTimer = 0;
  int _spacePatternIndex = 0;
  final math.Random _rng = math.Random();

  final List<Obstacle> _obstacles = [];
  final List<Collectible> _coins = [];
  final List<Meteor> _meteors = [];
  final List<FallingStone> _fallingStones = [];
  CollectibleType? _lastPowerupType;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state == GameState.playing) {
      _updateGroundSpawning(dt);
    } else if (game.state == GameState.spaceMode) {
      _updateMeteorSpawning(dt);
    }

    // Clean up removed entities
    _obstacles.removeWhere((o) => o.isRemoved);
    _coins.removeWhere((c) => c.isRemoved);
    _meteors.removeWhere((m) => m.isRemoved);
    _fallingStones.removeWhere((f) => f.isRemoved);
  }

  void _updateGroundSpawning(double dt) {
    obstacleTimer -= dt;
    if (obstacleTimer <= 0) {
      if (_isTooCloseToExistingObstacle()) {
        obstacleTimer = 0.2; // delay until existing obstacle moves further left
        return;
      }

      final currentBiomeName = game.biomeManager.current.name;
      final r = _rng.nextDouble();

      if (currentBiomeName == 'DESERT' && r < 0.25) {
        _spawnRollingBall(isIce: false);
        obstacleTimer = 2.0 + _rng.nextDouble() * 1.0;
      } else if (currentBiomeName == 'ICE' && r < 0.25) {
        _spawnRollingBall(isIce: true);
        obstacleTimer = 2.0 + _rng.nextDouble() * 1.0;
      } else if (game.score > 300 && r < 0.18) {
        _spawnGap();
        obstacleTimer = 2.0 + _rng.nextDouble() * 1.1;
      } else if (game.score > 800 && r < 0.30) {
        _spawnFallingStone();
        obstacleTimer = 2.0 + _rng.nextDouble() * 1.1;
      } else {
        _spawnObstacle();
        obstacleTimer = 1.6 + _rng.nextDouble() * 1.0;
      }
    }

    coinTimer -= dt;
    if (coinTimer <= 0) {
      _spawnCollectible();
      coinTimer = 1.6 + _rng.nextDouble() * 1.6;
    }
  }

  bool _isTooCloseToExistingObstacle() {
    final screenRight = game.size.x;
    const minDistance = 255.0; // Increased obstacle distance by ~6% for better spacing

    for (final obs in _obstacles) {
      if (obs.position.x + obs.size.x > screenRight - minDistance) {
        return true;
      }
    }
    for (final stone in _fallingStones) {
      if (stone.position.x + stone.size.x > screenRight - minDistance) {
        return true;
      }
    }
    for (final gap in game.ground.gaps) {
      if (gap.x + gap.width > screenRight - minDistance) {
        return true;
      }
    }
    return false;
  }

  void _updateMeteorSpawning(double dt) {
    // Only spawn coins during the coin rain phase, and stop spawning 2.5s before timer ends!
    if (game.spacePhase != SpacePhase.coinRain) return;
    if (game.spaceTimer <= 2.5) return; // Coins stop spawning 2.5s before timer finishes

    coinTimer -= dt;
    if (coinTimer <= 0) {
      _spawnSpaceCoinsFilled();
      coinTimer = 0.4; // Rapid spawning so space is filled with coins
    }
  }

  void _spawnSpaceCoinsFilled() {
    double startX = game.size.x + 30;
    _spacePatternIndex = (_spacePatternIndex + 1) % 4;

    switch (_spacePatternIndex) {
      case 0:
        // 2 parallel lines of 6 coins
        double y1 = 80 + _rng.nextDouble() * 100;
        double y2 = y1 + 100;
        for (int i = 0; i < 6; i++) {
          final coin1 = Collectible(collectType: CollectibleType.coin, position: Vector2(startX + i * 40, y1));
          final coin2 = Collectible(collectType: CollectibleType.coin, position: Vector2(startX + i * 40, y2));
          game.add(coin1); _coins.add(coin1);
          game.add(coin2); _coins.add(coin2);
        }
        break;

      case 1:
        // Wave trail of 8 coins
        double baseY = 150 + _rng.nextDouble() * (game.size.y - 300);
        for (int i = 0; i < 8; i++) {
          double wy = baseY + math.sin(i * 0.6) * 60;
          final coin = Collectible(collectType: CollectibleType.coin, position: Vector2(startX + i * 38, wy));
          game.add(coin); _coins.add(coin);
        }
        break;

      case 2:
        // 3x3 grid of coins with a powerup in the middle
        double gridY = 100 + _rng.nextDouble() * (game.size.y - 250);
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            final type = (row == 1 && col == 1) ? CollectibleType.magnet : CollectibleType.coin;
            final coin = Collectible(collectType: type, position: Vector2(startX + col * 42, gridY + row * 42));
            game.add(coin); _coins.add(coin);
          }
        }
        break;

      case 3:
        // Arch of 7 coins
        double archCenterY = 120 + _rng.nextDouble() * (game.size.y - 240);
        for (int i = 0; i < 7; i++) {
          double dy = math.sin((i / 6.0) * math.pi) * -70;
          final coin = Collectible(collectType: CollectibleType.coin, position: Vector2(startX + i * 40, archCenterY + dy));
          game.add(coin); _coins.add(coin);
        }
        break;
    }
  }

  void _spawnObstacle() {
    final currentBiome = game.biomeManager.effectiveBiome.name;
    final List<ObstacleType> types = [];

    switch (currentBiome) {
      case 'DESERT':
        types.addAll([
          ObstacleType.cactusSmall,
          ObstacleType.cactusTall,
          ObstacleType.rock,
          ObstacleType.bush,
          ObstacleType.pillar,
        ]);
        break;
      case 'VOLCANO':
        types.addAll([
          ObstacleType.lavaPit,
          ObstacleType.rock,
          ObstacleType.pillar,
        ]);
        break;
      case 'ICE':
        types.addAll([
          ObstacleType.rock,
          ObstacleType.pillar,
        ]);
        break;
      case 'FOREST':
      case 'RAIN':
        types.addAll([
          ObstacleType.bush,
          ObstacleType.rock,
          ObstacleType.pillar,
        ]);
        break;
      case 'SPACE':
        types.addAll([
          ObstacleType.pillar,
          ObstacleType.rock,
        ]);
        break;
      default:
        types.addAll([
          ObstacleType.cactusSmall,
          ObstacleType.cactusTall,
          ObstacleType.rock,
          ObstacleType.bush,
          ObstacleType.pillar,
        ]);
    }

    if (game.score > 250) {
      types.add(ObstacleType.pipePair);
    }
    if (game.score > 1000) {
      types.add(ObstacleType.bird);
    }
    
    final type = types[_rng.nextInt(types.length)];
    
    int count = 1;
    if (game.score > 500 && (type == ObstacleType.cactusSmall || type == ObstacleType.cactusTall)) {
       final r = _rng.nextDouble();
       if (r < 0.25) {
         count = 2; // Capped to max 2 cacti so hurdle width is jumpable
       }
    }

    final groundY = game.ground.groundY;

    for (int i = 0; i < count; i++) {
      final obs = Obstacle(type: type, speed: game.speedManager.currentSpeed);
      double offsetX = game.size.x + 20 + i * 26.0;

      switch (type) {
        case ObstacleType.cactusSmall:
        case ObstacleType.cactusTall:
        case ObstacleType.rock:
        case ObstacleType.bush:
        case ObstacleType.lavaPit:
          // SIT EXACTLY ON GROUND LINE flush
          obs.position = Vector2(offsetX, groundY - obs.size.y);
          break;
        case ObstacleType.pillar:
          // Drops down rapidly from high in the sky!
          obs.isFallingFromSky = true;
          obs.targetGroundY = groundY - obs.size.y;
          obs.position = Vector2(offsetX, -obs.size.y - 120.0);
          break;
        case ObstacleType.ceilingPipe:
          // Hanging pipe extending down from top edge of screen (y = 0)
          final clearanceGap = 105.0 + _rng.nextDouble() * 35.0; // 105-140px clearance gap above ground
          obs.size = Vector2(obs.size.x, groundY - clearanceGap);
          obs.position = Vector2(offsetX, 0);
          break;
        case ObstacleType.pipePair:
          final fullHeight = groundY;
          obs.size = Vector2(65, fullHeight);
          obs.position = Vector2(offsetX, 0);

          // Generous 175px vertical opening positioned right at Dino's jump height!
          final gapHeight = 175.0;
          // Target bottom pipe lip at jumpable height (110px - 150px above ground)
          final targetBottomY = fullHeight - (110.0 + _rng.nextDouble() * 40.0);
          obs.gapBottomY = targetBottomY;
          obs.gapTopY = math.max(25.0, obs.gapBottomY - gapHeight);
          break;
        case ObstacleType.bird:
          obs.position = Vector2(offsetX, groundY - 100 - _rng.nextDouble() * 60);
          break;
      }

      // Remove any existing coin that overlaps this newly spawned obstacle!
      for (final coin in List<Collectible>.from(_coins)) {
        if (coin.position.x >= offsetX - 50 && coin.position.x <= offsetX + obs.size.x + 50) {
          final coinRect = coin.toRect();
          final obsRect = obs.toRect();
          if (coinRect.overlaps(obsRect.inflate(15))) {
            coin.removeFromParent();
            _coins.remove(coin);
          }
        }
      }

      game.add(obs);
      _obstacles.add(obs);
    }
  }


  void _spawnFallingStone() {
    final count = 3 + _rng.nextInt(2);
    final stone = FallingStone(
      initialSpeedX: game.speedManager.currentSpeed,
      stoneCount: count,
    );
    game.add(stone);
    _fallingStones.add(stone);
  }

  void _spawnRollingBall({required bool isIce}) {
    final ball = RollingBall(isIce: isIce, rollSpeed: 240.0 + _rng.nextDouble() * 60.0);
    game.add(ball);
  }

  void _spawnCollectible() {
    final roll = _rng.nextDouble();
    double startX = game.size.x + 40;

    // Check if startX collides with any gaps, obstacles, or stones.
    // Use a wider scan window to cover the full coin-group width (~120px).
    bool positionValid = false;
    int attempts = 0;
    while (!positionValid && attempts < 10) {
      attempts++;
      positionValid = true;

      // Check gaps
      for (final gap in game.ground.gaps) {
        if (startX >= gap.x - 80 && startX <= gap.x + gap.width + 140) {
          startX = gap.x + gap.width + 160;
          positionValid = false;
          break;
        }
      }
      if (!positionValid) continue;

      // Check obstacles — scan range covers startX to startX + 130
      for (final obs in _obstacles) {
        final obsLeft = obs.position.x - 60;
        final obsRight = obs.position.x + obs.size.x + 60;
        if (startX + 130 > obsLeft && startX < obsRight) {
          startX = obsRight + 70;
          positionValid = false;
          break;
        }
      }
      if (!positionValid) continue;

      // Check falling stones
      for (final stone in _fallingStones) {
        final sLeft = stone.position.x - 40;
        final sRight = stone.position.x + stone.size.x + 40;
        if (startX + 120 > sLeft && startX < sRight) {
          startX = sRight + 60;
          positionValid = false;
          break;
        }
      }
    }

    final groundY = game.ground.groundY;

    final coinType = (game.score >= 10000) ? CollectibleType.doubleCoin : CollectibleType.coin;

    if (roll < 0.70) {
      // Spawn a group of 3 coins in a gentle arc or flat line, close to ground.
      final isArch = _rng.nextBool();
      for (int i = 0; i < 3; i++) {
        double cx = startX + i * 36;
        double cy;
        if (isArch) {
          // Low jump arc — peak at ~70px above ground, edges at ~35px
          cy = groundY - 35 - math.sin((i / 2.0) * math.pi) * 35;
        } else {
          // Flat line 30-55px above ground — easy to grab while running/jumping
          cy = groundY - 30 - _rng.nextDouble() * 25;
        }
        final coin = Collectible(collectType: coinType, position: Vector2(cx, cy));
        game.add(coin);
        _coins.add(coin);
      }
    } else {
      // Spawn a single powerup or prehistoric dino egg cleanly away from obstacles
      final availablePowerups = [
        CollectibleType.shield,
        CollectibleType.magnet,
        CollectibleType.giant,
        CollectibleType.gravity,
        CollectibleType.dinoEgg,
      ];
      if (_lastPowerupType != null && availablePowerups.length > 1) {
        availablePowerups.remove(_lastPowerupType);
      }

      final type = availablePowerups[_rng.nextInt(availablePowerups.length)];
      _lastPowerupType = type;

      // Powerups 40-70px above ground — visible & reachable on a normal jump
      final pos = Vector2(startX, groundY - 40 - _rng.nextDouble() * 30);
      final item = Collectible(collectType: type, position: pos);
      game.add(item);
      _coins.add(item);
    }
  }

  void _spawnGap() {
    final width = 180 + _rng.nextDouble() * 70;
    game.ground.addGap(game.size.x + 20, width);
  }

  void clearGroundEntities() {
    for (final o in _obstacles) {
      o.removeFromParent();
    }
    for (final c in _coins) {
      c.removeFromParent();
    }
    for (final f in _fallingStones) {
      f.removeFromParent();
    }
    _obstacles.clear();
    _coins.clear();
    _fallingStones.clear();
    game.ground.clearGaps();
  }

  void resumeGroundSpawning() {
    obstacleTimer = 1.5;
    coinTimer = 0.8;
  }

  void reset() {
    clearGroundEntities();
    for (final m in _meteors) {
      m.removeFromParent();
    }
    _meteors.clear();
    obstacleTimer = 1.8;
    coinTimer = 1.0;
    meteorTimer = 0;
    _spacePatternIndex = 0;
  }
}
