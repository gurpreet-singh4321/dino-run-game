import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';

/// Game over screen with score summary.
class GameOverScreen extends PositionComponent with HasGameReference<DinoGame> {
  double _time = 0;

  @override
  Future<void> onLoad() async {
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state == GameState.gameOver) {
      _time += dt;
    } else {
      _time = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.state != GameState.gameOver) return;

    final cx = game.size.x / 2;
    final cy = game.size.y / 2;

    // 1. Smooth Fade-To-Dark Backdrop
    final fadeProgress = (_time * 1.5).clamp(0.0, 1.0);
    final darkAlpha = 0.90 * fadeProgress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = Colors.black.withValues(alpha: darkAlpha),
    );

    // 2. Rolling Black Swirling Fog Clouds
    final fogPaint = Paint()..color = const Color(0x3B0C0D14);
    for (int i = 0; i < 7; i++) {
      final fogX = (game.size.x * 0.16 * i + _time * (18.0 + i * 6.0)) % (game.size.x + 240) - 120;
      final fogY = game.size.y * 0.18 + math.sin(_time * 0.7 + i * 1.1) * 35.0 + (i * 38.0);
      final radiusX = 150.0 + (i % 3) * 45.0;
      final radiusY = 80.0 + (i % 2) * 35.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fogX, fogY), width: radiusX * 2, height: radiusY * 2),
        fogPaint,
      );
    }

    // 3. Panel Background (Clean Dark Panel)
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 340, height: 300),
      const Radius.circular(22),
    );
    canvas.drawRRect(panelRect, Paint()..color = const Color(0xFF12171E));
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Title: GAME OVER
    final titlePaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFF5252),
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
    );
    titlePaint.render(canvas, 'GAME OVER', Vector2(cx, cy - 102), anchor: Anchor.center);

    // Score
    final scorePaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
    scorePaint.render(canvas, 'SCORE: ${game.score.toInt()}',
      Vector2(cx, cy - 58), anchor: Anchor.center);

    // High score & Coins
    final infoPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
    infoPaint.render(canvas, 'HIGH SCORE: ${game.coinManager.highScore}  |  COINS: ${game.coinManager.coins}',
      Vector2(cx, cy - 24), anchor: Anchor.center);

    // 4. HIGHLIGHTED REVIVE BUTTON (Pulsing Energy Glow Aura)
    final glowPulse = math.sin(_time * 5.0);
    final glowWidth = 240.0 + glowPulse * 10.0;
    final glowHeight = 48.0 + glowPulse * 4.0;
    final glowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: glowWidth, height: glowHeight),
      const Radius.circular(24),
    );
    final auraPaint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: 0.60 + glowPulse * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(glowRect, auraPaint);

    final reviveButtonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 228, height: 44),
      const Radius.circular(22),
    );

    final pulseColor = (glowPulse + 1) / 2;
    canvas.drawRRect(
      reviveButtonRect,
      Paint()..shader = LinearGradient(
        colors: [
          Color.lerp(const Color(0xFFFFC107), const Color(0xFF00E676), pulseColor)!,
          Color.lerp(const Color(0xFFFF9100), const Color(0xFF00E5FF), pulseColor)!,
        ],
      ).createShader(reviveButtonRect.outerRect),
    );
    canvas.drawRRect(
      reviveButtonRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final reviveTextPaint = TextPaint(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
    reviveTextPaint.render(
      canvas,
      '❤️ REVIVE',
      Vector2(cx, cy + 20),
      anchor: Anchor.center,
    );

    // 5. GOLDEN SUBTEXT BELOW REVIVE BUTTON
    final subtextPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
        ],
      ),
    );
    subtextPaint.render(
      canvas,
      'One More Try! (Restore 3 Lives)',
      Vector2(cx, cy + 54),
      anchor: Anchor.center,
    );

    // 6. MUTED SUBTLE CONTINUE OPTION (Encourages Revive!)
    final continueTextPaint = TextPaint(
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45 + math.sin(_time * 2.5) * 0.15),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
    continueTextPaint.render(
      canvas,
      'Continue...',
      Vector2(cx, cy + 94),
      anchor: Anchor.center,
    );
  }
}
