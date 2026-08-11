import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';

enum CollectibleType { coin, doubleCoin, shield, magnet, gravity, giant }

class Collectible extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  final CollectibleType collectType;
  double _animTimer = 0;
  int _animFrame = 0;
  double _floatOffset = 0;
  bool _collected = false;

  Collectible({required this.collectType, required Vector2 position})
    : super(position: position, size: Vector2.all(42));

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 21));
    priority = 6;
    _floatOffset = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    // Scroll with the world
    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      position.x -= game.speedManager.currentSpeed * dt;
    }

    // Float bob
    _floatOffset += dt * 4;
    position.y += math.sin(_floatOffset) * 0.35;

    // Spin animation
    _animTimer += dt;
    if (_animTimer >= 0.08) {
      _animTimer -= 0.08;
      _animFrame = (_animFrame + 1) % 4;
    }

    // Remove if off-screen
    if (position.x < -40) {
      removeFromParent();
    }

    // Giant Dino super collection radius (collects ALL coins touched in 140px radius!)
    if (game.player.giantTimer > 0) {
      final dinoCenter = game.player.position + Vector2(game.player.size.x * game.player.scale.x / 2, game.player.size.y * game.player.scale.y / 2);
      final coinCenter = position + size / 2;
      final dist = dinoCenter.distanceTo(coinCenter);
      if (dist < 140) {
        onCollect();
        return;
      }
    }

    // Magnet attraction
    if (game.player.magnetTimer > 0) {
      final dx = game.player.position.x - position.x;
      final dy = game.player.position.y - position.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 160 && dist > 5) {
        position.x += dx / dist * 320 * dt;
        position.y += dy / dist * 320 * dt;
      }
    }
  }

  void onCollect() {
    if (_collected) return;
    _collected = true;

    switch (collectType) {
      case CollectibleType.coin:
        game.score += 25;
        game.coinManager.addCoins(1);
        break;
      case CollectibleType.doubleCoin:
        game.score += 50;
        game.coinManager.addCoins(2); // Grants 2x coins!
        break;
      case CollectibleType.shield:
        game.player.shieldTimer = (game.player.shieldTimer + 8.0).clamp(0.0, 20.0);
        break;
      case CollectibleType.magnet:
        game.player.magnetTimer = (game.player.magnetTimer + 8.0).clamp(0.0, 20.0);
        break;
      case CollectibleType.gravity:
        game.enterSpaceMode();
        break;
      case CollectibleType.giant:
        game.player.giantTimer = (game.player.giantTimer + 10.0).clamp(0.0, 25.0);
        game.player.scale = Vector2.all(3.0);
        break;
    }

    game.particlePool.emitCoinCollect(position + size / 2);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;

    switch (collectType) {
      case CollectibleType.coin:
        _renderCoin(canvas);
        break;
      case CollectibleType.doubleCoin:
        _renderDoubleCoin(canvas);
        break;
      case CollectibleType.shield:
        _renderShield(canvas);
        break;
      case CollectibleType.magnet:
        _renderMagnet(canvas);
        break;
      case CollectibleType.gravity:
        _renderJetpack(canvas);
        break;
      case CollectibleType.giant:
        _renderGiant(canvas);
        break;
    }
  }

  void _drawSingleCoinBody(Canvas canvas, double scaleX) {
    canvas.save();
    canvas.scale(scaleX, 1.0);

    // Outer rim
    canvas.drawCircle(
      Offset.zero,
      15,
      Paint()..color = const Color(0xFFFF8F00),
    );

    // Inner golden body gradient
    final coinGradient = const RadialGradient(
      colors: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFFFB300)],
    );
    final coinRect = Rect.fromCircle(center: Offset.zero, radius: 13);
    canvas.drawCircle(
      Offset.zero,
      13,
      Paint()..shader = coinGradient.createShader(coinRect),
    );

    // Inner rim line
    canvas.drawCircle(
      Offset.zero,
      10,
      Paint()
        ..color = const Color(0xFFFF8F00).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Shiny star highlight
    if (scaleX > 0.4) {
      canvas.drawCircle(
        const Offset(-3, -3),
        3,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    canvas.restore();
  }

  void _renderCoin(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final scaleX = [1.0, 0.6, 0.25, 0.6][_animFrame];

    // Outer bright golden glow halo
    canvas.drawCircle(
      center,
      19,
      Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    _drawSingleCoinBody(canvas, scaleX);
    canvas.restore();
  }

  void _renderDoubleCoin(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final scaleX = [1.0, 0.6, 0.25, 0.6][_animFrame];

    // Double coin glowing aura
    canvas.drawCircle(
      center,
      23,
      Paint()
        ..color = const Color(0xFFFFEA00).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 1. Back Coin (Offset top-left)
    canvas.save();
    canvas.translate(center.dx - 5, center.dy - 4);
    _drawSingleCoinBody(canvas, scaleX);
    canvas.restore();

    // 2. Front Coin (Offset bottom-right)
    canvas.save();
    canvas.translate(center.dx + 5, center.dy + 4);
    _drawSingleCoinBody(canvas, scaleX);
    canvas.restore();
  }

  /// 🚀 JETPACK / ROCKET POWERUP: Sleek cyan/silver rocket with flaming thrusters & badge
  void _renderJetpack(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Pulsing thruster energy aura glow
    final auraRadius = 20.0 + math.sin(_floatOffset * 3) * 2.0;
    canvas.drawCircle(
      Offset(cx, cy),
      auraRadius + 5,
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Circular Cyan/Blue Powerup Container Badge
    final badgeGradient = const RadialGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF00838F), Color(0xFF004D40)],
    );
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = badgeGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 19)));
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // 3. Rocket Thruster Exhaust Flame (Bottom)
    final flamePath = Path()
      ..moveTo(cx - 5, cy + 8)
      ..quadraticBezierTo(cx, cy + 17 + math.sin(_floatOffset * 10) * 3, cx + 5, cy + 8)
      ..close();
    final flameGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFEA00), Color(0xFFFF3D00)],
    );
    canvas.drawPath(flamePath, Paint()..shader = flameGradient.createShader(Rect.fromLTWH(cx - 5, cy + 8, 10, 10)));

    // 4. Sleek Metallic Rocket Fuselage
    final rocketPath = Path()
      ..moveTo(cx, cy - 13) // Rocket Nose Cone
      ..cubicTo(cx + 8, cy - 5, cx + 7, cy + 6, cx + 6, cy + 8) // Right Body
      ..lineTo(cx - 6, cy + 8) // Bottom Thruster Base
      ..cubicTo(cx - 7, cy + 6, cx - 8, cy - 5, cx, cy - 13) // Left Body
      ..close();
    canvas.drawPath(rocketPath, Paint()..color = Colors.white);

    // Red Nose Cone Tip
    final nosePath = Path()
      ..moveTo(cx, cy - 13)
      ..quadraticBezierTo(cx + 4, cy - 7, cx + 5, cy - 5)
      ..lineTo(cx - 5, cy - 5)
      ..quadraticBezierTo(cx - 4, cy - 7, cx, cy - 13)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFFF1744));

    // Rocket Side Fins
    canvas.drawPath(
      Path()..moveTo(cx - 5, cy + 3)..lineTo(cx - 10, cy + 9)..lineTo(cx - 5, cy + 8)..close(),
      Paint()..color = const Color(0xFFFF1744),
    );
    canvas.drawPath(
      Path()..moveTo(cx + 5, cy + 3)..lineTo(cx + 10, cy + 9)..lineTo(cx + 5, cy + 8)..close(),
      Paint()..color = const Color(0xFFFF1744),
    );

    // Circular Porthole Window
    canvas.drawCircle(Offset(cx, cy - 1), 3.0, Paint()..color = const Color(0xFF00B0FF));
    canvas.drawCircle(Offset(cx - 0.8, cy - 1.8), 1.0, Paint()..color = Colors.white);
  }

  /// 🛡️ DEFENDER SHIELD POWERUP: Metallic Blue/Gold Shield with star emblem
  void _renderShield(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Protective Cyan Energy Glow
    canvas.drawCircle(
      Offset(cx, cy),
      22,
      Paint()
        ..color = const Color(0xFF29B6F6).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Shield Body Path
    final shieldPath = Path()
      ..moveTo(cx, cy - 16)
      ..lineTo(cx + 14, cy - 16)
      ..quadraticBezierTo(cx + 15, cy + 2, cx, cy + 17)
      ..quadraticBezierTo(cx - 15, cy + 2, cx - 14, cy - 16)
      ..close();

    final shieldGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0288D1), Color(0xFF01579B)],
    );
    final shieldRect = Rect.fromLTWH(cx - 15, cy - 16, 30, 33);
    canvas.drawPath(shieldPath, Paint()..shader = shieldGradient.createShader(shieldRect));

    // Golden Rim Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(shieldPath, borderPaint);

    // Golden Star Emblem in Center
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final aOuter = (i * 72 - 90) * math.pi / 180;
      final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
      final rO = 6.5;
      final rI = 2.8;
      if (i == 0) {
        starPath.moveTo(cx + math.cos(aOuter) * rO, cy - 1 + math.sin(aOuter) * rO);
      } else {
        starPath.lineTo(cx + math.cos(aOuter) * rO, cy - 1 + math.sin(aOuter) * rO);
      }
      starPath.lineTo(cx + math.cos(aInner) * rI, cy - 1 + math.sin(aInner) * rI);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD700));
  }

  /// 🧲 HORSESHOE MAGNET POWERUP: Classic Red/Blue Magnet with silver pole tips & force arcs
  void _renderMagnet(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Magnetic Field Glow
    canvas.drawCircle(
      Offset(cx, cy),
      22,
      Paint()
        ..color = const Color(0xFFAB47BC).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Circular Purple Container Badge
    final badgeRect = Rect.fromCircle(center: Offset(cx, cy), radius: 19);
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = const RadialGradient(colors: [Color(0xFF8E24AA), Color(0xFF4A148C)]).createShader(badgeRect));
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // 3. Horseshoe Magnet U-Shape
    final uPath = Path()
      ..moveTo(cx - 10, cy - 8)
      ..lineTo(cx - 10, cy + 3)
      ..cubicTo(cx - 10, cy + 13, cx + 10, cy + 13, cx + 10, cy + 3)
      ..lineTo(cx + 10, cy - 8)
      ..lineTo(cx + 5, cy - 8)
      ..lineTo(cx + 5, cy + 3)
      ..cubicTo(cx + 5, cy + 8, cx - 5, cy + 8, cx - 5, cy + 3)
      ..lineTo(cx - 5, cy - 8)
      ..close();

    // Red North Arm (Left)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx - 12, cy - 10, 12, 25));
    canvas.drawPath(uPath, Paint()..color = const Color(0xFFE53935));
    canvas.restore();

    // Blue South Arm (Right)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, cy - 10, 12, 25));
    canvas.drawPath(uPath, Paint()..color = const Color(0xFF1E88E5));
    canvas.restore();

    // Silver Pole Tips
    final tipPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRect(Rect.fromLTWH(cx - 10, cy - 9, 5, 4), tipPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 5, cy - 9, 5, 4), tipPaint);

    // Magnetic Force Spark Arcs between tips
    final arcPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final arcPath = Path()
      ..moveTo(cx - 7, cy - 11)
      ..quadraticBezierTo(cx, cy - 15 + math.sin(_floatOffset * 8) * 2, cx + 7, cy - 11);
    canvas.drawPath(arcPath, arcPaint);
  }

  /// ⭐ GIANT MEGA STAR POWERUP: Vibrant Golden Star with expanding magenta aura
  void _renderGiant(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Expanding Aura Glow
    final glowRadius = 20.0 + math.sin(_floatOffset * 4) * 3.0;
    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Purple Badge
    final badgeRect = Rect.fromCircle(center: Offset(cx, cy), radius: 19);
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..shader = const RadialGradient(colors: [Color(0xFFD81B60), Color(0xFF880E4F)]).createShader(badgeRect));
    canvas.drawCircle(Offset(cx, cy), 19, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // 3. Mega Golden 5-Pointed Star
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final aOuter = (i * 72 - 90) * math.pi / 180;
      final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
      final rO = 12.0;
      final rI = 5.2;
      if (i == 0) {
        starPath.moveTo(cx + math.cos(aOuter) * rO, cy + math.sin(aOuter) * rO);
      } else {
        starPath.lineTo(cx + math.cos(aOuter) * rO, cy + math.sin(aOuter) * rO);
      }
      starPath.lineTo(cx + math.cos(aInner) * rI, cy + math.sin(aInner) * rI);
    }
    starPath.close();

    final starGradient = const RadialGradient(colors: [Color(0xFFFFFF8D), Color(0xFFFFD700), Color(0xFFFFAB00)]);
    canvas.drawPath(starPath, Paint()..shader = starGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 12)));
    canvas.drawPath(starPath, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }
}
