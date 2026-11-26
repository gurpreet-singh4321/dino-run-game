import '../../game/desert_journey.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
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

  int _lastScore = -1;
  String _cachedScoreStr = '000000';
  int _lastHiScore = -1;
  String _cachedHiStr = 'HI 000000';
  int _lastCoins = -1;
  String _cachedCoinsStr = '0';

  static final Paint _hudPaint = Paint();
  static final Paint _heartShadowPaint = Paint()..color = Colors.black54;
  static final Paint _journeyBgPaint = Paint()..color = const Color(0xDD25384A);
  static final Paint _journeyBarPaint = Paint()
    ..color = const Color(0xFFFFD367);
  static final Path _unitHeartPath = Path()
    ..moveTo(0, 1)
    ..cubicTo(-2, -0.5, -1, -1.5, 0, -0.5)
    ..cubicTo(1, -1.5, 2, -0.5, 0, 1);
  static final ui.Picture _pausePic = _recordPausePic();
  static final ui.Picture _activeCartTokenPic = _recordCartTokenPic(true);
  static final ui.Picture _inactiveCartTokenPic = _recordCartTokenPic(false);

  static ui.Picture _recordPausePic() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final shadowPaint = Paint()..color = const Color(0x66000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -9.5, 6, 20),
        const Radius.circular(2),
      ),
      shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, -9.5, 6, 20),
        const Radius.circular(2),
      ),
      shadowPaint,
    );
    final barPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -11, 6, 20),
        const Radius.circular(2),
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, -11, 6, 20),
        const Radius.circular(2),
      ),
      barPaint,
    );
    return recorder.endRecording();
  }

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
    if (score != _lastScore) {
      _lastScore = score;
      _cachedScoreStr = score.toString().padLeft(6, '0');
    }
    final scoreStr = _cachedScoreStr;
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

    if (highScore != _lastHiScore) {
      _lastHiScore = highScore;
      _cachedHiStr = 'HI ${highScore.toString().padLeft(6, '0')}';
    }
    _smallPaint.render(
      canvas,
      _cachedHiStr,
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
      const Rect.fromLTWH(14, 15, 24, 24),
    );
    canvas.restore();

    if (coins != _lastCoins) {
      _lastCoins = coins;
      _cachedCoinsStr = '$coins';
    }
    canvas.save();
    if (coinScale != 1.0) {
      canvas.translate(55, 27);
      canvas.scale(coinScale, coinScale);
      canvas.translate(-55, -27);
    }
    _coinPaint.render(canvas, _cachedCoinsStr, Vector2(45, 16));
    canvas.restore();

    // 3. Lives (under coins)
    final lives = game.player.lives;
    for (int i = 0; i < 3; i++) {
      final color = i < lives
          ? GameColors.uiRed
          : const Color(0x669E9E9E);
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
        _journeyBgPaint,
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
        _journeyBarPaint,
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
    if (wave != 0.0) {
      canvas.rotate(wave * .08);
      canvas.scale(1 + wave * .06);
    }
    canvas.drawPicture(_pausePic);
    canvas.restore();
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    _hudPaint.color = color;
    canvas.save();
    canvas.translate(center.dx + 1, center.dy + 1);
    canvas.scale(size, size);
    canvas.drawPath(_unitHeartPath, _heartShadowPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(size, size);
    canvas.drawPath(_unitHeartPath, _hudPaint);
    canvas.restore();
  }

  void _drawCartToken(Canvas canvas, Offset center, {required bool active}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawPicture(active ? _activeCartTokenPic : _inactiveCartTokenPic);
    canvas.restore();
  }

  static ui.Picture _recordCartTokenPic(bool active) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const r = 9.0;
    canvas.drawCircle(
      const Offset(0.8, 1.2),
      r,
      Paint()..color = Colors.black54,
    );
    const circleRect = Rect.fromLTWH(-r, -r, r * 2, r * 2);
    canvas.drawCircle(
      Offset.zero,
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
      Offset.zero,
      r - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = active ? const Color(0xFF6E4312) : const Color(0x995B6B7A),
    );

    final ink = Paint()
      ..color = active ? const Color(0xFF1F2B3D) : const Color(0x889BA9B6);
    final body = Path()
      ..moveTo(-5.4, 1.4)
      ..lineTo(-5.2, -1.4)
      ..lineTo(-2.6, -3.6)
      ..lineTo(2.2, -3.4)
      ..lineTo(4.8, -1.1)
      ..lineTo(5.6, 1.4)
      ..close();
    canvas.drawPath(body, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.8, -2.7, 3.0, 1.6),
        const Radius.circular(0.8),
      ),
      Paint()
        ..color = active ? const Color(0xFFFFE599) : const Color(0x55232E38),
    );
    for (final wx in const [-3.2, 3.2]) {
      final wPos = Offset(wx, 2.1);
      canvas.drawCircle(wPos, 2.0, ink);
      canvas.drawCircle(
        wPos,
        0.8,
        Paint()
          ..color = active ? const Color(0xFFFFE082) : const Color(0x66C7D2DC),
      );
    }
    return recorder.endRecording();
  }
}
