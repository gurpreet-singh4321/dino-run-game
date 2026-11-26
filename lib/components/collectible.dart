import '../utils/gear_assets.dart';
import '../utils/coin_art.dart';
import '../utils/cart_art.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';

enum CollectibleType {
  coin,
  doubleCoin,
  shield,
  magnet,
  gravity,
  giant,
  dinoEgg,
  cart,
}

class Collectible extends PositionComponent
    with CollisionCallbacks, HasGameReference<DinoGame> {
  final CollectibleType collectType;
  double _animTimer = 0;
  double _glintTimer = 0;
  double _floatOffset = 0;
  double _previousBob = 0;
  bool _collected = false;

  // Smoothed magnet attraction state
  double _magnetVx = 0.0;
  double _magnetVy = 0.0;
  double _magnetTime = 0.0;

  static final math.Random _rng = math.Random();
  static final Paint _rimPaint = Paint()..color = const Color(0xFFA67128);
  static final Paint _glintPaint = Paint()
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  static final Paint _coinGlowPaint = Paint()
    ..color = const Color(0x40FFEA00);
  static final Paint _doubleCoinGlowPaint = Paint()
    ..color = const Color(0x59FFEA00);
  static final Paint _auraPaint = Paint();
  static final Paint _sparkPaint = Paint()..color = Colors.white;
  static final Paint _arcPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Path _arcPath = Path();

  static final ui.Picture _jetpackBadgePic = _recordJetpackBadgePic();
  static final ui.Picture _shieldBadgePic = _recordShieldBadgePic();
  static final ui.Picture _magnetBadgePic = _recordMagnetBadgePic();
  static final ui.Picture _giantBadgePic = _recordGiantBadgePic();
  static final ui.Picture _eggShellPic = _recordEggShellPic();

  Collectible({required this.collectType, required Vector2 position})
    : super(position: position, size: Vector2.all(42)) {
    resetCollectible();
  }

  /// Resets per-collectible state so pooled/recycled instances never inherit stale velocities.
  void resetCollectible() {
    _magnetVx = 0.0;
    _magnetVy = 0.0;
    _magnetTime = 0.0;
    _collected = false;
    _animTimer = 0.0;
    _glintTimer = 0.0;
    _previousBob = 0;
  }

  @override
  Future<void> onLoad() async {
    resetCollectible();
    // Only active actors (Dino) should collide with pickups, never other coins.
    add(CircleHitbox(radius: 21, collisionType: CollisionType.passive));
    priority = 6;
    _floatOffset = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void update(double dt) {
    // dt comes from the authoritative simulation clock.
    super.update(dt);
    if (_collected) return;

    // Scroll with the world
    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      position.x -= game.speedManager.currentSpeed * dt;
    }

    // Float bob
    _floatOffset += dt * 4;
    final bob = math.sin(_floatOffset) * 2.5;
    position.y += bob - _previousBob;
    _previousBob = bob;

    // Continuous 3D spin and glint timers
    _animTimer += dt;
    _glintTimer = (_glintTimer + dt) % 1.8;

    // Remove if off-screen
    if (position.x < -40) {
      removeFromParent();
    }

    // Giant Dino super collection radius (collects ALL coins touched in 140px radius!)
    if (game.player.giantTimer > 0) {
      final dinoCenter =
          game.player.position +
          Vector2(
            game.player.size.x * game.player.scale.x / 2,
            game.player.size.y * game.player.scale.y / 2,
          );
      final coinCenter = position + size / 2;
      final dist = dinoCenter.distanceTo(coinCenter);
      if (dist < 140) {
        onCollect();
        return;
      }
    }

    // Magnet attraction with curved ease-in acceleration (Only pulls coins/doubleCoins)
    final isCoin =
        collectType == CollectibleType.coin ||
        collectType == CollectibleType.doubleCoin;
    if (game.player.magnetTimer > 0 && isCoin) {
      final magnetLvl = game.coinManager.magnetLevel;
      final pullRadius = 160.0 + (magnetLvl * 30.0);
      final pullSpeed = 320.0 + (magnetLvl * 40.0);

      final dinoCenter =
          game.player.position +
          Vector2(
            (game.player.size.x * game.player.scale.x) / 2,
            (game.player.size.y * game.player.scale.y) / 2,
          );
      final coinCenter = position + size / 2;
      final dx = dinoCenter.x - coinCenter.x;
      final dy = dinoCenter.y - coinCenter.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < pullRadius && dist > 5) {
        _magnetTime += dt;
        final ramp = (_magnetTime / 0.15).clamp(0.0, 1.0);
        final targetVx = (dx / dist) * pullSpeed;
        final targetVy = (dy / dist) * pullSpeed;
        _magnetVx = ui.lerpDouble(_magnetVx, targetVx, dt * 10.0) ?? targetVx;
        _magnetVy = ui.lerpDouble(_magnetVy, targetVy, dt * 10.0) ?? targetVy;
        position.x += _magnetVx * ramp * dt;
        position.y += _magnetVy * ramp * dt;
      } else {
        _magnetTime = 0.0;
        _magnetVx = 0.0;
        _magnetVy = 0.0;
      }
    } else {
      _magnetTime = 0.0;
      _magnetVx = 0.0;
      _magnetVy = 0.0;
    }
  }

  void onCollect() {
    if (_collected) return;
    _collected = true;

    final magnetLvl = game.coinManager.magnetLevel;
    final shieldLvl = game.coinManager.shieldLevel;
    final cosmicLvl = game.coinManager.cosmicLevel;
    final multLvl = game.coinManager.multiplierLevel;

    final cosmicBonus = (game.state == GameState.spaceMode
        ? (1.0 + cosmicLvl * 0.5)
        : 1.0);

    switch (collectType) {
      case CollectibleType.coin:
        final bonus =
            (multLvl > 0 && _rng.nextDouble() < multLvl * 0.2) ? 2 : 1;
        game.score += (25 * bonus * cosmicBonus).toInt();
        game.coinManager.collectCoins(bonus);
        game.hud.triggerCoinPulse();
        break;
      case CollectibleType.doubleCoin:
        final bonus = 2 + (multLvl > 0 ? 1 : 0);
        game.score += (50 * (bonus / 2) * cosmicBonus).toInt();
        game.coinManager.collectCoins(bonus);
        game.hud.triggerCoinPulse();
        break;
      case CollectibleType.shield:
        final dur = 8.0 + (shieldLvl * 2.0);
        game.player.shieldTimer = (game.player.shieldTimer + dur).clamp(
          0.0,
          30.0,
        );
        break;
      case CollectibleType.magnet:
        final dur = 8.0 + (magnetLvl * 2.0);
        game.player.magnetTimer = (game.player.magnetTimer + dur).clamp(
          0.0,
          30.0,
        );
        break;
      case CollectibleType.gravity:
        game.enterSpaceMode();
        break;
      case CollectibleType.giant:
        game.player.giantTimer = (game.player.giantTimer + 10.0).clamp(
          0.0,
          25.0,
        );
        game.player.activateGiant();
        break;
      case CollectibleType.cart:
        game.player.collectCart();
        break;
      case CollectibleType.dinoEgg:
        game.score += (100 * cosmicBonus).toInt();
        game.coinManager.addCoins(5);
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
      case CollectibleType.cart:
        canvas.save();
        canvas.translate(0, 8);
        canvas.scale(.4);
        CartArt.rear(canvas, skinId: game.coinManager.equippedCartSkin);
        CartArt.front(
          canvas,
          charges: 3,
          distance: 0,
          skinId: game.coinManager.equippedCartSkin,
        );
        canvas.restore();
        break;
      case CollectibleType.dinoEgg:
        _renderDinoEgg(canvas);
        break;
    }
  }

  void _drawSingleCoinBody(Canvas canvas, double scaleX) {
    canvas.save();
    canvas.scale(scaleX, 1.0);

    // 3D Rim depth when turning edge-on
    if (scaleX < 0.4) {
      final rimOffset = (1.0 - scaleX) * 2.5;
      canvas.drawCircle(
        Offset(-rimOffset, 0),
        15,
        _rimPaint,
      );
    }

    CoinArt.draw(canvas, const Rect.fromLTWH(-15, -15, 30, 30));

    // Specular glint sweep across face every ~1.8 seconds
    if (scaleX > 0.3 && _glintTimer < 0.35) {
      final t = _glintTimer / 0.35;
      final gx = -13.0 + 26.0 * t;
      final glintAlpha = 0.75 * math.sin(t * math.pi);
      _glintPaint.color = Colors.white.withValues(alpha: glintAlpha);
      canvas.drawLine(Offset(gx - 4, -8), Offset(gx + 4, 8), _glintPaint);
    }
    canvas.restore();
  }

  void _renderCoin(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    // Continuous 3D spin illusion
    final scaleX = math.cos(_animTimer * 5.0).abs().clamp(0.08, 1.0);

    // Outer bright golden glow halo
    canvas.drawCircle(center, 19, _coinGlowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    _drawSingleCoinBody(canvas, scaleX);
    canvas.restore();
  }

  void _renderDoubleCoin(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final scaleX1 = math.cos(_animTimer * 5.0).abs().clamp(0.08, 1.0);
    final scaleX2 = math.cos((_animTimer + 0.18) * 5.0).abs().clamp(0.08, 1.0);

    // Double coin glowing aura
    canvas.drawCircle(center, 23, _doubleCoinGlowPaint);

    // 1. Back Coin (Offset top-left)
    canvas.save();
    canvas.translate(center.dx - 5, center.dy - 4);
    _drawSingleCoinBody(canvas, scaleX2);
    canvas.restore();

    // 2. Front Coin (Offset bottom-right)
    canvas.save();
    canvas.translate(center.dx + 5, center.dy + 4);
    _drawSingleCoinBody(canvas, scaleX1);
    canvas.restore();
  }

  /// 🚀 JETPACK / ROCKET POWERUP: Sleek cyan/silver rocket with flaming thrusters & badge
  void _renderJetpack(Canvas canvas) {
    canvas.drawPicture(_jetpackBadgePic);
    GearAssets.drawJetpack(canvas, const Rect.fromLTWH(10, 2, 24, 36));
  }

  static ui.Picture _recordJetpackBadgePic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(21, 21),
      20,
      Paint()..color = const Color(0xFF163A56),
    );
    canvas.drawCircle(
      const Offset(21, 21),
      20,
      Paint()
        ..color = const Color(0xFFFFD267)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    return recorder.endRecording();
  }

  void _renderShield(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.drawPicture(_shieldBadgePic);
    canvas.restore();
  }

  static ui.Picture _recordShieldBadgePic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()..color = const Color(0xFF29B6F6).withValues(alpha: 0.30),
    );
    final shieldPath = Path()
      ..moveTo(0, -16)
      ..lineTo(14, -16)
      ..quadraticBezierTo(15, 2, 0, 17)
      ..quadraticBezierTo(-15, 2, -14, -16)
      ..close();

    const shieldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0288D1), Color(0xFF01579B)],
    );
    const shieldRect = Rect.fromLTWH(-15, -16, 30, 33);
    canvas.drawPath(
      shieldPath,
      Paint()..shader = shieldGradient.createShader(shieldRect),
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final aOuter = (i * 72 - 90) * math.pi / 180;
      final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
      const rO = 6.5;
      const rI = 2.8;
      if (i == 0) {
        starPath.moveTo(math.cos(aOuter) * rO, -1 + math.sin(aOuter) * rO);
      } else {
        starPath.lineTo(math.cos(aOuter) * rO, -1 + math.sin(aOuter) * rO);
      }
      starPath.lineTo(math.cos(aInner) * rI, -1 + math.sin(aInner) * rI);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = const Color(0xFFFFD700));
    return recorder.endRecording();
  }

  /// 🧲 HORSESHOE MAGNET POWERUP: Classic Red/Blue Magnet with silver pole tips & force arcs
  void _renderMagnet(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawPicture(_magnetBadgePic);
    canvas.restore();

    // Animated magnetic force spark arc between tips
    _arcPath
      ..reset()
      ..moveTo(cx - 7, cy - 11)
      ..quadraticBezierTo(
        cx,
        cy - 15 + math.sin(_floatOffset * 8) * 2,
        cx + 7,
        cy - 11,
      );
    canvas.drawPath(_arcPath, _arcPaint);
  }

  static ui.Picture _recordMagnetBadgePic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()..color = const Color(0xFFAB47BC).withValues(alpha: 0.30),
    );
    const badgeRect = Rect.fromLTWH(-19, -19, 38, 38);
    canvas.drawCircle(
      Offset.zero,
      19,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
        ).createShader(badgeRect),
    );
    canvas.drawCircle(
      Offset.zero,
      19,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final uPath = Path()
      ..moveTo(-10, -8)
      ..lineTo(-10, 3)
      ..cubicTo(-10, 13, 10, 13, 10, 3)
      ..lineTo(10, -8)
      ..lineTo(5, -8)
      ..lineTo(5, 3)
      ..cubicTo(5, 8, -5, 8, -5, 3)
      ..lineTo(-5, -8)
      ..close();

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(-12, -10, 12, 25));
    canvas.drawPath(uPath, Paint()..color = const Color(0xFFE53935));
    canvas.restore();

    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, -10, 12, 25));
    canvas.drawPath(uPath, Paint()..color = const Color(0xFF1E88E5));
    canvas.restore();

    final tipPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRect(const Rect.fromLTWH(-10, -9, 5, 4), tipPaint);
    canvas.drawRect(const Rect.fromLTWH(5, -9, 5, 4), tipPaint);
    return recorder.endRecording();
  }

  /// ⭐ GIANT MEGA STAR POWERUP: Vibrant Golden Star with expanding magenta aura
  void _renderGiant(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Expanding Aura Glow
    final glowRadius = 20.0 + math.sin(_floatOffset * 4) * 3.0;
    _auraPaint.color = const Color(0x59FF4081);
    canvas.drawCircle(Offset(cx, cy), glowRadius, _auraPaint);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawPicture(_giantBadgePic);
    canvas.restore();
  }

  static ui.Picture _recordGiantBadgePic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const badgeRect = Rect.fromLTWH(-19, -19, 38, 38);
    canvas.drawCircle(
      Offset.zero,
      19,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFD81B60), Color(0xFF880E4F)],
        ).createShader(badgeRect),
    );
    canvas.drawCircle(
      Offset.zero,
      19,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final aOuter = (i * 72 - 90) * math.pi / 180;
      final aInner = ((i + 0.5) * 72 - 90) * math.pi / 180;
      const rO = 12.0;
      const rI = 5.2;
      if (i == 0) {
        starPath.moveTo(math.cos(aOuter) * rO, math.sin(aOuter) * rO);
      } else {
        starPath.lineTo(math.cos(aOuter) * rO, math.sin(aOuter) * rO);
      }
      starPath.lineTo(math.cos(aInner) * rI, math.sin(aInner) * rI);
    }
    starPath.close();

    const starGradient = RadialGradient(
      colors: [Color(0xFFFFFF8D), Color(0xFFFFD700), Color(0xFFFFAB00)],
    );
    canvas.drawPath(
      starPath,
      Paint()
        ..shader = starGradient.createShader(
          const Rect.fromLTWH(-12, -12, 24, 24),
        ),
    );
    canvas.drawPath(
      starPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    return recorder.endRecording();
  }

  void _renderDinoEgg(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // 1. Golden Life Pulse Aura
    final pulse = 0.85 + math.sin(_floatOffset * 5.0) * 0.15;
    _auraPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.35 * pulse);
    canvas.drawCircle(Offset(cx, cy), 22.0 * pulse, _auraPaint);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawPicture(_eggShellPic);
    canvas.restore();

    // 5. Sparkle Starlets Orbiting the Egg
    for (int i = 0; i < 3; i++) {
      final a = _floatOffset * 3.0 + (i * math.pi * 2 / 3);
      final sx = cx + math.cos(a) * 17.0;
      final sy = cy + math.sin(a) * 17.0;
      canvas.drawCircle(Offset(sx, sy), 1.5, _sparkPaint);
    }
  }

  static ui.Picture _recordEggShellPic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final eggPath = Path()
      ..moveTo(0, -18)
      ..cubicTo(14, -18, 16, 10, 12, 18)
      ..cubicTo(8, 22, -8, 22, -12, 18)
      ..cubicTo(-16, 10, -14, -18, 0, -18)
      ..close();

    const eggGradient = RadialGradient(
      center: Alignment(-0.3, -0.4),
      colors: [
        Color(0xFFFFF9C4),
        Color(0xFFFFE082),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
    );
    canvas.drawPath(
      eggPath,
      Paint()
        ..shader = eggGradient.createShader(
          const Rect.fromLTWH(-16, -20, 32, 40),
        ),
    );
    canvas.drawPath(
      eggPath,
      Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final spotPaint1 = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75);
    final spotPaint2 = Paint()
      ..color = const Color(0xFF76FF03).withValues(alpha: 0.70);
    final spotPaint3 = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.75);

    canvas.drawOval(
      const Rect.fromLTWH(-8.25, -10, 6.5, 8),
      spotPaint1,
    );
    canvas.drawOval(
      const Rect.fromLTWH(2.25, -0.5, 7.5, 9),
      spotPaint2,
    );
    canvas.drawOval(
      const Rect.fromLTWH(-6.75, 7, 5.5, 6),
      spotPaint3,
    );
    canvas.drawOval(
      const Rect.fromLTWH(2.75, -12.75, 4.5, 5.5),
      spotPaint2,
    );

    final crackPath = Path()
      ..moveTo(-6, -1)
      ..lineTo(-1, 3)
      ..lineTo(4, 1)
      ..lineTo(8, 7);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    return recorder.endRecording();
  }
}
