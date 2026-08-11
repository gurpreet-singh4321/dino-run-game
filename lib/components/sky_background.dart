import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';

/// Full-screen gradient sky that seamlessly transitions between biomes.
/// Renders multi-layer detailed environments: Pyramids, God Rays, Active Volcanoes, Ringed Planets, Northern Lights, and Weather.
class SkyBackground extends PositionComponent with HasGameReference<DinoGame> {
  final List<_Cloud> _clouds = [];
  final List<_Star> _stars = [];
  final List<_RainDrop> _rainDrops = [];
  final List<_SnowFlake> _snowFlakes = [];
  final List<_AshParticle> _ashParticles = [];
  final List<_ForestSpore> _forestSpores = [];
  final List<_RollingBush> _rollingBushes = [];

  final math.Random _rng = math.Random();
  double _time = 0;

  // Space mode landscape slide down
  double _spaceSlideOffset = 0;
  // Background leftward parallax scroll offset
  double _bgScrollOffset = 0;

  // Lightning effect for rain/storm
  double _lightningTimer = 0;
  double _lightningFlashAlpha = 0;
  final List<Offset> _lightningBoltPoints = [];

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -100; // Draw behind everything

    // Spawn initial clouds
    for (int i = 0; i < 6; i++) {
      _clouds.add(_Cloud(
        x: _rng.nextDouble() * size.x,
        y: 20 + _rng.nextDouble() * (size.y * 0.3),
        width: 60 + _rng.nextDouble() * 80,
        speed: 8 + _rng.nextDouble() * 15,
      ));
    }

