import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../game/game_state.dart';
import '../../utils/colors.dart';

/// Progress bar showing remaining space mode coin-rain time.
class SpaceTimerBar extends PositionComponent with HasGameReference<DinoGame> {
  @override
  Future<void> onLoad() async {
    priority = 55;
  }

  @override
  void render(Canvas canvas) {
    // Only visible during coin rain phase
    if (game.state != GameState.spaceMode || game.spacePhase != SpacePhase.coinRain) {
      return;
    }

    final barWidth = game.size.x * 0.5;
    final barHeight = 8.0;
    final x = (game.size.x - barWidth) / 2;
    final y = 60.0;

    final progress = (game.spaceTimer / DinoGame.spaceCoinDuration).clamp(0.0, 1.0);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0x44FFFFFF),
    );

    // Fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth * progress, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = GameColors.gravityAura,
    );

    // Glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth * progress, barHeight),
        const Radius.circular(4),
      ),
      Paint()
        ..color = GameColors.gravityAura.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Label
    final labelPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPaint.render(canvas, 'SPACE MODE',
        Vector2(game.size.x / 2, y - 14), anchor: Anchor.center);
  }
}
