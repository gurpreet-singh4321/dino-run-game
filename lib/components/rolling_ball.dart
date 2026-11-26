import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../game/hazard_contact.dart';
import '../utils/colors.dart';

/// Rolling Stone Ball (Desert) & Rolling Ice Ball (Ice Land) obstacle
class RollingBall extends PositionComponent
    with CollisionCallbacks, HasGameReference<DinoGame>, HazardContact {
  @override
  HazardMaterial get impactMaterial =>
      isIce ? HazardMaterial.ice : HazardMaterial.stone;
  final bool isIce;
  final double rollSpeed;
  double _rotationAngle = 0;
  @override
  bool isRemoved = false;
  bool passed = false;
  double _dustTimer = 0;

  RollingBall({required this.isIce, this.rollSpeed = 280.0}) {
    size = Vector2(58, 58); // 58px diameter ball
  }

  @override
  Future<void> onLoad() async {
    final groundY = game.ground.groundY;
    position = Vector2(game.size.x + 40, groundY - size.y);

    // Circular hitbox
    add(CircleHitbox(radius: size.x / 2 * 0.88, position: size * 0.06));
    priority = 5;
  }

  @override
  void update(double dt) {
    // dt comes from the authoritative simulation clock.
    super.update(dt);

    if (game.state == GameState.playing) {
      // Roll towards player faster than ground speed for dynamic challenge
      final totalSpeed = game.speedManager.currentSpeed + 135.0;
      position.x -= totalSpeed * dt;

      // Rotate proportional to rolling movement
      _rotationAngle += (totalSpeed / (size.x / 2)) * dt;

      // Kicking up dust/snow particles as it rolls!
      _dustTimer += dt;
      if (_dustTimer > 0.08) {
        _dustTimer = 0;
        if (isIce) {
          game.particlePool.emitJumpDust(
            position + Vector2(size.x / 2, size.y),
          );
        } else {
          game.particlePool.emitJumpDust(
            position + Vector2(size.x / 2, size.y),
          );
        }
      }
    }

    if (position.x + size.x < -40) {
      isRemoved = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);

    // Ground contact shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromLTWH(0, size.y - 4, size.x, 8), shadowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotationAngle);

    if (isIce) {
      _renderIceBall(canvas, radius);
    } else {
      _renderStoneBall(canvas, radius);
    }

    canvas.restore();
  }

  /// Render rolling canyon boulder with sculpted strata, fissures & mineral glints
  void _renderStoneBall(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = GameColors.rockDark,
    );

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r - 1.5,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [
            Color(0xFFC29064),
            Color(0xFF8C5D3C),
            Color(0xFF563526),
            Color(0xFF2D1913),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ).createShader(rect),
    );

    // Chiseled sedimentary strata arcs rotating realistically with the boulder.
    final strataPaint = Paint()
      ..color = const Color(0x5529150E)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(r * 0.28), -0.4, 2.2, false, strataPaint);
    canvas.drawArc(rect.deflate(r * 0.52), 2.1, 2.1, false, strataPaint);

    // Chiseled dark rock shadow polygon facets on lower-right side.
    final facetPath = Path()
      ..moveTo(-r * 0.1, r * 0.05)
      ..lineTo(r * 0.65, -r * 0.15)
      ..lineTo(r * 0.48, r * 0.65)
      ..lineTo(-r * 0.32, r * 0.55)
      ..close();
    canvas.drawPath(
      facetPath,
      Paint()..color = const Color(0x3D1F0E0A),
    );

    // Deep dark cracks paired with sunlit rim bevels.
    final crackDark = Paint()
      ..color = const Color(0xFF24130F)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final crackLit = Paint()
      ..color = const Color(0x66FFE2B8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crackPath = Path()
      ..moveTo(-r * 0.52, -r * 0.18)
      ..lineTo(-r * 0.08, r * 0.28)
      ..lineTo(r * 0.42, r * 0.08)
      ..moveTo(0, -r * 0.62)
      ..lineTo(r * 0.28, -r * 0.08);
    canvas.drawPath(crackPath.shift(const Offset(1, 1)), crackLit);
    canvas.drawPath(crackPath, crackDark);

    // Embedded gold ore flecks & upper-left sunlit rim crescent.
    final goldPaint = Paint()..color = const Color(0xFFFFD66B);
    for (final pt in [
      Offset(-r * 0.32, -r * 0.08),
      Offset(r * 0.22, r * 0.42),
      Offset(r * 0.36, -r * 0.34),
    ]) {
      canvas.drawCircle(pt, 1.9, goldPaint);
    }
    canvas.drawArc(
      rect.deflate(3),
      3.5,
      1.2,
      false,
      Paint()
        ..color = const Color(0x88FFE6BD)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Render rolling glacial ice sphere with crystalline shards & frost sheen
  void _renderIceBall(Canvas canvas, double r) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r + 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x6680F5FF),
            const Color(0x0080F5FF),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r + 4)),
    );

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFA7F0FA),
            Color(0xFF28B0CC),
            Color(0xFF0A607D),
          ],
          stops: [0.0, 0.32, 0.72, 1.0],
        ).createShader(rect),
    );

    // Internal angular refraction facet planes.
    final shard = Path()
      ..moveTo(-r * 0.45, -r * 0.15)
      ..lineTo(0, -r * 0.58)
      ..lineTo(r * 0.42, -r * 0.08)
      ..lineTo(r * 0.10, r * 0.48)
      ..close();
    canvas.drawPath(
      shard,
      Paint()..color = const Color(0x42FFFFFF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-r * 0.15, r * 0.05)
        ..lineTo(r * 0.55, r * 0.20)
        ..lineTo(0, r * 0.70)
        ..close(),
      Paint()..color = const Color(0x36083E59),
    );

    // Frosted snow-crust patches & crystalline fracture lines.
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.86)
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(-r * 0.6, -r * 0.1)
        ..lineTo(0, r * 0.2)
        ..lineTo(r * 0.5, -r * 0.4)
        ..moveTo(-r * 0.2, -r * 0.5)
        ..lineTo(r * 0.2, 0)
        ..lineTo(r * 0.3, r * 0.5),
      crackPaint,
    );

    // Specular ice gleam & frost sparkles.
    canvas.drawArc(
      rect.deflate(3.5),
      3.45,
      1.15,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(-r * 0.32, -r * 0.34),
      r * 0.20,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }
}
