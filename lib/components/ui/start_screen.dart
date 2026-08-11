import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../utils/colors.dart';

/// Start/title screen rendered in the game canvas.
class StartScreen extends PositionComponent with HasGameReference<DinoGame> {
  double _time = 0;

  @override
  Future<void> onLoad() async {
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (game.state != GameState.menu) return;

    final cx = game.size.x / 2;
    final cy = game.size.y / 2;

    // Semi-transparent backdrop
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = const Color(0x66000000),
    );

    // Title
    final titlePaint = TextPaint(
      style: const TextStyle(
        color: GameColors.uiGreen,
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        shadows: [
          Shadow(color: Color(0xFF000000), offset: Offset(2, 2), blurRadius: 4),
          Shadow(color: GameColors.uiGreen, offset: Offset(0, 0), blurRadius: 12),
        ],
      ),
    );
    titlePaint.render(canvas, 'DINO RUN', Vector2(cx, cy - 80), anchor: Anchor.center);

    // Subtitle
    final subtitlePaint = TextPaint(
      style: const TextStyle(
        color: GameColors.gravityAura,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
        shadows: [
          Shadow(color: Color(0xFF000000), offset: Offset(1, 1), blurRadius: 2),
        ],
      ),
    );
    subtitlePaint.render(canvas, 'EPOCHS', Vector2(cx, cy - 40), anchor: Anchor.center);

    // Blinking "tap to start"
    final blink = (math.sin(_time * 3) + 1) / 2;
    final promptPaint = TextPaint(
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5 + blink * 0.5),
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
    promptPaint.render(canvas, 'TAP OR PRESS SPACE TO START',
        Vector2(cx, cy + 40), anchor: Anchor.center);

    // Total persistent coins & High score
    final totalCoins = game.coinManager.coins;
    final coinPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFD54F),
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3),
        ],
      ),
    );
    coinPaint.render(
      canvas,
      '🪙 TOTAL COINS: $totalCoins',
      Vector2(cx, cy + 75),
      anchor: Anchor.center,
    );

    final hi = game.coinManager.highScore;
    if (hi > 0) {
      final hiPaint = TextPaint(
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
      hiPaint.render(canvas, 'HIGH SCORE: $hi',
          Vector2(cx, cy + 102), anchor: Anchor.center);
    }

    // Mini dino preview (animated)
    final dinoX = cx - 20;
    final dinoY = cy + 110.0;
    final frame = (_time * 8).toInt() % 4;
    game.player.skin.renderRunning(canvas..save()..translate(dinoX, dinoY), const Size(40, 48), frame);
    canvas.restore();

    // Top Right Settings Button Prompt
    final settingsPaint = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFB300).withValues(alpha: 0.9),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3),
        ],
      ),
    );
    settingsPaint.render(
      canvas,
      '⚙ SETTINGS',
      Vector2(game.size.x - 20, 20),
      anchor: Anchor.topRight,
    );
  }
}
