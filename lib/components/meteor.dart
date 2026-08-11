import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../utils/colors.dart';

class Meteor extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  late Vector2 velocity;
  double rotationSpeed = 0;
  double _angle = 0;
  final List<Vector2> trail = [];

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    final sizeVar = 18 + rng.nextDouble() * 22;
    size = Vector2.all(sizeVar);

    position = Vector2(
      rng.nextDouble() * (game.size.x - size.x),
      -size.y - 10,
    );

    velocity = Vector2(
      (rng.nextDouble() - 0.5) * 90,
      150 + rng.nextDouble() * 150,
    );
    rotationSpeed = (rng.nextDouble() - 0.5) * 3;

    add(CircleHitbox(radius: size.x * 0.4));
    priority = 8;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    _angle += rotationSpeed * dt;

    // Trail
    if (game.frameCount % 3 == 0) {
      trail.add(position.clone() + size / 2);
    }
    if (trail.length > 8) {
      trail.removeAt(0);
    }

    if (position.y > game.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw trail
    for (int i = 0; i < trail.length; i++) {
      final alpha = (i / trail.length) * 0.6;
      final trailPos = trail[i] - position;
      canvas.drawCircle(
        Offset(trailPos.x, trailPos.y),
        size.x * 0.15 * (i / trail.length),
        Paint()
          ..color = GameColors.meteorFire.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Rotate the meteor
    final center = Offset(size.x / 2, size.y / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_angle);

    // Meteor body
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.4,
      Paint()..color = GameColors.meteorBody,
    );

    // Craters
    canvas.drawCircle(
      Offset(size.x * 0.1, -size.x * 0.05),
      size.x * 0.1,
      Paint()..color = GameColors.meteorCrater,
    );
    canvas.drawCircle(
      Offset(-size.x * 0.08, size.x * 0.12),
      size.x * 0.07,
      Paint()..color = GameColors.meteorCrater,
    );

    // Fire glow
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.45,
      Paint()
        ..color = GameColors.meteorGlow.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.restore();
  }
}
