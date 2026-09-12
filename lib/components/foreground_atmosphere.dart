import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';

/// Cinematic foreground layer adding:
/// 1. High-speed foreground silhouettes (1.45x parallax) with depth-of-field blur.
/// 2. Photographic vignette framing.
/// 3. Velocity-based aerodynamic wind streaks.
class ForegroundAtmosphere extends PositionComponent with HasGameReference<DinoGame> {
  double _scrollOffset = 0;

  ForegroundAtmosphere() {
    priority = 25; // Renders in front of gameplay plane, behind UI HUD
  }

  @override
  Future<void> onLoad() async {
    size = game.size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    size = game.size;

    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      _scrollOffset += game.speedManager.currentSpeed * 1.45 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.state == GameState.menu) return;

    final w = size.x;
    final h = size.y;

    // High-speed Aerodynamic Wind Streaks (Triggers at speed > 320 to deliver high-velocity juice!)
    _renderSpeedStreaks(canvas, w, h);
  }

  void _renderSpeedStreaks(Canvas canvas, double w, double h) {
    final currentSpeed = game.speedManager.currentSpeed;
    if (currentSpeed < 320) return;

    final intensity = ((currentSpeed - 320) / 130.0).clamp(0.0, 1.0);
    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22 * intensity)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final seed = i * 137.5;
      final speedFactor = 1.6 + (i % 3) * 0.4;
      final sx = (w + 200) - ((_scrollOffset * speedFactor + seed * 2) % (w + 400));
      final sy = (i < 4) ? (25.0 + (i * 22.0)) : (h - 90.0 + ((i - 4) * 20.0));
      final len = 65.0 + (i % 4) * 45.0;

      canvas.drawLine(Offset(sx, sy), Offset(sx + len, sy), streakPaint);
    }
  }
}
