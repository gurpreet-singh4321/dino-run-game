import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../skins/skin.dart';
import '../skins/skin_registry.dart';
import '../managers/audio_manager.dart';

import '../utils/vibration_util.dart';
import 'obstacle.dart';
import 'falling_stone.dart';
import 'collectible.dart';
import 'rolling_ball.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  static const double gravity = 800;
  static const double jumpForce = -480;

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

  // Animation
  int _animFrame = 0;
  double _animTimer = 0;
  static const double _animSpeed = 0.1; // 100ms per frame

  // Skin system
  late CharacterSkin skin;

  void setSkin(CharacterSkin newSkin) {
    skin = newSkin;
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
    super.update(dt);
    
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

    skin.update(dt);

    // Animation timer
    _animTimer += dt;
    if (_animTimer >= _animSpeed) {
      _animTimer -= _animSpeed;
      _animFrame = (_animFrame + 1) % 4;
    }

    if (game.state == GameState.playing) {
      _updateGroundPhysics(dt);
    } else if (game.state == GameState.spaceMode) {
      _updateSpacePhysics(dt);
    }

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
  }

  void _updateGroundPhysics(double dt) {
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
        if (!isOnGround) {
          game.particlePool.emitJumpDust(Vector2(position.x + (size.x * scale.x) / 2, position.y + size.y * scale.y));
        }
        velocityY = 0;
        isOnGround = true;
        jumpsLeft = 2;

        // Emit water splash droplets under feet when running in rain/storm
        final currentBiome = game.biomeManager.current.name;
        if (currentBiome == 'RAIN' || currentBiome == 'STORM') {
          if (math.Random().nextDouble() < 0.45) {
            game.particlePool.emitWaterSplash(Vector2(position.x + (size.x * scale.x) * 0.4, position.y + size.y * scale.y));
          }
        }
      } else {
        isOnGround = false;
        // Check if hit lava (let's say lava is 40px below ground)
        if (position.y >= groundY + 30) {
          _hitLava();
        }
      }
    } else {
      isOnGround = false;
    }
  }

  void _hitLava() {
    if (invincibleTimer > 0) return; // Wait until they can take damage again
    
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
      // Auto-thrust upward during launch — no player control
      velocityY = -350;
      position.y += velocityY * dt;
      // Center horizontally
      position.x += (game.size.x * 0.35 - position.x) * 3 * dt;
      targetX = position.x;
    } else if (phase == SpacePhase.coinRain) {
      // Free-fly physics — player can thrust and move
      if (isThrusting) {
        velocityY -= 2000 * dt;
      } else {
        velocityY += gravity * dt;
      }
      velocityY = velocityY.clamp(-800.0, 1000.0);
      position.y += velocityY * dt;

      // Horizontal movement
      if (movingLeft) targetX -= 500 * dt;
      if (movingRight) targetX += 500 * dt;
      targetX = targetX.clamp(10.0, game.size.x - size.x * scale.x - 10.0);
      position.x += (targetX - position.x) * 10 * dt;
    } else if (phase == SpacePhase.returning) {
      // Controlled, gentle descent back to ground — Dino stays 100% visible
      isThrusting = false;
      final groundY = game.ground.groundY - size.y * scale.y;
      velocityY = 220.0;
      position.y += velocityY * dt;

      // Drift smoothly back to left running position
      position.x += (80 - position.x) * 3 * dt;
      targetX = position.x;

      // Clamp to ground line on landing
      if (position.y >= groundY) {
        position.y = groundY;
        velocityY = 0;
      }
    }

    // Always clamp Dino inside visible screen bounds (y between top of screen and ground)
    final maxY = game.ground.groundY - size.y * scale.y;
    position.y = position.y.clamp(0.0, maxY);
  }

  void jump() {
    if (game.state != GameState.playing) return;
    if (jumpsLeft > 0) {
      velocityY = jumpForce;
      isOnGround = false;
      jumpsLeft--;
      game.coinManager.recordJump();
      game.particlePool.emitJumpDust(Vector2(position.x + (size.x * scale.x) / 2, position.y + size.y * scale.y));
    }
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
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (invincibleTimer > 0 || isDead) return;

    if (other is Obstacle && !other.isRemoving) {
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage();
    } else if (other is FallingStone && !other.isRemoving) {
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage();
    } else if (other is RollingBall && !other.isRemoved) {
      if (giantTimer > 0) {
        _knockout(other);
        return;
      }
      other.removeFromParent();
      _handleDamage();
    } else if (other is Collectible) {
      other.onCollect();
    }
  }

  void _handleDamage() {
    GameVibration.mediumImpact();
    final shieldLvl = game.coinManager.shieldLevel;
    final postHitInvincibility = 1.2 + (shieldLvl * 0.4);
    if (shieldTimer > 0) {
      shieldTimer = 0;
      invincibleTimer = postHitInvincibility;
      game.coinManager.recordShieldHit();
      game.particlePool.emitShieldBreak(position);
    } else {
      lives--;
      if (lives <= 0) {
        die();
      } else {
        invincibleTimer = postHitInvincibility;
        game.particlePool.emitShieldBreak(position);
      }
    }
  }

  void _knockout(PositionComponent target) {
    game.score += 150;
    game.particlePool.emitShieldBreak(target.position);
    game.particlePool.emitJumpDust(target.position);
    game.particlePool.emitNearMiss(target.position);
    GameVibration.heavyImpact();
    game.triggerShake(duration: 0.35, intensity: 6.0);
    target.removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (isDead) {
      canvas.save();
      final alpha = (1.0 - (deathTimer / 0.85)).clamp(0.0, 1.0);
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(deathAngle * 0.5);
      canvas.translate(-size.x / 2, -size.y / 2);

      final fadePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.saveLayer(Rect.fromLTWH(-20, -30, size.x + 40, size.y + 40), fadePaint);
      skin.renderJumping(canvas, Size(size.x, size.y), true);

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
      final plasterPaint = Paint()..color = const Color(0xFFFF80AB);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.x * 0.55, size.y * 0.18, 16, 6), const Radius.circular(3)),
        plasterPaint,
      );

      canvas.restore(); // for saveLayer
      canvas.restore(); // for translate/rotate
      return;
    }

    bool applyGlitch = false;
    // Invincibility flash and glitch
    if (invincibleTimer > 0) {
      if (math.Random().nextDouble() > 0.7) return; // 30% chance to be invisible (blink)
      applyGlitch = true;
    }

    if (applyGlitch) {
      canvas.save();
      canvas.translate((math.Random().nextDouble() - 0.5) * 20, 0);
    }

    final drawSize = Size(size.x, size.y);

    // 1. Draw BACK ARC of 3D Magnet Ring (Behind Dino's body)
    if (magnetTimer > 0) {
      _renderHulaHoopMagnetBack(canvas, drawSize);
    }

    // 2. Draw Dino Skin
    if (inSpaceMode) {
      skin.renderSpace(canvas, drawSize, _animFrame);
    } else if (!isOnGround) {
      skin.renderJumping(canvas, drawSize, velocityY > 0);
    } else {
      skin.renderRunning(canvas, drawSize, _animFrame);
    }

    if (applyGlitch) {
      canvas.restore();
    }

    // 3. Draw FRONT ARC of 3D Magnet Ring (In Front of Dino's waist)
    if (magnetTimer > 0) {
      _renderHulaHoopMagnetFront(canvas, drawSize);
    }

    // 4. Draw Soap Bubble Shield Overlay
    if (shieldTimer > 0) {
      _renderSoapBubbleShield(canvas, drawSize);
    }
  }

  /// 🫧 Cute Iridescent Soap Bubble Shield centered on Dino
  void _renderSoapBubbleShield(Canvas canvas, Size drawSize) {
    final center = Offset(drawSize.width / 2, drawSize.height / 2);
    final baseRadius = math.max(drawSize.width, drawSize.height) * 0.72;
    // Organic liquid bubble wobble
    final wobble = math.sin(_animTimer * 6.0) * 2.5;
    final bubbleRadius = baseRadius + wobble;

    final bubbleRect = Rect.fromCircle(center: center, radius: bubbleRadius);

    // 1. Translucent Soap Bubble Fill
    final bubbleFillShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: [
        const Color(0x45E0F7FA), // Translucent cyan center
        const Color(0x2580DEEA),
        const Color(0x35F8BBD0), // Soft pink/magenta refraction
        const Color(0x5500E5FF), // Glowing rim edge
      ],
      stops: const [0.0, 0.45, 0.78, 1.0],
    ).createShader(bubbleRect);

    canvas.drawCircle(center, bubbleRadius, Paint()..shader = bubbleFillShader);

    // 2. Iridescent Rainbow Rim Stroke
    final rimShader = SweepGradient(
      center: Alignment.center,
      startAngle: _animTimer * 2.0,
      endAngle: _animTimer * 2.0 + math.pi * 2,
      colors: const [
        Color(0xFF00E5FF), // Cyan
        Color(0xFFFF4081), // Magenta
        Color(0xFFFFD54F), // Gold
        Color(0xFF00E676), // Emerald
        Color(0xFF00E5FF), // Cyan repeat
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

    canvas.drawPath(
      sheenPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Secondary smaller bottom-right reflection dot
    canvas.drawCircle(
      Offset(center.dx + bubbleRadius * 0.55, center.dy + bubbleRadius * 0.55),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  /// 🧲 3D Hula Hoop Magnet Ring - BACK ARC (Drawn behind Dino's body)
  void _renderHulaHoopMagnetBack(Canvas canvas, Size drawSize) {
    final center = Offset(drawSize.width * 0.44, drawSize.height * 0.54);
    final rx = drawSize.width * 0.56;
    final ry = 11.0;

    // Super slow, smooth, relaxing spin (1.0 rad/s)
    final hoopAngle = _animTimer * 1.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.06); // 3D tilt

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Back Arc Glow Halo
    final backHaloPath = Path()..addArc(hoopRect, math.pi, math.pi);
    canvas.drawPath(
      backHaloPath,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Back Arc Ring Gradient (Behind Dino)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.45),
        const Color(0xFFE040FB).withValues(alpha: 0.45),
        const Color(0xFFFFFF8D).withValues(alpha: 0.45),
        const Color(0xFF00E5FF).withValues(alpha: 0.45),
      ],
    ).createShader(hoopRect);

    canvas.drawPath(
      backHaloPath,
      Paint()
        ..shader = ringShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // 3. Back Orbiting Sparkle Nodes (oy < 0)
    for (int i = 0; i < 4; i++) {
      final a = hoopAngle + (i * math.pi / 2);
      final ox = math.cos(a) * rx;
      final oy = math.sin(a) * ry;

      if (oy < 0) { // Behind Dino
        canvas.drawCircle(
          Offset(ox, oy),
          1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.40),
        );
        canvas.drawCircle(
          Offset(ox, oy),
          3.2,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.25),
        );
      }
    }

    canvas.restore();
  }

  /// 🧲 3D Hula Hoop Magnet Ring - FRONT ARC (Drawn in front of Dino's body)
  void _renderHulaHoopMagnetFront(Canvas canvas, Size drawSize) {
    final center = Offset(drawSize.width * 0.44, drawSize.height * 0.54);
    final rx = drawSize.width * 0.56;
    final ry = 11.0;

    // Super slow, smooth, relaxing spin (1.0 rad/s)
    final hoopAngle = _animTimer * 1.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.06); // 3D tilt

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Front Arc Glow Halo
    final frontArcPath = Path()..addArc(hoopRect, 0, math.pi);
    canvas.drawPath(
      frontArcPath,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Front Arc Ring Gradient (In front of Dino's belly)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.60),
        const Color(0xFFE040FB).withValues(alpha: 0.60),
        const Color(0xFFFFFF8D).withValues(alpha: 0.60),
        const Color(0xFF00E5FF).withValues(alpha: 0.60),
      ],
    ).createShader(hoopRect);

    canvas.drawPath(
      frontArcPath,
      Paint()
        ..shader = ringShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );

    // 3. Front Orbiting Sparkle Nodes (oy >= 0)
    for (int i = 0; i < 4; i++) {
      final a = hoopAngle + (i * math.pi / 2);
      final ox = math.cos(a) * rx;
      final oy = math.sin(a) * ry;

      if (oy >= 0) { // In front of Dino
        canvas.drawCircle(
          Offset(ox, oy),
          2.6,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
        canvas.drawCircle(
          Offset(ox, oy),
          4.5,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.45),
        );
      }
    }

    canvas.restore();
  }
}
