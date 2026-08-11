import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../utils/colors.dart';

/// Rolling Stone Ball (Desert) & Rolling Ice Ball (Ice Land) obstacle
class RollingBall extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
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
          game.particlePool.emitJumpDust(position + Vector2(size.x / 2, size.y));
        } else {
          game.particlePool.emitJumpDust(position + Vector2(size.x / 2, size.y));
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

  /// Render rolling stone ball with fissures & rock shading
  void _renderStoneBall(Canvas canvas, double r) {
    // Outer rock circle
    final rockPaint = Paint()..color = GameColors.rockDark;
    canvas.drawCircle(Offset.zero, r, rockPaint);

    // Rock body gradient
    final gradient = const RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
    );
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(Offset.zero, r - 2, Paint()..shader = gradient.createShader(rect));

    // Rock fissure lines
    final crackPaint = Paint()
      ..color = const Color(0xFF261815)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final crackPath = Path()
      ..moveTo(-r * 0.5, -r * 0.2)
      ..lineTo(-r * 0.1, r * 0.3)
      ..lineTo(r * 0.4, r * 0.1)
      ..moveTo(0, -r * 0.6)
      ..lineTo(r * 0.3, -r * 0.1);
    canvas.drawPath(crackPath, crackPaint);

    // Highlights
    final hlPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.35), r * 0.2, hlPaint);
  }

  /// Render rolling ice ball with frozen ice cracks & glistening frost
  void _renderIceBall(Canvas canvas, double r) {
    // Outer ice glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4DEEEA).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, r + 2, glowPaint);

    // Ice body gradient
    final gradient = const RadialGradient(
      center: Alignment(-0.3, -0.3),
      colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF00ACC1), Color(0xFF006064)],
    );
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(Offset.zero, r, Paint()..shader = gradient.createShader(rect));

    // Frozen ice cracks
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final crackPath = Path()
      ..moveTo(-r * 0.6, -r * 0.1)
      ..lineTo(0, r * 0.2)
      ..lineTo(r * 0.5, -r * 0.4)
      ..moveTo(-r * 0.2, -r * 0.5)
      ..lineTo(r * 0.2, 0)
      ..lineTo(r * 0.3, r * 0.5);
    canvas.drawPath(crackPath, crackPaint);

    // Glistening frost highlight
    final hlPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.35), r * 0.25, hlPaint);
  }
}
