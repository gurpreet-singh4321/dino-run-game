import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../utils/vibration_util.dart';

class GroundGap {
  double x;
  final double width;
  bool isRemoved = false;
  bool hasShaken = false;
  double eruptionTimer = 0;
  final List<double> spikeTargetHeights;

  GroundGap(this.x, this.width)
      : spikeTargetHeights = List.generate(6, (i) {
          final rng = math.Random(i * 137 + 29);
          // 6 distinct variable height targets between 110px and 240px!
          return 110.0 + rng.nextDouble() * 130.0;
        });
}

/// Scrolling ground strip with biome-colored texture and lava gaps.
class Ground extends PositionComponent with HasGameReference<DinoGame> {
  static const double groundHeight = 60;
  static const double tileWidth = 640.0;
  static const double tileHeight = 60.0;

  double _scrollOffset = 0;
  final List<GroundGap> _gaps = [];
  double _time = 0;
  
  // Space mode: ground slides down
  double _spaceSlideOffset = 0;

  // Cached ground texture tile strips
  final Map<String, ui.Image> _biomeTileImages = {};
  final Map<String, ui.Picture> _biomeTilePictures = {};
  double _emberTimer = 0.0;
  bool _tilesInitialized = false;

  List<GroundGap> get gaps => _gaps;
  double get groundY => game.size.y - groundHeight + _spaceSlideOffset;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _initBiomeTiles();
  }

  @override
  void onRemove() {
    for (final img in _biomeTileImages.values) {
      img.dispose();
    }
    _biomeTileImages.clear();
    for (final pic in _biomeTilePictures.values) {
      pic.dispose();
    }
    _biomeTilePictures.clear();
    super.onRemove();
  }

  @override
  void update(double dt) {
    dt *= game.globalTimeScale;
    super.update(dt);
    _time += dt;
    
    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      final speed = game.speedManager.currentSpeed;
      _scrollOffset += speed * dt;

      // Update gaps
      for (final gap in _gaps) {
        gap.x -= speed * dt;

        // Trigger 1-sec screen vibration & eruption when gap approaches dino
        final distToPlayer = gap.x - game.player.position.x;
        if (distToPlayer < 400 && !gap.hasShaken) {
          gap.hasShaken = true;
          game.triggerShake(duration: 1.0, intensity: 6.5);
          GameVibration.heavyImpact();
        }
        
        if (gap.hasShaken) {
          gap.eruptionTimer = (gap.eruptionTimer + dt * 1.8).clamp(0.0, 1.0);
        }

        if (gap.x + gap.width < -50) {
          gap.isRemoved = true;
        }
      }
      _gaps.removeWhere((g) => g.isRemoved);

      // Rising embers: emit 2 ember particles per second per active gap onscreen
      _emberTimer += dt;
      if (_emberTimer >= 0.5) {
        _emberTimer = 0.0;
        final groundLine = groundY;
        for (final gap in _gaps) {
          if (gap.x > -gap.width && gap.x < game.size.x) {
            final emberX = gap.x + gap.width * (0.2 + math.Random().nextDouble() * 0.6);
            game.particlePool.emitLavaEmber(Vector2(emberX, groundLine + 14));
          }
        }
      }
    }
    
    // Space mode: ground slides down off screen & rises back on return
    if (game.state == GameState.spaceMode) {
      if (game.spacePhase == SpacePhase.returning) {
        final returnProgress = (1.0 - (game.spacePhaseTimer / DinoGame.spaceReturnDuration)).clamp(0.0, 1.0);
        if (returnProgress >= 0.58) {
          // Path rises smoothly and heroically into place!
          final groundT = ((returnProgress - 0.58) / 0.26).clamp(0.0, 1.0);
          final curvedT = Curves.easeOutBack.transform(groundT);
          _spaceSlideOffset = (1.0 - curvedT).clamp(0.0, 1.0) * (groundHeight + 200);
        } else {
          _spaceSlideOffset = groundHeight + 200;
        }
      } else {
        _spaceSlideOffset += 450 * dt;
        if (_spaceSlideOffset > groundHeight + 200) {
          _spaceSlideOffset = groundHeight + 200;
        }
      }
    } else {
      // Ensure ground is at baseline when playing
      if (_spaceSlideOffset > 0) {
        _spaceSlideOffset -= 450 * dt;
        if (_spaceSlideOffset < 0) _spaceSlideOffset = 0;
      }
    }
  }

  void addGap(double x, double width) {
    _gaps.add(GroundGap(x, width));
  }

  void clearGaps() {
    _gaps.clear();
  }

  bool isOverGap(double playerX, double playerWidth) {
    final playerCenter = playerX + playerWidth / 2;
    // Allow a small leniency of 15px on each side before falling
    for (final gap in _gaps) {
      if (playerCenter > gap.x + 15 && playerCenter < gap.x + gap.width - 15) {
        return true;
      }
    }
    return false;
  }

  bool hitsLavaSprout(double playerX, double playerY, double playerWidth, double playerHeight) {
    // Inset player hit box (middle 50% width, bottom 75% height) so outer sprite margins don't trigger phantom hits
    final playerRect = Rect.fromLTWH(
      playerX + playerWidth * 0.25,
      playerY + playerHeight * 0.2,
      playerWidth * 0.5,
      playerHeight * 0.75,
    );
    final y = groundY;
    
    for (final gap in _gaps) {
      // Dino MUST be horizontally at or over the lava gap
      if (playerRect.right < gap.x || playerRect.left > gap.x + gap.width) {
        continue;
      }

      if (gap.eruptionTimer > 0.1) {
        final sproutOffsets = [0.08, 0.24, 0.40, 0.56, 0.72, 0.88];
        final eruptionScale = gap.eruptionTimer < 0.2 
            ? (gap.eruptionTimer / 0.2) * 0.70
            : 0.70 + math.sin((gap.eruptionTimer - 0.2) / 0.8 * math.pi / 2) * 0.30;

        final eqFrequencies = [8.0, 12.0, 16.0, 14.0, 10.0, 15.0];
        final eqPhases = [0.0, 1.2, 2.5, 0.8, 3.1, 1.9];

        for (int s = 0; s < 6; s++) {
          final cx = gap.x + gap.width * sproutOffsets[s];
          final targetH = gap.spikeTargetHeights[s] * 0.65;
          final eqBounce = 0.40 + 0.60 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
          final H = targetH * eruptionScale * eqBounce;
          
          // Only dangerous when erupting noticeably above ground (H > 22)
          if (H < 22) continue;

          final topY = y + 15 - H;
          final spikeRect = Rect.fromLTWH(cx - 9, topY, 18, H);
          if (playerRect.overlaps(spikeRect)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final y = groundY;
    final topColor = game.biomeManager.interpolatedGroundTop;
    final bottomColor = game.biomeManager.interpolatedGroundBottom;
    // Condition 2: Ensure ground covers the full bottom region on all screen sizes
    final effectiveGroundHeight = math.max(groundHeight, game.size.y - y);

    // Draw ground segments (clipping gaps)
    final groundPath = Path();
    double currentX = 0;
    
    final sortedGaps = List<GroundGap>.from(_gaps)..sort((a, b) => a.x.compareTo(b.x));
    
    for (final gap in sortedGaps) {
      if (gap.x > currentX) {
        groundPath.addRect(Rect.fromLTWH(currentX, y, gap.x - currentX, effectiveGroundHeight));
      }
      currentX = math.max(currentX, gap.x + gap.width);
    }
    if (currentX < w) {
      groundPath.addRect(Rect.fromLTWH(currentX, y, w - currentX, effectiveGroundHeight));
    }

    canvas.save();
    canvas.clipPath(groundPath);

    final currentBiome = game.biomeManager.effectiveBiome.name;
    final detailAlpha = (game.biomeManager.isTransitioning
            ? (game.biomeManager.progress - 0.5).abs() * 2.0
            : 1.0)
        .clamp(0.0, 1.0);

    // Ground fill gradient
    final rect = Rect.fromLTWH(0, y, w, effectiveGroundHeight);
    final Gradient gradient;
    if (currentBiome == 'DESERT') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.16, 0.42, 0.72, 1.0],
        colors: [
          Color(0xFFFFDB94), // Sunlit sand cap
          Color(0xFFD98C51), // Weathered sandstone
          Color(0xFFBE6844), // Terracotta strata
          Color(0xFF934C3C), // Cool rock shadows
          Color(0xFF633A36), // Deep canyon bedrock
        ],
      );
    } else if (currentBiome == 'COSMOS') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.14, 0.42, 0.75, 1.0],
        colors: [
          Color(0xFF2C1A57), // Surface twilight purple-indigo
          Color(0xFF1E113E), // Rich obsidian lunar crust
          Color(0xFF140B2C), // Deep space bedrock
          Color(0xFF0C061D), // Subterranean cosmic rock
          Color(0xFF060310), // Void abyss
        ],
      );
    } else if (currentBiome == 'FOREST') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.12, 0.36, 0.68, 1.0],
        colors: [
          Color(0xFF9CCC65), // Vibrant sunlit lime-emerald moss
          Color(0xFF689F38), // Lush green forest turf
          Color(0xFF3E6B20), // Rich fertile forest humus soil
          Color(0xFF264015), // Dark nutrient-dense peat
          Color(0xFF122008), // Deep ancient root-rock bedrock
        ],
      );
    } else if (currentBiome == 'ICE') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.12, 0.35, 0.68, 1.0],
        colors: [
          Color(0xFFFFFFFF), // Pure crystalline diamond ice & fresh powder snow crest
          Color(0xFFB2EBF2), // Translucent sunlit frost
          Color(0xFF4DD0E1), // Vibrant cyan glacial ice layer
          Color(0xFF00838F), // Deep arctic sapphire permafrost
          Color(0xFF00363A), // Subterranean glacial bedrock abyss
        ],
      );
    } else if (currentBiome == 'VOLCANO') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.14, 0.38, 0.70, 1.0],
        colors: [
          Color(0xFF37474F), // Charred obsidian crust with glowing heat cracks
          Color(0xFF263238), // Smoldering basalt rock layer
          Color(0xFF1E1210), // Dark volcanic stone with embedded embers
          Color(0xFF3E1107), // Subterranean magma-heated bedrock
          Color(0xFF180402), // Deep volcanic magma chamber floor
        ],
      );
    } else {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      );
    }
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Blit cached ground texture tile strips (seamlessly scaled to effectiveGroundHeight)
    _renderGroundTiles(canvas, w, y, effectiveGroundHeight, detailAlpha);

    // Surface top highlight line (drawn flush atop the texture tiles)
    final topHighlightColor = currentBiome == 'DESERT'
        ? const Color(0xFFFFF1A8)
        : (currentBiome == 'COSMOS'
            ? const Color(0xFF4DEEEA)
            : (currentBiome == 'FOREST'
                ? const Color(0xFFCCFF90)
                : (currentBiome == 'ICE'
                    ? const Color(0xFFE0F7FA)
                    : (currentBiome == 'VOLCANO'
                        ? const Color(0xFFFF6D00)
                        : topColor))));
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..color = topHighlightColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.5,
    );

    canvas.clipRect(Rect.fromLTWH(0, y, w, effectiveGroundHeight));

    // Fallback small pebbles (deterministic scrolling positions)
    if (currentBiome != 'DESERT' && currentBiome != 'RAIN' && currentBiome != 'STORM' && currentBiome != 'COSMOS' && currentBiome != 'FOREST' && currentBiome != 'ICE' && currentBiome != 'VOLCANO') {
      final pebblePaint = Paint()..color = bottomColor.withValues(alpha: 0.3);
      for (int i = 0; i < 12; i++) {
        final seedX = (i * 127.0);
        final px = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
        final py = y + 14 + (i * 3.7) % (effectiveGroundHeight - 24);
        canvas.drawCircle(Offset(px, py), 2.0, pebblePaint);
      }
    }

    canvas.restore();

    // Render Lava Gaps & True Bottom-Up Roaring Fire Pit over each gap
    for (final gap in sortedGaps) {
      if (gap.x > w || gap.x + gap.width < -50) continue;
      _renderLavaGeyser(canvas, gap, y, w);
    }
  }

  // --- Cached Tile Blitting & Procedural Generation ---

  void _renderGroundTiles(Canvas canvas, double screenWidth, double groundY, double groundHeight, double detailAlpha) {
    if (detailAlpha < 0.05) return;
    if (_biomeTilePictures.isEmpty && !_tilesInitialized) {
      _initBiomeTiles();
    }

    final currentBiome = game.biomeManager.effectiveBiome.name;

    if (game.biomeManager.isTransitioning) {
      final currBiome = game.biomeManager.current.name;
      final nextBiome = game.biomeManager.next.name;
      final progress = game.biomeManager.progress.clamp(0.0, 1.0);

      // Render old biome fading out
      _drawTileStrip(canvas, currBiome, screenWidth, groundY, groundHeight, detailAlpha * (1.0 - progress));
      // Render new biome fading in
      _drawTileStrip(canvas, nextBiome, screenWidth, groundY, groundHeight, detailAlpha * progress);
    } else {
      _drawTileStrip(canvas, currentBiome, screenWidth, groundY, groundHeight, detailAlpha);
    }
  }

  void _drawTileStrip(Canvas canvas, String biome, double screenWidth, double groundY, double groundHeight, double alpha) {
    if (alpha <= 0.01) return;
    final img = _biomeTileImages[biome] ?? _biomeTileImages['DESERT'];
    final pic = _biomeTilePictures[biome] ?? _biomeTilePictures['DESERT'];

    final double offsetX = (-_scrollOffset) % tileWidth;
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);

    double currentX = offsetX;
    if (currentX > 0) currentX -= tileWidth;

    while (currentX < screenWidth + tileWidth) {
      if (img != null) {
        canvas.drawImageRect(
          img,
          const Rect.fromLTWH(0, 0, tileWidth, tileHeight),
          Rect.fromLTWH(currentX, groundY, tileWidth, groundHeight),
          paint,
        );
      } else if (pic != null) {
        canvas.save();
        canvas.translate(currentX, groundY);
        if (groundHeight != tileHeight) {
          canvas.scale(1.0, groundHeight / tileHeight);
        }
        canvas.drawPicture(pic);
        canvas.restore();
      }
      currentX += tileWidth;
    }
  }

  Future<void> _initBiomeTiles() async {
    if (_tilesInitialized) return;
    _tilesInitialized = true;

    final biomes = ['DESERT', 'RAIN', 'STORM', 'COSMOS', 'FOREST', 'ICE', 'VOLCANO'];

    for (final biome in biomes) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, tileWidth, tileHeight));
      
      // Draw procedural details onto tile canvas
      _drawBiomeTileContent(canvas, biome, tileWidth, tileHeight);

      final picture = recorder.endRecording();
      _biomeTilePictures[biome] = picture;
      try {
        final img = await picture.toImage(tileWidth.toInt(), tileHeight.toInt());
        _biomeTileImages[biome] = img;
      } catch (_) {
        // Fallback gracefully in headless testing
      }
    }
  }

  void _drawBiomeTileContent(Canvas canvas, String biome, double w, double h) {
    final double y = 0.0; // Local tile coordinate y = 0
    final double groundHeight = h;

    if (biome == 'DESERT') {
      // Broad fractured rock faces, cached once with the scrolling ground.
      final rockPaint = Paint();
      for (int row = 0; row < 3; row++) {
        final top = 12.0 + row * 16;
        for (int col = -1; col < 9; col++) {
          final left = col * 80.0 + (row.isOdd ? 40 : 0);
          final face = Path()
            ..moveTo(left + 3, top + 2)
            ..lineTo(left + 66, top)
            ..lineTo(left + 78, top + 6)
            ..lineTo(left + 71, top + 15)
            ..lineTo(left + 14, top + 17)
            ..close();
          rockPaint.color = (col + row).isEven
              ? const Color(0x32FFC18A)
              : const Color(0x28663639);
          canvas.drawPath(face, rockPaint);
        }
      }
      // Small ammonite fossils embedded below the playable surface.
      final fossilPaint = Paint()
        ..color = const Color(0xFFCE9C78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      for (final x in [137.0, 463.0]) {
        final spiral = Path();
        for (int i = 0; i <= 64; i++) {
          final angle = i * math.pi / 16;
          final radius = 0.6 + i * 0.15;
          final point = Offset(x + math.cos(angle) * radius,
              37 + math.sin(angle) * radius);
          if (i == 0) {
            spiral.moveTo(point.dx, point.dy);
          } else {
            spiral.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(spiral, fossilPaint);
      }
      // 🏜️ 1. Multi-layered Wind-blown Sand Dune Surface & Ripples
      final sandHighlightPaint = Paint()
        ..color = const Color(0xFFFFF1A8).withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final sandMidWavePaint = Paint()
        ..color = const Color(0xFFE5A038).withValues(alpha: 0.70)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final sandShadowWavePaint = Paint()
        ..color = const Color(0xFF9E5719).withValues(alpha: 0.65)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final sandDeepStrataPaint = Paint()
        ..color = const Color(0xFF6B3308).withValues(alpha: 0.50)
        ..strokeWidth = 3.0;

      final duneCrestPaint = Paint()
        ..color = const Color(0xFFFFECB3).withValues(alpha: 0.95)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), duneCrestPaint);

      const r1W = 32.0;
      final r1Path = Path();
      for (double rx = 0.0; rx < w; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, sandHighlightPaint..style = PaintingStyle.stroke);

      const r2W = 64.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = 0.0; rx < w; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 24, y + 20, rx + r2W, y + 15);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 26, y + 22, rx + r2W, y + 17);
      }
      canvas.drawPath(r2DarkPath, sandShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, sandMidWavePaint..style = PaintingStyle.stroke);

      const r3W = 80.0;
      final r3Path = Path();
      for (double rx = 0.0; rx < w; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 55, y + 28, rx + r3W, y + 32);
      }
      canvas.drawPath(r3Path, sandDeepStrataPaint..style = PaintingStyle.stroke);

      const r4W = 128.0;
      final r4Path = Path();
      for (double rx = 0.0; rx < w; rx += r4W) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 64, y + 56, rx + r4W, y + 50);
      }
      canvas.drawPath(r4Path, sandDeepStrataPaint..style = PaintingStyle.stroke);

      final quartzSparklePaint = Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.90);
      final goldSandPaint = Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.75);
      final amberSandPaint = Paint()..color = const Color(0xFFFFA000).withValues(alpha: 0.60);
      final darkSandGrainPaint = Paint()..color = const Color(0xFF795548).withValues(alpha: 0.50);

      for (int i = 0; i < 32; i++) {
        final gx = (i * 17.3) % w;
        final gy = y + 3.0 + ((i * 13.7) % (groundHeight - 12.0));
        final grainRadius = 0.8 + ((i % 5) * 0.35);
        final paint = (i % 4 == 0)
            ? quartzSparklePaint
            : (i % 3 == 0)
                ? goldSandPaint
                : (i % 2 == 0)
                    ? amberSandPaint
                    : darkSandGrainPaint;
        canvas.drawCircle(Offset(gx, gy), grainRadius, paint);
      }

      final agateStonePaint = Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.85);
      final agateHighlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
      final amberPebblePaint = Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.75);

      const pebblePeriod = 160.0;
      for (double fx = 0.0; fx < w; fx += pebblePeriod) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), agateStonePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, agateHighlightPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), amberPebblePaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, agateHighlightPaint);
      }
    } else if (biome == 'RAIN' || biome == 'STORM') {
      final stoneBorderPaint = Paint()
        ..color = const Color(0xFF141E1C).withValues(alpha: 0.75)
        ..strokeWidth = 2.0;
      final stoneLitPaint = Paint()
        ..color = const Color(0xFF4D695E).withValues(alpha: 0.55)
        ..strokeWidth = 1.4;
      final mossCrevicePaint = Paint()
        ..color = const Color(0xFF388E3C).withValues(alpha: 0.45);

      const blockWidth = 64.0;
      for (double bx = 0.0; bx < w; bx += blockWidth) {
        canvas.drawLine(Offset(bx, y), Offset(bx, y + groundHeight), stoneBorderPaint);
        canvas.drawLine(Offset(bx + 2, y + 1.5), Offset(bx + blockWidth - 2, y + 1.5), stoneLitPaint);
        canvas.drawCircle(Offset(bx, y + 3), 2.5, mossCrevicePaint);
      }
      canvas.drawLine(Offset(0, y + 22), Offset(w, y + 22), stoneBorderPaint);
      canvas.drawLine(Offset(0, y + 23), Offset(w, y + 23), stoneLitPaint);

      final puddlePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.45);
      const puddlePeriod = 160.0;
      for (double px = 30.0; px < w; px += puddlePeriod) {
        canvas.drawOval(Rect.fromLTWH(px, y - 2, 48, 6), puddlePaint);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(px + 24, y + 1), width: 24.0, height: 4.0),
          Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.2,
        );
      }
      final wetSparklePaint = Paint()..color = const Color(0xFFE0F7FA).withValues(alpha: 0.85);
      for (int i = 0; i < 24; i++) {
        final gx = (i * 21.3) % w;
        final gy = y + 4.0 + ((i * 11.7) % (groundHeight - 12.0));
        canvas.drawCircle(Offset(gx, gy), 1.0, wetSparklePaint);
      }
    } else if (biome == 'COSMOS') {
      final cyanEnergyPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final purpleVeinPaint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: 0.60)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final deepObsidianPaint = Paint()
        ..color = const Color(0xFF4A148C).withValues(alpha: 0.50)
        ..strokeWidth = 2.4;

      final surfaceRimPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.95)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), surfaceRimPaint);

      const eW = 40.0;
      final ePath = Path();
      for (double ex = 0.0; ex < w; ex += eW) {
        ePath.moveTo(ex, y + 8);
        ePath.quadraticBezierTo(ex + 18, y + 14, ex + eW, y + 8);
      }
      canvas.drawPath(ePath, cyanEnergyPaint..style = PaintingStyle.stroke);

      const pW = 80.0;
      final pPath = Path();
      for (double px = 0.0; px < w; px += pW) {
        pPath.moveTo(px, y + 24);
        pPath.cubicTo(px + 20, y + 29, px + 55, y + 19, px + pW, y + 24);
      }
      canvas.drawPath(pPath, purpleVeinPaint..style = PaintingStyle.stroke);

      const bW = 128.0;
      final bPath = Path();
      for (double bx = 0.0; bx < w; bx += bW) {
        bPath.moveTo(bx, y + 42);
        bPath.cubicTo(bx + 30, y + 46, bx + 70, y + 38, bx + bW, y + 42);
      }
      canvas.drawPath(bPath, deepObsidianPaint..style = PaintingStyle.stroke);

      final cosmosWhite = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.90);
      final cosmosCyan = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.85);
      final cosmosMagenta = Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.75);
      final cosmosPurple = Paint()..color = const Color(0xFFCE93D8).withValues(alpha: 0.60);

      for (int i = 0; i < 32; i++) {
        final gx = (i * 19.3) % w;
        final gy = y + 3.0 + ((i * 13.1) % (groundHeight - 12.0));
        final grainRadius = 0.8 + ((i % 5) * 0.35);
        final paint = (i % 4 == 0)
            ? cosmosWhite
            : (i % 3 == 0)
                ? cosmosCyan
                : (i % 2 == 0)
                    ? cosmosMagenta
                    : cosmosPurple;
        canvas.drawCircle(Offset(gx, gy), grainRadius, paint);
      }

      const crystalSpacing = 160.0;
      for (double cx = 0.0; cx < w; cx += crystalSpacing) {
        final cPath = Path()
          ..moveTo(cx + 8, y + 1)
          ..lineTo(cx + 12, y - 9.0)
          ..lineTo(cx + 16, y + 1)
          ..close();
        canvas.drawPath(cPath, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.85));
        canvas.drawCircle(Offset(cx + 12, y - 9.0), 1.2, Paint()..color = Colors.white);
      }
    } else if (biome == 'FOREST') {
      final forestHighlightPaint = Paint()
        ..color = const Color(0xFFDCEDC8).withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final forestMidWavePaint = Paint()
        ..color = const Color(0xFF7CB342).withValues(alpha: 0.70)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final forestShadowWavePaint = Paint()
        ..color = const Color(0xFF33691E).withValues(alpha: 0.65)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final forestDeepStrataPaint = Paint()
        ..color = const Color(0xFF1B3E0B).withValues(alpha: 0.55)
        ..strokeWidth = 3.0;

      final forestCrestPaint = Paint()
        ..color = const Color(0xFFCCFF90).withValues(alpha: 0.95)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), forestCrestPaint);

      const r1W = 32.0;
      final r1Path = Path();
      for (double rx = 0.0; rx < w; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, forestHighlightPaint..style = PaintingStyle.stroke);

      const r2W = 64.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = 0.0; rx < w; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 24, y + 20, rx + r2W, y + 15);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 26, y + 22, rx + r2W, y + 17);
      }
      canvas.drawPath(r2DarkPath, forestShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, forestMidWavePaint..style = PaintingStyle.stroke);

      const r3W = 80.0;
      final r3Path = Path();
      for (double rx = 0.0; rx < w; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 55, y + 28, rx + r3W, y + 32);
      }
      canvas.drawPath(r3Path, forestDeepStrataPaint..style = PaintingStyle.stroke);

      const r4W = 128.0;
      final r4Path = Path();
      for (double rx = 0.0; rx < w; rx += r4W) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 64, y + 56, rx + r4W, y + 50);
      }
      canvas.drawPath(r4Path, forestDeepStrataPaint..style = PaintingStyle.stroke);

      final dewSparklePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95);
      final emeraldGlitterPaint = Paint()..color = const Color(0xFFB2FF59).withValues(alpha: 0.85);
      final goldPollenPaint = Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.75);
      final forestPeatFlecks = Paint()..color = const Color(0xFF558B2F).withValues(alpha: 0.55);

      for (int i = 0; i < 32; i++) {
        final gx = (i * 17.3) % w;
        final gy = y + 3.0 + ((i * 13.7) % (groundHeight - 12.0));
        final grainRadius = 0.8 + ((i % 5) * 0.35);
        final paint = (i % 4 == 0)
            ? dewSparklePaint
            : (i % 3 == 0)
                ? emeraldGlitterPaint
                : (i % 2 == 0)
                    ? goldPollenPaint
                    : forestPeatFlecks;
        canvas.drawCircle(Offset(gx, gy), grainRadius, paint);
      }

      final jadePebblePaint = Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.85);
      final jadeHighlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
      final forestAmberPaint = Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.75);

      const pebblePeriod = 160.0;
      for (double fx = 0.0; fx < w; fx += pebblePeriod) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), jadePebblePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, jadeHighlightPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), forestAmberPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, jadeHighlightPaint);
      }

      const grassSpacing = 32.0;
      int gIdx = 0;
      final grassLight = Paint()..color = const Color(0xFFAEEA00).withValues(alpha: 0.90);
      final grassEmerald = Paint()..color = const Color(0xFF64DD17).withValues(alpha: 0.85);
      final flowerPaint = Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.95);

      for (double gx = 0.0; gx < w; gx += grassSpacing) {
        gIdx++;
        final bladeH = 5.0 + (gIdx % 4) * 2.0;
        final gPath = Path()
          ..moveTo(gx, y + 1.0)
          ..quadraticBezierTo(gx + 2.0, y - bladeH * 0.7, gx + 4.0, y - bladeH)
          ..quadraticBezierTo(gx + 3.0, y - bladeH * 0.3, gx + 2.0, y + 1.0)
          ..close();
        canvas.drawPath(gPath, (gIdx % 2 == 0) ? grassLight : grassEmerald);
        if (gIdx % 4 == 0) {
          canvas.drawCircle(Offset(gx + 4.0, y - bladeH), 1.6, flowerPaint);
          canvas.drawCircle(Offset(gx + 4.0, y - bladeH), 0.7, Paint()..color = Colors.white);
        }
      }
    } else if (biome == 'ICE') {
      final iceHighlightPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.90)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final iceMidWavePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.75)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final iceShadowWavePaint = Paint()
        ..color = const Color(0xFF0097A7).withValues(alpha: 0.65)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final iceDeepStrataPaint = Paint()
        ..color = const Color(0xFF006064).withValues(alpha: 0.55)
        ..strokeWidth = 3.0;

      final snowCrestPaint = Paint()
        ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.95)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), snowCrestPaint);

      const r1W = 32.0;
      final r1Path = Path();
      for (double rx = 0.0; rx < w; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, iceHighlightPaint..style = PaintingStyle.stroke);

      const r2W = 64.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = 0.0; rx < w; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 24, y + 20, rx + r2W, y + 15);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 26, y + 22, rx + r2W, y + 17);
      }
      canvas.drawPath(r2DarkPath, iceShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, iceMidWavePaint..style = PaintingStyle.stroke);

      const r3W = 80.0;
      final r3Path = Path();
      for (double rx = 0.0; rx < w; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 55, y + 28, rx + r3W, y + 32);
      }
      canvas.drawPath(r3Path, iceDeepStrataPaint..style = PaintingStyle.stroke);

      const r4W = 128.0;
      final r4Path = Path();
      for (double rx = 0.0; rx < w; rx += r4W) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 64, y + 56, rx + r4W, y + 50);
      }
      canvas.drawPath(r4Path, iceDeepStrataPaint..style = PaintingStyle.stroke);

      final diamondSparklePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95);
      final cyanFrostPaint = Paint()..color = const Color(0xFFB2EBF2).withValues(alpha: 0.85);
      final sapphireGlitterPaint = Paint()..color = const Color(0xFF4DD0E1).withValues(alpha: 0.75);
      final deepIceFlecks = Paint()..color = const Color(0xFF00ACC1).withValues(alpha: 0.55);

      for (int i = 0; i < 32; i++) {
        final gx = (i * 17.3) % w;
        final gy = y + 3.0 + ((i * 13.7) % (groundHeight - 12.0));
        final grainRadius = 0.8 + ((i % 5) * 0.35);
        final paint = (i % 4 == 0)
            ? diamondSparklePaint
            : (i % 3 == 0)
                ? cyanFrostPaint
                : (i % 2 == 0)
                    ? sapphireGlitterPaint
                    : deepIceFlecks;
        canvas.drawCircle(Offset(gx, gy), grainRadius, paint);
      }

      final sapphireGemPaint = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.85);
      final iceGlintPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
      final arcticOpalPaint = Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.75);

      const pebblePeriod = 160.0;
      for (double fx = 0.0; fx < w; fx += pebblePeriod) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), sapphireGemPaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, iceGlintPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), arcticOpalPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, iceGlintPaint);
      }

      const crystalSpacing = 32.0;
      int cIdx = 0;
      for (double cx = 0.0; cx < w; cx += crystalSpacing) {
        cIdx++;
        final spikeH = 6.0 + (cIdx % 4) * 2.5;
        final cPath = Path()
          ..moveTo(cx + 4.0, y + 1.0)
          ..lineTo(cx + 8.0, y - spikeH)
          ..lineTo(cx + 12.0, y + 1.0)
          ..close();
        canvas.drawPath(cPath, Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.85));
        canvas.drawCircle(Offset(cx + 8.0, y - spikeH), 1.2, Paint()..color = Colors.white);
      }
    } else if (biome == 'VOLCANO') {
      final volcanoHighlightPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final volcanoMidWavePaint = Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.70)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final volcanoShadowWavePaint = Paint()
        ..color = const Color(0xFFD84315).withValues(alpha: 0.65)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final volcanoDeepStrataPaint = Paint()
        ..color = const Color(0xFF3E1107).withValues(alpha: 0.55)
        ..strokeWidth = 3.0;

      final volcanoCrestPaint = Paint()
        ..color = const Color(0xFFFFAB40).withValues(alpha: 0.95)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), volcanoCrestPaint);

      const r1W = 32.0;
      final r1Path = Path();
      for (double rx = 0.0; rx < w; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, volcanoHighlightPaint..style = PaintingStyle.stroke);

      const r2W = 64.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = 0.0; rx < w; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 24, y + 20, rx + r2W, y + 15);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 26, y + 22, rx + r2W, y + 17);
      }
      canvas.drawPath(r2DarkPath, volcanoShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, volcanoMidWavePaint..style = PaintingStyle.stroke);

      const r3W = 80.0;
      final r3Path = Path();
      for (double rx = 0.0; rx < w; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 55, y + 28, rx + r3W, y + 32);
      }
      canvas.drawPath(r3Path, volcanoDeepStrataPaint..style = PaintingStyle.stroke);

      const r4W = 128.0;
      final r4Path = Path();
      for (double rx = 0.0; rx < w; rx += r4W) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 64, y + 56, rx + r4W, y + 50);
      }
      canvas.drawPath(r4Path, volcanoDeepStrataPaint..style = PaintingStyle.stroke);

      final magmaSparklePaint = Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.95);
      final goldHeatPaint = Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.85);
      final orangeEmberPaint = Paint()..color = const Color(0xFFFF9100).withValues(alpha: 0.75);
      final basaltFlecks = Paint()..color = const Color(0xFFDD2C00).withValues(alpha: 0.55);

      for (int i = 0; i < 32; i++) {
        final gx = (i * 17.3) % w;
        final gy = y + 3.0 + ((i * 13.7) % (groundHeight - 12.0));
        final grainRadius = 0.8 + ((i % 5) * 0.35);
        final paint = (i % 4 == 0)
            ? magmaSparklePaint
            : (i % 3 == 0)
                ? goldHeatPaint
                : (i % 2 == 0)
                    ? orangeEmberPaint
                    : basaltFlecks;
        canvas.drawCircle(Offset(gx, gy), grainRadius, paint);
      }

      final fireAgatePaint = Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.85);
      final fireGlintPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);
      final obsidianGemPaint = Paint()..color = const Color(0xFFFFAB00).withValues(alpha: 0.75);

      const pebblePeriod = 160.0;
      for (double fx = 0.0; fx < w; fx += pebblePeriod) {
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), fireAgatePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, fireGlintPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), obsidianGemPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, fireGlintPaint);
      }

      const rockSpacing = 32.0;
      int rIdx = 0;
      final basaltRockPaint = Paint()..color = const Color(0xFF1E1E24);
      final heatPeakPaint = Paint()..color = const Color(0xFFFF9100);

      for (double rx = 0.0; rx < w; rx += rockSpacing) {
        rIdx++;
        final rH = 5.0 + (rIdx % 4) * 2.0;
        final rPath = Path()
          ..moveTo(rx + 2.0, y + 1.0)
          ..lineTo(rx + 6.0, y - rH)
          ..lineTo(rx + 10.0, y + 1.0)
          ..close();

        canvas.drawPath(rPath, basaltRockPaint);
        canvas.drawCircle(Offset(rx + 6.0, y - rH), 1.1, heatPeakPaint);
      }
    }
  }


  void _renderLavaGeyser(Canvas canvas, GroundGap gap, double y, double w) {
    if (gap.x > w || gap.x + gap.width < -50) return;

    _renderLavaPool(canvas, gap, y);

    if (gap.eruptionTimer > 0.05) {
      _renderLavaEruption(canvas, gap, y);
    }
  }

  /// Helper to draw a single organic curling flame tongue with fluid Bezier curves
  void _drawOrganicFlameTongue(
    Canvas canvas, {
    required double baseX,
    required double baseY,
    required double baseWidth,
    required double height,
    required double sway,
    required double curl,
    required List<Color> colors,
    List<double>? stops,
    double opacity = 1.0,
  }) {
    final apexX = baseX + sway;
    final apexY = baseY - height;
    final halfW = baseWidth * 0.5;

    // Organic S-curve flame tongue with fluid curling licking tip
    final flamePath = Path()
      ..moveTo(baseX - halfW, baseY)
      ..cubicTo(
        baseX - halfW * 0.8 + curl * 0.35, baseY - height * 0.38,
        apexX - halfW * 0.35 + curl, apexY + height * 0.28,
        apexX, apexY,
      )
      ..cubicTo(
        apexX + halfW * 0.35 - curl * 0.5, apexY + height * 0.28,
        baseX + halfW * 0.8 - curl * 0.35, baseY - height * 0.38,
        baseX + halfW, baseY,
      )
      ..close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors.map((c) => c.withValues(alpha: c.a * opacity)).toList(),
      stops: stops,
    ).createShader(Rect.fromLTWH(baseX - halfW - 12, apexY, baseWidth + 24, height + 12));

    canvas.drawPath(flamePath, Paint()..shader = shader);
  }

  /// 🌋 True Bottom-Up Roaring Fire Pit 🔥
  void _renderLavaPool(Canvas canvas, GroundGap gap, double y) {
    final leftX = gap.x;
    final rightX = gap.x + gap.width;
    final pitWidth = gap.width;
    final pitHeight = groundHeight + 35.0;

    // 1. Subterranean Volcanic Chasm Abyss (Dark glowing background behind the fire)
    final abyssPath = Path()
      ..moveTo(leftX, y)
      ..lineTo(leftX, y + pitHeight)
      ..lineTo(rightX, y + pitHeight)
      ..lineTo(rightX, y)
      ..close();

    final abyssShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF4A0E06), // Fiery dark upper glow
        Color(0xFF260805), // Charred volcanic shadow
        Color(0xFF0F0403), // Deep abyssal darkness
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(leftX, y, pitWidth, pitHeight));
    canvas.drawPath(abyssPath, Paint()..shader = abyssShader);

    // 1b. Lava Emissive Pulse (0.7 Hz, alpha 0.20 - 0.45 inner glow)
    final pulse = 0.5 + 0.5 * math.sin(_time * 0.7 * 2 * math.pi);
    final emissiveAlpha = (0.20 + 0.25 * pulse).clamp(0.20, 0.45);
    final emissiveRect = Rect.fromLTWH(leftX - 4, y - 2, pitWidth + 8, pitHeight + 4);
    final emissiveShader = RadialGradient(
      center: Alignment.topCenter,
      radius: 0.85,
      colors: [
        Color(0xFFFF6D00).withValues(alpha: emissiveAlpha),
        Color(0xFFDD2C00).withValues(alpha: emissiveAlpha * 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(emissiveRect);
    canvas.drawRect(emissiveRect, Paint()..shader = emissiveShader);

    // 2. Rugged Charred Basalt Cliff Borders (Left & Right rock overhangs)
    final basaltPaint = Paint()..color = const Color(0xFF1E1E24);
    final heatEdgePaint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.90)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left cliff edge
    final leftWall = Path()
      ..moveTo(leftX - 6.0, y - 2.0)
      ..lineTo(leftX, y)
      ..lineTo(leftX + 2.5, y + 14.0)
      ..lineTo(leftX - 1.5, y + 30.0)
      ..lineTo(leftX + 3.0, y + pitHeight)
      ..lineTo(leftX - 10.0, y + pitHeight)
      ..close();
    canvas.drawPath(leftWall, basaltPaint);

    final leftRim = Path()
      ..moveTo(leftX, y)
      ..lineTo(leftX + 2.5, y + 14.0)
      ..lineTo(leftX - 1.5, y + 30.0)
      ..lineTo(leftX + 3.0, y + pitHeight);
    canvas.drawPath(leftRim, heatEdgePaint);

    // Right cliff edge
    final rightWall = Path()
      ..moveTo(rightX + 6.0, y - 2.0)
      ..lineTo(rightX, y)
      ..lineTo(rightX - 2.5, y + 15.0)
      ..lineTo(rightX + 1.5, y + 32.0)
      ..lineTo(rightX - 3.0, y + pitHeight)
      ..lineTo(rightX + 10.0, y + pitHeight)
      ..close();
    canvas.drawPath(rightWall, basaltPaint);

    final rightRim = Path()
      ..moveTo(rightX, y)
      ..lineTo(rightX - 2.5, y + 15.0)
      ..lineTo(rightX + 1.5, y + 32.0)
      ..lineTo(rightX - 3.0, y + pitHeight);
    canvas.drawPath(rightRim, heatEdgePaint);

    // 3. Deep Molten Magma Reservoir Bed (Viscous incandescent basin at the bottom with Heat Shimmer)
    final magmaBedY = y + 18.0;
    final magmaBedHeight = pitHeight - 18.0;
    final magmaBedPath = Path()..moveTo(leftX, y + pitHeight);
    magmaBedPath.lineTo(leftX, magmaBedY);

    for (double px = leftX; px <= rightX; px += 4.0) {
      final normX = (px - leftX) / pitWidth;
      final wave = math.sin(_time * 4.5 + normX * math.pi * 3) * 2.0;
      final shimmer = math.sin(_time * 6.0 + px * 0.12) * 1.5;
      magmaBedPath.lineTo(px, magmaBedY + wave + shimmer);
    }
    magmaBedPath.lineTo(rightX, y + pitHeight);
    magmaBedPath.close();

    final magmaShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF9C4), // White-hot molten surface
        Color(0xFFFFD600), // Intense solar gold
        Color(0xFFFF6D00), // Blazing orange magma
        Color(0xFFC62828), // Deep volcanic crimson
        Color(0xFF1B0000), // Deep basalt chamber base
      ],
      stops: [0.0, 0.14, 0.42, 0.76, 1.0],
    ).createShader(Rect.fromLTWH(leftX, magmaBedY, pitWidth, magmaBedHeight));
    canvas.drawPath(magmaBedPath, Paint()..shader = magmaShader);

    // 4. 🔥 MULTI-LAYERED BOTTOM-UP ROARING FLAME TONGUES 🔥
    final flameCount = math.max(8, (pitWidth / 11).floor());
    final flameBaseY = magmaBedY + 4.0;

    // PASS 1: Billowing Deep Crimson & Fiery Orange Outer Flames (Wide body)
    for (int i = 0; i <= flameCount; i++) {
      final norm = i / flameCount;
      final bx = leftX + pitWidth * norm;
      final phase = _time * 8.5 + i * 1.7;
      final fH = 24.0 + math.sin(phase).abs() * 26.0 + math.cos(phase * 0.7) * 8.0;
      final sway = math.sin(_time * 7.0 + i * 1.9) * 6.0;
      final curl = math.cos(_time * 6.0 + i * 1.5) * 4.0;
      final baseW = 16.0 + (i % 3) * 4.0;

      _drawOrganicFlameTongue(
        canvas,
        baseX: bx,
        baseY: flameBaseY,
        baseWidth: baseW,
        height: fH,
        sway: sway,
        curl: curl,
        colors: const [
          Color(0xFFFFF176), // Bright apex tip
          Color(0xFFFF9100), // Vibrant fiery orange
          Color(0xFFFF3D00), // Blazing red-orange
          Color(0xFFD50000), // Crimson flame base
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
        opacity: 0.92,
      );
    }

    // PASS 2: Solar Gold & Fiery Amber Mid Flames (Dynamic dancing tongues)
    for (int i = 0; i <= flameCount; i++) {
      final norm = (i + 0.5) / (flameCount + 1);
      final bx = leftX + pitWidth * norm;
      final phase = _time * 11.0 + i * 2.1;
      final fH = 18.0 + math.sin(phase).abs() * 28.0 + math.cos(phase * 0.9) * 6.0;
      final sway = math.sin(_time * 9.5 + i * 2.3) * 5.0;
      final curl = math.cos(_time * 8.0 + i * 1.8) * 3.5;
      final baseW = 12.0 + (i % 2) * 4.0;

      _drawOrganicFlameTongue(
        canvas,
        baseX: bx,
        baseY: flameBaseY,
        baseWidth: baseW,
        height: fH,
        sway: sway,
        curl: curl,
        colors: const [
          Color(0xFFFFFFFF), // Pure white apex
          Color(0xFFFFEA00), // Intense solar gold
          Color(0xFFFF9800), // Fiery amber
          Color(0xFFFF5722), // Red-orange root
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
        opacity: 0.95,
      );
    }

    // PASS 3: White-Hot Incandescent Fire Core Tendrils
    for (int i = 0; i < flameCount; i += 2) {
      final norm = (i + 0.5) / flameCount;
      final bx = leftX + pitWidth * norm;
      final phase = _time * 12.5 + i * 2.4;
      final fH = 12.0 + math.sin(phase).abs() * 16.0;
      final sway = math.sin(_time * 10.0 + i * 2.5) * 3.0;
      final curl = math.cos(_time * 9.0 + i * 2.0) * 2.0;

      _drawOrganicFlameTongue(
        canvas,
        baseX: bx,
        baseY: flameBaseY,
        baseWidth: 7.0,
        height: fH,
        sway: sway,
        curl: curl,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFFDE7),
          Color(0xFFFFD54F),
        ],
        stops: const [0.0, 0.40, 1.0],
        opacity: 0.95,
      );
    }

    // 5. Popping Lava Bubbles at Magma Bed
    final bubbleOffsets = [0.18, 0.38, 0.62, 0.82];
    final yellowPaint = Paint()..color = const Color(0xFFFFEA00);
    final orangePaint = Paint()..color = const Color(0xFFFF6D00);
    final whitePaint = Paint()..color = Colors.white;

    for (int b = 0; b < bubbleOffsets.length; b++) {
      final bx = leftX + pitWidth * bubbleOffsets[b];
      final cycle = (_time * (2.4 + b * 0.5) + b * 0.9) % 1.6;
      final progress = (cycle / 1.6).clamp(0.0, 1.0);
      final maxR = 3.4 + (b % 2) * 1.5;
      final curR = maxR * math.sin(progress * math.pi);
      final bubbleY = magmaBedY - curR * 0.4;

      if (progress < 0.85) {
        canvas.drawCircle(Offset(bx, bubbleY), curR, yellowPaint);
        canvas.drawCircle(Offset(bx - curR * 0.25, bubbleY - curR * 0.25), curR * 0.35, whitePaint);
      } else {
        final popProg = (progress - 0.85) / 0.15;
        for (int p = 0; p < 4; p++) {
          final dir = (p % 2 == 0) ? 1.0 : -1.0;
          final spX = bx + dir * (3 + p * 2.5) * popProg;
          final spY = magmaBedY - (5 + p * 6) * popProg;
          final spR = (2.0 * (1.0 - popProg)).clamp(0.5, 2.0);
          final pPaint = (p % 2 == 0) ? whitePaint : orangePaint;
          canvas.drawCircle(Offset(spX, spY), spR, pPaint);
        }
      }
    }

    // 6. Floating Swirling Fire Embers, Cinders & Sparks 🔥
    final sparkYellow = Paint()..color = const Color(0xFFFFF59D);
    final sparkOrange = Paint()..color = const Color(0xFFFF9100);
    final sparkRed = Paint()..color = const Color(0xFFFF3D00);

    for (int e = 0; e < 12; e++) {
      final normX = ((e * 0.11 + _time * 0.12) % 1.0);
      final ex = leftX + pitWidth * normX + math.sin(_time * 4.0 + e) * 4.0;
      final ey = y + 10.0 - ((_time * 50.0 + e * 18.0) % 75.0);
      final dist = (y + 10.0 - ey).clamp(0.0, 75.0);
      final alpha = (1.0 - dist / 75.0).clamp(0.0, 0.95);
      final radius = 1.2 + (e % 3) * 0.7;
      final pPaint = (e % 3 == 0) ? sparkYellow : (e % 2 == 0) ? sparkOrange : sparkRed;

      canvas.drawCircle(
        Offset(ex, ey),
        radius,
        Paint()..color = pPaint.color.withValues(alpha: alpha),
      );
    }
  }

  /// 🌋 Roaring Eruption Inferno Fire Pillars & Flame Tornadoes 🔥
  void _renderLavaEruption(Canvas canvas, GroundGap gap, double y) {
    final eruptionScale = gap.eruptionTimer < 0.2
        ? (gap.eruptionTimer / 0.2) * 0.70
        : 0.70 + math.sin((gap.eruptionTimer - 0.2) / 0.8 * math.pi / 2) * 0.30;

    final pitLeft = gap.x;
    final pitWidth = gap.width;

    final sproutOffsets = [0.15, 0.38, 0.62, 0.85];
    final eqFrequencies = [9.0, 14.0, 12.0, 15.0];
    final eqPhases = [0.0, 1.4, 2.8, 0.9];

    // 1. Towering Roaring Flame Pillars
    for (int s = 0; s < sproutOffsets.length; s++) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s % gap.spikeTargetHeights.length] * 0.85;
      final eqBounce = 0.50 + 0.50 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = (targetH * eruptionScale * eqBounce).clamp(12.0, 145.0);
      final pillarBaseY = y + 18.0;
      final pillarW = 16.0 + (H / 145.0) * 12.0;

      final sway = math.sin(_time * 11.0 + s * 1.8) * 7.0;
      final curl = math.cos(_time * 9.0 + s * 2.2) * 5.0;

      // Outer Inferno Pillar Flame (Red/Orange)
      _drawOrganicFlameTongue(
        canvas,
        baseX: cx,
        baseY: pillarBaseY,
        baseWidth: pillarW,
        height: H,
        sway: sway,
        curl: curl,
        colors: const [
          Color(0xFFFFF9C4), // White-hot liquid apex tip
          Color(0xFFFFD600), // Intense solar gold
          Color(0xFFFF6D00), // Blazing volcanic orange
          Color(0xFFDD2C00), // Deep magma crimson
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
        opacity: 0.95,
      );

      // Mid Flame Pillar Tongue (Solar Gold)
      _drawOrganicFlameTongue(
        canvas,
        baseX: cx,
        baseY: pillarBaseY,
        baseWidth: pillarW * 0.65,
        height: H * 0.88,
        sway: sway * 0.85,
        curl: curl * 0.85,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFF59D),
          Color(0xFFFFAB00),
          Color(0xFFFF3D00),
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
        opacity: 0.95,
      );

      // Inner White-Hot Magma Core Tongue
      _drawOrganicFlameTongue(
        canvas,
        baseX: cx,
        baseY: pillarBaseY,
        baseWidth: pillarW * 0.35,
        height: H * 0.72,
        sway: sway * 0.6,
        curl: curl * 0.6,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFFDE7),
          Color(0xFFFFD54F),
        ],
        stops: const [0.0, 0.40, 1.0],
        opacity: 0.95,
      );
    }

    // 2. Leaping Molten Magma Droplets & Fire Cinder Showers
    final sparkYellow = Paint()..color = const Color(0xFFFFFF8D);
    final sparkOrange = Paint()..color = const Color(0xFFFF9800);
    final sparkRed = Paint()..color = const Color(0xFFFF3D00);

    for (int s = 0; s < sproutOffsets.length; s++) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s % gap.spikeTargetHeights.length] * 0.85;
      final eqBounce = 0.50 + 0.50 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 18.0 - H;

      final rng = math.Random((cx * 77 + s * 31).toInt());
      for (int p = 0; p < 5; p++) {
        final phase = (_time * 4.0 + p * 0.35 + s) % 1.5;
        final progress = phase / 1.5;
        final spreadX = (rng.nextDouble() - 0.5) * 40.0 * progress;
        final sparkY = topY - (24.0 * math.sin(progress * math.pi)) + progress * progress * 22.0;
        final sparkX = cx + spreadX;
        final r = (2.6 * (1.0 - progress)).clamp(0.6, 2.6);
        final pPaint = (p % 3 == 0) ? sparkYellow : (p % 2 == 0) ? sparkOrange : sparkRed;

        canvas.drawCircle(Offset(sparkX, sparkY), r, pPaint);
      }
    }

    // 3. Billowing Rising Smoke Plumes from Spouts
    final smokePaint = Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.28);

    for (int s = 0; s < sproutOffsets.length; s += 2) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s % gap.spikeTargetHeights.length] * 0.85;
      final eqBounce = 0.50 + 0.50 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 18.0 - H;

      final sCycle = (_time * 1.8 + s * 0.4) % 1.4;
      final sProg = sCycle / 1.4;
      final sX = cx + math.sin(_time * 3.0 + s) * (4.0 + sProg * 12.0);
      final sY = topY - 10 - sProg * 35.0;
      final sR = 5.0 + sProg * 9.0;
      canvas.drawCircle(Offset(sX, sY), sR, smokePaint);
    }
  }
}
