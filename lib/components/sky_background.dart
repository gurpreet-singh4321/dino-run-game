import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<_DesertSandDust> _desertSandDust = [];
  final List<_Pterodactyl> _pterodactyls = [];

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
  ui.Image? _desertBgImage;
  ui.Image? _rainBgImage;
  ui.Image? _forestBgImage;
  ui.Image? _iceBgImage;
  ui.Image? _volcanoBgImage;
  ui.Image? _cosmosBgImage;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = -100; // Draw behind everything

    try {
      final data = await rootBundle.load('assets/images/desert_bg_v3.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _desertBgImage = frame.image;
    } catch (_) {
      try {
        _desertBgImage = await game.images.load('desert_bg_v3.jpg');
      } catch (_) {}
    }

    try {
      final data = await rootBundle.load('assets/images/rain_bg.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _rainBgImage = frame.image;
    } catch (_) {
      try {
        _rainBgImage = await game.images.load('rain_bg.jpg');
      } catch (_) {}
    }

    try {
      final data = await rootBundle.load('assets/images/forest_bg.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _forestBgImage = frame.image;
    } catch (_) {
      try {
        _forestBgImage = await game.images.load('forest_bg.jpg');
      } catch (_) {}
    }

    try {
      final data = await rootBundle.load('assets/images/ice_bg.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _iceBgImage = frame.image;
    } catch (_) {
      try {
        _iceBgImage = await game.images.load('ice_bg.jpg');
      } catch (_) {}
    }

    try {
      final data = await rootBundle.load('assets/images/volcano_bg.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _volcanoBgImage = frame.image;
    } catch (_) {
      try {
        _volcanoBgImage = await game.images.load('volcano_bg.jpg');
      } catch (_) {}
    }

    try {
      final data = await rootBundle.load('assets/images/cosmos_bg.jpg');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cosmosBgImage = frame.image;
    } catch (_) {
      try {
        _cosmosBgImage = await game.images.load('cosmos_bg.jpg');
      } catch (_) {}
    }

    // Spawn pterodactyls for prehistoric skies
    for (int i = 0; i < 3; i++) {
      _pterodactyls.add(_Pterodactyl(
        x: _rng.nextDouble() * size.x,
        y: 35 + _rng.nextDouble() * 95,
        speed: 30 + _rng.nextDouble() * 22,
        wingPhase: _rng.nextDouble() * math.pi * 2,
        scale: 0.70 + _rng.nextDouble() * 0.40,
      ));
    }

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

    // Spawn desert airborne micro sand dust
    for (int i = 0; i < 45; i++) {
      _desertSandDust.add(_DesertSandDust(
        x: _rng.nextDouble() * size.x,
        y: 35 + _rng.nextDouble() * (size.y * 0.72),
        radius: 0.8 + _rng.nextDouble() * 1.8,
        speedX: 100 + _rng.nextDouble() * 120,
        waveAmp: 2.0 + _rng.nextDouble() * 4.0,
        phase: _rng.nextDouble() * math.pi * 2,
        alpha: 0.20 + _rng.nextDouble() * 0.35,
        color: (i % 3 == 0)
            ? const Color(0xFFFFF9C4)
            : (i % 2 == 0)
                ? const Color(0xFFFFE082)
                : const Color(0xFFEAA63F),
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

    // Forest spores & flying pterodactyls update
    if (currentBiome == 'FOREST') {
      for (final spore in _forestSpores) {
        spore.y += math.sin(_time * spore.floatSpeed + spore.phase) * 12 * dt;
        spore.x -= 20 * dt;
        if (spore.x < -10) {
          spore.x = size.x + 10;
        }
      }
      for (final pt in _pterodactyls) {
        pt.x -= pt.speed * dt;
        pt.wingPhase += dt * 5.5;
        pt.y += math.sin(pt.wingPhase * 0.4) * 0.35;
        if (pt.x < -100) {
          pt.x = size.x + 100 + _rng.nextDouble() * 150;
          pt.y = 35 + _rng.nextDouble() * 100;
        }
      }
    }

    // Rolling bushes & sand dust update
    if (currentBiome == 'DESERT') {
      for (final rb in _rollingBushes) {
        rb.x -= rb.speed * dt;
        rb.rotation += (rb.speed / rb.radius) * dt;
        if (rb.x + rb.radius * 2 < -40) {
          rb.x = size.x + 60;
        }
      }
      for (final dust in _desertSandDust) {
        dust.x -= (dust.speedX + game.speedManager.currentSpeed * 0.10) * dt;
        if (dust.x < -10) {
          dust.x = size.x + 10 + _rng.nextDouble() * 40;
          dust.y = 40 + _rng.nextDouble() * (size.y * 0.72);
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
    final currentBiome = game.biomeManager.effectiveBiome.name;

    // Sky gradient (multi-stop deep twilight to golden horizon for Desert, or standard transition)
    final Gradient gradient;
    if (currentBiome == 'DESERT' && sp <= 0.01) {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF18539B), // Vibrant royal sky blue top
          Color(0xFF2E6FB8), // Clear cerulean
          Color(0xFF6B8FB8), // Soft atmospheric haze
          Color(0xFFDEAA4A), // Bright golden amber
          Color(0xFFF7C858), // Warm glowing sunlit horizon
        ],
        stops: [0.0, 0.22, 0.45, 0.72, 1.0],
      );
    } else {
      final topColor = sp > 0
          ? Color.lerp(skyTop, const Color(0xFF050510), sp)!
          : skyTop;
      final bottomColor = sp > 0
          ? Color.lerp(skyBottom, const Color(0xFF0A0A25), sp)!
          : skyBottom;
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      );
    }
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

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

      // Cosmic space nebulae & ringed planet (procedural fallback only)
      if (currentBiome == 'COSMOS' && _cosmosBgImage == null) {
        _drawSpaceNebulae(canvas);
        _drawRingedPlanet(canvas);
      }

      // Northern Lights for ICE land (procedural fallback only)
      if (currentBiome == 'ICE' && _iceBgImage == null) {
        _drawAuroraBorealis(canvas);
      }

      // God rays for Forest (procedural fallback only)
      if (currentBiome == 'FOREST' && _forestBgImage == null) {
        _drawGodRays(canvas);
      }

      // Detailed multi-layer parallax environments
      _drawParallaxBackground(canvas, currentBiome);

      // Stars (visible in space/night procedural fallbacks)
      final skyBrightness = skyTop.computeLuminance();
      if (skyBrightness < 0.35 && currentBiome != 'DESERT' && _cosmosBgImage == null && _iceBgImage == null) {
        for (final star in _stars) {
          final alpha = ((math.sin(star.brightness) + 1) / 2 * (1 - skyBrightness)).clamp(0.0, 1.0);
          canvas.drawCircle(
            Offset(star.x, star.y),
            1.5,
            Paint()..color = Colors.white.withValues(alpha: alpha),
          );
        }
      }

      // Sun (Procedural fallback only)
      if (currentBiome == 'DESERT' && _desertBgImage == null) {
        _drawSun(canvas, size.x, skyBrightness);
      }

      // Clouds (Procedural fallback only)
      if (_desertBgImage == null && _rainBgImage == null && _forestBgImage == null && _iceBgImage == null && _volcanoBgImage == null && _cosmosBgImage == null) {
        final cloudAlpha = skyBrightness > 0.2 ? 0.75 : 0.2;
        for (final cloud in _clouds) {
          _drawCloud(canvas, cloud, cloudAlpha);
        }
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

      // Atmospheric wind & rolling bushes for DESERT
      if (currentBiome == 'DESERT') {
        _drawDesertWind(canvas);
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

  /// 🌌 Deep Space Cosmic Parallax Realm (Atmospheric Cosmos Mode)
  void _drawSpaceModeVisuals(Canvas canvas, double sp) {
    final w = size.x;
    final h = size.y;

    // 1. Deep Space Cosmic Parallax Image Layer (if loaded)
    if (_cosmosBgImage != null) {
      final img = _cosmosBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = h / imgH;
      final tileW = imgW * scale;
      final pShift = (_bgScrollOffset * 0.4) % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..color = Colors.white.withValues(alpha: sp * 0.92);

      double startX = -pShift;
      while (startX < w + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, h),
          paint,
        );
        startX += tileW;
      }
    }

    // 2. Interstellar Nebulae Formations (Multi-spectral cosmic clouds)
    _drawDeepSpaceNebulae(canvas, sp);

    // 3. Majestic Ringed Gas Giant (Saturn-like Planet on Horizon)
    _drawDeepSpaceRingedPlanet(canvas, sp);

    // 4. Distant Radiant Crescent Moon / Celestial Exoplanet
    _drawDeepSpaceMoon(canvas, sp);

    // 5. Multi-Layered Twinkling Starfield & Colored Giant Stars
    _drawDeepSpaceStarfield(canvas, sp);

    // 6. Dynamic Shooting Stars & Comets with glowing dust tails
    _drawDeepSpaceComets(canvas, sp);

    // 7. Swirling Cosmic Stardust & Micro-Ion Motes
    _drawCosmosAtmosphere(canvas, w, h);

    // 8. Warp Speed streaks during Launch and Returning
    final phase = game.spacePhase;
    if (phase == SpacePhase.launch || phase == SpacePhase.returning) {
      _drawSpeedLines(canvas, phase);
    }
  }

  void _drawDeepSpaceNebulae(Canvas canvas, double sp) {
    final w = size.x;
    final h = size.y;

    // Cyan & Electric Indigo Nebula
    final n1Center = Offset(w * 0.28 + math.sin(_time * 0.08) * 20, h * 0.25 + math.cos(_time * 0.06) * 12);
    final n1Rect = Rect.fromCircle(center: n1Center, radius: 180);
    final n1Shader = RadialGradient(
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.22 * sp),
        const Color(0xFF7C4DFF).withValues(alpha: 0.12 * sp),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(n1Rect);
    canvas.drawCircle(n1Center, 180, Paint()..shader = n1Shader);

    // Magenta & Radiant Purple Nebula
    final n2Center = Offset(w * 0.75 + math.cos(_time * 0.09) * 18, h * 0.40 + math.sin(_time * 0.07) * 10);
    final n2Rect = Rect.fromCircle(center: n2Center, radius: 210);
    final n2Shader = RadialGradient(
      colors: [
        const Color(0xFFFF4081).withValues(alpha: 0.20 * sp),
        const Color(0xFF9C27B0).withValues(alpha: 0.10 * sp),
        Colors.transparent,
      ],
      stops: const [0.0, 0.50, 1.0],
    ).createShader(n2Rect);
    canvas.drawCircle(n2Center, 210, Paint()..shader = n2Shader);
  }

  void _drawDeepSpaceRingedPlanet(Canvas canvas, double sp) {
    final planetCenter = Offset(size.x * 0.84, size.y * 0.22 + math.sin(_time * 0.1) * 6);
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-math.pi / 7);

    // 1. Atmosphere Celestial Aura
    final auraRect = Rect.fromCircle(center: Offset.zero, radius: 46);
    final auraShader = RadialGradient(
      colors: [
        const Color(0xFF4DEEEA).withValues(alpha: 0.35 * sp),
        const Color(0xFF00B0FF).withValues(alpha: 0.12 * sp),
        Colors.transparent,
      ],
      stops: const [0.0, 0.65, 1.0],
    ).createShader(auraRect);
    canvas.drawCircle(Offset.zero, 46, Paint()..shader = auraShader);

    // 2. Planet Sphere Body with 3D Spherical Light
    final bodyRect = Rect.fromCircle(center: Offset.zero, radius: 32);
    final bodyShader = RadialGradient(
      center: const Alignment(-0.45, -0.45),
      colors: [
        const Color(0xFF80DEEA).withValues(alpha: sp),
        const Color(0xFF00838F).withValues(alpha: sp),
        const Color(0xFF004D40).withValues(alpha: sp),
        const Color(0xFF001518).withValues(alpha: sp),
      ],
      stops: const [0.0, 0.45, 0.80, 1.0],
    ).createShader(bodyRect);
    canvas.drawCircle(Offset.zero, 32, Paint()..shader = bodyShader);

    // 3. Multi-Band 3D Planetary Rings
    final ringOuterPaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.55 * sp)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawOval(const Rect.fromLTWH(-68, -13, 136, 26), ringOuterPaint);

    final ringInnerPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35 * sp)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(const Rect.fromLTWH(-56, -10, 112, 20), ringInnerPaint);

    canvas.restore();
  }

  void _drawDeepSpaceMoon(Canvas canvas, double sp) {
    final moonCenter = Offset(size.x * 0.16, size.y * 0.28 + math.cos(_time * 0.12) * 5);
    final moonRect = Rect.fromCircle(center: moonCenter, radius: 22);

    // Celestial Soft Moon Glow
    final glowShader = RadialGradient(
      colors: [
        const Color(0xFFE1BEE7).withValues(alpha: 0.30 * sp),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: moonCenter, radius: 36));
    canvas.drawCircle(moonCenter, 36, Paint()..shader = glowShader);

    // Moon Crescent Body
    final moonShader = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      colors: [
        const Color(0xFFF3E5F5).withValues(alpha: sp),
        const Color(0xFFBA68C8).withValues(alpha: sp),
        const Color(0xFF4A148C).withValues(alpha: sp),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(moonRect);
    canvas.drawCircle(moonCenter, 22, Paint()..shader = moonShader);

    // Surface Crater Accents
    final craterPaint = Paint()..color = const Color(0xFF38006B).withValues(alpha: 0.40 * sp);
    canvas.drawCircle(Offset(moonCenter.dx + 4, moonCenter.dy - 3), 4.0, craterPaint);
    canvas.drawCircle(Offset(moonCenter.dx - 6, moonCenter.dy + 5), 3.0, craterPaint);
    canvas.drawCircle(Offset(moonCenter.dx + 6, moonCenter.dy + 6), 2.5, craterPaint);
  }

  void _drawDeepSpaceStarfield(Canvas canvas, double sp) {
    final w = size.x;
    final h = size.y;

    // 1. Far Twinkling Micro Stars
    for (final star in _stars) {
      final twinkle = ((math.sin(star.brightness + _time * 2.5) + 1) / 2).clamp(0.0, 1.0);
      final starAlpha = sp * (0.35 + twinkle * 0.65);
      final starSize = 1.0 + twinkle * 1.6;
      canvas.drawCircle(
        Offset(star.x, star.y),
        starSize,
        Paint()..color = Colors.white.withValues(alpha: starAlpha),
      );
    }

    // 2. Giant Colored Celestial Stars with 4-point Diamond Diffraction Spikes
    final giantStarPositions = [
      Offset(w * 0.12, h * 0.15),
      Offset(w * 0.45, h * 0.18),
      Offset(w * 0.62, h * 0.55),
      Offset(w * 0.88, h * 0.68),
      Offset(w * 0.35, h * 0.72),
    ];
    final giantStarColors = [
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFFFFD54F), // Gold
      const Color(0xFFFF4081), // Magenta
      const Color(0xFF76FF03), // Emerald
      const Color(0xFF7C4DFF), // Violet
    ];

    for (int i = 0; i < giantStarPositions.length; i++) {
      final pos = giantStarPositions[i];
      final color = giantStarColors[i];
      final pulse = 0.85 + 0.15 * math.sin(_time * 3.0 + i * 1.7);

      // Star core
      canvas.drawCircle(pos, 3.2 * pulse, Paint()..color = Colors.white.withValues(alpha: sp));
      // Color halo
      canvas.drawCircle(
        pos,
        8.0 * pulse,
        Paint()..color = color.withValues(alpha: 0.35 * sp)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // 4-Point Diamond Cross Spikes
      final spikePaint = Paint()
        ..color = color.withValues(alpha: 0.60 * sp)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final spikeLen = 11.0 * pulse;
      canvas.drawLine(Offset(pos.dx - spikeLen, pos.dy), Offset(pos.dx + spikeLen, pos.dy), spikePaint);
      canvas.drawLine(Offset(pos.dx, pos.dy - spikeLen), Offset(pos.dx, pos.dy + spikeLen), spikePaint);
    }
  }

  void _drawDeepSpaceComets(Canvas canvas, double sp) {
    // Dynamic periodic comet streak
    final cometCycle = (_time * 0.35) % 1.0;
    if (cometCycle < 0.45) {
      final t = cometCycle / 0.45;
      final startX = size.x * 0.95 - t * (size.x * 0.75);
      final startY = size.y * 0.05 + t * (size.y * 0.45);
      final head = Offset(startX, startY);
      final tail = Offset(startX + 85, startY - 45);

      final cometAlpha = (math.sin(t * math.pi) * sp).clamp(0.0, 1.0);

      // Comet Tail Gradient
      final tailShader = LinearGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.85 * cometAlpha),
          const Color(0xFF7C4DFF).withValues(alpha: 0.40 * cometAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(head, tail));

      canvas.drawLine(
        head,
        tail,
        Paint()
          ..shader = tailShader
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );

      // Comet Glowing Head
      canvas.drawCircle(head, 3.5, Paint()..color = Colors.white.withValues(alpha: cometAlpha));
      canvas.drawCircle(
        head,
        7.0,
        Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: 0.45 * cometAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
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

  /// Draw organic fluffy rolling desert sagebrush / tumbleweed with smooth edge fade
  void _drawRollingBush(Canvas canvas, _RollingBush rb) {
    // Smooth fade near edges to prevent any popping near the left corner / dino
    double edgeAlpha = 1.0;
    if (rb.x < 180.0) {
      edgeAlpha = (rb.x / 180.0).clamp(0.0, 1.0);
    } else if (rb.x > size.x - 100.0) {
      edgeAlpha = ((size.x - rb.x) / 100.0).clamp(0.0, 1.0);
    }
    if (edgeAlpha <= 0.01) return;

    final yGround = size.y - 120 + _spaceSlideOffset;
    final r = rb.radius;

    // 1. Static Ground Shadow with edgeAlpha
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.16 * edgeAlpha);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rb.x, yGround - 1), width: r * 2.4, height: r * 0.45),
      shadowPaint,
    );

    // 2. Rolling Bush Body
    canvas.save();
    canvas.translate(rb.x, yGround - r);
    canvas.rotate(rb.rotation);

    // Warm desert sagebrush palette
    final shadowFoliagePaint = Paint()..color = const Color(0xFF4E5830).withValues(alpha: edgeAlpha);
    final midFoliagePaint = Paint()..color = const Color(0xFF76834E).withValues(alpha: edgeAlpha);
    final lightFoliagePaint = Paint()..color = const Color(0xFF9EAC6F).withValues(alpha: edgeAlpha);
    final sunlitFoliagePaint = Paint()..color = const Color(0xFFC7D493).withValues(alpha: edgeAlpha);
    final twigPaint = Paint()
      ..color = const Color(0xFF4A3418).withValues(alpha: 0.85 * edgeAlpha)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // 2a. Internal organic branching dry twigs
    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * math.pi * 2 + (i % 2 == 0 ? 0.1 : -0.15);
      final len = r * (0.65 + (i % 3) * 0.1);
      final tx = math.cos(angle) * len;
      final ty = math.sin(angle) * len;
      canvas.drawLine(Offset.zero, Offset(tx, ty), twigPaint);

      // Secondary fork
      final forkAngle = angle + (i % 2 == 0 ? 0.35 : -0.35);
      canvas.drawLine(
        Offset(tx * 0.55, ty * 0.55),
        Offset(tx * 0.55 + math.cos(forkAngle) * r * 0.32, ty * 0.55 + math.sin(forkAngle) * r * 0.32),
        twigPaint..strokeWidth = 1.1,
      );
    }

    // 2b. Base shadow foliage puffs (7 organic lobes)
    for (int i = 0; i < 7; i++) {
      final angle = (i / 7) * math.pi * 2;
      final dist = r * 0.52;
      final puffR = r * 0.44;
      canvas.drawCircle(Offset(math.cos(angle) * dist, math.sin(angle) * dist), puffR, shadowFoliagePaint);
    }

    // 2c. Mid-layer sage foliage puffs (8 offset lobes)
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2 + 0.38;
      final dist = r * 0.42;
      final puffR = r * 0.38;
      canvas.drawCircle(Offset(math.cos(angle) * dist, math.sin(angle) * dist), puffR, midFoliagePaint);
    }

    // 2d. Light top foliage clusters (5 central-offset lobes)
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 + 0.2;
      final dist = r * 0.28;
      final puffR = r * 0.32;
      canvas.drawCircle(Offset(math.cos(angle) * dist - 1.5, math.sin(angle) * dist - 1.5), puffR, lightFoliagePaint);
    }

    // 2e. Sunlit golden top highlights
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * math.pi * 2 - 0.4;
      final dist = r * 0.18;
      final puffR = r * 0.22;
      canvas.drawCircle(Offset(math.cos(angle) * dist - 2.0, math.sin(angle) * dist - 2.5), puffR, sunlitFoliagePaint);
    }

    // 2f. Center dense core puff
    canvas.drawCircle(const Offset(-1.0, -1.0), r * 0.28, lightFoliagePaint);

    canvas.restore();
  }

  /// 🏜️ Airborne Ambient Desert Dust Specks drifting in the breeze (Organic particles, no lines)
  void _drawDesertWind(Canvas canvas) {
    for (final dust in _desertSandDust) {
      final curY = dust.y + math.sin(_time * 2.2 + dust.phase) * dust.waveAmp;
      final dustPaint = Paint()..color = dust.color.withValues(alpha: dust.alpha);
      canvas.drawCircle(Offset(dust.x, curY), dust.radius, dustPaint);
    }
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
        Color(0xFFFBE48A), // Bright glowing sunlit sandstone
        Color(0xFFE5BF54), // Warm amber mid-tone
        Color(0xFFD4A842), // Base sandstone
      ],
      stops: const [0.0, 0.5, 1.0],
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
        Color(0xFFA67E36), // Deep warm sandstone shadow
        Color(0xFF825F22), // Ambient occlusion shadow
      ],
    ).createShader(Rect.fromLTRB(ridgeX, apex.dy, rightBaseX, yGround));
    canvas.drawPath(shadowFacePath, Paint()..shader = shadowShader);

    // Subtle 3D Center Ridge Shadow Line
    canvas.drawLine(
      apex,
      Offset(ridgeX, yGround),
      Paint()
        ..color = const Color(0xFF5D4216).withValues(alpha: 0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 3. Horizontal Stone Block Courses (Alternating highlight and groove for depth)
    final numCourses = 9;
    for (int k = 1; k <= numCourses; k++) {
      final t = k / (numCourses + 1.0);
      final py = apex.dy + (yGround - apex.dy) * t;
      final lx = apex.dx + (leftBaseX - apex.dx) * t;
      final cx = apex.dx + (ridgeX - apex.dx) * t;
      final rx = apex.dx + (rightBaseX - apex.dx) * t;

      // Lit face block line (subtle warm groove)
      canvas.drawLine(
        Offset(lx, py),
        Offset(cx, py),
        Paint()
          ..color = const Color(0xFFB58E34).withValues(alpha: 0.40)
          ..strokeWidth = 1.3,
      );
      // Lit face upper block edge highlight
      canvas.drawLine(
        Offset(lx + 2, py - 1),
        Offset(cx, py - 1),
        Paint()
          ..color = const Color(0xFFFFF3B0).withValues(alpha: 0.45)
          ..strokeWidth = 1.0,
      );

      // Shadow face block line
      canvas.drawLine(
        Offset(cx, py),
        Offset(rx, py),
        Paint()
          ..color = const Color(0xFF5C4116).withValues(alpha: 0.45)
          ..strokeWidth = 1.3,
      );
    }

    // 4. Golden Apex Capstone (Pyramidion)
    if (hasGoldenCapstone) {
      final capT = 0.16;
      final capBaseY = apex.dy + (yGround - apex.dy) * capT;
      final capLx = apex.dx + (leftBaseX - apex.dx) * capT;
      final capRx = apex.dx + (rightBaseX - apex.dx) * capT;
      final capRidgeX = apex.dx + (ridgeX - apex.dx) * capT;

      final capLitPath = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(capLx, capBaseY)
        ..lineTo(capRidgeX, capBaseY)
        ..close();
      final capLitShader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFFF9C4), // Gleaming white gold tip
          Color(0xFFFFD54F), // Pure yellow gold
          Color(0xFFFFB300), // Rich amber gold
        ],
      ).createShader(Rect.fromLTRB(capLx, apex.dy, capRidgeX, capBaseY));
      canvas.drawPath(capLitPath, Paint()..shader = capLitShader);

      final capShadowPath = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(capRidgeX, capBaseY)
        ..lineTo(capRx, capBaseY)
        ..close();
      final capShadowShader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
        ],
      ).createShader(Rect.fromLTRB(capRidgeX, apex.dy, capRx, capBaseY));
      canvas.drawPath(capShadowPath, Paint()..shader = capShadowShader);

      // Specular diamond star glint on apex
      _drawStarGlint(canvas, apex, 14.0);
    }
  }

  /// 4-point diamond specular star glint
  void _drawStarGlint(Canvas canvas, Offset center, double size) {
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
    final hPath = Path()
      ..moveTo(center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size * 0.25)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size * 0.25)
      ..close();
    final vPath = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size * 0.25, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size * 0.25, center.dy)
      ..close();
    canvas.drawPath(hPath, glintPaint);
    canvas.drawPath(vPath, glintPaint);
    canvas.drawCircle(center, size * 0.22, Paint()..color = Colors.white);
  }

  /// Master Desert Artwork rendering: AI background image or procedural vector fallback
  void _drawDesertArtwork(Canvas canvas, double w, double yGround) {
    if (_desertBgImage != null) {
      final img = _desertBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final renderW = imgW * scale;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final dstRect = Rect.fromLTWH(0, 0, renderW, size.y);
      canvas.drawImageRect(img, srcRect, dstRect, Paint()..filterQuality = FilterQuality.low);
      return;
    }

    // 1. Far Soft Sand Dune Horizon Silhouette (Atmospheric backdrop - seamlessly matching at 0 and w)
    final farDunePath = Path()
      ..moveTo(0, yGround - 50)
      ..quadraticBezierTo(w * 0.18, yGround - 72, w * 0.38, yGround - 48)
      ..quadraticBezierTo(w * 0.58, yGround - 80, w * 0.78, yGround - 52)
      ..quadraticBezierTo(w * 0.90, yGround - 72, w, yGround - 50)
      ..lineTo(w, size.y)
      ..lineTo(0, size.y);
    final farDuneShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF0D58C).withValues(alpha: 0.75),
        const Color(0xFFE0B65E).withValues(alpha: 0.60),
      ],
    ).createShader(Rect.fromLTWH(0, yGround - 85, w, 140));
    canvas.drawPath(farDunePath, Paint()..shader = farDuneShader);

    // 2. Far Landmarks:
    // Distant Sphinx on left dune ridge
    _drawDesertSphinx(canvas, Offset(w * 0.08, yGround - 58), 0.68);
    // Secondary Sphinx on mid-right dune ridge
    _drawDesertSphinx(canvas, Offset(w * 0.72, yGround - 66), 0.75);
    // Ancient Sand Citadel / Castle on right dune
    _drawDesertSandCitadel(canvas, Offset(w * 0.88, yGround - 66), 0.80);

    // 3. Midground Sweeping Sand Dunes (Rich S-crests with golden light & shadow - seamlessly matching at 0 and w)
    final midDunePath = Path()
      ..moveTo(0, yGround - 40)
      ..cubicTo(w * 0.16, yGround - 62, w * 0.32, yGround - 26, w * 0.48, yGround - 52)
      ..cubicTo(w * 0.62, yGround - 74, w * 0.76, yGround - 28, w * 0.90, yGround - 58)
      ..lineTo(w, yGround - 40)
      ..lineTo(w, size.y)
      ..lineTo(0, size.y);
    final midDuneShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFBE48A), // Bright sunlit crest
        const Color(0xFFE8BC50), // Mid dune gold
        const Color(0xFFC7922E), // Rich warm shadow
      ],
      stops: const [0.0, 0.42, 1.0],
    ).createShader(Rect.fromLTWH(0, yGround - 75, w, 150));
    canvas.drawPath(midDunePath, Paint()..shader = midDuneShader);

    // Dune Ridge Golden Highlight & Shadow Crest Sweep
    final ridgePath = Path()
      ..moveTo(0, yGround - 40)
      ..cubicTo(w * 0.16, yGround - 62, w * 0.32, yGround - 26, w * 0.48, yGround - 52)
      ..cubicTo(w * 0.62, yGround - 74, w * 0.76, yGround - 28, w * 0.90, yGround - 58)
      ..lineTo(w, yGround - 40);

    // Golden sun glint on the ridge edge
    canvas.drawPath(
      ridgePath,
      Paint()
        ..color = const Color(0xFFFFF5B8).withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..style = ui.PaintingStyle.stroke,
    );
    // Soft shadow below the ridge
    canvas.drawPath(
      ridgePath,
      Paint()
        ..color = const Color(0xFF9E6E1C).withValues(alpha: 0.40)
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..style = ui.PaintingStyle.stroke,
    );

    // 4. Midground Scenic Elements:
    // Desert Oasis nestled in left dune valley
    _drawDesertOasis(canvas, Offset(w * 0.22, yGround - 42), 135);

    // Camel Caravan walking along the central ridge
    _drawDesertCamelCaravan(canvas, Offset(w * 0.60, yGround - 48), 0.82);

    // Ancient Petroglyphs carved into the sand slopes
    _drawDesertPetroglyphs(canvas, Offset(w * 0.11, yGround - 28), 0.75);
    _drawDesertPetroglyphs(canvas, Offset(w * 0.78, yGround - 32), 0.65);

    // 5. Grand 3D Pyramids with Golden Capstones
    // Great Pyramid of Giza (Center Left)
    _draw3DPyramid(
      canvas,
      apex: Offset(w * 0.38, yGround - 165),
      leftBaseX: w * 0.18,
      rightBaseX: w * 0.56,
      yGround: yGround,
      hasGoldenCapstone: true,
    );

    // Pyramid of Khafre (Center Right)
    _draw3DPyramid(
      canvas,
      apex: Offset(w * 0.76, yGround - 140),
      leftBaseX: w * 0.62,
      rightBaseX: w * 0.89,
      yGround: yGround,
      hasGoldenCapstone: true,
    );

    // 6. Foreground Dune Ridge Hugging Base of Pyramids (seamlessly matching at 0 and w)
    final fgDunePath = Path()
      ..moveTo(0, yGround - 15)
      ..quadraticBezierTo(w * 0.22, yGround - 26, w * 0.46, yGround - 8)
      ..quadraticBezierTo(w * 0.72, yGround - 28, w, yGround - 15)
      ..lineTo(w, size.y)
      ..lineTo(0, size.y);
    final fgDuneShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFBE48A),
        Color(0xFFE5B946),
        Color(0xFFCA9428),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(Rect.fromLTWH(0, yGround - 30, w, 60));
    canvas.drawPath(fgDunePath, Paint()..shader = fgDuneShader);

    // Foreground Crest Golden Edge
    final fgCrest = Path()
      ..moveTo(0, yGround - 15)
      ..quadraticBezierTo(w * 0.22, yGround - 26, w * 0.46, yGround - 8)
      ..quadraticBezierTo(w * 0.72, yGround - 28, w, yGround - 15);
    canvas.drawPath(
      fgCrest,
      Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.85)
        ..strokeWidth = 1.8
        ..style = ui.PaintingStyle.stroke,
    );
  }

  void _drawDesertSphinx(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    // Soft cast shadow on dune
    final shadowPath = Path()
      ..addOval(const Rect.fromLTWH(-55, 18, 120, 16));
    canvas.drawPath(shadowPath, Paint()..color = const Color(0xFF8A5D18).withValues(alpha: 0.35));

    // Sphinx Lion Body (Rich golden sandstone gradient)
    final bodyPath = Path()
      ..moveTo(-50, 20)
      ..cubicTo(-48, -6, -28, -20, -8, -12)
      ..cubicTo(6, -6, 16, -14, 22, -30)
      ..lineTo(28, -30)
      ..cubicTo(34, -14, 36, 2, 38, 18)
      ..lineTo(62, 18)
      ..quadraticBezierTo(66, 23, 60, 25)
      ..lineTo(-55, 25)
      ..quadraticBezierTo(-60, 22, -50, 20);

    final sphinxGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFBE48A), Color(0xFFE5B946), Color(0xFFB88628)],
      stops: [0.0, 0.5, 1.0],
    );
    final bounds = const Rect.fromLTWH(-60, -50, 130, 80);
    canvas.drawPath(bodyPath, Paint()..shader = sphinxGrad.createShader(bounds));

    // Curved Tail resting against flank
    final tailPath = Path()
      ..moveTo(-48, 16)
      ..cubicTo(-54, 4, -48, -4, -42, -2)
      ..cubicTo(-40, 4, -44, 12, -45, 18);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFF9E6E1C)
        ..strokeWidth = 2.4
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Front Paws with defined claws
    final pawPaint = Paint()..color = const Color(0xFFF5CE6E);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 16, 26, 9), const Radius.circular(3)), pawPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 18, 22, 7), const Radius.circular(3)), Paint()..color = const Color(0xFFD8A53B));

    // Royal Nemes Headdress (Egyptian pharaoh cloth with blue & gold bands)
    final nemesPath = Path()
      ..moveTo(12, -30)
      ..lineTo(14, -52)
      ..quadraticBezierTo(24, -60, 35, -52)
      ..lineTo(37, -30)
      ..lineTo(33, -22)
      ..lineTo(15, -22)
      ..close();
    canvas.drawPath(nemesPath, Paint()..color = const Color(0xFFFFD54F));

    // Pharaoh Face profile
    final facePath = Path()
      ..moveTo(22, -50)
      ..quadraticBezierTo(28, -52, 34, -48)
      ..lineTo(36, -42)
      ..lineTo(39, -39) // Noble nose
      ..lineTo(35, -36) // Lips
      ..lineTo(36, -32) // Chin
      ..lineTo(22, -32)
      ..close();
    canvas.drawPath(facePath, Paint()..color = const Color(0xFFFFF1A8));

    // Pharaoh Beard (Osiris Beard)
    final beardPath = Path()
      ..moveTo(33, -32)
      ..lineTo(36, -32)
      ..lineTo(37, -23)
      ..lineTo(32, -23)
      ..close();
    canvas.drawPath(beardPath, Paint()..color = const Color(0xFF4A3412));

    // Royal Blue Nemes Stripes
    final blueStripePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 1.4;
    for (int k = 0; k < 5; k++) {
      final sy = -48.0 + k * 3.8;
      canvas.drawLine(Offset(14, sy), Offset(35, sy), blueStripePaint);
    }

    // Uraeus Cobra crest on brow
    canvas.drawCircle(const Offset(25, -56), 2.0, Paint()..color = const Color(0xFFFFD700));

    canvas.restore();
  }

  void _drawDesertCamelCaravan(Canvas canvas, Offset startPos, double scale) {
    canvas.save();
    canvas.translate(startPos.dx, startPos.dy);
    canvas.scale(scale);

    final saddlePaints = [
      Paint()..color = const Color(0xFFD32F2F), // Crimson
      Paint()..color = const Color(0xFF1976D2), // Royal Cobalt
      Paint()..color = const Color(0xFF388E3C), // Emerald
      Paint()..color = const Color(0xFFF57C00), // Sunset Orange
    ];
    final ropePaint = Paint()
      ..color = const Color(0xFF5D4037).withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    // Leader Bedouin scout figure
    const scoutX = 145.0;
    final scoutPaint = Paint()..color = const Color(0xFF4E342E);
    // Flowing desert keffiyeh headwear
    canvas.drawCircle(const Offset(scoutX, -18), 4.0, Paint()..color = const Color(0xFFFFF8E1));
    canvas.drawCircle(const Offset(scoutX, -18), 2.5, scoutPaint);
    // Flowing Robe (Galabeya)
    final robePath = Path()
      ..moveTo(scoutX - 4, -14)
      ..lineTo(scoutX + 4, -14)
      ..lineTo(scoutX + 6, 8)
      ..lineTo(scoutX - 6, 8)
      ..close();
    canvas.drawPath(robePath, Paint()..color = const Color(0xFFECEFF1));
    // Walking legs
    canvas.drawLine(const Offset(scoutX - 3, 8), const Offset(scoutX - 5, 16), scoutPaint..strokeWidth = 2.0);
    canvas.drawLine(const Offset(scoutX + 3, 8), const Offset(scoutX + 5, 16), scoutPaint..strokeWidth = 2.0);
    // Shepherd staff
    canvas.drawLine(
      const Offset(scoutX + 7, -24),
      const Offset(scoutX + 7, 16),
      Paint()..color = const Color(0xFF795548)..strokeWidth = 1.5,
    );

    // Lead rope to first camel
    canvas.drawLine(const Offset(scoutX - 4, -6), const Offset(108, -12), ropePaint);

    for (int c = 0; c < 4; c++) {
      final cx = 100.0 - c * 40.0;
      final cy = (c % 2 == 0) ? 0.0 : 2.5;

      canvas.save();
      canvas.translate(cx, cy);

      // Connecting rein rope to previous camel
      if (c < 3) {
        final ropeCurve = Path()
          ..moveTo(-14, -6)
          ..quadraticBezierTo(-26, 4, -40 + 12, -10);
        canvas.drawPath(ropeCurve, ropePaint..style = ui.PaintingStyle.stroke);
      }

      // Camel Soft Drop Shadow
      canvas.drawOval(
        const Rect.fromLTWH(-16, 12, 36, 6),
        Paint()..color = const Color(0xFF7A5820).withValues(alpha: 0.35),
      );

      // Smooth Anatomical Camel Silhouette
      final cPath = Path()
        ..moveTo(-16, 2)
        ..cubicTo(-18, -4, -16, -10, -10, -12) // Rear flank
        ..cubicTo(-6, -12, -4, -20, 2, -20)   // Rounded Single Hump
        ..cubicTo(7, -20, 9, -12, 13, -10)    // Shoulder
        ..lineTo(16, -22)                     // Arched neck
        ..cubicTo(18, -26, 24, -26, 24, -21)  // Head & muzzle
        ..lineTo(22, -18)
        ..lineTo(17, -14)                     // Throat
        ..cubicTo(14, -6, 13, 0, 10, 2)       // Chest
        ..cubicTo(0, 5, -8, 5, -16, 2)        // Belly
        ..close();

      final camelGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFD4A552),
          Color(0xFFB58230),
        ],
      ).createShader(const Rect.fromLTWH(-18, -26, 45, 35));
      canvas.drawPath(cPath, Paint()..shader = camelGradient);

      // Embroidered Nomadic Saddle Blanket with Gold Fringe
      final saddleRect = const Rect.fromLTWH(-5, -20, 14, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(saddleRect, const Radius.circular(2)),
        saddlePaints[c % saddlePaints.length],
      );
      // Gold fringe trim on saddle
      canvas.drawLine(
        const Offset(-5, -10),
        const Offset(9, -10),
        Paint()..color = const Color(0xFFFFD700)..strokeWidth = 1.4,
      );

      // Articulated legs with knees & hooves
      final legPaint = Paint()
        ..color = const Color(0xFF8D6220)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      // Hind legs (stride motion)
      canvas.drawLine(const Offset(-12, 2), const Offset(-15, 14), legPaint);
      canvas.drawLine(const Offset(-7, 2), const Offset(-5, 14), legPaint);
      // Fore legs (stride motion)
      canvas.drawLine(const Offset(6, 2), const Offset(4, 14), legPaint);
      canvas.drawLine(const Offset(11, 2), const Offset(14, 14), legPaint);

      // Head bridle detail
      canvas.drawCircle(const Offset(22, -22), 1.0, Paint()..color = const Color(0xFF3E2723));

      canvas.restore();
    }

    canvas.restore();
  }

  void _drawDesertOasis(Canvas canvas, Offset pos, double width) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // 1. Soft glowing shoreline moisture ring
    final shoreRect = Rect.fromCenter(center: Offset.zero, width: width * 1.15, height: width * 0.42);
    final shoreShader = RadialGradient(
      center: Alignment.center,
      colors: [
        const Color(0xFF4DB6AC).withValues(alpha: 0.45),
        const Color(0xFFE0B65E).withValues(alpha: 0.0),
      ],
    ).createShader(shoreRect);
    canvas.drawOval(shoreRect, Paint()..shader = shoreShader);

    // 2. Crystal clear turquoise spring pool
    final poolRect = Rect.fromCenter(center: Offset.zero, width: width, height: width * 0.36);
    final poolPath = Path()..addOval(poolRect);

    final waterShader = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      colors: const [
        Color(0xFFE0F7FA), // Radiant sky reflection
        Color(0xFF4DD0E1), // Turquoise clear water
        Color(0xFF0097A7), // Deep emerald azure spring
        Color(0xFF006064), // Deep basin
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(poolRect);
    canvas.drawPath(poolPath, Paint()..shader = waterShader);

    // 3. Shimmering water ripple arcs & white wave crests
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    canvas.drawArc(Rect.fromCenter(center: const Offset(-10, -5), width: width * 0.52, height: width * 0.16), 0.2, 2.2, false, ripplePaint);
    canvas.drawArc(Rect.fromCenter(center: const Offset(12, 4), width: width * 0.38, height: width * 0.12), 0.6, 1.8, false, ripplePaint);

    // 4. Smooth shoreline river rocks with highlights & shadows
    final stones = [
      (Offset(-width * 0.48, 3), 11.0, 7.0, const Color(0xFF795548)),
      (Offset(-width * 0.36, width * 0.15), 14.0, 8.0, const Color(0xFF8D6E63)),
      (Offset(-width * 0.12, width * 0.18), 10.0, 6.0, const Color(0xFFA1887F)),
      (Offset(width * 0.14, width * 0.17), 13.0, 7.5, const Color(0xFF795548)),
      (Offset(width * 0.42, width * 0.08), 12.0, 7.0, const Color(0xFF8D6E63)),
      (Offset(width * 0.46, -width * 0.06), 9.0, 6.0, const Color(0xFFA1887F)),
      (Offset(-width * 0.22, -width * 0.16), 11.0, 6.5, const Color(0xFF6D4C41)),
      (Offset(width * 0.22, -width * 0.17), 12.0, 7.0, const Color(0xFF795548)),
    ];
    for (final stone in stones) {
      final stoneRect = Rect.fromCenter(center: stone.$1, width: stone.$2, height: stone.$3);
      // Cast shadow
      canvas.drawOval(
        Rect.fromCenter(center: stone.$1 + const Offset(1, 2), width: stone.$2, height: stone.$3),
        Paint()..color = const Color(0xFF4E342E).withValues(alpha: 0.4),
      );
      // Stone body
      canvas.drawOval(stoneRect, Paint()..color = stone.$4);
      // Stone sunlit top highlight
      canvas.drawOval(
        Rect.fromCenter(center: stone.$1 - const Offset(1, 1.5), width: stone.$2 * 0.7, height: stone.$3 * 0.5),
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }

    // 5. Lush Date Palm Trees gracefully framing the oasis
    _drawPalmTree(canvas, Offset(-width * 0.32, -4), scale: 0.90, tilt: -0.24);
    _drawPalmTree(canvas, Offset(-width * 0.16, -12), scale: 1.15, tilt: -0.06);
    _drawPalmTree(canvas, Offset(width * 0.30, -6), scale: 0.95, tilt: 0.20);

    canvas.restore();
  }

  void _drawPalmTree(Canvas canvas, Offset rootPos, {required double scale, required double tilt}) {
    canvas.save();
    canvas.translate(rootPos.dx, rootPos.dy);
    canvas.scale(scale);

    // Natural curved segmented palm trunk
    final trunkPath = Path()
      ..moveTo(-5, 0)
      ..cubicTo(-4 + tilt * 40, -25, -3 + tilt * 70, -50, tilt * 90 - 1, -78)
      ..lineTo(tilt * 90 + 5, -78)
      ..cubicTo(4 + tilt * 70, -50, 5 + tilt * 40, -25, 5, 0)
      ..close();

    final trunkGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFF8D6E63), // Lit side bark
        Color(0xFF5D4037), // Core bark
        Color(0xFF3E2723), // Shadow bark
      ],
    ).createShader(const Rect.fromLTWH(-10, -80, 40, 80));
    canvas.drawPath(trunkPath, Paint()..shader = trunkGradient);

    // Palm trunk texture rings
    final ringPaint = Paint()
      ..color = const Color(0xFF2D1B18).withValues(alpha: 0.6)
      ..strokeWidth = 1.8;
    for (int k = 1; k <= 9; k++) {
      final t = k / 10.0;
      final rx = (1 - t) * 0 + t * (tilt * 90);
      final ry = -t * 78;
      canvas.drawLine(Offset(rx - 4.5, ry), Offset(rx + 4.5, ry), ringPaint);
    }

    final crownX = tilt * 90 + 2;
    const crownY = -78.0;

    // Golden / Brown Date Clusters
    final datePaint = Paint()..color = const Color(0xFF6D4C41);
    final dateHighlight = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset(crownX - 4, crownY + 3), 3.5, datePaint);
    canvas.drawCircle(Offset(crownX - 4, crownY + 3), 1.8, dateHighlight);
    canvas.drawCircle(Offset(crownX + 3, crownY + 4), 3.8, datePaint);
    canvas.drawCircle(Offset(crownX + 3, crownY + 4), 2.0, dateHighlight);
    canvas.drawCircle(Offset(crownX, crownY + 6), 3.2, datePaint);

    // Multi-Layered Feathered Date Palm Fronds
    final frondTiers = [
      // Deep background fronds
      (const Color(0xFF1B5E20), 0.95, -0.15),
      // Mid rich forest fronds
      (const Color(0xFF2E7D32), 1.05, 0.0),
      // Bright sunlit emerald fronds
      (const Color(0xFF43A047), 1.15, 0.12),
      // Top lime highlight fronds
      (const Color(0xFF66BB6A), 1.0, 0.22),
    ];

    final baseAngles = [-2.5, -1.9, -1.3, -0.7, 0.0, 0.7, 1.3, 1.9, 2.5];
    for (int i = 0; i < baseAngles.length; i++) {
      final baseAngle = baseAngles[i] + tilt * 0.45;
      final tier = frondTiers[i % frondTiers.length];
      final frondLen = (32.0 + (i % 3) * 7.0) * tier.$2;

      final tipX = crownX + math.cos(baseAngle - math.pi / 2) * frondLen;
      final tipY = crownY + math.sin(baseAngle - math.pi / 2) * frondLen + 10.0;

      // Elegant cascading curved frond leaf body
      final fPath = Path()
        ..moveTo(crownX, crownY)
        ..quadraticBezierTo(
          (crownX + tipX) / 2 + math.sin(baseAngle) * 9,
          (crownY + tipY) / 2 - 10,
          tipX,
          tipY,
        )
        ..quadraticBezierTo(
          (crownX + tipX) / 2 - math.sin(baseAngle) * 5,
          (crownY + tipY) / 2 + 6,
          crownX,
          crownY,
        );

      canvas.drawPath(fPath, Paint()..color = tier.$1);

      // Bright sunlit central frond stem (rachis)
      canvas.drawLine(
        Offset(crownX, crownY),
        Offset(tipX, tipY),
        Paint()
          ..color = const Color(0xFFDCEDC8).withValues(alpha: 0.8)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );

      // Fine feathery leaflet strokes along the frond
      final leafStrokePaint = Paint()
        ..color = tier.$1
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (int lf = 1; lf <= 6; lf++) {
        final lt = lf / 7.0;
        final lx = crownX + (tipX - crownX) * lt;
        final ly = crownY + (tipY - crownY) * lt;
        final lAng = baseAngle + (lf % 2 == 0 ? 0.6 : -0.6);
        canvas.drawLine(
          Offset(lx, ly),
          Offset(lx + math.cos(lAng) * 6, ly + math.sin(lAng) * 6 + 2),
          leafStrokePaint,
        );
      }
    }

    canvas.restore();
  }

  void _drawDesertSandCitadel(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    // Fortress shadow on sand
    canvas.drawOval(
      const Rect.fromLTWH(-55, 20, 115, 14),
      Paint()..color = const Color(0xFF7A5820).withValues(alpha: 0.35),
    );

    final litPaint = Paint()..color = const Color(0xFFFBE48A);
    final midPaint = Paint()..color = const Color(0xFFE5B946);
    final shadowPaint = Paint()..color = const Color(0xFF9E6E1C);

    // Main Curtain Wall
    canvas.drawRect(const Rect.fromLTWH(-36, -26, 72, 38), midPaint);
    canvas.drawRect(const Rect.fromLTWH(-36, -26, 36, 38), litPaint);
    canvas.drawRect(const Rect.fromLTWH(0, -26, 36, 38), shadowPaint);

    // Battlements & Crenellations across curtain wall
    for (int i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-36 + i * 15, -34, 9, 8), const Radius.circular(1.5)),
        litPaint,
      );
    }

    // Grand Central Keep
    canvas.drawRect(const Rect.fromLTWH(-14, -54, 28, 28), midPaint);
    canvas.drawRect(const Rect.fromLTWH(-14, -54, 14, 28), litPaint);
    canvas.drawRect(const Rect.fromLTWH(0, -54, 14, 28), shadowPaint);

    // Gleaming Golden Onion Dome on Central Keep
    final domePath = Path()
      ..moveTo(-16, -54)
      ..cubicTo(-18, -66, -8, -75, 0, -78)
      ..cubicTo(8, -75, 18, -66, 16, -54)
      ..close();
    final domeShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFFFFF9C4),
        Color(0xFFFFD54F),
        Color(0xFFFF8F00),
      ],
    ).createShader(const Rect.fromLTWH(-18, -78, 36, 26));
    canvas.drawPath(domePath, Paint()..shader = domeShader);
    // Dome crescent finial
    canvas.drawCircle(const Offset(0, -81), 2.2, Paint()..color = const Color(0xFFFFD700));

    // Left Watchtower with Conical Spire
    canvas.drawRect(const Rect.fromLTWH(-50, -44, 18, 52), litPaint);
    final leftSpire = Path()
      ..moveTo(-52, -44)
      ..lineTo(-41, -64)
      ..lineTo(-30, -44)
      ..close();
    canvas.drawPath(leftSpire, Paint()..color = const Color(0xFFFFD54F));
    // Fluttering red banner flag
    final flagPath = Path()
      ..moveTo(-41, -64)
      ..lineTo(-41, -74)
      ..lineTo(-32, -69)
      ..lineTo(-41, -64);
    canvas.drawPath(flagPath, Paint()..color = const Color(0xFFD32F2F));

    // Right Watchtower with Conical Spire
    canvas.drawRect(const Rect.fromLTWH(32, -44, 18, 52), shadowPaint);
    final rightSpire = Path()
      ..moveTo(30, -44)
      ..lineTo(41, -64)
      ..lineTo(52, -44)
      ..close();
    canvas.drawPath(rightSpire, Paint()..color = const Color(0xFFC7922E));

    // Moorish Arched Entry Portal with Depth
    final archPath = Path()
      ..moveTo(-9, 12)
      ..lineTo(-9, -6)
      ..cubicTo(-9, -18, 9, -18, 9, -6)
      ..lineTo(9, 12)
      ..close();
    canvas.drawPath(archPath, Paint()..color = const Color(0xFF3E2723));

    // Decorative Arched Windows / Arrow Slits
    final winPaint = Paint()..color = const Color(0xFF4A3412);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-45, -32, 7, 12), const Radius.circular(3.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, -32, 7, 12), const Radius.circular(3.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -44, 10, 14), const Radius.circular(5)), winPaint);

    canvas.restore();
  }

  void _drawDesertPetroglyphs(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final glyphPaint = Paint()
      ..color = const Color(0xFFB57E28).withValues(alpha: 0.65)
      ..strokeWidth = 2.2
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spiralPath = Path();
    for (double a = 0; a < math.pi * 5; a += 0.2) {
      final r = a * 2.6;
      final px = math.cos(a) * r;
      final py = math.sin(a) * r;
      if (a == 0) {
        spiralPath.moveTo(px, py);
      } else {
        spiralPath.lineTo(px, py);
      }
    }
    canvas.drawPath(spiralPath, glyphPaint);

    for (int i = 0; i < 8; i++) {
      final ang = (i / 8) * math.pi * 2;
      canvas.drawCircle(
        Offset(math.cos(ang) * 44, math.sin(ang) * 44),
        2.2,
        Paint()..color = const Color(0xFFB57E28).withValues(alpha: 0.6),
      );
    }

    final birdPath = Path()
      ..moveTo(-35, 15)
      ..quadraticBezierTo(-20, 5, 0, 20)
      ..quadraticBezierTo(20, 5, 35, 15)
      ..moveTo(0, 20)
      ..lineTo(0, 38)
      ..lineTo(-10, 48)
      ..moveTo(0, 38)
      ..lineTo(10, 48);
    canvas.drawPath(birdPath, glyphPaint);

    canvas.restore();
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

  /// 🐪 Distant Wandering Camel Caravan, Solar Flare, and Heat Mirage Haze
  void _drawDesertAtmosphereImmersion(Canvas canvas, double yGround) {
    // 1. Sun Solar Corona & Anamorphic Lens Flare
    final sunCenter = Offset(size.x * 0.72, size.y * 0.22);
    final sunPulse = 1.0 + math.sin(_time * 1.5) * 0.06;

    final sunCoronaShader = RadialGradient(
      colors: const [
        Color(0x70FFF9C4), // Golden white core
        Color(0x35FFE082), // Warm amber halo
        Color(0x15FFB300), // Soft orange rim
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: 120 * sunPulse));
    canvas.drawCircle(sunCenter, 120 * sunPulse, Paint()..shader = sunCoronaShader);

    // 2. Distant Wandering Camel Caravan on Horizon
    _drawCamelCaravan(canvas, yGround);

    // 3. Atmospheric Heat Mirage Shimmer above Horizon
    final heatWavePaint = Paint()
      ..color = const Color(0x18FFE082)
      ..strokeWidth = 1.8
      ..style = ui.PaintingStyle.stroke;
    for (int hw = 0; hw < 2; hw++) {
      final hwPath = Path();
      final baseY = yGround - 18 + hw * 8;
      hwPath.moveTo(0, baseY);
      for (double x = 0; x <= size.x; x += 25) {
        final wy = baseY + math.sin(_time * 4.0 + x * 0.04 + hw * 1.5) * 2.0;
        hwPath.lineTo(x, wy);
      }
      canvas.drawPath(hwPath, heatWavePaint);
    }
  }

  void _drawCamelCaravan(Canvas canvas, double yGround) {
    final caravanX = ((size.x * 1.6 - _bgScrollOffset * 0.5) % (size.x + 350)) - 150;
    final caravanY = yGround - 24;
    final camelPaint = Paint()..color = const Color(0xAA42240C); // Warm silhouette
    final ropePaint = Paint()
      ..color = const Color(0x6642240C)
      ..strokeWidth = 0.8
      ..style = ui.PaintingStyle.stroke;

    for (int c = 0; c < 3; c++) {
      final cx = caravanX + c * 38.0;
      final cy = caravanY + math.sin(_time * 3.0 + c) * 0.8;
      final legWalk = math.sin(_time * 4.5 + c * 1.2) * 2.5;

      // Body & Hump
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 18, height: 10), camelPaint);
      canvas.drawCircle(Offset(cx - 2, cy - 6), 5.0, camelPaint); // Hump

      // Neck & Head
      final neckPath = Path()
        ..moveTo(cx + 6, cy)
        ..quadraticBezierTo(cx + 12, cy - 8, cx + 10, cy - 14)
        ..lineTo(cx + 14, cy - 13)
        ..lineTo(cx + 8, cy + 2)
        ..close();
      canvas.drawPath(neckPath, camelPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 12, cy - 14), width: 6, height: 4), camelPaint);

      // Tail
      canvas.drawLine(Offset(cx - 8, cy), Offset(cx - 12, cy + 5), camelPaint..strokeWidth = 1.0);

      // 4 Walking Legs
      canvas.drawLine(Offset(cx - 5, cy + 4), Offset(cx - 6 + legWalk, cy + 13), camelPaint..strokeWidth = 1.4);
      canvas.drawLine(Offset(cx - 2, cy + 4), Offset(cx - 3 - legWalk, cy + 13), camelPaint..strokeWidth = 1.4);
      canvas.drawLine(Offset(cx + 3, cy + 4), Offset(cx + 2 - legWalk, cy + 13), camelPaint..strokeWidth = 1.4);
      canvas.drawLine(Offset(cx + 6, cy + 4), Offset(cx + 7 + legWalk, cy + 13), camelPaint..strokeWidth = 1.4);

      // Lead rope connecting to next camel
      if (c < 2) {
        final nextX = cx + 38.0;
        final nextY = caravanY + math.sin(_time * 3.0 + (c + 1)) * 0.8;
        final ropePath = Path()
          ..moveTo(cx - 6, cy - 2)
          ..quadraticBezierTo((cx + nextX) / 2, cy + 6, nextX + 10, nextY - 10);
        canvas.drawPath(ropePath, ropePaint);
      }
    }
  }

  /// Draw multi-layer detailed parallax background silhouettes for all 6 biomes
  void _drawParallaxBackground(Canvas canvas, String biome) {
    final yGround = size.y - 120 + _spaceSlideOffset;

    if (_desertBgImage != null && biome == 'DESERT') {
      final img = _desertBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      // Draw seamlessly repeating tiles
      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }

      // Draw atmospheric immersion (sun corona, camels, mirage)
      _drawDesertAtmosphereImmersion(canvas, yGround);
      return;
    }

    if (_rainBgImage != null && biome == 'RAIN') {
      final img = _rainBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      // Draw seamlessly repeating tiles
      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }
      _drawRainAtmosphere(canvas, size.x, yGround);
      return;
    }

    if (_forestBgImage != null && biome == 'FOREST') {
      final img = _forestBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      // Draw seamlessly repeating tiles
      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }
      _drawForestAtmosphere(canvas, size.x, yGround);
      return;
    }

    if (_iceBgImage != null && biome == 'ICE') {
      final img = _iceBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }
      _drawIceAtmosphere(canvas, size.x, yGround);
      return;
    }

    if (_volcanoBgImage != null && biome == 'VOLCANO') {
      final img = _volcanoBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }
      _drawVolcanoAtmosphere(canvas, size.x, yGround);
      return;
    }

    if (_cosmosBgImage != null && biome == 'COSMOS') {
      final img = _cosmosBgImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();
      final scale = size.y / imgH;
      final tileW = imgW * scale;
      final pShift = _bgScrollOffset % tileW;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final paint = Paint()..filterQuality = FilterQuality.low;

      double startX = -pShift;
      while (startX < size.x + 50) {
        canvas.drawImageRect(
          img,
          srcRect,
          Rect.fromLTWH(startX, 0, tileW, size.y),
          paint,
        );
        startX += tileW;
      }
      _drawCosmosAtmosphere(canvas, size.x, yGround);
      return;
    }

    final tileW = size.x;
    final pShift = _bgScrollOffset % tileW;
    canvas.save();
    canvas.translate(-pShift, 0);
    _drawBiomeLandscape(canvas, biome, yGround);
    canvas.translate(tileW, 0);
    _drawBiomeLandscape(canvas, biome, yGround);
    canvas.restore();
  }

  void _drawBiomeLandscape(Canvas canvas, String biome, double yGround) {
    if (biome == 'DESERT') {
      _drawDesertArtwork(canvas, size.x, yGround);
    } else if (biome == 'RAIN') {
      _drawRainTempleArtwork(canvas, size.x, yGround);
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
    final sunCenter = Offset(w - 180, 65);
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

  /// 🌧️ Procedural Ancient Rain Temple & Meerkats Vector Artwork Fallback
  void _drawRainTempleArtwork(Canvas canvas, double w, double yGround) {
    // 1. Distant Rainforest Mountains & Misty Hills
    final mountainPath = Path()
      ..moveTo(0, yGround)
      ..lineTo(0, yGround - 110)
      ..quadraticBezierTo(w * 0.15, yGround - 170, w * 0.32, yGround - 130)
      ..quadraticBezierTo(w * 0.50, yGround - 200, w * 0.70, yGround - 140)
      ..quadraticBezierTo(w * 0.85, yGround - 180, w, yGround - 120)
      ..lineTo(w, size.y)
      ..lineTo(0, size.y);

    final mountainShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2E4756).withValues(alpha: 0.85),
        const Color(0xFF1E323D).withValues(alpha: 0.95),
      ],
    ).createShader(Rect.fromLTWH(0, yGround - 200, w, 200));
    canvas.drawPath(mountainPath, Paint()..shader = mountainShader);

    // 2. Grand Ancient Angkor Wat / Mayan Stone Temple (Left)
    _drawAncientTempleStupa(canvas, Offset(w * 0.22, yGround - 30), 1.0);

    // 3. Middle Ancient Stone Temple Ruins & Frog Guardian Statue
    _drawTempleRuinsAndFrog(canvas, Offset(w * 0.46, yGround - 35), 0.85);

    // 4. Elevated Mossy Plateau on Right with Waterfall & Meerkats with Umbrellas
    _drawMeerkatTemplePlateau(canvas, Offset(w * 0.82, yGround - 30), 1.0);

    // 5. Ambient Low Rain Mist & Glowing Cyan Spores
    _drawRainAtmosphere(canvas, w, yGround);
  }

  void _drawAncientTempleStupa(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final stoneDark = const Color(0xFF2D3E3A);
    final stoneMid = const Color(0xFF455A52);
    final stoneLit = const Color(0xFF5C756B);
    final mossGreen = const Color(0xFF4CAF50);

    // Base Temple Structure Block
    final baseRect = const Rect.fromLTWH(-70, -75, 140, 75);
    final baseShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [stoneLit, stoneMid, stoneDark],
    ).createShader(baseRect);
    canvas.drawRect(baseRect, Paint()..shader = baseShader);

    // Tiered Stupa Spire Levels (5 tiers ascending to lotus crest)
    for (int tier = 0; tier < 5; tier++) {
      final tw = 120.0 - tier * 18.0;
      final th = 18.0;
      final ty = -75.0 - (tier + 1) * th;
      final tRect = Rect.fromCenter(center: Offset(0, ty + th / 2), width: tw, height: th);
      canvas.drawRRect(RRect.fromRectAndRadius(tRect, const Radius.circular(3)), Paint()..color = stoneMid);

      // Cornice carved ledge
      canvas.drawRect(Rect.fromLTWH(-tw / 2 - 4, ty + th - 3, tw + 8, 3), Paint()..color = stoneDark);

      // Creeping moss patch
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-tw / 2 + 6, ty + 2, 22, 6), const Radius.circular(2)),
        Paint()..color = mossGreen.withValues(alpha: 0.65),
      );
    }

    // Top Stupa Pinnacle / Finial
    final finialPath = Path()
      ..moveTo(-8, -170)
      ..lineTo(0, -195)
      ..lineTo(8, -170)
      ..close();
    canvas.drawPath(finialPath, Paint()..color = stoneLit);

    // Temple Portal Entrance with Depth Arch
    final portalPath = Path()
      ..moveTo(-18, 0)
      ..lineTo(-18, -40)
      ..quadraticBezierTo(0, -52, 18, -40)
      ..lineTo(18, 0)
      ..close();
    canvas.drawPath(portalPath, Paint()..color = const Color(0xFF141E1C));

    // Cascading Waterfall spilling down temple stone steps
    final waterPaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.85)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    final waterFoam = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (int k = -1; k <= 1; k++) {
      final wx = k * 10.0;
      canvas.drawLine(Offset(wx, -55), Offset(wx, -15), waterPaint);
      canvas.drawLine(Offset(wx, -15), Offset(wx + (k * 4), 10), waterPaint);
      canvas.drawCircle(Offset(wx, 8), 3.5, waterFoam);
    }

    // Forest Pool at base of temple
    final poolRect = const Rect.fromLTWH(-80, 2, 160, 25);
    final poolShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF80DEEA).withValues(alpha: 0.75),
        const Color(0xFF00838F).withValues(alpha: 0.9),
      ],
    ).createShader(poolRect);
    canvas.drawOval(poolRect, Paint()..shader = poolShader);

    canvas.restore();
  }

  void _drawTempleRuinsAndFrog(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final stoneDark = const Color(0xFF263632);
    final stoneMid = const Color(0xFF3F554E);
    final stoneLit = const Color(0xFF557067);

    // Ruined Temple Stupa Tower in background
    final towerPath = Path()
      ..moveTo(-35, 0)
      ..lineTo(-30, -90)
      ..lineTo(-15, -115)
      ..lineTo(15, -115)
      ..lineTo(30, -90)
      ..lineTo(35, 0)
      ..close();
    canvas.drawPath(towerPath, Paint()..color = stoneDark);

    // Ancient Stone Carved Frog Statue on Pedestal Plinth
    final plinthRect = const Rect.fromLTWH(-25, -28, 50, 28);
    canvas.drawRect(plinthRect, Paint()..color = stoneMid);

    // Frog Body & Head
    final frogBody = Path()
      ..moveTo(-20, -28)
      ..cubicTo(-26, -42, -18, -55, 0, -56)
      ..cubicTo(18, -55, 26, -42, 20, -28)
      ..close();
    canvas.drawPath(frogBody, Paint()..color = stoneLit);

    // Frog Eyes on top
    canvas.drawCircle(const Offset(-10, -56), 6.5, Paint()..color = stoneLit);
    canvas.drawCircle(const Offset(10, -56), 6.5, Paint()..color = stoneLit);
    canvas.drawCircle(const Offset(-10, -56), 3.0, Paint()..color = stoneDark);
    canvas.drawCircle(const Offset(10, -56), 3.0, Paint()..color = stoneDark);

    // Sprouting Leaf Crown on Frog Head
    final leafPaint = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawOval(const Rect.fromLTWH(-5, -68, 10, 14), leafPaint);

    // Stone columns with creeping jungle vines
    final colPaint = Paint()..color = stoneMid;
    canvas.drawRect(const Rect.fromLTWH(-65, -70, 14, 70), colPaint);
    canvas.drawRect(const Rect.fromLTWH(50, -70, 14, 70), colPaint);

    final vinePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.0
      ..style = ui.PaintingStyle.stroke;
    for (double vy = -65; vy < 0; vy += 14) {
      canvas.drawLine(Offset(-65, vy), Offset(-51, vy + 8), vinePaint);
      canvas.drawLine(Offset(50, vy), Offset(64, vy + 8), vinePaint);
    }

    canvas.restore();
  }

  void _drawMeerkatTemplePlateau(Canvas canvas, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final stoneWall = const Color(0xFF354841);
    final stoneDark = const Color(0xFF212F2B);

    // Elevated Stone Ledge Wall
    final wallPath = Path()
      ..moveTo(-50, 0)
      ..lineTo(-50, -75)
      ..lineTo(90, -75)
      ..lineTo(90, 0)
      ..close();
    canvas.drawPath(wallPath, Paint()..color = stoneWall);
    canvas.drawLine(const Offset(-50, -35), const Offset(90, -35), Paint()..color = stoneDark..strokeWidth = 1.5);

    // Cascading Waterfalls from wall ledge
    final waterPaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.85)
      ..strokeWidth = 3.5;
    for (int i = 0; i < 3; i++) {
      final wx = -30.0 + i * 25.0;
      canvas.drawLine(Offset(wx, -75), Offset(wx, 0), waterPaint);
      canvas.drawCircle(Offset(wx, 2), 3.0, Paint()..color = Colors.white);
    }

    // 2 Cute Meerkats with Green Umbrellas standing on the ledge!
    _drawMeerkatWithUmbrella(canvas, const Offset(-15, -75), scale: 0.95);
    _drawMeerkatWithUmbrella(canvas, const Offset(18, -75), scale: 1.05);

    // Bioluminescent Cyan Glowing Mushrooms along the ledge
    final mushStalk = Paint()..color = const Color(0xFFB2EBF2)..strokeWidth = 1.6;
    final mushCap = Paint()
      ..color = const Color(0xFF00E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int m = 0; m < 4; m++) {
      final mx = 45.0 + m * 10.0;
      canvas.drawLine(Offset(mx, -75), Offset(mx, -83), mushStalk);
      canvas.drawCircle(Offset(mx, -83), 3.5, mushCap);
    }

    canvas.restore();
  }

  void _drawMeerkatWithUmbrella(Canvas canvas, Offset pos, {required double scale}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final furLight = const Color(0xFFD7CCC8);
    final furDark = const Color(0xFF8D6E63);
    final eyeBlack = const Color(0xFF212121);

    // Meerkat Body (slender standing posture)
    final bodyPath = Path()
      ..moveTo(-4, 0)
      ..lineTo(-5, -22)
      ..quadraticBezierTo(0, -28, 5, -22)
      ..lineTo(4, 0)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = furLight);

    // Belly patch & dark back stripes
    canvas.drawOval(const Rect.fromLTWH(-2.5, -18, 5, 12), Paint()..color = const Color(0xFFEFEBE9));
    for (int s = 0; s < 3; s++) {
      final sy = -16.0 + s * 4.0;
      canvas.drawLine(Offset(1, sy), Offset(4, sy), Paint()..color = furDark..strokeWidth = 1.4);
    }

    // Meerkat Head & Snout
    canvas.drawCircle(const Offset(0, -25), 4.5, Paint()..color = furLight);
    canvas.drawCircle(const Offset(2.5, -25), 1.2, Paint()..color = eyeBlack); // Eye
    canvas.drawCircle(const Offset(4.0, -24), 0.8, Paint()..color = eyeBlack); // Snout nose
    // Dark ear
    canvas.drawCircle(const Offset(-3.5, -27), 1.5, Paint()..color = furDark);

    // Tail for balance
    final tailPath = Path()
      ..moveTo(-3, -2)
      ..quadraticBezierTo(-10, -2, -12, 0);
    canvas.drawPath(tailPath, Paint()..color = furDark..strokeWidth = 1.8..style = ui.PaintingStyle.stroke);

    // Umbrella Handle (held by meerkat)
    final handlePaint = Paint()..color = const Color(0xFF4E342E)..strokeWidth = 1.4;
    canvas.drawLine(const Offset(1, -12), const Offset(1, -38), handlePaint);
    // Umbrella Hook Handle at bottom
    canvas.drawArc(const Rect.fromLTWH(-1, -14, 4, 4), 0, math.pi, false, handlePaint..style = ui.PaintingStyle.stroke);

    // Green Rainforest Leaf Umbrella Canopy
    final umbrellaCanopy = Path()
      ..moveTo(-15, -36)
      ..quadraticBezierTo(1, -48, 17, -36)
      ..lineTo(1, -38)
      ..close();
    final umbrellaGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF81C784),
        Color(0xFF388E3C),
      ],
    ).createShader(const Rect.fromLTWH(-15, -48, 32, 14));
    canvas.drawPath(umbrellaCanopy, Paint()..shader = umbrellaGrad);

    // Umbrella top spike
    canvas.drawLine(const Offset(1, -48), const Offset(1, -52), handlePaint);

    canvas.restore();
  }

  static final _rainSporePaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.45);
  static final _forestSporeYellow = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.55);
  static final _forestSporeGreen = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.45);
  static final _iceFrostPaint = Paint()..color = const Color(0xFFE0F7FA).withValues(alpha: 0.6);
  static final _volcanoEmberPaint = Paint()..color = const Color(0xFFFF9100).withValues(alpha: 0.75);
  static final _volcanoCoreEmber = Paint()..color = const Color(0xFFFFF59D);
  static final _cosmosCyanDust = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.6);
  static final _cosmosVioletDust = Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.5);

  void _drawRainAtmosphere(Canvas canvas, double w, double yGround) {
    // Soft bioluminescent floating spores & mist
    for (int i = 0; i < 15; i++) {
      final sx = ((i * 73 + _time * 15) % w);
      final sy = yGround - 30 - math.sin(_time * 1.5 + i) * 20;
      canvas.drawCircle(Offset(sx, sy), 1.5, _rainSporePaint);
    }
  }

  void _drawForestAtmosphere(Canvas canvas, double w, double yGround) {
    // 1. Soaring Flying Pterodactyls across the prehistoric canopy openings
    for (final pt in _pterodactyls) {
      _drawPterodactyl(canvas, pt);
    }

    // 2. Floating golden pollen and emerald spores drifting through the prehistoric canopy
    for (int i = 0; i < 22; i++) {
      final sx = ((i * 67 + _time * (12 + (i % 5) * 3)) % w);
      final sy = yGround - 40 - math.sin(_time * 1.6 + i * 0.8) * 35 - (i * 12) % (size.y * 0.5);
      final r = 1.2 + (i % 3) * 0.8;
      final paint = (i % 2 == 0) ? _forestSporeYellow : _forestSporeGreen;
      canvas.drawCircle(Offset(sx, sy), r, paint);
    }

    // 3. Easter Egg: Cute Peeking Baby Dino popping up from behind mossy hillock!
    final cycle = (_time * 0.16) % 1.0;
    if (cycle < 0.42) {
      final peekProgress = (cycle < 0.10)
          ? (cycle / 0.10) // Pop up
          : (cycle > 0.32)
              ? (1.0 - (cycle - 0.32) / 0.10) // Duck down
              : 1.0; // Stay looking around
      
      final dinoX = (w * 0.58);
      final dinoY = yGround - 8 - (peekProgress * 26);

      canvas.save();
      canvas.translate(dinoX, dinoY);

      // Baby Dino Body
      final dinoPaint = Paint()..color = const Color(0xFF66BB6A);
      final bellyPaint = Paint()..color = const Color(0xFFC8E6C9);
      final eyeWhite = Paint()..color = Colors.white;
      final eyePupil = Paint()..color = const Color(0xFF1B5E20);
      final blushPaint = Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.65);

      // Head
      canvas.drawCircle(Offset.zero, 12, dinoPaint);
      // Cute Snout
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, -4, 13, 9), const Radius.circular(4.5)), dinoPaint);
      canvas.drawOval(const Rect.fromLTWH(4, 0, 9, 4), bellyPaint);

      // Little Triceratops Crown Frill
      final frillPath = Path()
        ..moveTo(-4, -10)
        ..lineTo(-2, -17)
        ..lineTo(2, -10)
        ..lineTo(6, -17)
        ..lineTo(8, -9);
      canvas.drawPath(frillPath, Paint()..color = const Color(0xFF81C784)..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round);

      // Big glossy happy blinking eye
      final blink = (math.sin(_time * 6) > 0.94);
      if (blink) {
        canvas.drawLine(const Offset(6, -4), const Offset(10, -4), eyePupil..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      } else {
        canvas.drawCircle(const Offset(8, -4), 3.2, eyeWhite);
        canvas.drawCircle(const Offset(8.6, -4), 1.9, eyePupil);
        canvas.drawCircle(const Offset(9.2, -4.8), 0.9, eyeWhite); // Glint
      }

      // Cute Rosy Cheek Blush
      canvas.drawCircle(const Offset(4, 2), 2.4, blushPaint);

      // Happy Smile
      final mouthPath = Path()
        ..moveTo(8, 2)
        ..quadraticBezierTo(10, 4.5, 12, 2);
      canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 1.3..strokeCap = StrokeCap.round);

      // Little waving dino hand
      final waveAng = math.sin(_time * 14) * 0.45;
      canvas.save();
      canvas.translate(9, 7);
      canvas.rotate(waveAng);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 5, 7), const Radius.circular(2.5)), dinoPaint);
      canvas.restore();

      canvas.restore();
    }
  }

  void _drawIceAtmosphere(Canvas canvas, double w, double yGround) {
    // Swirling ice crystalline diamond dust and frosty mist
    for (int i = 0; i < 25; i++) {
      final sx = ((i * 59 + _time * 24) % w);
      final sy = yGround - 30 - math.sin(_time * 2.0 + i) * 35 - (i * 14) % (size.y * 0.6);
      canvas.drawCircle(Offset(sx, sy), 1.2 + (i % 3) * 0.6, _iceFrostPaint);
    }
  }

  void _drawVolcanoAtmosphere(Canvas canvas, double w, double yGround) {
    // Rising fiery magma embers and glowing sparks
    for (int i = 0; i < 28; i++) {
      final ex = ((i * 63 - _time * 28) % w);
      final ey = yGround - 20 - ((_time * 65 + i * 28) % (size.y * 0.75));
      final er = 1.0 + (i % 3) * 0.8;
      canvas.drawCircle(Offset(ex, ey), er, _volcanoEmberPaint);
      canvas.drawCircle(Offset(ex, ey), er * 0.5, _volcanoCoreEmber);
    }
  }

  void _drawCosmosAtmosphere(Canvas canvas, double w, double yGround) {
    // Floating cosmic stardust and starlight energy motes
    for (int i = 0; i < 24; i++) {
      final cx = ((i * 71 + _time * 18) % w);
      final cy = yGround - 50 - math.sin(_time * 1.8 + i) * 40 - (i * 16) % (size.y * 0.65);
      final cr = 1.2 + (i % 3) * 0.7;
      final paint = (i % 2 == 0) ? _cosmosCyanDust : _cosmosVioletDust;
      canvas.drawCircle(Offset(cx, cy), cr, paint);
    }
  }

  void _drawPterodactyl(Canvas canvas, _Pterodactyl pt) {
    canvas.save();
    canvas.translate(pt.x, pt.y);
    canvas.scale(pt.scale, pt.scale);

    final wingFlap = math.sin(pt.wingPhase);
    final wingY = wingFlap * 13.0;

    final bodyPaint = Paint()..color = const Color(0xFF263238).withValues(alpha: 0.80);
    final wingPaint = Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.75);
    final eyePaint = Paint()..color = const Color(0xFFFFD54F);

    // 1. Long Aerodynamic Body & Tail
    final bodyPath = Path()
      ..moveTo(15, -2) // Beak tip
      ..lineTo(7, -4)  // Head top
      ..lineTo(1, -6)  // Crest back
      ..lineTo(4, -1)  // Neck
      ..lineTo(-18, 1) // Tail
      ..lineTo(4, 2)   // Belly
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // 2. Head Crest
    final crestPath = Path()
      ..moveTo(1, -6)
      ..lineTo(-9, -12) // Pointy crest
      ..lineTo(3, -3)
      ..close();
    canvas.drawPath(crestPath, bodyPaint);

    // Amber Glint Eye
    canvas.drawCircle(const Offset(7, -2), 1.0, eyePaint);

    // 3. Flapping Leather Wings
    // Left Wing
    final leftWing = Path()
      ..moveTo(2, -1)
      ..lineTo(-4, -17 + wingY) // Wing tip
      ..lineTo(-13, -3 + wingY * 0.5) // Trailing membrane
      ..lineTo(-4, 1)
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    // Right Wing (Perspective offset)
    final rightWing = Path()
      ..moveTo(3, -1)
      ..lineTo(7, -15 + wingY)
      ..lineTo(-2, -2 + wingY * 0.5)
      ..close();
    canvas.drawPath(rightWing, bodyPaint..color = const Color(0xFF455A64).withValues(alpha: 0.65));

    canvas.restore();
  }
}

class _Pterodactyl {
  double x, y, speed, wingPhase, scale;
  _Pterodactyl({
    required this.x,
    required this.y,
    required this.speed,
    required this.wingPhase,
    required this.scale,
  });
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

class _DesertSandDust {
  double x, y, radius, speedX, waveAmp, phase, alpha;
  Color color;
  _DesertSandDust({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.waveAmp,
    required this.phase,
    required this.alpha,
    required this.color,
  });
}
