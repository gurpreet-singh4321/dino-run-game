import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../utils/colors.dart';

/// Lightweight particle system with actual visible particles.
class ParticlePool extends PositionComponent {
  final List<_Particle> _particles = [];

  void emitJumpDust(Vector2 pos) {
    _emit(pos, 6, GameColors.groundTop[0], 0.4, 30, 15);
  }

  void emitDesertFootstepDust(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 3; i++) {
      _particles.add(_Particle(
        x: pos.x - 4 + (rng.nextDouble() - 0.5) * 6,
        y: pos.y - 2 + (rng.nextDouble() - 0.5) * 4,
        vx: -60 - rng.nextDouble() * 50,
        vy: -15 - rng.nextDouble() * 25,
        life: 0.35,
        maxLife: 0.35,
        color: (i % 2 == 0) ? const Color(0xFFFBE49B) : const Color(0xFFE5A038),
        radius: 2.0 + rng.nextDouble() * 2.5,
      ));
    }
  }

  void emitDesertLandingImpact(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 16; i++) {
      final angle = math.pi + (rng.nextDouble() - 0.5) * (math.pi * 0.9);
      final speed = 50 + rng.nextDouble() * 110;
      final isQuartz = rng.nextDouble() > 0.7;
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 20,
        y: pos.y - 2,
        vx: math.cos(angle) * speed - 30,
        vy: -20 - rng.nextDouble() * 60,
        life: 0.55,
        maxLife: 0.55,
        color: isQuartz ? Colors.white : (i % 2 == 0 ? const Color(0xFFFFD54F) : const Color(0xFFD7CCC8)),
        radius: 2.2 + rng.nextDouble() * 3.0,
      ));
    }
  }

  void emitDesertNearMiss(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 16,
        y: pos.y + (rng.nextDouble() - 0.5) * 25,
        vx: -80 - rng.nextDouble() * 100,
        vy: (rng.nextDouble() - 0.5) * 90,
        life: 0.45,
        maxLife: 0.45,
        color: (i % 2 == 0) ? const Color(0xFFFFD700) : const Color(0xFFFFF9C4),
        radius: 1.8 + rng.nextDouble() * 2.8,
      ));
    }
  }

  void emitShieldBreak(Vector2 pos) {
    _emit(pos, 12, GameColors.shieldAura, 0.6, 60, 25);
  }

  void emitNearMiss(Vector2 pos) {
    _emit(pos, 8, Colors.yellow, 0.5, 50, 20);
  }

  void emitCoinCollect(Vector2 pos) {
    _emit(pos, 6, GameColors.coinGold, 0.4, 40, 15);
  }

  void emitGravityLaunch(Vector2 pos) {
    _emit(pos, 16, GameColors.gravityAura, 0.8, 80, 30);
  }

  void emitCuteDeath(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 14; i++) {
      final isHeart = i % 2 == 0;
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 35,
        y: pos.y + (rng.nextDouble() - 0.5) * 20,
        vx: (rng.nextDouble() - 0.5) * 70,
        vy: -50 - rng.nextDouble() * 80,
        life: 0.8,
        maxLife: 0.8,
        color: isHeart ? const Color(0xFFFF4081) : const Color(0xFFFFD700),
        radius: 3.5 + rng.nextDouble() * 3.5,
      ));
    }
  }

  void emitWaterSplash(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 5; i++) {
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 16,
        y: pos.y + (rng.nextDouble() - 0.5) * 4,
        vx: (rng.nextDouble() - 0.5) * 40,
        vy: -25 - rng.nextDouble() * 35,
        life: 0.35,
        maxLife: 0.35,
        color: Color.lerp(const Color(0xFF4DEEEA), Colors.white, rng.nextDouble())!,
        radius: 1.5 + rng.nextDouble() * 2.5,
      ));
    }
  }

  void emitLavaSparks(Vector2 pos) {
    final rng = math.Random();
    for (int i = 0; i < 8; i++) {
      final isRock = rng.nextDouble() > 0.6;
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 35,
        y: pos.y,
        vx: (rng.nextDouble() - 0.5) * 70,
        vy: -70 - rng.nextDouble() * 90,
        life: 0.65,
        maxLife: 0.65,
        color: isRock ? const Color(0xFF3E2723) : (rng.nextDouble() > 0.5 ? const Color(0xFFFFD700) : const Color(0xFFFF5722)),
        radius: isRock ? 2.5 + rng.nextDouble() * 3.5 : 1.5 + rng.nextDouble() * 2.5,
      ));
    }
  }

  void emitBiomeTransition() {
    // Full-width sparkle
    for (int i = 0; i < 20; i++) {
      final rng = math.Random();
      _particles.add(_Particle(
        x: rng.nextDouble() * 800,
        y: rng.nextDouble() * 400,
        vx: (rng.nextDouble() - 0.5) * 20,
        vy: (rng.nextDouble() - 0.5) * 20,
        life: 1.0,
        maxLife: 1.0,
        color: Colors.white,
        radius: 2 + rng.nextDouble() * 3,
      ));
    }
  }

  void _emit(Vector2 pos, int count, Color color, double maxLife, double spread, double maxRadius) {
    final rng = math.Random();
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: pos.x + (rng.nextDouble() - 0.5) * 10,
        y: pos.y + (rng.nextDouble() - 0.5) * 10,
        vx: (rng.nextDouble() - 0.5) * spread,
        vy: -(rng.nextDouble()) * spread * 0.8,
        life: maxLife,
        maxLife: maxLife,
        color: color,
        radius: 1.5 + rng.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 40 * dt; // gravity on particles
      p.life -= dt;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  static final _paint = Paint();

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius * alpha,
        _paint,
      );
    }
  }
}

class _Particle {
  double x, y, vx, vy, life, maxLife, radius;
  Color color;
  _Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.life, required this.maxLife,
    required this.color, required this.radius,
  });
}
