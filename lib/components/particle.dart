import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../utils/colors.dart';

import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../game/hazard_contact.dart';

/// Lightweight particle system with pooled particles and zero per-frame allocations.
class ParticlePool extends PositionComponent with HasGameReference<DinoGame> {
  final List<_Particle> _particles = [];
  final List<_Particle> _freePool = [];
  final math.Random _rng = math.Random();
  int _oldestIndex = 0;

  static const maxParticles = 192;
  void clear() {
    _freePool.addAll(_particles);
    _particles.clear();
    _oldestIndex = 0;
  }

  int get activeParticleCount => _particles.length;

  void _spawnParticle({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double maxLife,
    required Color color,
    required double radius,
    HazardMaterial? material,
    double angle = 0,
    bool isLine = false,
    double length = 0,
    bool isRing = false,
    double startRadius = 0,
    double endRadius = 0,
  }) {
    final _Particle p;
    if (_particles.length >= maxParticles) {
      if (_oldestIndex >= _particles.length) _oldestIndex = 0;
      p = _particles[_oldestIndex];
      _oldestIndex = (_oldestIndex + 1) % maxParticles;
      p.reset(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        life: life,
        maxLife: maxLife,
        color: color,
        radius: radius,
        material: material,
        angle: angle,
        isLine: isLine,
        length: length,
        isRing: isRing,
        startRadius: startRadius,
        endRadius: endRadius,
      );
      return;
    }
    if (_freePool.isNotEmpty) {
      p = _freePool.removeLast()
        ..reset(
          x: x,
          y: y,
          vx: vx,
          vy: vy,
          life: life,
          maxLife: maxLife,
          color: color,
          radius: radius,
          material: material,
          angle: angle,
          isLine: isLine,
          length: length,
          isRing: isRing,
          startRadius: startRadius,
          endRadius: endRadius,
        );
    } else {
      p = _Particle(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        life: life,
        maxLife: maxLife,
        color: color,
        radius: radius,
        material: material,
        angle: angle,
        isLine: isLine,
        length: length,
        isRing: isRing,
        startRadius: startRadius,
        endRadius: endRadius,
      );
    }
    _particles.add(p);
  }

  void _addParticle(_Particle particle) {
    if (_particles.length >= maxParticles) {
      if (_oldestIndex >= _particles.length) _oldestIndex = 0;
      _freePool.add(_particles[_oldestIndex]);
      _particles[_oldestIndex] = particle;
      _oldestIndex = (_oldestIndex + 1) % maxParticles;
      return;
    }
    _particles.add(particle);
  }

  void emitStumble(Vector2 pos) {
    _emit(pos, 6, const Color(0xFFEAC58A), .32, 70, 4);
  }

  void emitSmash(Vector2 pos, HazardMaterial material) {
    final palette = switch (material) {
      HazardMaterial.stone => const [Color(0xFF94745D), Color(0xFFD4B69B)],
      HazardMaterial.wood => const [Color(0xFF92542C), Color(0xFFDFB06C)],
      HazardMaterial.ice => const [Color(0xFF70D9EF), Color(0xFFE6FCFF)],
      HazardMaterial.crystal => const [Color(0xFFAA78ED), Color(0xFF7EF4EB)],
      HazardMaterial.plant => const [Color(0xFF4DA857), Color(0xFFA9D55F)],
      HazardMaterial.metal => const [Color(0xFF7298AE), Color(0xFFE3EEF4)],
      HazardMaterial.feathers => const [Color(0xFFEAAC61), Color(0xFFFFE6A4)],
      HazardMaterial.fire => const [Color(0xFFFF883E), Color(0xFFFFD763)],
    };
    if (material == HazardMaterial.feathers) {
      // A living bird escapes upward; it never breaks into fragments.
      _addParticle(
        _Particle(
          x: pos.x,
          y: pos.y,
          vx: 180,
          vy: -170,
          life: .65,
          maxLife: .65,
          color: palette.first,
          radius: 10,
          material: material,
        ),
      );
      return;
    }
    for (var i = 0; i < 12; i++) {
      _addParticle(
        _Particle(
          x: pos.x,
          y: pos.y,
          vx: (i.isEven ? -1 : 1) * (35 + _rng.nextDouble() * 100),
          vy: -60 - _rng.nextDouble() * 110,
          life: .55,
          maxLife: .55,
          color: palette[i % 2],
          radius: 2 + _rng.nextDouble() * 3,
          material: material,
          angle: _rng.nextDouble() * math.pi,
        ),
      );
    }
  }

