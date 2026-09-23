import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../game/dino_game.dart';

/// Shows "NEAR MISS x3!" text that pops in, scales with combo heat, and displays combo breaks.
class ComboDisplay extends PositionComponent with HasGameReference<DinoGame> {
  double _timer = 0;
  int _combo = 0;
  bool _visible = false;

  double _popTimer = 0.0;
  static const double _popDuration = 0.18; // 180 ms scale pop

  bool _isBreaking = false;
  double _breakTimer = 0.0;
  static const double _breakDuration = 0.35; // 350 ms break flash

  @override
  Future<void> onLoad() async {
    priority = 60;
  }

  /// Heat color tier for combo streaks:
  /// < 5: white
  /// 5-9: electric gold
  /// 10-19: hot orange
  /// 20+: blazing crimson
  static Color getHeatColor(int combo) {
    if (combo < 5) {
      return const Color(0xFFFFFFFF);
    } else if (combo < 10) {
      return const Color(0xFFFFD700);
    } else if (combo < 20) {
      return const Color(0xFFFF9100);
    } else {
      return const Color(0xFFFF1744);
    }
  }

  void show(int combo) {
    _combo = combo;
    _timer = 1.2;
    _visible = true;
    _popTimer = _popDuration;
    _isBreaking = false;
  }

  /// Brief desaturated gray flash when combo is broken (by damage or timer expiry).
  void showComboBreak(int combo) {
    if (combo <= 0) return;
    _combo = combo;
    _isBreaking = true;
    _breakTimer = _breakDuration;
    _visible = true;
  }

  void hide() {
    _visible = false;
    _isBreaking = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_popTimer > 0) {
      _popTimer -= dt;
      if (_popTimer < 0) _popTimer = 0;
    }

    if (_isBreaking) {
      _breakTimer -= dt;
      if (_breakTimer <= 0) {
        _visible = false;
        _isBreaking = false;
      }
    } else if (_visible) {
      _timer -= dt;
      if (_timer <= 0) {
        _visible = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;

    if (_isBreaking) {
      final breakAlpha = (_breakTimer / _breakDuration).clamp(0.0, 1.0);
      final breakPaint = TextPaint(
        style: TextStyle(
          color: const Color(0xFF9E9E9E).withValues(alpha: breakAlpha), // Desaturated gray
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: breakAlpha * 0.8),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      );

      final renderPos = Vector2(game.player.position.x + 50, game.player.position.y - 30);
      breakPaint.render(
        canvas,
        'COMBO LOST!',
        renderPos,
      );
      return;
    }

    final alpha = (_timer / 1.2).clamp(0.0, 1.0);
    final yOffset = (1 - alpha) * 20;

    final popProgress = (1.0 - (_popTimer / _popDuration)).clamp(0.0, 1.0);
    final scale = _popTimer > 0 ? 1.0 + 0.35 * math.sin(popProgress * math.pi) : 1.0;

    final heatColor = getHeatColor(_combo);
    final fontSize = (22.0 + math.min(_combo, 20) * 1.2);

    final paint = TextPaint(
      style: TextStyle(
        color: heatColor.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha),
            offset: const Offset(1.5, 1.5),
            blurRadius: 3,
          ),
          if (_combo >= 10)
            Shadow(
              color: heatColor.withValues(alpha: alpha * 0.6),
              offset: Offset.zero,
              blurRadius: 8,
            ),
        ],
      ),
    );

    final renderX = game.player.position.x + 50.0;
    final renderY = game.player.position.y - 30.0 - yOffset;

    canvas.save();
    if (scale != 1.0) {
      canvas.translate(renderX, renderY);
      canvas.scale(scale, scale);
      canvas.translate(-renderX, -renderY);
    }

    paint.render(
      canvas,
      'NEAR MISS ×$_combo!',
      Vector2(renderX, renderY),
    );

    canvas.restore();
  }
}
