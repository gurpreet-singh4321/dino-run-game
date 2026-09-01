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
  double _totalElapsed = 0;
  double _footstepTimer = 0;
  static const double _animSpeed = 0.12; // 100ms per frame

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

    skin.update(dt);

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
        final footPos = Vector2(position.x + (size.x * scale.x) * 0.45, position.y + size.y * scale.y);
        final currentBiome = game.biomeManager.effectiveBiome.name;

        if (!isOnGround) {
          if (currentBiome == 'DESERT') {
            game.particlePool.emitDesertLandingImpact(footPos);
            game.triggerShake(duration: 0.1, intensity: 1.5);
          } else {
            game.particlePool.emitJumpDust(footPos);
          }
        }
        velocityY = 0;
        isOnGround = true;
        jumpsLeft = 2;

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

  void _knockout(PositionComponent obs) {
    obs.removeFromParent();
    game.score += 50;
    game.particlePool.emitShieldBreak(obs.position);
    HapticFeedback.lightImpact();
    game.triggerShake(duration: 0.15, intensity: 3.0);
  }

  void _handleDamage() {
    if (shieldTimer > 0) {
      shieldTimer = 0;
      invincibleTimer = 1.2;
      game.particlePool.emitShieldBreak(Vector2(position.x + (size.x * scale.x) / 2, position.y + (size.y * scale.y) / 2));
      HapticFeedback.mediumImpact();
      game.triggerShake(duration: 0.2, intensity: 4.0);
      return;
    }

    lives--;
    game.particlePool.emitCuteDeath(Vector2(position.x + (size.x * scale.x) / 2, position.y + (size.y * scale.y) / 2));
    HapticFeedback.heavyImpact();
    game.triggerShake(duration: 0.35, intensity: 7.0);

    if (lives <= 0) {
      die();
    } else {
      invincibleTimer = 1.8; // Brief invincibility after hit
    }
  }

  @override
  void render(Canvas canvas) {
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

    // 2. Draw Jetpack Tanks & Thruster Exhaust (Behind Dino's back)
    if (inSpaceMode) {
      _renderJetpackBack(canvas, drawSize);
    }

    // 3. Draw Dino Skin
    if (inSpaceMode) {
      skin.renderSpace(canvas, drawSize, _animFrame);
    } else if (!isOnGround) {
      skin.renderJumping(canvas, drawSize, velocityY > 0);
    } else {
      skin.renderRunning(canvas, drawSize, _animFrame);
    }

    // 4. Draw Jetpack Front Harness Straps (Across Dino's chest)
    if (inSpaceMode) {
      _renderJetpackFront(canvas, drawSize);
    }

    if (applyGlitch) {
      canvas.restore();
    }

    // 5. Draw FRONT ARC of 3D Magnet Ring (In Front of Dino's waist)
    if (magnetTimer > 0) {
      _renderHulaHoopMagnetFront(canvas, drawSize);
    }

    // 6. Draw Soap Bubble Shield Overlay
    if (shieldTimer > 0) {
      _renderSoapBubbleShield(canvas, drawSize);
    }
  }

  /// 🚀 Sci-Fi Dual-Thruster Jetpack & Plasma Plume (Backpack Tanks & Exhaust)
  void _renderJetpackBack(Canvas canvas, Size drawSize) {
    final w = drawSize.width;
    final h = drawSize.height;

    // Dino is facing right. The jetpack sits on Dino's back (left side: x ~ 0.14w to 0.32w, y ~ 0.44h to 0.72h)
    final packLeft = w * 0.14;
    final packTop = h * 0.46;
    final packW = w * 0.18;
    final packH = h * 0.26;

    final isFiring = isThrusting || game.spacePhase == SpacePhase.launch;

    // 1. Dual Plasma Exhaust Plumes (Shooting downward from rocket nozzles)
    final flamePulse = 0.85 + 0.15 * math.sin(_totalElapsed * (isFiring ? 28.0 : 12.0));
    final flameLen = isFiring ? (32.0 * flamePulse) : (14.0 * flamePulse);
    final nozzleY = packTop + packH;

    for (int t = 0; t < 2; t++) {
      final nozzleX = packLeft + 3.0 + t * (packW - 8.0);
      final flamePath = Path()
        ..moveTo(nozzleX - 3.5, nozzleY)
        ..lineTo(nozzleX + 3.5, nozzleY)
        ..quadraticBezierTo(nozzleX + 2.0, nozzleY + flameLen * 0.6, nozzleX, nozzleY + flameLen)
        ..quadraticBezierTo(nozzleX - 2.0, nozzleY + flameLen * 0.6, nozzleX - 3.5, nozzleY)
        ..close();

      // Outer Plasma Glow
      final outerFlameShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isFiring
            ? const [Color(0xFF00E5FF), Color(0xFF7C4DFF), Color(0x00FF4081)]
            : const [Color(0x9900E5FF), Color(0x44448AFF), Colors.transparent],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(nozzleX - 6, nozzleY, 12, flameLen));

      canvas.drawPath(
        flamePath,
        Paint()
          ..shader = outerFlameShader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Inner White-Hot Core
      final corePath = Path()
        ..moveTo(nozzleX - 1.8, nozzleY)
        ..lineTo(nozzleX + 1.8, nozzleY)
        ..lineTo(nozzleX, nozzleY + flameLen * 0.55)
        ..close();
      canvas.drawPath(corePath, Paint()..color = Colors.white.withValues(alpha: isFiring ? 0.95 : 0.7));
    }

    // 2. Twin Titanium Fuel Canisters
    for (int t = 0; t < 2; t++) {
      final tankRect = Rect.fromLTWH(packLeft + t * (packW * 0.52), packTop, packW * 0.46, packH - 4);
      final tankShader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFCFD8DC), // Chrome highlight
          Color(0xFF90A4AE), // Mid titanium
          Color(0xFF37474F), // Shadowed edge
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(tankRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(tankRect, const Radius.circular(4)),
        Paint()..shader = tankShader,
      );

      // Cyan Glowing Energy Fuel Core Slit
      final slitRect = Rect.fromLTWH(tankRect.left + 2.5, tankRect.top + 5, tankRect.width - 5, tankRect.height - 10);
      final slitPulse = 0.75 + 0.25 * math.sin(_totalElapsed * 6.0 + t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(slitRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85 * slitPulse),
      );

      // Bottom Bell Nozzles
      final nozzleRect = Rect.fromLTWH(tankRect.left - 1, packTop + packH - 4, tankRect.width + 2, 4.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(nozzleRect, const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF263238),
      );
      // Nozzle Heat Glow Rim
      canvas.drawLine(
        Offset(nozzleRect.left, nozzleRect.bottom),
        Offset(nozzleRect.right, nozzleRect.bottom),
        Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: isFiring ? 0.9 : 0.4)
          ..strokeWidth = 1.2,
      );

      // Top Intake Cap & LED
      final capRect = Rect.fromLTWH(tankRect.left + 1, packTop - 2.5, tankRect.width - 2, 3);
      canvas.drawOval(capRect, Paint()..color = const Color(0xFF455A64));
      canvas.drawCircle(
        Offset(tankRect.center.dx, packTop - 1),
        1.2,
        Paint()..color = (t == 0 ? const Color(0xFF76FF03) : const Color(0xFF00E5FF)),
      );
    }
  }

  /// 🚀 Sci-Fi Jetpack Mounting Harness & Chest Buckle (Front Layer over Dino)
  void _renderJetpackFront(Canvas canvas, Size drawSize) {
    final w = drawSize.width;
    final h = drawSize.height;

    // Dark carbon-fiber mounting strap over Dino's shoulder / chest
    final strapPaint = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: 0.85)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final strapPath = Path()
      ..moveTo(w * 0.28, h * 0.50)
      ..quadraticBezierTo(w * 0.38, h * 0.56, w * 0.52, h * 0.57);
    canvas.drawPath(strapPath, strapPaint);

    // Metallic Golden Chest Buckle Badge
    final buckleCenter = Offset(w * 0.44, h * 0.56);
    canvas.drawCircle(buckleCenter, 3.2, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(buckleCenter, 1.5, Paint()..color = const Color(0xFF37474F));
  }

  /// 🫧 Cute Iridescent Soap Bubble Shield centered on Dino
  void _renderSoapBubbleShield(Canvas canvas, Size drawSize) {
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.52);
    final baseRadius = math.max(drawSize.width, drawSize.height) * 0.68;
    // Smooth organic liquid bubble wobble
    final wobble = math.sin(_totalElapsed * 4.0) * 2.0;
    final bubbleRadius = baseRadius + wobble;

    final bubbleRect = Rect.fromCircle(center: center, radius: bubbleRadius);

    // 1. Translucent Soap Bubble Fill
    final bubbleFillShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: const [
        Color(0x45E0F7FA), // Translucent cyan center
        Color(0x2580DEEA),
        Color(0x35F8BBD0), // Soft pink/magenta refraction
        Color(0x5500E5FF), // Glowing rim edge
      ],
      stops: const [0.0, 0.45, 0.78, 1.0],
    ).createShader(bubbleRect);

    canvas.drawCircle(center, bubbleRadius, Paint()..shader = bubbleFillShader);

    // 2. Iridescent Rainbow Rim Stroke
    final rimShader = SweepGradient(
      center: Alignment.center,
      startAngle: _totalElapsed * 1.5,
      endAngle: _totalElapsed * 1.5 + math.pi * 2,
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
        ..strokeCap = StrokeCap.round,
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
    // Perfectly centered at Dino's waist/torso
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.62);
    final rx = drawSize.width * 0.58;
    final ry = 14.0;

    // Smooth continuous 360-degree rotation
    final hoopAngle = _totalElapsed * 2.8;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Back Arc Glow Halo
    final backHaloPath = Path()..addArc(hoopRect, math.pi, math.pi);
    canvas.drawPath(
      backHaloPath,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // 2. Back Arc Ring Gradient (Behind Dino)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: const [
        Color(0x8000E5FF),
        Color(0x80E040FB),
        Color(0x80FFFF8D),
        Color(0x8000E5FF),
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
          2.0,
          Paint()..color = Colors.white.withValues(alpha: 0.50),
        );
        canvas.drawCircle(
          Offset(ox, oy),
          3.6,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.30),
        );
      }
    }

    canvas.restore();
  }

  /// 🧲 3D Hula Hoop Magnet Ring - FRONT ARC (Drawn in front of Dino's body)
  void _renderHulaHoopMagnetFront(Canvas canvas, Size drawSize) {
    // Perfectly centered at Dino's waist/torso
    final center = Offset(drawSize.width * 0.50, drawSize.height * 0.62);
    final rx = drawSize.width * 0.58;
    final ry = 14.0;

    // Smooth continuous 360-degree rotation
    final hoopAngle = _totalElapsed * 2.8;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final hoopRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    // 1. Front Arc Glow Halo
    final frontArcPath = Path()..addArc(hoopRect, 0, math.pi);
    canvas.drawPath(
      frontArcPath,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // 2. Front Arc Ring Gradient (In front of Dino's belly)
    final ringShader = SweepGradient(
      center: Alignment.center,
      startAngle: hoopAngle,
      endAngle: hoopAngle + math.pi * 2,
      colors: const [
        Color(0xCC00E5FF),
        Color(0xCCE040FB),
        Color(0xCCFFFF8D),
        Color(0xCC00E5FF),
      ],
    ).createShader(hoopRect);

    canvas.drawPath(
      frontArcPath,
      Paint()
        ..shader = ringShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );

    // 3. Front Orbiting Sparkle Nodes (oy >= 0)
    for (int i = 0; i < 4; i++) {
      final a = hoopAngle + (i * math.pi / 2);
      final ox = math.cos(a) * rx;
      final oy = math.sin(a) * ry;

      if (oy >= 0) { // In front of Dino
        canvas.drawCircle(
          Offset(ox, oy),
          3.0,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(ox, oy),
          5.5,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.55),
        );
      }
    }

    canvas.restore();
  }
}
