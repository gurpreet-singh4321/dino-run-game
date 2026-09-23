import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../skins/skin.dart';
import '../skins/skin_registry.dart';
import '../managers/audio_manager.dart';

import 'obstacle.dart';
import 'falling_stone.dart';
import 'collectible.dart';
import 'rolling_ball.dart';

class _TrailEntry {
  double dx = 0;
  double dy = 0;
  double scaleX = 1.0;
  double scaleY = 1.0;
  double lean = 0.0;
  double age = 0.0;
  int frame = 0;
  bool isFalling = false;
  bool isOnGround = true;
  bool active = false;
}

class Player extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  static const double gravity = 800;
  static const double jumpForce = -480;
  static final math.Random _rng = math.Random();

  double velocityY = 0;
  int jumpsLeft = 2;
  bool isOnGround = true;
  int lives = 3;

  // Powerups
  double shieldTimer = 0;
  double magnetTimer = 0;
  double invincibleTimer = 0;
  double giantTimer = 0;

  // Space mode
  bool inSpaceMode = false;
  bool isThrusting = false;
  bool movingLeft = false;
  bool movingRight = false;
  double targetX = 0;

  // Jump Juice Mechanics
  bool _jumpCutApplied = false;
  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double squashX = 1.0;
  double squashY = 1.0;
  double _prevVelocityY = 0;
  double _jumpTime = 0;
  bool _isJumpReleased = false;

  // Animation
  int _animFrame = 0;
  double _animTimer = 0;
  double _totalElapsed = 0;
  double _footstepTimer = 0;
  static const double _animSpeed = 0.12; // 100ms per frame

  // Visual Polish
  double _currentLean = 0.0;
  final List<_TrailEntry> _trail = List.generate(3, (_) => _TrailEntry());
  int _trailHead = 0;
  double _trailTimer = 0;

  static final List<Paint> _shadowPaints = List.generate(8, (i) {
    final alpha = 0.1 + 0.2 * (i / 7.0);
    return Paint()..shader = ui.Gradient.radial(
      Offset.zero, 
      48.0, 
      [Colors.black.withValues(alpha: alpha), Colors.transparent], 
      const [0.2, 1.0]
    );
  });
  static final Paint _magnetRingPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _magnetFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _magnetHaloBack = Paint()..style = PaintingStyle.stroke..strokeWidth = 4.0;
  static final Paint _magnetHaloFront = Paint()..style = PaintingStyle.stroke..strokeWidth = 4.5;
  static final Paint _magnetRingBack = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4;
  static final Paint _magnetRingFront = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.8;
  static final Paint _sparklePaint = Paint()..color = Colors.white;
  static final Paint _sparkleGlowPaint = Paint()..color = const Color(0xFF00E5FF);
  
  static final Paint _giantAuraPaint = Paint();
  static final Paint _giantStrokePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
  
  static final Paint _invincibleAuraPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5;
  static final Paint _invincibleGlowPaint = Paint();
  
  static final Paint _shieldSheenPaint = Paint();
  static final Paint _shieldDotPaint = Paint();
  
  static final Paint _plasterPaint = Paint()..color = const Color(0xFFFF80AB);
  static final Paint _trailPaint = Paint();

  // Skin system
  late CharacterSkin skin;

  void setSkin(CharacterSkin newSkin) {
    if (!SkinRegistry.isAvailable(newSkin.id)) return;
    skin = newSkin;
    skin.resetMotion();
    game.coinManager.setActiveSkin(newSkin.id);
  }

  @override
  Future<void> onLoad() async {
    skin = SkinRegistry.getById(game.coinManager.activeSkinId);
    size = Vector2(80, 96); // Bigger dino size!
    _resetPosition();
    add(RectangleHitbox(size: size * 0.75, position: size * 0.125));
    priority = 10;
  }

  void revive() {
    isDead = false;
    deathTimer = 0;
    deathAngle = 0;
    lives = 3; // Back to 3 full lives!
    invincibleTimer = 3.0; // 3 seconds invincibility shield!
    shieldTimer = 0;
    magnetTimer = 0;
    giantTimer = 0;
    _resetPosition();
    game.particlePool.emitCuteDeath(position + Vector2(size.x / 2, size.y / 2));
    game.particlePool.emitShieldBreak(position + Vector2(size.x / 2, size.y / 2));
  }

  void _resetPosition() {
    position = Vector2(80, game.ground.groundY - size.y * scale.y);
    velocityY = 0;
    isOnGround = true;
    jumpsLeft = 2;
    targetX = position.x;
  }

  // Death animation
  bool isDead = false;
  double deathTimer = 0;
  double deathAngle = 0;

  void die() {
    if (isDead) return;
    isDead = true;
    deathTimer = 0;
    deathAngle = 0;
    velocityY = -360; // Pop upward into the air
    HapticFeedback.heavyImpact();

    // Emit cute poof explosion of pink hearts, yellow stars, dust & sparkles!
    game.particlePool.emitCuteDeath(position + Vector2(size.x / 2, size.y / 2));
    game.particlePool.emitShieldBreak(position + Vector2(size.x / 2, size.y / 2));
    game.particlePool.emitJumpDust(position + Vector2(size.x / 2, size.y / 2));
    game.particlePool.emitNearMiss(position + Vector2(size.x / 2, size.y / 2));
    AudioManager.playGameOverBgm();
    game.triggerShake(duration: 0.5, intensity: 6.0);
  }

  @override
  void update(double dt) {
    dt *= game.globalTimeScale;
    super.update(dt);
    _totalElapsed += dt;
    
    if (isDead) {
      deathTimer += dt;
      deathAngle += 7.0 * dt;
      velocityY += 1100 * dt; // Fall with gravity
      position.y += velocityY * dt;

      if (deathTimer >= 0.85 && game.state != GameState.gameOver) {
        game.gameOver();
      }
      return;
    }


    // Animation timer (Freeze animation cycles in space mode and mid-air!)
    if (game.state == GameState.playing && isOnGround) {
      _animTimer += dt;
      if (_animTimer >= _animSpeed) {
        _animTimer -= _animSpeed;
        _animFrame = (_animFrame + 1) % 4;
      }
    } else {
      _animFrame = 0; // Frozen aerodynamic gliding/flight pose
    }

    if (game.state == GameState.playing) {
      _updateGroundPhysics(dt);
    } else if (game.state == GameState.spaceMode) {
      _updateSpacePhysics(dt);
    }

    skin.advanceMotion(dt, speed: game.speedManager.currentSpeed,
      velocityY: velocityY, grounded: isOnGround,
      idle: game.state == GameState.menu,
      space: inSpaceMode, characterWidth: size.x * scale.x);

    // Powerup timers
    if (shieldTimer > 0) shieldTimer -= dt;
    if (magnetTimer > 0) magnetTimer -= dt;
    if (invincibleTimer > 0) invincibleTimer -= dt;
    if (giantTimer > 0) {
      giantTimer -= dt;
      if (giantTimer <= 0) {
        scale = Vector2.all(1.0);
      }
    }

    // Jump Juice Timers & Squash
    if (_coyoteTimer > 0) {
      _coyoteTimer -= dt;
      if (_coyoteTimer <= 0 && jumpsLeft == 2) {
        jumpsLeft = 1;
      }
    }
    if (_jumpBufferTimer > 0) _jumpBufferTimer -= dt;

    squashX += (1.0 - squashX) * 15 * dt;
    squashY += (1.0 - squashY) * 15 * dt;

    // Visual Polish: Lean
    if (!inSpaceMode && !isDead) {
      final speedFactor = (game.speedManager.currentSpeed / 1200.0).clamp(0.0, 1.0);
      _currentLean = speedFactor * 0.10;
      if (!isOnGround) {
        if (velocityY < 0) {
          _currentLean += 0.08;
        } else {
          _currentLean -= 0.12;
        }
      }
    } else {
      _currentLean = 0.0;
    }

    // Visual Polish: Trail
    for (var e in _trail) {
      if (e.active) {
        e.age += dt;
        if (e.age > 0.25) e.active = false;
      }
    }

    final isHighSpeed = (game.speedManager.currentSpeed / game.speedManager.maxSpeed) > 0.7;
    final hasPowerup = invincibleTimer > 0 || giantTimer > 0 || shieldTimer > 0;
    
    if (!isDead && !inSpaceMode && (isHighSpeed || hasPowerup)) {
      _trailTimer += dt;
      if (_trailTimer >= 0.04) {
        _trailTimer = 0;
        final entry = _trail[_trailHead];
        entry.dx = position.x;
        entry.dy = position.y;
        entry.scaleX = squashX;
        entry.scaleY = squashY;
        entry.lean = _currentLean;
        entry.frame = _animFrame;
        entry.isFalling = velocityY > 0;
        entry.isOnGround = isOnGround;
        entry.age = 0;
        entry.active = true;
        _trailHead = (_trailHead + 1) % 3; // Reduce to 3 entries
      }
    } else {
      for (var e in _trail) {
        e.active = false;
      }
    }
    
    _jumpTime += dt;
    
    if (_isJumpReleased && !_jumpCutApplied && velocityY < 0 && !inSpaceMode) {
      if (_jumpTime >= 0.09) {
        velocityY *= 0.6;
        _jumpCutApplied = true;
      }
    }
  }

  void _updateGroundPhysics(double dt) {
    _prevVelocityY = velocityY;
    velocityY += gravity * dt;
    position.y += velocityY * dt;

    final groundY = game.ground.groundY - size.y * scale.y;
    
    // Check if player hits erupting lava geyser spikes (in air or ground)
    if (game.ground.hitsLavaSprout(position.x, position.y, size.x * scale.x, size.y * scale.y)) {
      _hitLava();
    }

    // Check if we are over a lava gap
    bool overGap = game.ground.isOverGap(position.x, size.x * scale.x);
    
    if (position.y >= groundY) {
      if (!overGap) {
        // Normal ground landing
        position.y = groundY;
        final footPos = Vector2(position.x + (size.x * scale.x) * 0.45, position.y + size.y * scale.y);
        final currentBiome = game.biomeManager.effectiveBiome.name;

        if (!isOnGround) {
          if (currentBiome == 'DESERT') {
            game.particlePool.emitDesertLandingImpact(footPos);
            game.triggerShake(duration: 0.1, intensity: 1.5);
          } else {
            game.particlePool.emitJumpDust(footPos);
          }

          if (_prevVelocityY > 400) {
            game.triggerShake(duration: 0.08, intensity: 1.5);
            if (currentBiome == 'DESERT') {
              game.particlePool.emitDesertLandingImpact(footPos);
            } else {
              game.particlePool.emitJumpDust(footPos);
            }
          }

          if (_prevVelocityY > 200) {
            squashX = 1.25;
            squashY = 0.75;
          }
          _jumpCutApplied = false;
        }
        velocityY = 0;
        isOnGround = true;
        jumpsLeft = 2;

        if (_jumpBufferTimer > 0) {
          _jumpBufferTimer = 0;
          jump();
        }

        // Continuous biome footstep particles
        if (currentBiome == 'DESERT') {
          _footstepTimer += dt;
          if (_footstepTimer >= 0.08) {
            _footstepTimer = 0;
            final stepPos = Vector2(position.x + (size.x * scale.x) * 0.35, position.y + size.y * scale.y);
            game.particlePool.emitDesertFootstepDust(stepPos);
          }
        } else if (currentBiome == 'RAIN' || currentBiome == 'STORM') {
          if (math.Random().nextDouble() < 0.45) {
            game.particlePool.emitWaterSplash(footPos);
          }
        }
      } else {
        if (isOnGround) {
          _coyoteTimer = 0.090;
        }
        isOnGround = false;
        // Check if hit lava (let's say lava is 40px below ground)
        if (position.y >= groundY + 30) {
          _hitLava();
        }
      }
    } else {
      if (isOnGround) {
        _coyoteTimer = 0.090;
      }
      isOnGround = false;
    }
  }

  void _hitLava() {
    if (invincibleTimer > 0) return; // Wait until they can take damage again
    
    // Break combo on lava hit
    if (game.combo > 0) {
      game.comboDisplay.showComboBreak(game.combo);
      game.combo = 0;
      game.comboTimer = 0;
    }

    // Lose a life
    if (shieldTimer > 0) {
      shieldTimer = 0;
    } else {
      lives--;
    }
    
    if (lives <= 0) {
      die();
      return;
    }
    
    // Bounce out of lava with invincibility
    HapticFeedback.vibrate();
    velocityY = jumpForce * 1.2; // Huge bounce
    invincibleTimer = 2.0;
    game.particlePool.emitShieldBreak(position); // Re-use shield break particles for damage
  }

  void _updateSpacePhysics(double dt) {
    final phase = game.spacePhase;

    if (phase == SpacePhase.launch) {
      // Auto-thrust upward during launch — smooth ascension
      velocityY = -340;
      position.y += velocityY * dt;
      if (position.y <= game.size.y * 0.35) {
        position.y = game.size.y * 0.35;
        velocityY = 0;
      }
      // Center horizontally
      position.x += (game.size.x * 0.35 - position.x) * 3 * dt;
      targetX = position.x;
    } else if (phase == SpacePhase.coinRain) {
      // Arcade floaty zero-G physics
      if (isThrusting) {
        velocityY -= 1050 * dt; // Upward jetpack thrust
      } else {
        velocityY += 460 * dt; // Gentle cosmic drift gravity
      }
      velocityY = velocityY.clamp(-400.0, 420.0);
      position.y += velocityY * dt;

      // Soft ceiling clamp — never get stuck!
      const minY = 20.0;
      if (position.y <= minY) {
        position.y = minY;
        if (velocityY < 0) velocityY = 0;
      }

      // Soft floor clamp — never fall below screen!
      final maxY = game.size.y - size.y * scale.y - 25.0;
      if (position.y >= maxY) {
        position.y = maxY;
        if (velocityY > 0) velocityY = 0;
      }

      // Horizontal movement
      if (movingLeft) targetX -= 500 * dt;
      if (movingRight) targetX += 500 * dt;
      targetX = targetX.clamp(20.0, game.size.x - size.x * scale.x - 20.0);
      position.x += (targetX - position.x) * 10 * dt;
    } else if (phase == SpacePhase.returning) {
      // Cinematic Re-entry Descent & Touchdown
      isThrusting = false;
      movingLeft = false;
      movingRight = false;
      
      final returnProgress = (1.0 - (game.spacePhaseTimer / DinoGame.spaceReturnDuration)).clamp(0.0, 1.0);

      if (returnProgress < 0.36) {
        // 1. Plunge down rapidly off the bottom of the screen!
        velocityY += 1800 * dt;
        position.y += velocityY * dt;
        position.x += (80 - position.x) * 4 * dt;
        targetX = position.x;
      } else if (returnProgress < 0.72) {
        // 2. Off-screen waiting while BG reveals from center to top & path rises
        position.y = -250;
        position.x = 80;
        targetX = 80;
        velocityY = 0;
      } else {
        // 3. Drop in heroically from top sky onto the ground path!
        final dropT = ((returnProgress - 0.72) / 0.28).clamp(0.0, 1.0);
        final groundY = game.ground.groundY - size.y * scale.y;
        final easeDrop = Curves.easeInCubic.transform(dropT);
        position.y = -120.0 + easeDrop * (groundY - (-120.0));
        position.x = 80;
        targetX = 80;
        velocityY = 400.0;

        if (dropT >= 0.98) {
          position.y = groundY;
          velocityY = 0;
        }
      }
    }
  }

  void jump() {
    if (game.state != GameState.playing) return;
    
    if (jumpsLeft <= 0) {
      _jumpBufferTimer = 0.120;
      return;
    }

    _jumpCutApplied = false;
    _coyoteTimer = 0;
    skin.onJump();
    velocityY = jumpForce;
    isOnGround = false;
    jumpsLeft--;
    _jumpTime = 0;
    _isJumpReleased = false;

    squashX = 0.75;
    squashY = 1.25;

    game.coinManager.recordJump();
    game.particlePool.emitJumpDust(Vector2(position.x + (size.x * scale.x) / 2, position.y + size.y * scale.y));
  }

  void onJumpRelease() {
    _isJumpReleased = true;
  }

  void enterSpaceMode() {
    inSpaceMode = true;
    velocityY = -700;
    game.coinManager.recordSpaceTrip();
  }

  void exitSpaceMode() {
    inSpaceMode = false;
    isThrusting = false;
    movingLeft = false;
    movingRight = false;
    position.x = 80;
    targetX = 80;
    position.y = game.ground.groundY - size.y * scale.y;
    velocityY = 0;
    isOnGround = true;
    jumpsLeft = 2;
  }

  void reset() {
    _resetPosition();
    isDead = false;
    deathTimer = 0;
    deathAngle = 0;
    velocityY = 0;
    jumpsLeft = 2;
    isOnGround = true;
    lives = 3;
    shieldTimer = 0;
    magnetTimer = 0;
    invincibleTimer = 0;
    giantTimer = 0;
    scale = Vector2.all(1.0);
    inSpaceMode = false;
    isThrusting = false;
    movingLeft = false;
    movingRight = false;
    skin = SkinRegistry.getById(game.coinManager.activeSkinId);

    _jumpCutApplied = false;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
    squashX = 1.0;
    squashY = 1.0;
    _prevVelocityY = 0;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (invincibleTimer > 0 || isDead) return;

    if (other is Obstacle && !other.isRemoving) {
      if (!other.isEntranceComplete) return;
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage(other);
    } else if (other is FallingStone && !other.isRemoving) {
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage(other);
    } else if (other is RollingBall && !other.isRemoved) {
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage(other);
    } else if (other is Collectible) {
      other.onCollect();
    }
  }

  void _knockout(PositionComponent obs) {
    obs.removeFromParent();
    game.score += 50;
    game.particlePool.emitShieldBreak(obs.position);
    HapticFeedback.lightImpact();
    game.triggerShake(duration: 0.15, intensity: 3.0);
  }

  void _handleDamage(PositionComponent? obs) {
    // Break combo on damage
    if (game.combo > 0) {
      game.comboDisplay.showComboBreak(game.combo);
      game.combo = 0;
      game.comboTimer = 0;
    }

    ShakePreset preset = ShakePreset.sideHit;
    if (obs is Obstacle) {
      if (obs.type == ObstacleType.ceilingPipe || obs.type == ObstacleType.bird) {
        preset = ShakePreset.topHit;
      }
    } else if (obs is FallingStone) {
      preset = ShakePreset.topHit;
    }

    if (shieldTimer > 0) {
      shieldTimer = 0;
      invincibleTimer = 1.2;
      game.particlePool.emitShieldBreak(Vector2(position.x + (size.x * scale.x) / 2, position.y + (size.y * scale.y) / 2));
      HapticFeedback.mediumImpact();
      game.triggerShake(duration: 0.2, intensity: 4.0, preset: ShakePreset.shieldBreak);
      game.triggerHitStop();
      return;
    }

    lives--;
    game.particlePool.emitCuteDeath(Vector2(position.x + (size.x * scale.x) / 2, position.y + (size.y * scale.y) / 2));
    HapticFeedback.heavyImpact();
    game.triggerShake(duration: 0.35, intensity: 7.0, preset: preset);
    game.triggerHitStop();

    if (lives <= 0) {
      die();
    } else {
      invincibleTimer = 1.8; // Brief invincibility after hit
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.state == GameState.menu) return;
    super.render(canvas);

    if (isDead) {
      canvas.save();
      final centerX = size.x / 2;
      final centerY = size.y / 2;
      canvas.translate(centerX, centerY);
      canvas.rotate(deathAngle);
      canvas.translate(-centerX, -centerY);

      final alpha = (1.0 - (deathTimer / 0.85)).clamp(0.0, 1.0);
      final fadePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.saveLayer(Rect.fromLTWH(-20, -30, size.x + 40, size.y + 40), fadePaint);
      skin.renderCharacter(canvas, Size(size.x, size.y), 0, pose: CharacterPose.falling);

      // Cute spinning dizzy golden stars above Dino's head
      final starAngle = deathTimer * 12.0;
      final headX = size.x * 0.65;
      final headY = -12.0;
      final starPaint = Paint()..color = const Color(0xFFFFD700);

      for (int i = 0; i < 3; i++) {
        final a = starAngle + (i * math.pi * 2 / 3);
        final sx = headX + math.cos(a) * 22.0;
        final sy = headY + math.sin(a) * 8.0;
        canvas.drawCircle(Offset(sx, sy), 3.5, starPaint);
      }

      // Cute pink band-aid plaster on forehead
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.x * 0.55, size.y * 0.18, 16, 6), const Radius.circular(3)),
        _plasterPaint,
      );

      canvas.restore(); // for saveLayer
      canvas.restore(); // for translate/rotate
      return;
    }

    bool applyGlitch = false;
    // Invincibility flash and glitch
    if (invincibleTimer > 0) {
      if (invincibleTimer <= 0.6) {
        if (!isPowerupBlinkVisible(invincibleTimer)) return;
      } else {
        if (_rng.nextDouble() > 0.7) return; // 30% chance to be invisible (blink)
      }
      applyGlitch = true;
    }

    final drawSize = Size(size.x, size.y);

    // Aura pulsing at ~1.2 Hz (scale: 1.0 -> 1.05 -> 1.0, alpha: 0.7 -> 0.9 -> 0.7)
    final pulseT = 0.5 + 0.5 * math.sin(_totalElapsed * 1.2 * 2 * math.pi);
    final pulse = 1.0 + 0.05 * pulseT;
    final alphaPulse = 0.7 + 0.2 * pulseT;

    final showShield = isPowerupBlinkVisible(shieldTimer);
    final showMagnet = isPowerupBlinkVisible(magnetTimer);
    final showGiant = isPowerupBlinkVisible(giantTimer);
    final showInvincible = isPowerupBlinkVisible(invincibleTimer);

    // Subtle pulsing magnet pull radius visualization circle centered on Dino
    if (showMagnet) {
      final magnetLvl = game.coinManager.magnetLevel;
      final pullRadius = 160.0 + (magnetLvl * 30.0);
      final fieldRadius = (pullRadius / scale.x) * pulse;
      final fieldCenter = Offset(size.x / 2, size.y / 2);

      _magnetRingPaint
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.14 * alphaPulse)
        ..strokeWidth = 1.5 / scale.x;
      canvas.drawCircle(fieldCenter, fieldRadius, _magnetRingPaint);

      _magnetFillPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.03 * alphaPulse);
      canvas.drawCircle(fieldCenter, fieldRadius, _magnetFillPaint);
    }

    // 0. Ground Shadow Blob
    if (!inSpaceMode && !isDead) {
      final groundY = game.ground.groundY;
      final distFromGround = groundY - (position.y + size.y * scale.y);
      if (distFromGround >= -10 && distFromGround < 300) {
        final shadowScale = (1.0 - (distFromGround / 300.0).clamp(0.0, 1.0)) * 0.6 + 0.4;
        final distFactor = (1.0 - (distFromGround / 300.0).clamp(0.0, 1.0));
        int bucket = (distFactor * 7).round();
        
        canvas.save();
        canvas.translate(size.x / 2, size.y + distFromGround);
        canvas.scale(shadowScale, 0.25);
        canvas.drawCircle(Offset.zero, size.x * 0.6, _shadowPaints[bucket]);
        canvas.restore();
      }
    }

    // 0.5 Afterimage Trail
    bool trailActive = false;
    for (var e in _trail) { if (e.active) trailActive = true; }
    if (trailActive) {
      Color trailColor = const Color(0xFF00E5FF);
      if (invincibleTimer > 0) {
        trailColor = const Color(0xFFFFD700);
      } else if (giantTimer > 0) {
        trailColor = const Color(0xFFFF1744);
      } else if (shieldTimer > 0) {
        trailColor = const Color(0xFF00E5FF);
      }
      
      for (int i = 0; i < _trail.length; i++) {
        int idx = (_trailHead + i) % _trail.length;
        final entry = _trail[idx];
        if (!entry.active) continue;
        
        final alpha = (1.0 - (entry.age / 0.25)).clamp(0.0, 1.0) * 0.18;
        _trailPaint.color = trailColor.withValues(alpha: alpha);
        
        canvas.save();
        final offsetX = game.speedManager.currentSpeed * entry.age;
        canvas.translate(-offsetX + size.x / 2, entry.dy - position.y + size.y);
        canvas.scale(entry.scaleX, entry.scaleY);
        if (entry.lean != 0) canvas.rotate(entry.lean);
        canvas.translate(-size.x / 2, -size.y);
        
        // Small horizontal motion streaks, never body-sized opaque blocks.
        // Keep the effect behind the runner and away from the face.
        for (int streak = 0; streak < 2; streak++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-size.x * 0.18,
                  size.y * (0.58 + streak * 0.16),
                  size.x * (0.25 - streak * 0.06), 2.0),
              const Radius.circular(1.0),
            ),
            _trailPaint,
          );
        }
        
        canvas.restore();
      }
    }

    if (applyGlitch) {
      canvas.save();
      canvas.translate((_rng.nextDouble() - 0.5) * 20, 0);
    }

    canvas.save();
    canvas.translate(size.x / 2, size.y);
    if (!skin.hasArticulatedMotion) {
      canvas.scale(squashX, squashY);
      if (_currentLean != 0) canvas.rotate(_currentLean);
    }
    canvas.translate(-size.x / 2, -size.y);

    // 0.8 Giant Dino Primal Fire Aura
    if (showGiant) {
      _renderGiantAura(canvas, drawSize, pulse, alphaPulse);
    }

    // 0.9 Invincible Radiant Golden Prismatic Aura
    if (showInvincible) {
      _renderInvincibleAura(canvas, drawSize, pulse, alphaPulse);
    }

    // 1. Draw BACK ARC of 3D Magnet Ring (Behind Dino's body)
    if (showMagnet) {
      _renderHulaHoopMagnetBack(canvas, drawSize, pulse, alphaPulse);
    }

    // 2. Draw Jetpack Tanks & Thruster Exhaust (Behind Dino's back)
    if (inSpaceMode) {
      _renderJetpackBack(canvas, drawSize);
    }

    // 3. Draw Dino Skin
    if (inSpaceMode) {
      skin.renderCharacter(canvas, drawSize, _animFrame, pose: CharacterPose.space);
    } else if (!isOnGround) {
      skin.renderCharacter(canvas, drawSize, _animFrame, pose: velocityY > 0 ? CharacterPose.falling : CharacterPose.jumping);
    } else {
      skin.renderCharacter(canvas, drawSize, _animFrame);
    }

    // 4. Draw Jetpack Front Harness Straps (Across Dino's chest)
    if (inSpaceMode) {
      _renderJetpackFront(canvas, drawSize);
    }

    if (applyGlitch) {
      canvas.restore();
    }

    // 5. Draw FRONT ARC of 3D Magnet Ring (In Front of Dino's waist)
    if (showMagnet) {
      _renderHulaHoopMagnetFront(canvas, drawSize, pulse, alphaPulse);
    }

    // 6. Draw Soap Bubble Shield Overlay
    if (showShield) {
      _renderSoapBubbleShield(canvas, drawSize, pulse, alphaPulse);
    }

    canvas.restore(); // Restore squash/stretch transform
  }

  /// 🚀 High-Tech Stylized Sci-Fi Jetpack (Aero-Chassis, Dual Thrusters, Arc Reactor & Plasma Plumes)
  void _renderJetpackBack(Canvas canvas, Size drawSize) {
    final w = drawSize.width;
    final h = drawSize.height;

    // Dino is facing right. Jetpack is mounted on the back (left side: x ~ 0.08w to 0.30w, y ~ 0.44h to 0.74h)
    final packLeft = w * 0.10;
    final packTop = h * 0.46;
    final packW = w * 0.22;
    final packH = h * 0.28;

    final isFiring = isThrusting || game.spacePhase == SpacePhase.launch;

    // 1. Dual High-Velocity Plasma Exhaust Jets (Shooting downward from rocket nozzles)
    final flamePulse = 0.85 + 0.15 * math.sin(_totalElapsed * (isFiring ? 30.0 : 14.0));
    final flameLen = isFiring ? (36.0 * flamePulse) : (16.0 * flamePulse);
    final nozzleY = packTop + packH;

    for (int t = 0; t < 2; t++) {
      final nozzleX = packLeft + 4.5 + t * (packW - 9.0);
      final flameW = isFiring ? 8.0 : 5.0;

      // Outer Plasma Energy Sheath
      final outerFlamePath = Path()
        ..moveTo(nozzleX - flameW * 0.5, nozzleY)
        ..lineTo(nozzleX + flameW * 0.5, nozzleY)
        ..quadraticBezierTo(nozzleX + flameW * 0.3, nozzleY + flameLen * 0.65, nozzleX, nozzleY + flameLen)
        ..quadraticBezierTo(nozzleX - flameW * 0.3, nozzleY + flameLen * 0.65, nozzleX - flameW * 0.5, nozzleY)
        ..close();

      final outerFlameShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isFiring
            ? const [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0x00FF4081)]
            : const [Color(0xBB00E5FF), Color(0x5500B0FF), Colors.transparent],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(nozzleX - flameW, nozzleY, flameW * 2, flameLen));

      canvas.drawPath(
        outerFlamePath,
        Paint()
          ..shader = outerFlameShader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Mid Electric Cyan Thrust Jet
      final midFlamePath = Path()
        ..moveTo(nozzleX - flameW * 0.3, nozzleY)
        ..lineTo(nozzleX + flameW * 0.3, nozzleY)
        ..lineTo(nozzleX, nozzleY + flameLen * 0.8)
        ..close();
      canvas.drawPath(
        midFlamePath,
        Paint()..color = (isFiring ? const Color(0xFF18FFFF) : const Color(0xFF80D8FF)).withValues(alpha: 0.9),
      );

      // Inner White-Hot Shock Diamond Core
      final corePath = Path()
        ..moveTo(nozzleX - flameW * 0.15, nozzleY)
        ..lineTo(nozzleX + flameW * 0.15, nozzleY)
        ..lineTo(nozzleX, nozzleY + flameLen * 0.45)
        ..close();
      canvas.drawPath(corePath, Paint()..color = Colors.white.withValues(alpha: isFiring ? 0.98 : 0.85));

      // Dynamic Plasma Spark Particles
      if (isFiring) {
        for (int p = 0; p < 2; p++) {
          final sparkOffset = math.sin(_totalElapsed * 24.0 + t * 5.0 + p * 3.0) * 3.5;
          final sparkY = nozzleY + flameLen * (0.6 + p * 0.3);
          canvas.drawCircle(
            Offset(nozzleX + sparkOffset, sparkY),
            1.2,
            Paint()..color = const Color(0xFF80D8FF).withValues(alpha: 0.8),
          );
        }
      }
    }

    // 2. Central Aero-Chassis Shell (Ergonomic Matte White & Carbon Titanium Backplate)
    final chassisRect = Rect.fromLTWH(packLeft + 2.0, packTop + 2.0, packW - 4.0, packH - 6.0);
    final chassisShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFECEFF1), // Clean astronaut white
        Color(0xFFB0BEC5), // High-tech matte alloy
        Color(0xFF37474F), // Shadowed dark trim
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(chassisRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(chassisRect, const Radius.circular(5.0)),
      Paint()..shader = chassisShader,
    );

    // 3. Twin High-Pressure Titanium Thruster Pods
    for (int t = 0; t < 2; t++) {
      final podW = (packW - 3.0) * 0.46;
      final podLeft = packLeft + t * (podW + 3.0);
      final podRect = Rect.fromLTWH(podLeft, packTop, podW, packH - 4.0);

      final podShader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // Specular chrome highlight
          Color(0xFF78909C), // Spacecraft titanium
          Color(0xFF263238), // Carbon dark edge
        ],
        stops: [0.0, 0.40, 1.0],
      ).createShader(podRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(podRect, const Radius.circular(4.0)),
        Paint()..shader = podShader,
      );

      // Top Intake Aero Cap & LED Status Indicator
      final capRect = Rect.fromLTWH(podLeft + 1.0, packTop - 2.5, podW - 2.0, 3.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(capRect, const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF263238),
      );
      canvas.drawCircle(
        Offset(podRect.center.dx, packTop - 1.0),
        1.1,
        Paint()..color = (t == 0 ? const Color(0xFF00E676) : const Color(0xFF00E5FF)),
      );

      // Neon Cyan Energy Level Conduit Line
      final conduitRect = Rect.fromLTWH(podLeft + 2.2, packTop + 5.0, podW - 4.4, podRect.height - 12.0);
      final pulse = 0.75 + 0.25 * math.sin(_totalElapsed * 6.0 + t * 2.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(conduitRect, const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.90 * pulse),
      );

      // Heavy Vector Bell Nozzle
      final nozzleRect = Rect.fromLTWH(podLeft - 0.5, packTop + packH - 4.0, podW + 1.0, 4.5);
      final nozzleShader = const LinearGradient(
        colors: [Color(0xFF455A64), Color(0xFF212121)],
      ).createShader(nozzleRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(nozzleRect, const Radius.circular(1.5)),
        Paint()..shader = nozzleShader,
      );

      // Nozzle Heat Glow Rim
      canvas.drawLine(
        Offset(nozzleRect.left, nozzleRect.bottom),
        Offset(nozzleRect.right, nozzleRect.bottom),
        Paint()
          ..color = (isFiring ? const Color(0xFFFF9100) : const Color(0xFF00E5FF)).withValues(alpha: 0.95)
          ..strokeWidth = 1.4,
      );
    }

    // 4. Central Arc Reactor Core (Pulsating Blue Core on Jetpack Center)
    final coreCenter = Offset(packLeft + packW * 0.5, packTop + packH * 0.42);
    final corePulse = 0.8 + 0.2 * math.sin(_totalElapsed * 8.0);
    canvas.drawCircle(coreCenter, 3.6, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(coreCenter, 2.5, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: corePulse));
    canvas.drawCircle(coreCenter, 1.2, Paint()..color = Colors.white);
  }

  /// 🚀 Sci-Fi Jetpack Torso Harness & Chest Buckle (Properly positioned across torso, never covering the face/eye)
  void _renderJetpackFront(Canvas canvas, Size drawSize) {
    final w = drawSize.width;
    final h = drawSize.height;

    // Dark padded tech strap across Dino's upper torso/belly (clearing head and eyes)
    final strapPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.90)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final strapPath = Path()
      ..moveTo(w * 0.22, h * 0.64)
      ..quadraticBezierTo(w * 0.36, h * 0.68, w * 0.52, h * 0.67);
    canvas.drawPath(strapPath, strapPaint);

    // Cyan Telemetry Stripe on the harness strap
    final stripePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(strapPath, stripePaint);

    // Sci-Fi Metallic Chest Buckle Badge with LED Indicator
    final buckleCenter = Offset(w * 0.40, h * 0.67);
    canvas.drawCircle(buckleCenter, 3.2, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(buckleCenter, 1.8, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(buckleCenter, 0.9, Paint()..color = const Color(0xFF00E5FF));
  }

  /// 🫧 Cute Iridescent Soap Bubble Shield centered on Dino
  void _renderSoapBubbleShield(Canvas canvas, Size drawSize, double pulse, double alphaPulse) {
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.52);
    final baseRadius = math.max(drawSize.width, drawSize.height) * 0.68 * pulse;
    // Smooth organic liquid bubble wobble
    final wobble = math.sin(_totalElapsed * 4.0) * 2.0;
    final bubbleRadius = baseRadius + wobble;

    final bubbleRect = Rect.fromCircle(center: center, radius: bubbleRadius);

    // 1. Translucent Soap Bubble Fill
    final bubbleFillShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: [
        const Color(0x45E0F7FA).withValues(alpha: 0.28 * alphaPulse), // Translucent cyan center
        const Color(0x2580DEEA).withValues(alpha: 0.16 * alphaPulse),
        const Color(0x35F8BBD0).withValues(alpha: 0.22 * alphaPulse), // Soft pink/magenta refraction
        const Color(0x5500E5FF).withValues(alpha: 0.38 * alphaPulse), // Glowing rim edge
      ],
      stops: const [0.0, 0.45, 0.78, 1.0],
    ).createShader(bubbleRect);

    canvas.drawCircle(center, bubbleRadius, Paint()..shader = bubbleFillShader);

    // 2. Iridescent Rainbow Rim Stroke
    final rimShader = SweepGradient(
      center: Alignment.center,
      startAngle: _totalElapsed * 1.5,
      endAngle: _totalElapsed * 1.5 + math.pi * 2,
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.95 * alphaPulse), // Cyan
        const Color(0xFFFF4081).withValues(alpha: 0.95 * alphaPulse), // Magenta
        const Color(0xFFFFD54F).withValues(alpha: 0.95 * alphaPulse), // Gold
        const Color(0xFF00E676).withValues(alpha: 0.95 * alphaPulse), // Emerald
        const Color(0xFF00E5FF).withValues(alpha: 0.95 * alphaPulse), // Cyan repeat
      ],
    ).createShader(bubbleRect);

    canvas.drawCircle(
      center,
      bubbleRadius,
      Paint()
        ..shader = rimShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // 3. Curved Specular Reflection Arc (Top-Left Glass Highlight)
    final sheenPath = Path();
    final sheenRadius = bubbleRadius * 0.82;
    sheenPath.addArc(
      Rect.fromCircle(center: center, radius: sheenRadius),
      math.pi * 1.15,
      math.pi * 0.45,
    );

    _shieldSheenPaint.color = Colors.white.withValues(alpha: 0.85 * alphaPulse);
    _shieldSheenPaint.style = PaintingStyle.stroke;
    _shieldSheenPaint.strokeWidth = 3.2;
    _shieldSheenPaint.strokeCap = StrokeCap.round;
    canvas.drawPath(sheenPath, _shieldSheenPaint);

    // Secondary smaller bottom-right reflection dot
    _shieldDotPaint.color = Colors.white.withValues(alpha: 0.65 * alphaPulse);
    canvas.drawCircle(
      Offset(center.dx + bubbleRadius * 0.55, center.dy + bubbleRadius * 0.55),
      2.5,
      _shieldDotPaint,
    );
  }

  /// 🧲 3D Hula Hoop Magnet Ring - BACK ARC (Drawn behind Dino's body)
  void _renderHulaHoopMagnetBack(Canvas canvas, Size drawSize, double pulse, double alphaPulse) {
    // Perfectly centered at Dino's waist/torso
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.62);
    final rx = drawSize.width * 0.58 * pulse;
    final ry = 14.0 * pulse;

    // Smooth continuous 360-degree rotation
    final hoopAngle = _totalElapsed * 2.8;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Back Arc Glow Halo
    final backHaloPath = Path()..addArc(hoopRect, math.pi, math.pi);
    _magnetHaloBack.color = const Color(0xFF00E5FF).withValues(alpha: 0.18 * alphaPulse);
    canvas.drawPath(backHaloPath, _magnetHaloBack);

    // 2. Back Arc Ring Gradient (Behind Dino)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: [
        const Color(0x8000E5FF).withValues(alpha: 0.50 * alphaPulse),
        const Color(0x80E040FB).withValues(alpha: 0.50 * alphaPulse),
        const Color(0x80FFFF8D).withValues(alpha: 0.50 * alphaPulse),
        const Color(0x8000E5FF).withValues(alpha: 0.50 * alphaPulse),
      ],
    ).createShader(hoopRect);

    _magnetRingBack.shader = ringShader;
    canvas.drawPath(backHaloPath, _magnetRingBack);

    // 3. Back Orbiting Sparkle Nodes (oy < 0)
    for (int i = 0; i < 4; i++) {
      final a = hoopAngle + (i * math.pi / 2);
      final ox = math.cos(a) * rx;
      final oy = math.sin(a) * ry;

      if (oy < 0) { // Behind Dino
        _sparklePaint.color = Colors.white.withValues(alpha: 0.50 * alphaPulse);
        canvas.drawCircle(Offset(ox, oy), 2.0, _sparklePaint);
        _sparkleGlowPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.30 * alphaPulse);
        canvas.drawCircle(Offset(ox, oy), 3.6, _sparkleGlowPaint);
      }
    }

    canvas.restore();
  }

  /// 🧲 3D Hula Hoop Magnet Ring - FRONT ARC (Drawn in front of Dino's body)
  void _renderHulaHoopMagnetFront(Canvas canvas, Size drawSize, double pulse, double alphaPulse) {
    // Perfectly centered at Dino's waist/torso
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.62);
    final rx = drawSize.width * 0.58 * pulse;
    final ry = 14.0 * pulse;

    // Smooth continuous 360-degree rotation
    final hoopAngle = _totalElapsed * 2.8;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Front Arc Glow Halo
    final frontArcPath = Path()..addArc(hoopRect, 0, math.pi);
    _magnetHaloFront.color = const Color(0xFF00E5FF).withValues(alpha: 0.25 * alphaPulse);
    canvas.drawPath(frontArcPath, _magnetHaloFront);

    // 2. Front Arc Ring Gradient (In front of Dino's belly)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: [
        const Color(0xCC00E5FF).withValues(alpha: 0.80 * alphaPulse),
        const Color(0xCCE040FB).withValues(alpha: 0.80 * alphaPulse),
        const Color(0xCCFFFF8D).withValues(alpha: 0.80 * alphaPulse),
        const Color(0xCC00E5FF).withValues(alpha: 0.80 * alphaPulse),
      ],
    ).createShader(hoopRect);

    _magnetRingFront.shader = ringShader;
    canvas.drawPath(frontArcPath, _magnetRingFront);

    // 3. Front Orbiting Sparkle Nodes (oy >= 0)
    for (int i = 0; i < 4; i++) {
      final a = hoopAngle + (i * math.pi / 2);
      final ox = math.cos(a) * rx;
      final oy = math.sin(a) * ry;

      if (oy >= 0) { // In front of Dino
        _sparklePaint.color = Colors.white.withValues(alpha: alphaPulse);
        canvas.drawCircle(Offset(ox, oy), 3.0, _sparklePaint);
        _sparkleGlowPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.55 * alphaPulse);
        canvas.drawCircle(Offset(ox, oy), 5.5, _sparkleGlowPaint);
      }
    }

    canvas.restore();
  }

  /// 🔥 Giant Dino Primal Energy Aura
  void _renderGiantAura(Canvas canvas, Size drawSize, double pulse, double alphaPulse) {
    final center = Offset(drawSize.width * 0.5, drawSize.height * 0.52);
    final radius = math.max(drawSize.width, drawSize.height) * 0.65 * pulse;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final auraShader = RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        const Color(0xFFFF1744).withValues(alpha: 0.0),
        const Color(0xFFFF5252).withValues(alpha: 0.16 * alphaPulse),
        const Color(0xFFFFD600).withValues(alpha: 0.26 * alphaPulse),
        const Color(0xFFFF1744).withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.45, 0.80, 1.0],
    ).createShader(rect);

    _giantAuraPaint.shader = auraShader;
    canvas.drawCircle(center, radius, _giantAuraPaint);

    _giantStrokePaint.color = const Color(0xFFFF5252).withValues(alpha: 0.35 * alphaPulse);
    canvas.drawCircle(center, radius * 0.90, _giantStrokePaint);
  }

  /// ⭐ Invincible Prismatic Radiant Aura
  void _renderInvincibleAura(Canvas canvas, Size drawSize, double pulse, double alphaPulse) {
    final center = Offset(drawSize.width * 0.5, drawSize.height * 0.52);
    final radius = math.max(drawSize.width, drawSize.height) * 0.60 * pulse;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepShader = SweepGradient(
      center: Alignment.center,
      startAngle: _totalElapsed * 3.0,
      endAngle: _totalElapsed * 3.0 + math.pi * 2,
      colors: [
        const Color(0xFFFFD700).withValues(alpha: 0.40 * alphaPulse),
        const Color(0xFFFFF9C4).withValues(alpha: 0.20 * alphaPulse),
        const Color(0xFFFFAB00).withValues(alpha: 0.40 * alphaPulse),
        const Color(0xFFFFD700).withValues(alpha: 0.40 * alphaPulse),
      ],
    ).createShader(rect);

    _invincibleAuraPaint.shader = sweepShader;
    canvas.drawCircle(center, radius, _invincibleAuraPaint);

    _invincibleGlowPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.08 * alphaPulse);
    canvas.drawCircle(center, radius * 0.95, _invincibleGlowPaint);
  }

  /// 0.6s expiry telegraph: 3 blinks (0.1s on, 0.1s off).
  static bool isPowerupBlinkVisible(double timer) {
    if (timer <= 0) return false;
    if (timer <= 0.6) {
      return (timer / 0.1).floor() % 2 == 0;
    }
    return true;
  }
}