  void emitJumpDust(Vector2 pos) {
    _emit(pos, 6, GameColors.groundTop[0], 0.4, 30, 15);
  }

  void emitDesertFootstepDust(Vector2 pos) {
    for (int i = 0; i < 3; i++) {
      _addParticle(
        _Particle(
          x: pos.x - 4 + (_rng.nextDouble() - 0.5) * 6,
          y: pos.y - 2 + (_rng.nextDouble() - 0.5) * 4,
          vx: -60 - _rng.nextDouble() * 50,
          vy: -15 - _rng.nextDouble() * 25,
          life: 0.35,
          maxLife: 0.35,
          color: (i % 2 == 0)
              ? const Color(0xFFFBE49B)
              : const Color(0xFFE5A038),
          radius: 2.0 + _rng.nextDouble() * 2.5,
        ),
      );
    }
  }

  void emitDesertLandingImpact(Vector2 pos) {
    for (int i = 0; i < 16; i++) {
      final angle = math.pi + (_rng.nextDouble() - 0.5) * (math.pi * 0.9);
      final speed = 50 + _rng.nextDouble() * 110;
      final isQuartz = _rng.nextDouble() > 0.7;
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 20,
          y: pos.y - 2,
          vx: math.cos(angle) * speed - 30,
          vy: -20 - _rng.nextDouble() * 60,
          life: 0.55,
          maxLife: 0.55,
          color: isQuartz
              ? Colors.white
              : (i % 2 == 0
                    ? const Color(0xFFFFD54F)
                    : const Color(0xFFD7CCC8)),
          radius: 2.2 + _rng.nextDouble() * 3.0,
        ),
      );
    }
  }

  void emitDesertNearMiss(Vector2 pos) {
    for (int i = 0; i < 12; i++) {
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 16,
          y: pos.y + (_rng.nextDouble() - 0.5) * 25,
          vx: -80 - _rng.nextDouble() * 100,
          vy: (_rng.nextDouble() - 0.5) * 90,
          life: 0.45,
          maxLife: 0.45,
          color: (i % 2 == 0)
              ? const Color(0xFFFFD700)
              : const Color(0xFFFFF9C4),
          radius: 1.8 + _rng.nextDouble() * 2.8,
        ),
      );
    }
  }

  void emitShieldBreak(Vector2 pos) {
    _emit(pos, 12, GameColors.shieldAura, 0.6, 60, 25);
  }

  void emitNearMiss(Vector2 pos) {
    _emit(pos, 8, Colors.yellow, 0.5, 50, 20);
  }

  void emitCoinCollect(Vector2 pos) {
    // 6-8 small gold sparkle particles
    final count = 6 + _rng.nextInt(3);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _rng.nextDouble() * 60.0;
      final color = i % 2 == 0 ? GameColors.coinGold : const Color(0xFFFFF9C4);
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 6,
          y: pos.y + (_rng.nextDouble() - 0.5) * 6,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 20.0,
          life: 0.35 + _rng.nextDouble() * 0.15,
          maxLife: 0.50,
          color: color,
          radius: 1.5 + _rng.nextDouble() * 2.0,
        ),
      );
    }

    // Quick expanding ring: radius 12 -> 28, alpha fade over ~0.20s
    _addParticle(
      _Particle(
        x: pos.x,
        y: pos.y,
        vx: 0,
        vy: 0,
        life: 0.20,
        maxLife: 0.20,
        color: const Color(0xFFFFD54F),
        radius: 12.0,
        isRing: true,
        startRadius: 12.0,
        endRadius: 28.0,
      ),
    );
  }

  void emitGravityLaunch(Vector2 pos) {
    _emit(pos, 16, GameColors.gravityAura, 0.8, 80, 30);
  }

  void emitCuteDeath(Vector2 pos) {
    for (int i = 0; i < 14; i++) {
      final isHeart = i % 2 == 0;
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 35,
          y: pos.y + (_rng.nextDouble() - 0.5) * 20,
          vx: (_rng.nextDouble() - 0.5) * 70,
          vy: -50 - _rng.nextDouble() * 80,
          life: 0.8,
          maxLife: 0.8,
          color: isHeart ? const Color(0xFFFF4081) : const Color(0xFFFFD700),
          radius: 3.5 + _rng.nextDouble() * 3.5,
        ),
      );
    }
  }

  void emitWaterSplash(Vector2 pos) {
    for (int i = 0; i < 5; i++) {
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 16,
          y: pos.y + (_rng.nextDouble() - 0.5) * 4,
          vx: (_rng.nextDouble() - 0.5) * 40,
          vy: -25 - _rng.nextDouble() * 35,
          life: 0.35,
          maxLife: 0.35,
          color: Color.lerp(
            const Color(0xFF4DEEEA),
            Colors.white,
            _rng.nextDouble(),
          )!,
          radius: 1.5 + _rng.nextDouble() * 2.5,
        ),
      );
    }
  }

  void emitLavaSparks(Vector2 pos) {
    for (int i = 0; i < 8; i++) {
      final isRock = _rng.nextDouble() > 0.6;
      _addParticle(
        _Particle(
          x: pos.x + (_rng.nextDouble() - 0.5) * 35,
          y: pos.y,
          vx: (_rng.nextDouble() - 0.5) * 70,
          vy: -70 - _rng.nextDouble() * 90,
          life: 0.65,
          maxLife: 0.65,
          color: isRock
              ? const Color(0xFF3E2723)
              : (_rng.nextDouble() > 0.5
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFF5722)),
          radius: isRock
              ? 2.5 + _rng.nextDouble() * 3.5
              : 1.5 + _rng.nextDouble() * 2.5,
        ),
      );
    }
  }

  void emitLavaEmber(Vector2 pos) {
    _addParticle(
      _Particle(
        x: pos.x + (_rng.nextDouble() - 0.5) * 24,
        y: pos.y,
        vx: (_rng.nextDouble() - 0.5) * 20,
        vy: -35 - _rng.nextDouble() * 35,
        life: 0.85,
        maxLife: 0.85,
        color: _rng.nextBool()
            ? const Color(0xFFFFD54F)
            : const Color(0xFFFF5722),
        radius: 1.5 + _rng.nextDouble() * 1.5,
      ),
    );
  }

  void emitBiomeTransition({Color? accentColor}) {
    // Full-width sparkle
    final w = game.size.x > 0 ? game.size.x : 800.0;
    final h = game.size.y > 0 ? game.size.y * 0.6 : 400.0;
    for (int i = 0; i < 28; i++) {
      final color = (accentColor != null && i % 2 == 0)
          ? accentColor
          : (i % 3 == 0 ? const Color(0xFFFFD54F) : Colors.white);
      _addParticle(
        _Particle(
          x: _rng.nextDouble() * w,
          y: _rng.nextDouble() * h,
          vx: (_rng.nextDouble() - 0.5) * 40,
          vy: -10 - _rng.nextDouble() * 30,
          life: 0.9 + _rng.nextDouble() * 0.5,
          maxLife: 1.4,
          color: color,
          radius: 2 + _rng.nextDouble() * 3.5,
        ),
      );
    }
  }

  void emitFireworkBurst(Vector2 pos, {List<Color>? colors, int count = 22}) {
    final defaultColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFF4DEEEA), // Cyan
      const Color(0xFFFF4081), // Pink
      Colors.white,
      const Color(0xFFFF9100), // Amber
    ];
    final palette = (colors != null && colors.isNotEmpty)
        ? colors
        : defaultColors;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 40.0 + _rng.nextDouble() * 100.0;
      final life = 0.5 + _rng.nextDouble() * 0.35;
      final color = palette[_rng.nextInt(palette.length)];
      _addParticle(
        _Particle(
          x: pos.x,
          y: pos.y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 15.0,
          life: life,
          maxLife: life,
          color: color,
          radius: 2.0 + _rng.nextDouble() * 2.5,
        ),
      );
    }
  }

  void emitSpeedLines() {
    // High-speed streak lines
    for (int i = 0; i < 2; i++) {
      final y = _rng.nextDouble() * game.size.y;
      final length = 150 + _rng.nextDouble() * 300;
      _addParticle(
        _Particle(
          x: game.size.x + length,
          y: y,
          vx: -1200 - _rng.nextDouble() * 800,
          vy: 0,
          life: 1.5,
          maxLife: 1.5,
          color: const Color(0x66FFFFFF),
          radius: 1.5 + _rng.nextDouble() * 1.5,
          isLine: true,
          length: length,
        ),
      );
    }
  }

  void _emit(
    Vector2 pos,
    int count,
    Color color,
    double maxLife,
    double spread,
    double maxRadius,
  ) {
    for (int i = 0; i < count; i++) {
      _spawnParticle(
        x: pos.x + (_rng.nextDouble() - 0.5) * 10,
        y: pos.y + (_rng.nextDouble() - 0.5) * 10,
        vx: (_rng.nextDouble() - 0.5) * spread,
        vy: -(_rng.nextDouble()) * spread * 0.8,
        life: maxLife,
        maxLife: maxLife,
        color: color,
        radius: 1.5 + _rng.nextDouble() * 3,
      );
    }
  }

  @override
  void update(double dt) {
    // dt comes from the authoritative simulation clock.
    super.update(dt);
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (!p.isLine && !p.isRing) {
        if (p.material != HazardMaterial.feathers) p.angle += dt * 5;
        p.vy += (p.material == null ? 40 : 250) * dt; // gravity on particles
      }

      p.life -= dt;
      if (p.life <= 0) {
        final lastIdx = _particles.length - 1;
        if (i != lastIdx) {
          _particles[i] = _particles[lastIdx];
        }
        _freePool.add(_particles.removeLast());
      }
    }
  }

  static final _paint = Paint();
  static final Path _wingPath = Path();
  static final Path _beakUnitPath = Path()
    ..moveTo(0, -2)
    ..lineTo(5, 0)
    ..lineTo(0, 2)
    ..close();
  static final Path _rockUnitPath = Path()
    ..moveTo(-1, 1)
    ..lineTo(-0.6, -1)
    ..lineTo(1, -0.4)
    ..lineTo(0.5, 1)
    ..close();

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _paint.color = p.color.withValues(alpha: alpha);
      if (p.material != null) {
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.angle);
        final r = p.radius;
        switch (p.material!) {
          case HazardMaterial.wood:
          case HazardMaterial.metal:
            canvas.drawRect(Rect.fromLTWH(-r * 1.5, -r / 2, r * 3, r), _paint);
          case HazardMaterial.feathers:
            canvas.drawOval(Rect.fromLTWH(-r, -r / 2, r * 2, r), _paint);
            final flap = math.sin((p.maxLife - p.life) * 35) * r;
            _wingPath
              ..reset()
              ..moveTo(-r / 2, 0)
              ..quadraticBezierTo(0, -r + flap, r / 2, -r * 1.3 + flap)
              ..lineTo(r / 2, 0)
              ..close();
            canvas.drawPath(_wingPath, _paint);
            _paint.color = const Color(0xFFFFD25A).withValues(alpha: alpha);
            canvas.save();
            canvas.translate(r, 0);
            canvas.drawPath(_beakUnitPath, _paint);
            canvas.restore();
          case HazardMaterial.plant:
            canvas.drawOval(Rect.fromLTWH(-r, -r * 2, r * 2, r * 4), _paint);
          default:
            canvas.save();
            canvas.scale(r, r);
            canvas.drawPath(_rockUnitPath, _paint);
            canvas.restore();
        }
        canvas.restore();
      } else if (p.isRing) {
        final progress = (1.0 - (p.life / p.maxLife)).clamp(0.0, 1.0);
        final curRadius =
            p.startRadius + (p.endRadius - p.startRadius) * progress;
        _paint.style = PaintingStyle.stroke;
        _paint.strokeWidth = 2.0 * alpha;
        canvas.drawCircle(Offset(p.x, p.y), curRadius, _paint);
        _paint.style = PaintingStyle.fill;
      } else if (p.isLine) {
        canvas.drawRect(
          Rect.fromLTWH(p.x, p.y, p.length, p.radius * 2),
          _paint,
        );
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.radius * alpha, _paint);
      }
    }
  }
}

