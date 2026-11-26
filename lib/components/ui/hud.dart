import '../../game/desert_journey.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../utils/colors.dart';
import '../../utils/coin_art.dart';

/// Clean plain-font HUD without card backgrounds or transparent pills.
class Hud extends PositionComponent with HasGameReference<DinoGame> {
  late final TextPaint _scorePaint;
  late final TextPaint _scorePopPaint;
  late final TextPaint _smallPaint;
  late final TextPaint _coinPaint;
  late final TextPaint _biomePaint;

  double _scorePopTimer = 0.0;
  double _controlArrival = 0;
  double _scorePopDuration = 0.25;
  double _scorePopMaxScale = 1.3;

  double _coinPulseTimer = 0.0;
  static const double _coinPulseDuration = 0.15; // 150 ms punchy pop

  void triggerScorePop({bool isMajor = false}) {
    _scorePopDuration = isMajor ? 0.35 : 0.25;
    _scorePopMaxScale = isMajor ? 1.5 : 1.3;
    _scorePopTimer = _scorePopDuration;
  }

  void triggerCoinPulse() {
    _coinPulseTimer = _coinPulseDuration;
  }

  @override
  void update(double dt) {
    // dt comes from the authoritative simulation clock.
    super.update(dt);
    _controlArrival = game.state == GameState.menu
        ? 0
        : (_controlArrival + dt).clamp(0, 1);
    if (_scorePopTimer > 0) {
      _scorePopTimer -= dt;
      if (_scorePopTimer < 0) _scorePopTimer = 0;
    }
    if (_coinPulseTimer > 0) {
      _coinPulseTimer -= dt;
      if (_coinPulseTimer < 0) _coinPulseTimer = 0;
    }
  }

