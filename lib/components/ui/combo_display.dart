import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';
import '../../utils/colors.dart';

/// Shows "NEAR MISS x3!" text that fades out.
class ComboDisplay extends PositionComponent with HasGameReference<DinoGame> {
  double _timer = 0;
  int _combo = 0;
  bool _visible = false;

  @override
  Future<void> onLoad() async {
    priority = 60;
  }

  void show(int combo) {
    _combo = combo;
    _timer = 1.2;
    _visible = true;
  }

  void hide() {
    _visible = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_visible) {
      _timer -= dt;
      if (_timer <= 0) {
        _visible = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;

    final alpha = (_timer / 1.2).clamp(0.0, 1.0);
    final yOffset = (1 - alpha) * 20;

    final paint = TextPaint(
      style: TextStyle(
        color: GameColors.coinGold.withValues(alpha: alpha),
        fontSize: 22 + _combo * 2.0,
        fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Color(0xFF000000).withValues(alpha: alpha), offset: const Offset(1, 1), blurRadius: 2)],
      ),
    );

    paint.render(
      canvas,
      'NEAR MISS ×$_combo!',
      Vector2(game.player.position.x + 50, game.player.position.y - 30 - yOffset),
    );
  }
}
