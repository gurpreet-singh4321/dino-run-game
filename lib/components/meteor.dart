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
    // dt comes from the authoritative simulation clock.
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
    // Tapered glowing plasma wake along recent trail samples.
    for (int i = 0; i < trail.length; i++) {
      final t = (i + 1) / trail.length;
      final trailPos = trail[i] - position;
      canvas.drawCircle(
        Offset(trailPos.x, trailPos.y),
        size.x * 0.28 * t,
        Paint()
          ..color = Color.lerp(
            GameColors.meteorFire,
            const Color(0xFFFFF176),
            t * 0.6,
          )!.withValues(alpha: t * 0.48),
      );
    }

    final center = Offset(size.x / 2, size.y / 2);
    final r = size.x * 0.42;

    // Atmospheric incandescent halo.
    canvas.drawCircle(
      center,
      r * 1.45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            GameColors.meteorGlow.withValues(alpha: 0.45),
            GameColors.meteorFire.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.45)),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_angle);

    // Jagged molten-cracked asteroid body.
    final rock = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * (math.pi * 2 / 8);
      final rad = r * (i.isEven ? 1.04 : 0.85);
      final pt = Offset(math.cos(a) * rad, math.sin(a) * rad);
      if (i == 0) {
        rock.moveTo(pt.dx, pt.dy);
      } else {
        rock.lineTo(pt.dx, pt.dy);
      }
    }
    rock.close();
    canvas.drawPath(
      rock,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF9C7A82), Color(0xFF4F3841), Color(0xFF26171C)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );

    // Glowing magma fissure veins + impact craters.
    canvas.drawPath(
      Path()
        ..moveTo(-r * 0.45, -r * 0.1)
        ..lineTo(0, r * 0.25)
        ..lineTo(r * 0.45, -r * 0.2),
      Paint()
        ..color = const Color(0xFFFFAB40)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(r * 0.24, -r * 0.15),
      r * 0.22,
      Paint()..color = GameColors.meteorCrater,
    );
    canvas.drawCircle(
      Offset(-r * 0.20, r * 0.26),
      r * 0.16,
      Paint()..color = GameColors.meteorCrater,
    );

    canvas.restore();
  }
}