class _Particle {
  double x, y, vx, vy, life, maxLife, radius;
  Color color;
  HazardMaterial? material;
  double angle;
  bool isLine;
  double length;
  bool isRing;
  double startRadius;
  double endRadius;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.radius,
    this.material,
    this.angle = 0,
    this.isLine = false,
    this.length = 0,
    this.isRing = false,
    this.startRadius = 0,
    this.endRadius = 0,
  });

  void reset({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double maxLife,
    required Color color,
    required double radius,
    HazardMaterial? material,
    double angle = 0,
    bool isLine = false,
    double length = 0,
    bool isRing = false,
    double startRadius = 0,
    double endRadius = 0,
  }) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.life = life;
    this.maxLife = maxLife;
    this.color = color;
    this.radius = radius;
    this.material = material;
    this.angle = angle;
    this.isLine = isLine;
    this.length = length;
    this.isRing = isRing;
    this.startRadius = startRadius;
    this.endRadius = endRadius;
  }
}

class HighSpeedStreaks extends PositionComponent
    with HasGameReference<DinoGame> {
  final List<_Streak> _streaks = List.generate(3, (_) => _Streak());
  final math.Random _rng = math.Random();
  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _paint.shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(1.0, 0.0),
      [
        const Color(0x00FFFFFF),
        const Color(0x20FFFFFF),
        const Color(0x00FFFFFF),
      ],
      const [0.0, 0.5, 1.0],
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing && game.state != GameState.spaceMode) {
      for (final s in _streaks) {
        s.active = false;
      }
      return;
    }

    final ratio = game.speedManager.currentSpeed / game.speedManager.maxSpeed;
    if (ratio > 0.6) {
      for (final s in _streaks) {
        if (!s.active) {
          s.active = true;
          s.x = game.size.x + _rng.nextDouble() * 200;
          s.y =
              _rng.nextDouble() *
              (game.size.y * 0.75); // Skip bottom 25% of screen
          s.length = 120 + _rng.nextDouble() * 140; // Length 120-260px
          s.speed =
              game.speedManager.currentSpeed * 1.5 + _rng.nextDouble() * 500;
        } else {
          s.x -= s.speed * dt;
          if (s.x + s.length < 0) {
            s.active = false;
          }
        }
      }
    } else {
      for (final s in _streaks) {
        s.active = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.state != GameState.playing && game.state != GameState.spaceMode) {
      return;
    }
    final ratio = game.speedManager.currentSpeed / game.speedManager.maxSpeed;
    if (ratio <= 0.6) return;

    for (final s in _streaks) {
      if (s.active) {
        canvas.save();
        canvas.translate(s.x, s.y);
        canvas.scale(s.length, 1.0);
        canvas.drawRect(const Rect.fromLTWH(0, 0, 1.0, 2.0), _paint);
        canvas.restore();
      }
    }
  }
}

class _Streak {
  bool active = false;
  double x = 0;
  double y = 0;
  double length = 0;
  double speed = 0;
}