  @override
  Future<void> onLoad() async {
    _scorePaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 4),
          Shadow(color: Color(0xFF4DEEEA), offset: Offset(0, 0), blurRadius: 6),
        ],
      ),
    );
    _scorePopPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFFFD54F),
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 4),
          Shadow(
            color: Color(0xFFFFB300),
            offset: Offset(0, 0),
            blurRadius: 10,
          ),
          Shadow(
            color: Color(0xFFFFE082),
            offset: Offset(0, 0),
            blurRadius: 16,
          ),
        ],
      ),
    );
    _smallPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFFFD54F),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black87,
            offset: Offset(1.5, 1.5),
            blurRadius: 3,
          ),
        ],
      ),
    );
    _coinPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFFFD54F),
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black87,
            offset: Offset(1.5, 1.5),
            blurRadius: 3,
          ),
        ],
      ),
    );
    _biomePaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        shadows: const [
          Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3),
        ],
      ),
    );
    priority = 1000; // Always render on top of all game components
  }

  @override
  void render(Canvas canvas) {
    if (game.state == GameState.menu || game.state == GameState.gameOver) {
      return;
    }

    if (game.slowMoTimer > 0) {
      final intensity = (game.slowMoTimer / 0.20).clamp(0.0, 1.0);
      final Rect rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
      final Paint vignettePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: intensity * 0.2),
            Colors.white.withValues(alpha: intensity * 0.6),
          ],
          stops: const [0.5, 0.85, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, vignettePaint);
    }

    final score = game.score.toInt();
    final highScore = game.coinManager.highScore;
    final coins = game.coinManager.runCoins;
    final rightX = game.size.x - 20.0;

    // 1. Plain Font Score & High Score (top-right, NO card background)
    final scoreStr = score.toString().padLeft(6, '0');
    final scorePos = Vector2(rightX, 14);

    if (_scorePopTimer > 0) {
      final progress = (1.0 - (_scorePopTimer / _scorePopDuration)).clamp(
        0.0,
        1.0,
      );
      final scale =
          1.0 + (_scorePopMaxScale - 1.0) * math.sin(progress * math.pi);
      final pivotX = rightX - 60.0;
      final pivotY = 14.0 + 14.0;

      canvas.save();
      canvas.translate(pivotX, pivotY);
      canvas.scale(scale, scale);
      canvas.translate(-pivotX, -pivotY);

      _scorePopPaint.render(
        canvas,
        scoreStr,
        scorePos,
        anchor: Anchor.topRight,
      );

      canvas.restore();
    } else {
      _scorePaint.render(canvas, scoreStr, scorePos, anchor: Anchor.topRight);
    }

    _smallPaint.render(
      canvas,
      'HI ${highScore.toString().padLeft(6, '0')}',
      Vector2(rightX, 46),
      anchor: Anchor.topRight,
    );

    // 2. Plain Font Coins Count (top-left, NO card background)
    final coinCenter = const Offset(26, 27);
    final coinScale = _coinPulseTimer > 0
        ? 1.0 +
              0.25 *
                  math.sin(
                    (1.0 - (_coinPulseTimer / _coinPulseDuration)).clamp(
                          0.0,
                          1.0,
                        ) *
                        math.pi,
                  )
        : 1.0;

    canvas.save();
    if (coinScale != 1.0) {
      canvas.translate(coinCenter.dx, coinCenter.dy);
      canvas.scale(coinScale, coinScale);
      canvas.translate(-coinCenter.dx, -coinCenter.dy);
    }
    CoinArt.draw(
      canvas,
      Rect.fromCenter(center: coinCenter, width: 24, height: 24),
    );
    canvas.restore();

    canvas.save();
    if (coinScale != 1.0) {
      canvas.translate(55, 27);
      canvas.scale(coinScale, coinScale);
      canvas.translate(-55, -27);
    }
    _coinPaint.render(canvas, '$coins', Vector2(45, 16));
    canvas.restore();

    // 3. Lives (under coins)
    final lives = game.player.lives;
    for (int i = 0; i < 3; i++) {
      final color = i < lives
          ? GameColors.uiRed
          : Colors.grey.withValues(alpha: 0.4);
      _drawHeart(canvas, Offset(26.0 + i * 22.0, 52.0), 8.0, color);
    }

    // Aligned with the 3 heart columns directly below: 3 yellow medallions with a car icon per remaining hit.
    if (game.player.cart.charges > 0) {
      for (var i = 0; i < 3; i++) {
        _drawCartToken(
          canvas,
          Offset(26.0 + i * 22.0, 74.0),
          active: i < game.player.cart.charges,
        );
      }
    }

    // 4. Biome Label (top-center, hidden in space mode)
    if (game.state != GameState.spaceMode) {
      final biomeName = game.biomeManager.effectiveBiome.name;
      _biomePaint.render(
        canvas,
        biomeName,
        Vector2(game.size.x / 2, 54),
        anchor: Anchor.topCenter,
      );
    }

    if (game.desertJourney.active) {
      final cx = game.size.x / 2;
      final rect = Rect.fromLTWH(cx - 140, 80, 280, 23);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = const Color(0xDD25384A),
      );
      _smallPaint.render(
        canvas,
        game.desertJourney.instruction(game.runDistance),
        Vector2(cx, 83),
        anchor: Anchor.topCenter,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - 130,
            107,
            260 * (game.runDistance / DesertJourney.length).clamp(0, 1),
            3,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFD367),
      );
    }
    // 5. Pause Button (top-center, plain bars)
    final cx = game.size.x / 2;
    final cy = 30.0;

    final context = game.buildContext;
    final quiet = context != null && MediaQuery.disableAnimationsOf(context);
    final wave = quiet
        ? 0.0
        : math.sin(_controlArrival * math.pi * 3) * (1 - _controlArrival);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(wave * .08);
    canvas.scale(1 + wave * .06);
    canvas.translate(-cx, -cy);
    final barShadow = Paint()
      ..color = Colors.black45
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(Rect.fromLTWH(cx - 8, cy - 10, 6, 20), barShadow);
    canvas.drawRect(Rect.fromLTWH(cx + 2, cy - 10, 6, 20), barShadow);

    final barPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 9, cy - 11, 6, 20),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 1, cy - 11, 6, 20),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size);
    path.cubicTo(
      center.dx - size * 2,
      center.dy - size * 0.5,
      center.dx - size,
      center.dy - size * 1.5,
      center.dx,
      center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size,
      center.dy - size * 1.5,
      center.dx + size * 2,
      center.dy - size * 0.5,
      center.dx,
      center.dy + size,
    );
    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()..color = Colors.black54,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCartToken(Canvas canvas, Offset center, {required bool active}) {
    const r = 9.0;
    canvas.drawCircle(
      center.translate(0.8, 1.2),
      r,
      Paint()..color = Colors.black54,
    );
    final circleRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? const [Color(0xFFFFEB9C), Color(0xFFFFCA4C), Color(0xFFDD9820)]
              : const [Color(0x99384654), Color(0x99232E38)],
        ).createShader(circleRect),
    );
    canvas.drawCircle(
      center,
      r - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = active ? const Color(0xFF6E4312) : const Color(0x995B6B7A),
    );

    // Miniature side-profile rover/cart inside the medallion.
    final ink = Paint()
      ..color = active ? const Color(0xFF1F2B3D) : const Color(0x889BA9B6);
    final body = Path()
      ..moveTo(center.dx - 5.4, center.dy + 1.4)
      ..lineTo(center.dx - 5.2, center.dy - 1.4)
      ..lineTo(center.dx - 2.6, center.dy - 3.6)
      ..lineTo(center.dx + 2.2, center.dy - 3.4)
      ..lineTo(center.dx + 4.8, center.dy - 1.1)
      ..lineTo(center.dx + 5.6, center.dy + 1.4)
      ..close();
    canvas.drawPath(body, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 1.8, center.dy - 2.7, 3.0, 1.6),
        const Radius.circular(0.8),
      ),
      Paint()
        ..color = active ? const Color(0xFFFFE599) : const Color(0x55232E38),
    );
    for (final wx in [center.dx - 3.2, center.dx + 3.2]) {
      final wPos = Offset(wx, center.dy + 2.1);
      canvas.drawCircle(wPos, 2.0, ink);
      canvas.drawCircle(
        wPos,
        0.8,
        Paint()
          ..color = active ? const Color(0xFFFFE082) : const Color(0x66C7D2DC),
      );
    }
  }
}