    // Spawn stars for Cosmos & Dark biomes
    for (int i = 0; i < 45; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble() * size.x,
        y: _rng.nextDouble() * size.y * 0.7,
        brightness: _rng.nextDouble(),
        twinkleSpeed: 1 + _rng.nextDouble() * 3,
      ));
    }

    // Spawn snowflakes for Ice Age
    for (int i = 0; i < 45; i++) {
      _snowFlakes.add(_SnowFlake(
        x: _rng.nextDouble() * size.x,
        y: _rng.nextDouble() * size.y,
        radius: 1.5 + _rng.nextDouble() * 2.5,
        speedY: 25 + _rng.nextDouble() * 45,
        swaySpeed: 1.5 + _rng.nextDouble() * 2.0,
        swayWidth: 15 + _rng.nextDouble() * 20,
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }

    // Spawn volcanic ash embers
    for (int i = 0; i < 30; i++) {
      _ashParticles.add(_AshParticle(
        x: _rng.nextDouble() * size.x,
        y: _rng.nextDouble() * size.y,
        radius: 1.0 + _rng.nextDouble() * 2.0,
        speedY: 30 + _rng.nextDouble() * 50,
        speedX: -20 - _rng.nextDouble() * 30,
      ));
    }

    // Spawn forest glowing spores
    for (int i = 0; i < 25; i++) {
      _forestSpores.add(_ForestSpore(
        x: _rng.nextDouble() * size.x,
        y: 50 + _rng.nextDouble() * (size.y * 0.6),
        radius: 1.5 + _rng.nextDouble() * 2.0,
        floatSpeed: 0.8 + _rng.nextDouble() * 1.5,
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }

    // Spawn desert rolling bushes
    for (int i = 0; i < 2; i++) {
      _rollingBushes.add(_RollingBush(
        x: _rng.nextDouble() * size.x,
        speed: 80 + _rng.nextDouble() * 40,
        radius: 16 + _rng.nextDouble() * 8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    size = game.size;
    _time += dt;

    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      _bgScrollOffset += game.speedManager.currentSpeed * dt * 0.075;
    }

    // Space mode landscape slide down off-screen
    if (game.state == GameState.spaceMode) {
      _spaceSlideOffset += 450 * dt;
      if (_spaceSlideOffset > 300) {
        _spaceSlideOffset = 300;
      }
    } else {
      if (_spaceSlideOffset > 0) {
        _spaceSlideOffset -= 350 * dt;
        if (_spaceSlideOffset < 0) _spaceSlideOffset = 0;
      }
    }

    for (final cloud in _clouds) {
      cloud.x -= cloud.speed * dt;
      if (cloud.x + cloud.width < -30) {
        cloud.x = size.x + 30;
        cloud.y = 15 + _rng.nextDouble() * (size.y * 0.35);
      }
    }

    for (final star in _stars) {
      star.brightness += star.twinkleSpeed * dt;
    }

    final currentBiome = game.biomeManager.effectiveBiome.name;

    // Rain & Lightning
    if (game.biomeManager.isRaining) {
      if (_rainDrops.length < 150) {
        for (int i = 0; i < 5; i++) {
          _rainDrops.add(_RainDrop(
            x: _rng.nextDouble() * game.size.x * 1.5,
            y: -20 - _rng.nextDouble() * 50,
            speed: 600 + _rng.nextDouble() * 400,
            length: 15 + _rng.nextDouble() * 20,
          ));
        }
      }
      
      for (final drop in _rainDrops) {
        drop.x -= drop.speed * 0.35 * dt;
        drop.y += drop.speed * dt;
        if (drop.y > game.size.y) {
          drop.y = -20;
          drop.x = _rng.nextDouble() * game.size.x * 1.5;
        }
      }

      _lightningTimer -= dt;
      if (_lightningTimer <= 0) {
        _lightningTimer = 4.0 + _rng.nextDouble() * 5.0;
        _lightningFlashAlpha = 0.85;
        _generateLightningBolt();
      }

      if (_lightningFlashAlpha > 0) {
        _lightningFlashAlpha = math.max(0.0, _lightningFlashAlpha - dt * 2.5);
      }
    } else {
      _rainDrops.clear();
      _lightningFlashAlpha = 0;
    }

    // Snowflakes update
    if (currentBiome == 'ICE') {
      for (final sf in _snowFlakes) {
        sf.y += sf.speedY * dt;
        sf.x += math.sin(_time * sf.swaySpeed + sf.phase) * sf.swayWidth * dt;
        if (sf.y > game.size.y) {
          sf.y = -10;
          sf.x = _rng.nextDouble() * game.size.x;
        }
      }
    }

    // Volcanic ash embers update
    if (currentBiome == 'VOLCANO') {
      for (final ash in _ashParticles) {
        ash.y -= ash.speedY * dt;
        ash.x += ash.speedX * dt;
        if (ash.y < -10) {
          ash.y = size.y + 10;
          ash.x = _rng.nextDouble() * size.x;
        }
      }
    }

    // Forest spores update
    if (currentBiome == 'FOREST') {
      for (final spore in _forestSpores) {
        spore.y += math.sin(_time * spore.floatSpeed + spore.phase) * 12 * dt;
        spore.x -= 20 * dt;
        if (spore.x < -10) {
          spore.x = size.x + 10;
        }
      }
    }

    // Rolling bushes update
    if (currentBiome == 'DESERT') {
      for (final rb in _rollingBushes) {
        rb.x -= rb.speed * dt;
        rb.rotation += (rb.speed / rb.radius) * dt;
        if (rb.x + rb.radius * 2 < -40) {
          rb.x = size.x + 60;
        }
      }
    }
  }

  void _generateLightningBolt() {
    _lightningBoltPoints.clear();
    double startX = size.x * (0.2 + _rng.nextDouble() * 0.6);
    double startY = 20;
    _lightningBoltPoints.add(Offset(startX, startY));

    double curX = startX;
    double curY = startY;
    while (curY < size.y * 0.65) {
      curY += 25 + _rng.nextDouble() * 35;
      curX += (_rng.nextDouble() - 0.5) * 60;
      _lightningBoltPoints.add(Offset(curX, curY));
    }
  }

  @override
  void render(Canvas canvas) {
    final skyTop = game.biomeManager.interpolatedSkyTop;
    final skyBottom = game.biomeManager.interpolatedSkyBottom;
    final sp = game.spaceTransitionProgress; // 0 = normal, 1 = full space

    // Sky gradient (lerp towards deep space when sp > 0)
    final topColor = sp > 0
        ? Color.lerp(skyTop, const Color(0xFF050510), sp)!
        : skyTop;
    final bottomColor = sp > 0
        ? Color.lerp(skyBottom, const Color(0xFF0A0A25), sp)!
        : skyBottom;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final currentBiome = game.biomeManager.effectiveBiome.name;
    final biomeAlpha = (1.0 - sp).clamp(0.0, 1.0); // fade biome elements out

    // --- SPACE MODE VISUALS (drawn when transitioning or fully in space) ---
    if (sp > 0.01) {
      _drawSpaceModeVisuals(canvas, sp);
    }

    // --- BIOME ELEMENTS (fade out during space transition) ---
    if (biomeAlpha > 0.01) {
      if (biomeAlpha < 0.99) {
        canvas.saveLayer(rect, Paint()..color = Colors.white.withValues(alpha: biomeAlpha));
      }

      // Cosmic space nebulae & ringed planet
      if (currentBiome == 'COSMOS') {
        _drawSpaceNebulae(canvas);
        _drawRingedPlanet(canvas);
      }

      // Northern Lights for ICE land
      if (currentBiome == 'ICE') {
        _drawAuroraBorealis(canvas);
      }

      // God rays for Forest
      if (currentBiome == 'FOREST') {
        _drawGodRays(canvas);
      }

      // Detailed multi-layer parallax environments
      _drawParallaxBackground(canvas, currentBiome);

      // Stars (visible in dark biomes & space)
      final skyBrightness = skyTop.computeLuminance();
      if (skyBrightness < 0.35) {
        for (final star in _stars) {
          final alpha = ((math.sin(star.brightness) + 1) / 2 * (1 - skyBrightness)).clamp(0.0, 1.0);
          canvas.drawCircle(
            Offset(star.x, star.y),
            1.5,
            Paint()..color = Colors.white.withValues(alpha: alpha),
          );
        }
      }

      // Sun
      if (currentBiome != 'COSMOS' && currentBiome != 'VOLCANO') {
        _drawSun(canvas, size.x, skyBrightness);
      }

      // Clouds
      final cloudAlpha = skyBrightness > 0.2 ? 0.75 : 0.2;
      for (final cloud in _clouds) {
        _drawCloud(canvas, cloud, cloudAlpha);
      }

      // Rain & Lightning Bolt
      if (game.biomeManager.isRaining && _rainDrops.isNotEmpty) {
        final stormCeiling = Rect.fromLTWH(0, 0, size.x, 110);
        canvas.drawRect(
          stormCeiling,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1F2833).withValues(alpha: 0.85),
                const Color(0xFF1F2833).withValues(alpha: 0.0),
              ],
            ).createShader(stormCeiling),
        );

        final rainPaintNear = Paint()
          ..color = const Color(0xAAFFFFFF)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        final rainPaintFar = Paint()
          ..color = const Color(0x44FFFFFF)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
          
        for (int i = 0; i < _rainDrops.length; i++) {
          final drop = _rainDrops[i];
          final p = (i % 2 == 0) ? rainPaintNear : rainPaintFar;
          canvas.drawLine(
            Offset(drop.x, drop.y),
            Offset(drop.x - drop.length * 0.35, drop.y + drop.length),
            p,
          );
        }

        if (_lightningFlashAlpha > 0.05) {
          canvas.drawRect(
            rect,
            Paint()..color = const Color(0xFFE0F7FA).withValues(alpha: _lightningFlashAlpha * 0.35),
          );

          if (_lightningBoltPoints.length > 1) {
            final boltPath = Path()..moveTo(_lightningBoltPoints[0].dx, _lightningBoltPoints[0].dy);
            for (int i = 1; i < _lightningBoltPoints.length; i++) {
              boltPath.lineTo(_lightningBoltPoints[i].dx, _lightningBoltPoints[i].dy);
            }

            final boltGlow = Paint()
              ..color = const Color(0xFF4DEEEA).withValues(alpha: _lightningFlashAlpha)
              ..strokeWidth = 6.0
              ..style = ui.PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            canvas.drawPath(boltPath, boltGlow);

            final boltCore = Paint()
              ..color = Colors.white.withValues(alpha: _lightningFlashAlpha)
              ..strokeWidth = 2.5
              ..style = ui.PaintingStyle.stroke;
            canvas.drawPath(boltPath, boltCore);
          }
        }
      }

      // Snowflakes for ICE Age
      if (currentBiome == 'ICE') {
        final sfPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
        for (final sf in _snowFlakes) {
          canvas.drawCircle(Offset(sf.x, sf.y), sf.radius, sfPaint);
        }
      }

      // Volcanic ash embers for VOLCANO
      if (currentBiome == 'VOLCANO') {
        final ashOrange = Paint()..color = const Color(0xFFFF5722).withValues(alpha: 0.7);
        final ashYellow = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.8);
        for (int i = 0; i < _ashParticles.length; i++) {
          final ash = _ashParticles[i];
          canvas.drawCircle(
            Offset(ash.x, ash.y),
            ash.radius,
            (i % 2 == 0) ? ashOrange : ashYellow,
          );
        }
      }

      // Forest pollen spores for FOREST
      if (currentBiome == 'FOREST') {
        final sporePaint = Paint()
          ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        for (final spore in _forestSpores) {
          canvas.drawCircle(Offset(spore.x, spore.y), spore.radius, sporePaint);
        }
      }

      // Rolling green bushes for DESERT
      if (currentBiome == 'DESERT') {
        for (final rb in _rollingBushes) {
          _drawRollingBush(canvas, rb);
        }
      }

      if (biomeAlpha < 0.99) {
        canvas.restore(); // for saveLayer
      }
    }

    // Sweeping Cloud & Fog Layer during world change
    _drawBiomeTransitionFog(canvas);
  }

  /// Draw space mode visuals: twinkling stars, galaxies, speed lines
  void _drawSpaceModeVisuals(Canvas canvas, double sp) {
    final w = size.x;
    final h = size.y;

    // 1. Dense twinkling star field
    for (final star in _stars) {
      final twinkle = ((math.sin(star.brightness) + 1) / 2).clamp(0.0, 1.0);
      final starAlpha = sp * (0.4 + twinkle * 0.6);
      final starSize = 1.0 + twinkle * 1.5;
      canvas.drawCircle(
        Offset(star.x, star.y),
        starSize,
        Paint()..color = Colors.white.withValues(alpha: starAlpha),
      );
      // Subtle glow on brightest stars
      if (twinkle > 0.7) {
        canvas.drawCircle(
          Offset(star.x, star.y),
          starSize * 3,
          Paint()
            ..color = Colors.white.withValues(alpha: starAlpha * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // 2. Galaxies / Nebulae blobs (3 colorful, slowly drifting ellipses)
    _drawSpaceGalaxy(canvas, sp,
      cx: w * 0.25 + math.sin(_time * 0.1) * 20,
      cy: h * 0.22 + math.cos(_time * 0.08) * 10,
      rx: 110, ry: 55,
      color1: const Color(0xFF7C4DFF), color2: const Color(0xFF448AFF),
    );
    _drawSpaceGalaxy(canvas, sp,
      cx: w * 0.72 + math.cos(_time * 0.12) * 15,
      cy: h * 0.38 + math.sin(_time * 0.09) * 12,
      rx: 90, ry: 50,
      color1: const Color(0xFFFF4081), color2: const Color(0xFFFF6E40),
    );
    _drawSpaceGalaxy(canvas, sp,
      cx: w * 0.50 + math.sin(_time * 0.07) * 25,
      cy: h * 0.65 + math.cos(_time * 0.11) * 8,
      rx: 80, ry: 40,
      color1: const Color(0xFF00E5FF), color2: const Color(0xFF76FF03),
    );

    // 3. Speed lines / star streaks during launch and returning phases
    final phase = game.spacePhase;
    if (phase == SpacePhase.launch || phase == SpacePhase.returning) {
      _drawSpeedLines(canvas, phase);
    }
  }

  void _drawSpaceGalaxy(Canvas canvas, double sp, {
    required double cx, required double cy,
    required double rx, required double ry,
    required Color color1, required Color color2,
  }) {
    final galaxyRect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    final galaxyShader = RadialGradient(
      colors: [
        color1.withValues(alpha: 0.3 * sp),
        color2.withValues(alpha: 0.15 * sp),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(galaxyRect);
    canvas.drawOval(galaxyRect, Paint()
      ..shader = galaxyShader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  void _drawSpeedLines(Canvas canvas, SpacePhase phase) {
    final w = size.x;
    final h = size.y;
    // During launch: lines move downward (player going up)
    // During returning: lines move upward (player coming down)
    final direction = phase == SpacePhase.launch ? 1.0 : -1.0;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.20)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 30; i++) {
      final seed = (i * 137 + 42) % 997;
      final fx = (seed / 997.0) * w;
      final lineLen = 40.0 + (seed % 60);
      // Animate position based on time
      final baseY = (_time * (400 + (seed % 200)) * direction + seed * 3.7) % (h + lineLen * 2) - lineLen;
      canvas.drawLine(Offset(fx, baseY), Offset(fx, baseY + lineLen * direction), linePaint);
      canvas.drawLine(Offset(fx, baseY), Offset(fx, baseY + lineLen * direction * 0.6), glowPaint);
    }
  }

  /// Draw sweeping cloud & fog layer during biome transition to hide background switch
  void _drawBiomeTransitionFog(Canvas canvas) {
    final fogOpacity = game.biomeManager.fogOpacity;
    if (fogOpacity <= 0.001) return;

    final w = size.x;
    final h = size.y;

    // 1. Screen-wide soft ambient fog blanket
    final ambientFogPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45 * fogOpacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), ambientFogPaint);

    // 2. Dense Horizon & Sky Mist Shroud
    final horizonRect = Rect.fromLTWH(0, h * 0.15, w, h * 0.75);
    final horizonShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.10 * fogOpacity),
        Colors.white.withValues(alpha: 0.85 * fogOpacity),
        Colors.white.withValues(alpha: 0.90 * fogOpacity),
        Colors.white.withValues(alpha: 0.30 * fogOpacity),
      ],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(horizonRect);
    canvas.drawRect(horizonRect, Paint()..shader = horizonShader);

    // 3. Fast Sweeping Puffy Cloud Fronts across the sky
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * fogOpacity);

    final progress = game.biomeManager.progress;
    final sweepOffset = progress * w * 2.2;

    for (int i = 0; i < 9; i++) {
      final cx = (i * (w / 5.5) - sweepOffset) % (w + 350) - 175;
      final cy = (i % 3 == 0) ? h * 0.22 : (i % 3 == 1) ? h * 0.42 : h * 0.62;
      final r = 85.0 + (i % 4) * 30.0;

      canvas.drawCircle(Offset(cx, cy), r, cloudPaint);
      canvas.drawCircle(Offset(cx + r * 0.65, cy - r * 0.22), r * 0.75, cloudPaint);
      canvas.drawCircle(Offset(cx - r * 0.65, cy + r * 0.12), r * 0.70, cloudPaint);
      canvas.drawCircle(Offset(cx + r * 1.15, cy + r * 0.15), r * 0.60, cloudPaint);
    }

    // 4. Low ground mist rolls
    final mistPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.75 * fogOpacity);
    for (int i = 0; i < 6; i++) {
      final mx = (i * (w / 4.0) - sweepOffset * 1.5) % (w + 400) - 200;
      final my = h * 0.60 + (i % 2) * 35;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mx, my), width: 340, height: 110),
        mistPaint,
      );
    }
  }

  /// Draw sunbeams / god rays for Forest Canopy
  void _drawGodRays(Canvas canvas) {
    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = ui.PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final startX = size.x * (0.2 + i * 0.3);
      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX + 80, 0)
        ..lineTo(startX - 40, size.y)
        ..lineTo(startX - 120, size.y)
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  /// Draw purple/cyan cosmic nebulae clouds for Cosmos mode
  void _drawSpaceNebulae(Canvas canvas) {
    final nebulaCenter = Offset(size.x * 0.4, size.y * 0.3);
    final glowRect = Rect.fromCircle(center: nebulaCenter, radius: 220);
    final shader = RadialGradient(
      colors: [
        const Color(0xFFAB47BC).withValues(alpha: 0.35),
        const Color(0xFF00E5FF).withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(glowRect);
    canvas.drawCircle(nebulaCenter, 220, Paint()..shader = shader);
  }

  /// Draw distant ringed planet (Saturn-like) in Cosmos mode
  void _drawRingedPlanet(Canvas canvas) {
    final pCenter = Offset(130, 90);
    canvas.save();
    canvas.translate(pCenter.dx, pCenter.dy);
    canvas.rotate(-math.pi / 8);

    // Planet body
    final bodyRect = Rect.fromCircle(center: Offset.zero, radius: 28);
    final bodyGradient = const RadialGradient(
      center: Alignment(-0.4, -0.4),
      colors: [Color(0xFF80DEEA), Color(0xFF00838F), Color(0xFF004D40)],
    );
    canvas.drawCircle(Offset.zero, 28, Paint()..shader = bodyGradient.createShader(bodyRect));

    // Planetary Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawOval(Rect.fromLTWH(-55, -12, 110, 24), ringPaint);

    canvas.restore();
  }

  /// Draw rolling light dusty-green / dry sage tumbleweed in Desert background
  void _drawRollingBush(Canvas canvas, _RollingBush rb) {
    final yGround = size.y - 120 + _spaceSlideOffset;
    final r = rb.radius;

    // 1. Static Ground Shadow (drawn BEFORE canvas.rotate so it doesn't spin!)
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rb.x, yGround - 2), width: r * 2.2, height: r * 0.45),
      shadowPaint,
    );

    // 2. Rolling Bush Body (Round sphere with internal branch & foliage details)
    canvas.save();
    canvas.translate(rb.x, yGround - r);
    canvas.rotate(rb.rotation);

    // Base dark khaki green foliage background (#5A6B46) - Clean round sphere
    final basePaint = Paint()..color = const Color(0xFF5A6B46);
    canvas.drawCircle(Offset.zero, r, basePaint);

    // Main dry sage-green foliage (#7F8F63)
    final mainPaint = Paint()..color = const Color(0xFF7F8F63);
    canvas.drawCircle(Offset.zero, r * 0.92, mainPaint);

    // Soft dusty-sage highlight layer (#9AA87E)
    final hlPaint = Paint()..color = const Color(0xFF9AA87E);
    canvas.drawCircle(const Offset(-1.5, -2.0), r * 0.72, hlPaint);

    // Top bright highlight (#B5C49A)
    final topHlPaint = Paint()..color = const Color(0xFFB5C49A);
    canvas.drawCircle(const Offset(-2.5, -3.0), r * 0.45, topHlPaint);

    // Dark outer foliage rim (#4C5A3A)
    final rimPaint = Paint()
      ..color = const Color(0xFF4C5A3A).withValues(alpha: 0.5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset.zero, r * 0.95, rimPaint);

    // Symmetric skeletal dry branches inside round tumbleweed
    final twigPaint = Paint()
      ..color = const Color(0xFF4A3C2A)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a) * r * 0.70, math.sin(a) * r * 0.70),
        twigPaint,
      );
    }

    canvas.restore();
  }

  /// Render a 3D Sandstone Pyramid with lit/shadow faces, stone block ridges, and golden capstone
  void _draw3DPyramid(
    Canvas canvas, {
    required Offset apex,
    required double leftBaseX,
    required double rightBaseX,
    required double yGround,
    bool hasGoldenCapstone = true,
  }) {
    final ridgeX = leftBaseX + (rightBaseX - leftBaseX) * 0.42;

    // 1. Lit Face (Sun-side, Left Face)
    final litFacePath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(leftBaseX, yGround)
      ..lineTo(ridgeX, yGround)
      ..close();
    final litShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFFE5C158), // Bright sandstone gold
        Color(0xFFD4B04C), // Mid sandstone
      ],
    ).createShader(Rect.fromLTRB(leftBaseX, apex.dy, ridgeX, yGround));
    canvas.drawPath(litFacePath, Paint()..shader = litShader);

    // 2. Shadow Face (Right Face)
    final shadowFacePath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(ridgeX, yGround)
      ..lineTo(rightBaseX, yGround)
      ..close();
    final shadowShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF9E824A), // Desert shadow tan
        Color(0xFF7A6437), // Dark sandstone shadow
      ],
    ).createShader(Rect.fromLTRB(ridgeX, apex.dy, rightBaseX, yGround));
    canvas.drawPath(shadowFacePath, Paint()..shader = shadowShader);

    // Center Ridge Divide Line
    canvas.drawLine(
      apex,
      Offset(ridgeX, yGround),
      Paint()
        ..color = const Color(0xFF5D4A27).withValues(alpha: 0.6)
        ..strokeWidth = 2.0,
    );

    // 3. Horizontal Stone Block Ridges across faces (8 block layers for grand scale)
    final blockPaint = Paint()
      ..color = const Color(0xFF7A6437).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (int k = 1; k <= 8; k++) {
      final t = k / 9.0;
      final py = apex.dy + (yGround - apex.dy) * t;
      final lx = apex.dx + (leftBaseX - apex.dx) * t;
      final rx = apex.dx + (rightBaseX - apex.dx) * t;
      canvas.drawLine(Offset(lx, py), Offset(rx, py), blockPaint);
    }

    // 4. Golden Apex Capstone (Pyramidion)
    if (hasGoldenCapstone) {
      final capH = (yGround - apex.dy) * 0.16;
      final capApexY = apex.dy;
      final capBaseY = apex.dy + capH;
      final capT = 0.16;
      final capLx = apex.dx + (leftBaseX - apex.dx) * capT;
      final capRx = apex.dx + (rightBaseX - apex.dx) * capT;
      final capRidgeX = apex.dx + (ridgeX - apex.dx) * capT;

      final capLitPath = Path()
        ..moveTo(apex.dx, capApexY)
        ..lineTo(capLx, capBaseY)
        ..lineTo(capRidgeX, capBaseY)
        ..close();
      canvas.drawPath(capLitPath, Paint()..color = const Color(0xFFFFD700));

      final capShadowPath = Path()
        ..moveTo(apex.dx, capApexY)
        ..lineTo(capRidgeX, capBaseY)
        ..lineTo(capRx, capBaseY)
        ..close();
      canvas.drawPath(capShadowPath, Paint()..color = const Color(0xFFFFB300));
    }
  }

  /// Draw Northern Lights (Aurora Borealis) wave ribbon across the sky in ICE biome
  void _drawAuroraBorealis(Canvas canvas) {
    final auroraPath = Path();
    auroraPath.moveTo(0, 40);

    for (double x = 0; x <= size.x; x += 30) {
      final y = 40 + math.sin(_time * 1.2 + x * 0.008) * 22 + math.cos(_time * 0.8 + x * 0.004) * 15;
      auroraPath.lineTo(x, y);
    }
    auroraPath.lineTo(size.x, 140);
    auroraPath.lineTo(0, 140);
    auroraPath.close();

    final auroraRect = Rect.fromLTWH(0, 20, size.x, 120);
    final auroraShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF00E676).withValues(alpha: 0.35),
        const Color(0xFF00E5FF).withValues(alpha: 0.25),
        Colors.transparent,
      ],
    ).createShader(auroraRect);

    canvas.drawPath(auroraPath, Paint()..shader = auroraShader);
  }

  /// Draw multi-layer detailed parallax background silhouettes for all 6 biomes
  void _drawParallaxBackground(Canvas canvas, String biome) {
    final yGround = size.y - 120 + _spaceSlideOffset;
    final totalW = size.x; // tile width matches landscape drawing width
    final pShift = _bgScrollOffset % totalW;

    canvas.save();
    canvas.translate(-pShift, 0);
    _drawBiomeLandscape(canvas, biome, yGround);
    canvas.translate(totalW, 0);
    _drawBiomeLandscape(canvas, biome, yGround);
    canvas.restore();
  }

  void _drawBiomeLandscape(Canvas canvas, String biome, double yGround) {

    if (biome == 'DESERT') {
      // 1. Far Soft Background Sand Dunes (Behind Pyramids)
      final farDunePath = Path()
        ..moveTo(0, yGround)
        ..quadraticBezierTo(size.x * 0.20, yGround - 35, size.x * 0.45, yGround - 15)
        ..quadraticBezierTo(size.x * 0.70, yGround - 40, size.x, yGround - 18)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);
      final farDuneShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE5C158).withValues(alpha: 0.45),
          const Color(0xFFD4A359).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(0, yGround - 40, size.x, 100));
      canvas.drawPath(farDunePath, Paint()..shader = farDuneShader);

      // 2. 3 TOWERING ANCIENT 3D PYRAMIDS (Distant & Grand Scale - High Unblocked Pyramids!)
      // Great Pyramid of Giza (Far Left Center - 180px tall!)
      _draw3DPyramid(
        canvas,
        apex: Offset(size.x * 0.26, yGround - 180),
        leftBaseX: size.x * 0.06,
        rightBaseX: size.x * 0.44,
        yGround: yGround,
        hasGoldenCapstone: true,
      );

      // Middle Pyramid of Khafre (Center Right - 145px tall!)
      _draw3DPyramid(
        canvas,
        apex: Offset(size.x * 0.60, yGround - 145),
        leftBaseX: size.x * 0.44,
        rightBaseX: size.x * 0.76,
        yGround: yGround,
        hasGoldenCapstone: true,
      );

      // Third Pyramid of Menkaure (Far Right - 105px tall!)
      _draw3DPyramid(
        canvas,
        apex: Offset(size.x * 0.84, yGround - 105),
        leftBaseX: size.x * 0.74,
        rightBaseX: size.x * 0.94,
        yGround: yGround,
        hasGoldenCapstone: false,
      );

      // 3. Low Horizon Foreground Sand Dunes (Gentle low waves hugging base)
      final midDunePath = Path()
        ..moveTo(0, yGround)
        ..quadraticBezierTo(size.x * 0.25, yGround - 22, size.x * 0.50, yGround - 10)
        ..quadraticBezierTo(size.x * 0.75, yGround - 25, size.x, yGround - 12)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);
      final midDuneShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4B04C).withValues(alpha: 0.80),
          const Color(0xFFB88E36).withValues(alpha: 0.70),
        ],
      ).createShader(Rect.fromLTWH(0, yGround - 25, size.x, 80));
      canvas.drawPath(midDunePath, Paint()..shader = midDuneShader);

      // Gentle Dune Crest Shadow Line
      final duneCrestPaint = Paint()
        ..color = const Color(0xFF9E7728).withValues(alpha: 0.5)
        ..strokeWidth = 2.0
        ..style = ui.PaintingStyle.stroke;
      final crestPath = Path()
        ..moveTo(0, yGround - 10)
        ..quadraticBezierTo(size.x * 0.25, yGround - 22, size.x * 0.50, yGround - 10)
        ..quadraticBezierTo(size.x * 0.75, yGround - 25, size.x, yGround - 12);
      canvas.drawPath(crestPath, duneCrestPaint);

      // 4. Dusty Wind Gust Streaks & Flying Sand Particles (Dry Hazy Atmosphere)
      final windPaint = Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.22)
        ..strokeWidth = 1.5
        ..style = ui.PaintingStyle.stroke;

      for (int w = 0; w < 4; w++) {
        final windX = ((_time * 180 + w * 220) % (size.x + 300)) - 150;
        final windY = yGround - 110 + math.sin(_time * 2.0 + w) * 18;
        final wPath = Path()
          ..moveTo(windX, windY)
          ..quadraticBezierTo(windX + 60, windY - 8, windX + 130, windY + 4);
        canvas.drawPath(wPath, windPaint);
      }

      // Fine drifting sand grain particles
      final sandPaint = Paint()..color = const Color(0xFFFFECB3).withValues(alpha: 0.45);
      for (int s = 0; s < 18; s++) {
        final sx = ((_time * (90 + s * 10) + s * 65) % (size.x + 40)) - 20;
        final sy = yGround - 140 + (s * 7) % 120;
        canvas.drawCircle(Offset(sx, sy), 1.0 + (s % 3) * 0.5, sandPaint);
      }
    } else if (biome == 'ICE') {
      // 1. Far jagged ice glaciers & frozen mountain peaks
      final glacierPath = Path()
        ..moveTo(0, yGround)
        ..lineTo(size.x * 0.18, yGround - 85)
        ..lineTo(size.x * 0.32, yGround - 30)
        ..lineTo(size.x * 0.55, yGround - 110)
        ..lineTo(size.x * 0.75, yGround - 40)
        ..lineTo(size.x * 0.92, yGround - 90)
        ..lineTo(size.x, yGround - 20)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);
      canvas.drawPath(
        glacierPath,
        Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.35),
      );
    } else if (biome == 'VOLCANO') {
      // 2. Background Distant Volcanic Ridge Layer
      final bgMountainPath = Path()
        ..moveTo(0, yGround)
        ..lineTo(size.x * 0.1, yGround - 90)
        ..quadraticBezierTo(size.x * 0.18, yGround - 140, size.x * 0.25, yGround - 110)
        ..lineTo(size.x * 0.35, yGround - 180) // Distant peak
        ..lineTo(size.x * 0.48, yGround - 100)
        ..quadraticBezierTo(size.x * 0.65, yGround - 160, size.x * 0.78, yGround - 90)
        ..lineTo(size.x * 0.9, yGround - 130)
        ..lineTo(size.x, yGround - 60)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);

      canvas.drawPath(
        bgMountainPath,
        Paint()..color = const Color(0xFF1A0A0A).withValues(alpha: 0.8),
      );

      // 3. Foreground Main Active Volcano Mountain with Rugged Crags & Jagged Crater
      final craterLeft = size.x * 0.42;
      final craterRight = size.x * 0.68;
      final craterY = yGround - 160.0;

      final mainVolcanoPath = Path()
        ..moveTo(0, yGround)
        ..lineTo(size.x * 0.08, yGround)
        ..quadraticBezierTo(size.x * 0.18, yGround - 50, size.x * 0.25, yGround - 80)
        ..quadraticBezierTo(size.x * 0.32, yGround - 110, craterLeft, craterY) // Left rugged slope
        // Jagged open crater caldera lip
        ..lineTo(craterLeft + 15, craterY + 18)
        ..quadraticBezierTo(size.x * 0.55, craterY + 28, craterRight - 15, craterY + 14)
        ..lineTo(craterRight, craterY)
        // Right rugged slope with rocky ridges
        ..quadraticBezierTo(size.x * 0.76, yGround - 100, size.x * 0.84, yGround - 60)
        ..quadraticBezierTo(size.x * 0.92, yGround - 30, size.x, yGround)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);

      final volcanoGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2A0808), // Dark volcanic basalt top
          Color(0xFF1F1212),
          Color(0xFF140D0D),
        ],
      );
      canvas.drawPath(mainVolcanoPath, Paint()..shader = volcanoGradient.createShader(Rect.fromLTWH(0, craterY, size.x, yGround - craterY + 100)));

      // 4. Rocky Crag Shading & Cliff Highlight Detail Lines
      final cragPaint = Paint()
        ..color = const Color(0xFF3E1A1A).withValues(alpha: 0.7)
        ..strokeWidth = 2.5
        ..style = ui.PaintingStyle.stroke;

      // Ridge lines down mountain face
      final r1 = Path()
        ..moveTo(craterLeft + 25, craterY + 20)
        ..quadraticBezierTo(size.x * 0.4, yGround - 90, size.x * 0.35, yGround);
      final r2 = Path()
        ..moveTo(craterRight - 25, craterY + 18)
        ..quadraticBezierTo(size.x * 0.65, yGround - 90, size.x * 0.72, yGround);
      final r3 = Path()
        ..moveTo(size.x * 0.55, craterY + 28)
        ..quadraticBezierTo(size.x * 0.52, yGround - 80, size.x * 0.5, yGround);

      canvas.drawPath(r1, cragPaint);
      canvas.drawPath(r2, cragPaint);
      canvas.drawPath(r3, cragPaint);

      // 5. Molten Glowing Lava Lake Inside Crater Caldera
      final calderaRect = Rect.fromLTWH(craterLeft + 10, craterY + 8, craterRight - craterLeft - 20, 24);
      final calderaGradient = const RadialGradient(
        center: Alignment(0, 0.2),
        colors: [
          Color(0xFFFFFF8D), // White-hot molten core
          Color(0xFFFF9100), // Glowing orange
          Color(0xFFFF3D00), // Intense red
        ],
        stops: [0.0, 0.45, 1.0],
      );
      final calderaGlowPaint = Paint()
        ..shader = calderaGradient.createShader(calderaRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawOval(calderaRect, calderaGlowPaint);

      // 6. Multi-Branching Cascading Lava Rivers Down Slopes
      final lavaOuterPaint = Paint()
        ..color = const Color(0xFFFF3D00)
        ..strokeWidth = 6.0
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final lavaMidPaint = Paint()
        ..color = const Color(0xFFFF9100)
        ..strokeWidth = 3.5
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final lavaCorePaint = Paint()
        ..color = const Color(0xFFFFFF8D)
        ..strokeWidth = 1.5
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // River 1 (Main Central Cascade)
      final riv1 = Path()
        ..moveTo(size.x * 0.54, craterY + 25)
        ..quadraticBezierTo(size.x * 0.51, yGround - 110, size.x * 0.53, yGround - 70)
        ..quadraticBezierTo(size.x * 0.56, yGround - 35, size.x * 0.52, yGround);

      // River 2 (Left Branching Stream)
      final riv2 = Path()
        ..moveTo(craterLeft + 20, craterY + 22)
        ..quadraticBezierTo(size.x * 0.38, yGround - 120, size.x * 0.33, yGround - 80)
        ..quadraticBezierTo(size.x * 0.28, yGround - 40, size.x * 0.22, yGround);

      // River 3 (Right Branching Stream)
      final riv3 = Path()
        ..moveTo(craterRight - 20, craterY + 20)
        ..quadraticBezierTo(size.x * 0.69, yGround - 110, size.x * 0.74, yGround - 75)
        ..quadraticBezierTo(size.x * 0.79, yGround - 35, size.x * 0.83, yGround);

      // River 4 (Tributary stream splitting off River 1)
      final riv4 = Path()
        ..moveTo(size.x * 0.53, yGround - 70)
        ..quadraticBezierTo(size.x * 0.45, yGround - 50, size.x * 0.42, yGround);

      void drawLavaRiver(Path p) {
        canvas.drawPath(p, lavaOuterPaint);
        canvas.drawPath(p, lavaMidPaint);
        canvas.drawPath(p, lavaCorePaint);
      }

      drawLavaRiver(riv1);
      drawLavaRiver(riv2);
      drawLavaRiver(riv3);
      drawLavaRiver(riv4);

      // 7. Eruption Volumetric Smoke Plumes rising from Caldera
      final smokePaint = Paint()
        ..color = const Color(0xFF1E1010).withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      final smokeGlowPaint = Paint()
        ..color = const Color(0xFFFF3D00).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

      // Animated rising smoke clouds
      final t = _time * 1.5;
      final cX = size.x * 0.55;
      canvas.drawCircle(Offset(cX + math.sin(t) * 15, craterY - 30), 45, smokeGlowPaint);
      canvas.drawCircle(Offset(cX + math.sin(t) * 15, craterY - 30), 40, smokePaint);

      canvas.drawCircle(Offset(cX - 25 + math.cos(t * 1.2) * 20, craterY - 70), 55, smokeGlowPaint);
      canvas.drawCircle(Offset(cX - 25 + math.cos(t * 1.2) * 20, craterY - 70), 50, smokePaint);

      canvas.drawCircle(Offset(cX + 20 + math.sin(t * 0.9) * 25, craterY - 115), 65, smokeGlowPaint);
      canvas.drawCircle(Offset(cX + 20 + math.sin(t * 0.9) * 25, craterY - 115), 60, smokePaint);
    } else if (biome == 'FOREST') {
      // Prehistoric lush forest tree canopy silhouettes
      final forestPath = Path()
        ..moveTo(0, yGround)
        ..quadraticBezierTo(size.x * 0.2, yGround - 50, size.x * 0.4, yGround - 20)
        ..quadraticBezierTo(size.x * 0.7, yGround - 65, size.x, yGround - 30)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y);
      canvas.drawPath(
        forestPath,
        Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.35),
      );
    }
  }

  void _drawSun(Canvas canvas, double w, double skyBrightness) {
    final sunCenter = Offset(w - 240, 70);
    final t = _time;

    // 1. Massive Outer Heat Glow & Atmospheric Halo
    final outerHaloGradient = RadialGradient(
      colors: [
        const Color(0xFFFFF9C4).withValues(alpha: 0.55 * skyBrightness),
        const Color(0xFFFFB300).withValues(alpha: 0.35 * skyBrightness),
        const Color(0xFFFF3D00).withValues(alpha: 0.15 * skyBrightness),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    final haloRect = Rect.fromCircle(center: sunCenter, radius: 85);
    canvas.drawCircle(sunCenter, 85, Paint()..shader = outerHaloGradient.createShader(haloRect));

    // 2. Rotating Solar Corona Rays (16 dynamic rays)
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.5 * skyBrightness)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + t * 0.15;
      final r1 = 30.0;
      final r2 = 45.0 + math.sin(t * 3.0 + i) * 6.0;
      canvas.drawLine(
        Offset(sunCenter.dx + math.cos(angle) * r1, sunCenter.dy + math.sin(angle) * r1),
        Offset(sunCenter.dx + math.cos(angle) * r2, sunCenter.dy + math.sin(angle) * r2),
        rayPaint,
      );
    }

    // 3. Multi-stop Sun Core (Hot White -> Solar Gold -> Fiery Orange Edge)
    final coreGradient = const RadialGradient(
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFFFF59D),
        Color(0xFFFFB300),
        Color(0xFFFF5722),
      ],
      stops: [0.0, 0.45, 0.8, 1.0],
    );
    final coreRect = Rect.fromCircle(center: sunCenter, radius: 28);
    canvas.drawCircle(sunCenter, 28, Paint()..shader = coreGradient.createShader(coreRect));

    // Sun Surface Flare Rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * skyBrightness)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(sunCenter, 27.5, rimPaint);

    // 4. Photographic Lens Flare Optics (Diagonal flare line across sky)
    final flareDir = const Offset(-0.8, 0.6);
    final flareDistance = [120.0, 220.0, 310.0];
    final flareSizes = [14.0, 8.0, 20.0];
    final flareColors = [
      const Color(0xFF4DEEEA).withValues(alpha: 0.25 * skyBrightness),
      const Color(0xFFFFD54F).withValues(alpha: 0.30 * skyBrightness),
      const Color(0xFFFF4081).withValues(alpha: 0.18 * skyBrightness),
    ];

    for (int k = 0; k < flareDistance.length; k++) {
      final fPos = sunCenter + flareDir * flareDistance[k];
      final fPaint = Paint()
        ..color = flareColors[k]
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(fPos, flareSizes[k], fPaint);
    }
  }

  void _drawCloud(Canvas canvas, _Cloud cloud, double alpha) {
    final w = cloud.width;
    final h = w * 0.45;
    final cx = cloud.x;
    final cy = cloud.y;

    canvas.save();
    canvas.translate(cx, cy);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: alpha * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.45, w * 0.9, h * 0.55),
        Radius.circular(h * 0.28),
      ),
      shadowPaint,
    );

    final cloudPath = Path();
    cloudPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.35, w, h * 0.65),
      Radius.circular(h * 0.32),
    ));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.28, h * 0.4), radius: h * 0.42));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.28), radius: h * 0.52));
    cloudPath.addOval(Rect.fromCircle(center: Offset(w * 0.76, h * 0.45), radius: h * 0.38));

    final cloudGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: alpha),
        const Color(0xFFE0F7FA).withValues(alpha: alpha * 0.85),
      ],
    );
    final bounds = Rect.fromLTWH(0, 0, w, h * 1.1);
    canvas.drawPath(cloudPath, Paint()..shader = cloudGradient.createShader(bounds));

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.52, h * 0.28), radius: h * 0.50),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      highlightPaint,
    );

    canvas.restore();
  }
}

class _Cloud {
  double x, y, width, speed;
  _Cloud({required this.x, required this.y, required this.width, required this.speed});
}

class _Star {
  double x, y, brightness, twinkleSpeed;
  _Star({required this.x, required this.y, required this.brightness, required this.twinkleSpeed});
}

class _RainDrop {
  double x, y, speed, length;
  _RainDrop({required this.x, required this.y, required this.speed, required this.length});
}

class _SnowFlake {
  double x, y, radius, speedY, swaySpeed, swayWidth, phase;
  _SnowFlake({
    required this.x, required this.y, required this.radius,
    required this.speedY, required this.swaySpeed, required this.swayWidth, required this.phase,
  });
}

class _AshParticle {
  double x, y, radius, speedY, speedX;
  _AshParticle({required this.x, required this.y, required this.radius, required this.speedY, required this.speedX});
}

class _ForestSpore {
  double x, y, radius, floatSpeed, phase;
  _ForestSpore({required this.x, required this.y, required this.radius, required this.floatSpeed, required this.phase});
}

class _RollingBush {
  double x, speed, radius;
  double rotation = 0;
  _RollingBush({required this.x, required this.speed, required this.radius});
}
