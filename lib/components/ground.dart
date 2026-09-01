import 'dart:math' as math;
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

  double _scrollOffset = 0;
  final List<GroundGap> _gaps = [];
  double _time = 0;
  
  // Space mode: ground slides down
  double _spaceSlideOffset = 0;

  List<GroundGap> get gaps => _gaps;
  double get groundY => game.size.y - groundHeight + _spaceSlideOffset;

  @override
  void update(double dt) {
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

    // Draw ground segments (clipping gaps)
    final groundPath = Path();
    double currentX = 0;
    
    final sortedGaps = List<GroundGap>.from(_gaps)..sort((a, b) => a.x.compareTo(b.x));
    
    for (final gap in sortedGaps) {
      if (gap.x > currentX) {
        groundPath.addRect(Rect.fromLTWH(currentX, y, gap.x - currentX, groundHeight));
      }
      currentX = math.max(currentX, gap.x + gap.width);
    }
    if (currentX < w) {
      groundPath.addRect(Rect.fromLTWH(currentX, y, w - currentX, groundHeight));
    }

    canvas.save();
    canvas.clipPath(groundPath);

    final currentBiome = game.biomeManager.effectiveBiome.name;
    final detailAlpha = (game.biomeManager.isTransitioning
            ? (game.biomeManager.progress - 0.5).abs() * 2.0
            : 1.0)
        .clamp(0.0, 1.0);

    // Ground fill gradient
    final rect = Rect.fromLTWH(0, y, w, groundHeight);
    final Gradient gradient;
    if (currentBiome == 'DESERT') {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.16, 0.42, 0.72, 1.0],
        colors: [
          Color(0xFFFBE49B), // Sunlit golden sand crest sheen
          Color(0xFFECAE52), // Warm vibrant wind-swept sand
          Color(0xFFCF852B), // Amber dune shadow layer
          Color(0xFFA3571A), // Ancient desert sandstone
          Color(0xFF6A330C), // Deep subterranean desert rock
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

    // Surface top highlight line
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

    // Biome-specific ground surface details
    if (currentBiome == 'DESERT' && detailAlpha > 0.05) {
      // 🏜️ 1. Multi-layered Wind-blown Sand Dune Surface & Ripples (Aeolian Ripple Marks)
      final sandHighlightPaint = Paint()
        ..color = const Color(0xFFFFF1A8).withValues(alpha: 0.85 * detailAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final sandMidWavePaint = Paint()
        ..color = const Color(0xFFE5A038).withValues(alpha: 0.70 * detailAlpha)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final sandShadowWavePaint = Paint()
        ..color = const Color(0xFF9E5719).withValues(alpha: 0.65 * detailAlpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final sandDeepStrataPaint = Paint()
        ..color = const Color(0xFF6B3308).withValues(alpha: 0.50 * detailAlpha)
        ..strokeWidth = 3.0;

      // Soft Top Golden Dune Crest Rim
      final duneCrestPaint = Paint()
        ..color = const Color(0xFFFFECB3).withValues(alpha: 0.95 * detailAlpha)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), duneCrestPaint);

      // Layer 1: Fine Upper Sand Ripples (Wavelength ~28px)
      const r1W = 28.0;
      final r1Path = Path();
      for (double rx = -(_scrollOffset % r1W) - r1W; rx < w + r1W; rx += r1W) {
        final startX = rx;
        final midX = rx + r1W * 0.5;
        final endX = rx + r1W;
        r1Path.moveTo(startX, y + 5);
        r1Path.quadraticBezierTo(midX, y + 8, endX, y + 5);
      }
      canvas.drawPath(r1Path, sandHighlightPaint..style = PaintingStyle.stroke);

      // Layer 2: Mid Dune Sand Contours (Wavelength ~54px)
      const r2W = 54.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = -((_scrollOffset * 1.0) % r2W) - r2W; rx < w + r2W; rx += r2W) {
        // Dune ripple crest
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 22, y + 20, rx + 44, y + 14);
        // Dune ripple lee shadow
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 24, y + 22, rx + 46, y + 16);
      }
      canvas.drawPath(r2DarkPath, sandShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, sandMidWavePaint..style = PaintingStyle.stroke);

      // Layer 3: Lower Dune Sedimentary Strata Wavebands (Wavelength ~90px)
      const r3W = 90.0;
      final r3Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % r3W) - r3W; rx < w + r3W; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 65, y + 28, rx + r3W, y + 33);
      }
      canvas.drawPath(r3Path, sandDeepStrataPaint..style = PaintingStyle.stroke);

      // Layer 4: Deep Bedrock Desert Sandstone Layer
      final r4Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % 130.0) - 130.0; rx < w + 130.0; rx += 130.0) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 65, y + 56, rx + 130, y + 49);
      }
      canvas.drawPath(r4Path, sandDeepStrataPaint..style = PaintingStyle.stroke);

      // ✨ 2. Shimmering Sand Grains & Golden Quartz Flecks
      final quartzSparklePaint = Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.90 * detailAlpha);
      final goldSandPaint = Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.75 * detailAlpha);
      final amberSandPaint = Paint()..color = const Color(0xFFFFA000).withValues(alpha: 0.60 * detailAlpha);
      final darkSandGrainPaint = Paint()..color = const Color(0xFF795548).withValues(alpha: 0.50 * detailAlpha);

      for (int i = 0; i < 32; i++) {
        final seedX = i * 59.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
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

      // 🏜️ 3. Sun-polished Desert Jasper & Agate Pebbles in Sand (Deterministic, smooth)
      final agateStonePaint = Paint()..color = const Color(0xFFD7CCC8).withValues(alpha: 0.85 * detailAlpha);
      final agateHighlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.90 * detailAlpha);
      final amberPebblePaint = Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.75 * detailAlpha);

      const pebblePeriod = 180.0;
      for (double fx = -(_scrollOffset % pebblePeriod) + 40; fx < w + pebblePeriod; fx += pebblePeriod) {
        // Smooth desert agate pebble
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), agateStonePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, agateHighlightPaint);

        // Golden amber fleck
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), amberPebblePaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, agateHighlightPaint);
      }
    } else if ((currentBiome == 'RAIN' || currentBiome == 'STORM') && detailAlpha > 0.05) {
      // 1. Ancient Mossy Stone Block Slabs (Flagstone pavement - strictly scrolling left)
      final stoneBorderPaint = Paint()
        ..color = const Color(0xFF141E1C).withValues(alpha: 0.75 * detailAlpha)
        ..strokeWidth = 2.0;
      final stoneLitPaint = Paint()
        ..color = const Color(0xFF4D695E).withValues(alpha: 0.55 * detailAlpha)
        ..strokeWidth = 1.4;
      final mossCrevicePaint = Paint()
        ..color = const Color(0xFF388E3C).withValues(alpha: 0.45 * detailAlpha);

      const blockWidth = 52.0;
      for (double bx = -(_scrollOffset % blockWidth); bx < w + blockWidth; bx += blockWidth) {
        // Vertical stone slab joint
        canvas.drawLine(Offset(bx, y), Offset(bx, y + groundHeight), stoneBorderPaint);
        // Top edge stone bevel highlight
        canvas.drawLine(Offset(bx + 2, y + 1.5), Offset(bx + blockWidth - 2, y + 1.5), stoneLitPaint);
        // Moss tufts in the stone crevices
        canvas.drawCircle(Offset(bx, y + 3), 2.5, mossCrevicePaint);
      }

      // Horizontal stone course split line
      canvas.drawLine(Offset(0, y + 22), Offset(w, y + 22), stoneBorderPaint);
      canvas.drawLine(Offset(0, y + 23), Offset(w, y + 23), stoneLitPaint);

      // 2. Reflective Water Puddles with Concentric Rain Ripple Rings (strictly scrolling left)
      final puddlePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.45 * detailAlpha);
      final ripplePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.65 * detailAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      const puddlePeriod = 160.0;
      int puddleIndex = 0;
      for (double px = -(_scrollOffset % puddlePeriod) + 30; px < w + puddlePeriod; px += puddlePeriod) {
        puddleIndex++;
        // Puddle body
        canvas.drawOval(Rect.fromLTWH(px, y - 2, 48, 6), puddlePaint);
        
        // Expanding rain ripple rings
        final ripplePhase = (_time * 3.0 + (puddleIndex * 0.35)) % 1.0;
        final rWidth = 12.0 + ripplePhase * 28.0;
        final rHeight = 2.0 + ripplePhase * 4.5;
        final rAlpha = (1.0 - ripplePhase) * 0.7 * detailAlpha;
        
        canvas.drawOval(
          Rect.fromCenter(center: Offset(px + 24, y + 1), width: rWidth, height: rHeight),
          ripplePaint..color = Colors.white.withValues(alpha: rAlpha),
        );

        // Little raindrop splash droplets
        if (ripplePhase < 0.35) {
          final sH = (1.0 - (ripplePhase / 0.35)) * 5.0;
          canvas.drawCircle(Offset(px + 24 - 3, y - sH), 1.0, puddlePaint);
          canvas.drawCircle(Offset(px + 24 + 3, y - sH), 1.0, puddlePaint);
        }
      }

      // ✨ Shimmering wet stone flecks
      final wetSparklePaint = Paint()..color = const Color(0xFFE0F7FA).withValues(alpha: 0.85 * detailAlpha);
      for (int i = 0; i < 24; i++) {
        final seedX = i * 67.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
        final gy = y + 4.0 + ((i * 11.7) % (groundHeight - 12.0));
        canvas.drawCircle(Offset(gx, gy), 1.0, wetSparklePaint);
      }
    } else if (currentBiome == 'COSMOS' && detailAlpha > 0.05) {
      // 🌌 1. Bioluminescent Neon Cyan & Magenta Energy Currents
      final cyanEnergyPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75 * detailAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final purpleVeinPaint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: 0.60 * detailAlpha)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final deepObsidianPaint = Paint()
        ..color = const Color(0xFF4A148C).withValues(alpha: 0.50 * detailAlpha)
        ..strokeWidth = 2.4;

      // Glowing pulsating surface energy rim
      final pulse = 0.85 + math.sin(_time * 3.5) * 0.15;
      final surfaceRimPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.95 * pulse * detailAlpha)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), surfaceRimPaint);

      // Layer 1: Subterranean Cyan Energy Wave Currents (Wavelength ~45px)
      const eW = 45.0;
      final ePath = Path();
      for (double ex = -(_scrollOffset % eW) - eW; ex < w + eW; ex += eW) {
        ePath.moveTo(ex, y + 8);
        ePath.quadraticBezierTo(ex + 18, y + 14, ex + 36, y + 9);
      }
      canvas.drawPath(ePath, cyanEnergyPaint..style = PaintingStyle.stroke);

      // Layer 2: Deeper Purple/Magenta Cosmic Energy Strata (Wavelength ~75px)
      const pW = 75.0;
      final pPath = Path();
      for (double px = -((_scrollOffset * 1.0) % pW) - pW; px < w + pW; px += pW) {
        pPath.moveTo(px, y + 24);
        pPath.cubicTo(px + 20, y + 29, px + 50, y + 19, px + pW, y + 25);
      }
      canvas.drawPath(pPath, purpleVeinPaint..style = PaintingStyle.stroke);

      // Layer 3: Deep Obsidian Bedrock Faults (Wavelength ~110px)
      const bW = 110.0;
      final bPath = Path();
      for (double bx = -((_scrollOffset * 1.0) % bW) - bW; bx < w + bW; bx += bW) {
        bPath.moveTo(bx, y + 42);
        bPath.cubicTo(bx + 30, y + 46, bx + 70, y + 38, bx + bW, y + 43);
      }
      canvas.drawPath(bPath, deepObsidianPaint..style = PaintingStyle.stroke);

      // ✨ Glistening Stardust & Ion Quartz Flecks
      final cosmosWhite = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.90 * detailAlpha);
      final cosmosCyan = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.85 * detailAlpha);
      final cosmosMagenta = Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.75 * detailAlpha);
      final cosmosPurple = Paint()..color = const Color(0xFFCE93D8).withValues(alpha: 0.60 * detailAlpha);

      for (int i = 0; i < 32; i++) {
        final seedX = i * 61.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
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

      // 🌌 2. Embedded Bioluminescent Cyan Crystal Shards
      const crystalSpacing = 135.0;
      int crystalIdx = 0;
      for (double cx = -(_scrollOffset % crystalSpacing); cx < w + crystalSpacing; cx += crystalSpacing) {
        crystalIdx++;
        final shardH = 7.0 + (crystalIdx % 4) * 2.5;
        final cPath = Path()
          ..moveTo(cx + 8, y + 1)
          ..lineTo(cx + 12, y - shardH)
          ..lineTo(cx + 16, y + 1)
          ..close();

        final crystalShader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0F7FA).withValues(alpha: detailAlpha),
            const Color(0xFF00E5FF).withValues(alpha: 0.85 * detailAlpha),
            const Color(0xFF006064).withValues(alpha: 0.70 * detailAlpha),
          ],
        ).createShader(Rect.fromLTWH(cx + 8, y - shardH, 8, shardH + 1));

        canvas.drawPath(cPath, Paint()..shader = crystalShader);
        canvas.drawCircle(
          Offset(cx + 12, y - shardH),
          1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.9 * detailAlpha),
        );
      }
    } else if (currentBiome == 'FOREST' && detailAlpha > 0.05) {
      // 🌲 1. Multi-layered Forest Humus Strata & Soil Wave Contours (Matching Desert Level Depth)
      final forestHighlightPaint = Paint()
        ..color = const Color(0xFFDCEDC8).withValues(alpha: 0.85 * detailAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final forestMidWavePaint = Paint()
        ..color = const Color(0xFF7CB342).withValues(alpha: 0.70 * detailAlpha)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final forestShadowWavePaint = Paint()
        ..color = const Color(0xFF33691E).withValues(alpha: 0.65 * detailAlpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final forestDeepStrataPaint = Paint()
        ..color = const Color(0xFF1B3E0B).withValues(alpha: 0.55 * detailAlpha)
        ..strokeWidth = 3.0;

      // Soft Top Emerald Forest Turf Crest Rim
      final forestCrestPaint = Paint()
        ..color = const Color(0xFFCCFF90).withValues(alpha: 0.95 * detailAlpha)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), forestCrestPaint);

      // Layer 1: Fine Upper Moss Waves (Wavelength ~28px)
      const r1W = 28.0;
      final r1Path = Path();
      for (double rx = -(_scrollOffset % r1W) - r1W; rx < w + r1W; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, forestHighlightPaint..style = PaintingStyle.stroke);

      // Layer 2: Mid Loam Soil Contours (Wavelength ~54px)
      const r2W = 54.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = -((_scrollOffset * 1.0) % r2W) - r2W; rx < w + r2W; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 22, y + 20, rx + 44, y + 14);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 24, y + 22, rx + 46, y + 16);
      }
      canvas.drawPath(r2DarkPath, forestShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, forestMidWavePaint..style = PaintingStyle.stroke);

      // Layer 3: Lower Nutrient Peat Strata Wavebands (Wavelength ~90px)
      const r3W = 90.0;
      final r3Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % r3W) - r3W; rx < w + r3W; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 65, y + 28, rx + r3W, y + 33);
      }
      canvas.drawPath(r3Path, forestDeepStrataPaint..style = PaintingStyle.stroke);

      // Layer 4: Deep Ancient Root-Rock Bedrock
      final r4Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % 130.0) - 130.0; rx < w + 130.0; rx += 130.0) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 65, y + 56, rx + 130, y + 49);
      }
      canvas.drawPath(r4Path, forestDeepStrataPaint..style = PaintingStyle.stroke);

      // ✨ 2. Shimmering Morning Dewdrops & Emerald Quartz Glistening Flecks (Just like Desert!)
      final dewSparklePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * detailAlpha);
      final emeraldGlitterPaint = Paint()..color = const Color(0xFFB2FF59).withValues(alpha: 0.85 * detailAlpha);
      final goldPollenPaint = Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.75 * detailAlpha);
      final forestPeatFlecks = Paint()..color = const Color(0xFF558B2F).withValues(alpha: 0.55 * detailAlpha);

      for (int i = 0; i < 32; i++) {
        final seedX = i * 59.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
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

      // 🌲 3. Polished Forest Jade, River Pebbles & Amber Fossils
      final jadePebblePaint = Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.85 * detailAlpha);
      final jadeHighlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.90 * detailAlpha);
      final forestAmberPaint = Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.75 * detailAlpha);

      const pebblePeriod = 180.0;
      for (double fx = -(_scrollOffset % pebblePeriod) + 40; fx < w + pebblePeriod; fx += pebblePeriod) {
        // Polished jade river stone
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), jadePebblePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, jadeHighlightPaint);

        // Warm amber nodule
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), forestAmberPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, jadeHighlightPaint);
      }

      // 🌲 4. Surface Grass Tufts & Wildflower Clusters
      const grassSpacing = 28.0;
      int gIdx = 0;
      final grassLight = Paint()..color = const Color(0xFFAEEA00).withValues(alpha: 0.90 * detailAlpha);
      final grassEmerald = Paint()..color = const Color(0xFF64DD17).withValues(alpha: 0.85 * detailAlpha);
      final flowerPaint = Paint()..color = const Color(0xFFFFEE58).withValues(alpha: 0.95 * detailAlpha);

      for (double gx = -(_scrollOffset % grassSpacing); gx < w + grassSpacing; gx += grassSpacing) {
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
    } else if (currentBiome == 'ICE' && detailAlpha > 0.05) {
      // ❄️ 1. Multi-layered Glacial Permafrost Strata & Ice Wave Contours (Matching Desert Level Depth)
      final iceHighlightPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.90 * detailAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final iceMidWavePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.75 * detailAlpha)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final iceShadowWavePaint = Paint()
        ..color = const Color(0xFF0097A7).withValues(alpha: 0.65 * detailAlpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final iceDeepStrataPaint = Paint()
        ..color = const Color(0xFF006064).withValues(alpha: 0.55 * detailAlpha)
        ..strokeWidth = 3.0;

      // Soft Top Diamond Snow Crest Rim
      final snowCrestPaint = Paint()
        ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.95 * detailAlpha)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), snowCrestPaint);

      // Layer 1: Fine Upper Frost Ripples (Wavelength ~28px)
      const r1W = 28.0;
      final r1Path = Path();
      for (double rx = -(_scrollOffset % r1W) - r1W; rx < w + r1W; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, iceHighlightPaint..style = PaintingStyle.stroke);

      // Layer 2: Mid Glacial Sapphire Contours (Wavelength ~54px)
      const r2W = 54.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = -((_scrollOffset * 1.0) % r2W) - r2W; rx < w + r2W; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 22, y + 20, rx + 44, y + 14);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 24, y + 22, rx + 46, y + 16);
      }
      canvas.drawPath(r2DarkPath, iceShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, iceMidWavePaint..style = PaintingStyle.stroke);

      // Layer 3: Lower Deep Cobalt Permafrost Strata (Wavelength ~90px)
      const r3W = 90.0;
      final r3Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % r3W) - r3W; rx < w + r3W; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 65, y + 28, rx + r3W, y + 33);
      }
      canvas.drawPath(r3Path, iceDeepStrataPaint..style = PaintingStyle.stroke);

      // Layer 4: Deep Glacial Bedrock Abyss
      final r4Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % 130.0) - 130.0; rx < w + 130.0; rx += 130.0) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 65, y + 56, rx + 130, y + 49);
      }
      canvas.drawPath(r4Path, iceDeepStrataPaint..style = PaintingStyle.stroke);

      // ✨ 2. Shimmering Diamond Snow Crystals & Specular Glacial Flecks (Glistening Effect!)
      final diamondSparklePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * detailAlpha);
      final cyanFrostPaint = Paint()..color = const Color(0xFFB2EBF2).withValues(alpha: 0.85 * detailAlpha);
      final sapphireGlitterPaint = Paint()..color = const Color(0xFF4DD0E1).withValues(alpha: 0.75 * detailAlpha);
      final deepIceFlecks = Paint()..color = const Color(0xFF00ACC1).withValues(alpha: 0.55 * detailAlpha);

      for (int i = 0; i < 32; i++) {
        final seedX = i * 59.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
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

      // ❄️ 3. Polished Frozen Sapphires & Diamond Ice Geodes
      final sapphireGemPaint = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.85 * detailAlpha);
      final iceGlintPaint = Paint()..color = Colors.white.withValues(alpha: 0.95 * detailAlpha);
      final arcticOpalPaint = Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.75 * detailAlpha);

      const pebblePeriod = 180.0;
      for (double fx = -(_scrollOffset % pebblePeriod) + 40; fx < w + pebblePeriod; fx += pebblePeriod) {
        // Polished sapphire geode
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), sapphireGemPaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, iceGlintPaint);

        // Arctic opal nodule
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), arcticOpalPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, iceGlintPaint);
      }

      // ❄️ 4. Jagged Diamond Ice Crystals protruding from surface
      const crystalSpacing = 36.0;
      int cIdx = 0;
      for (double cx = -(_scrollOffset % crystalSpacing); cx < w + crystalSpacing; cx += crystalSpacing) {
        cIdx++;
        final spikeH = 6.0 + (cIdx % 4) * 2.5;
        final cPath = Path()
          ..moveTo(cx + 4.0, y + 1.0)
          ..lineTo(cx + 8.0, y - spikeH)
          ..lineTo(cx + 12.0, y + 1.0)
          ..close();

        final iceShader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95 * detailAlpha),
            const Color(0xFF80DEEA).withValues(alpha: 0.85 * detailAlpha),
            const Color(0xFF00ACC1).withValues(alpha: 0.70 * detailAlpha),
          ],
        ).createShader(Rect.fromLTWH(cx + 4.0, y - spikeH, 8.0, spikeH + 1.0));

        canvas.drawPath(cPath, Paint()..shader = iceShader);
        canvas.drawCircle(
          Offset(cx + 8.0, y - spikeH),
          1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.95 * detailAlpha),
        );
      }
    } else if (currentBiome == 'VOLCANO' && detailAlpha > 0.05) {
      // 🌋 1. Multi-layered Volcanic Basalt Strata & Magma Wave Contours (Matching Desert Level Depth)
      final volcanoHighlightPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85 * detailAlpha)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final volcanoMidWavePaint = Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.70 * detailAlpha)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final volcanoShadowWavePaint = Paint()
        ..color = const Color(0xFFD84315).withValues(alpha: 0.65 * detailAlpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final volcanoDeepStrataPaint = Paint()
        ..color = const Color(0xFF3E1107).withValues(alpha: 0.55 * detailAlpha)
        ..strokeWidth = 3.0;

      // Soft Top Molten Basalt Crest Rim
      final heatPulse = 0.85 + 0.15 * math.sin(_time * 4.0);
      final volcanoCrestPaint = Paint()
        ..color = const Color(0xFFFFAB40).withValues(alpha: 0.95 * detailAlpha * heatPulse)
        ..strokeWidth = 3.2;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), volcanoCrestPaint);

      // Layer 1: Fine Upper Magma Heat Ripples (Wavelength ~28px)
      const r1W = 28.0;
      final r1Path = Path();
      for (double rx = -(_scrollOffset % r1W) - r1W; rx < w + r1W; rx += r1W) {
        r1Path.moveTo(rx, y + 5);
        r1Path.quadraticBezierTo(rx + r1W * 0.5, y + 8, rx + r1W, y + 5);
      }
      canvas.drawPath(r1Path, volcanoHighlightPaint..style = PaintingStyle.stroke);

      // Layer 2: Mid Charred Basalt Contours (Wavelength ~54px)
      const r2W = 54.0;
      final r2LightPath = Path();
      final r2DarkPath = Path();
      for (double rx = -((_scrollOffset * 1.0) % r2W) - r2W; rx < w + r2W; rx += r2W) {
        r2LightPath.moveTo(rx, y + 15);
        r2LightPath.quadraticBezierTo(rx + 22, y + 20, rx + 44, y + 14);
        r2DarkPath.moveTo(rx + 2, y + 17);
        r2DarkPath.quadraticBezierTo(rx + 24, y + 22, rx + 46, y + 16);
      }
      canvas.drawPath(r2DarkPath, volcanoShadowWavePaint..style = PaintingStyle.stroke);
      canvas.drawPath(r2LightPath, volcanoMidWavePaint..style = PaintingStyle.stroke);

      // Layer 3: Lower Glowing Magma Strata Wavebands (Wavelength ~90px)
      const r3W = 90.0;
      final r3Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % r3W) - r3W; rx < w + r3W; rx += r3W) {
        r3Path.moveTo(rx, y + 32);
        r3Path.cubicTo(rx + 25, y + 36, rx + 65, y + 28, rx + r3W, y + 33);
      }
      canvas.drawPath(r3Path, volcanoDeepStrataPaint..style = PaintingStyle.stroke);

      // Layer 4: Deep Magma Chamber Floor
      final r4Path = Path();
      for (double rx = -((_scrollOffset * 1.0) % 130.0) - 130.0; rx < w + 130.0; rx += 130.0) {
        r4Path.moveTo(rx, y + 50);
        r4Path.quadraticBezierTo(rx + 65, y + 56, rx + 130, y + 49);
      }
      canvas.drawPath(r4Path, volcanoDeepStrataPaint..style = PaintingStyle.stroke);

      // ✨ 2. Shimmering Pyrite Sparks & Incandescent Magma Glistening Flecks
      final magmaSparklePaint = Paint()..color = const Color(0xFFFFFDE7).withValues(alpha: 0.95 * detailAlpha);
      final goldHeatPaint = Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.85 * detailAlpha);
      final orangeEmberPaint = Paint()..color = const Color(0xFFFF9100).withValues(alpha: 0.75 * detailAlpha);
      final basaltFlecks = Paint()..color = const Color(0xFFDD2C00).withValues(alpha: 0.55 * detailAlpha);

      for (int i = 0; i < 32; i++) {
        final seedX = i * 59.3;
        final gx = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
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

      // 🌋 3. Polished Fire Agate & Obsidian Gem Nodules
      final fireAgatePaint = Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.85 * detailAlpha);
      final fireGlintPaint = Paint()..color = Colors.white.withValues(alpha: 0.90 * detailAlpha);
      final obsidianGemPaint = Paint()..color = const Color(0xFFFFAB00).withValues(alpha: 0.75 * detailAlpha);

      const pebblePeriod = 180.0;
      for (double fx = -(_scrollOffset % pebblePeriod) + 40; fx < w + pebblePeriod; fx += pebblePeriod) {
        // Polished fire agate
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 35, y + 22), width: 7, height: 4.5), fireAgatePaint);
        canvas.drawCircle(Offset(fx + 33.5, y + 21), 1.0, fireGlintPaint);

        // Glowing obsidian amber nodule
        canvas.drawOval(Rect.fromCenter(center: Offset(fx + 120, y + 32), width: 5.5, height: 3.5), obsidianGemPaint);
        canvas.drawCircle(Offset(fx + 119, y + 31), 0.8, fireGlintPaint);
      }

      // 🌋 4. Jagged Obsidian Basalt Shards along running surface
      const rockSpacing = 32.0;
      int rIdx = 0;
      final basaltRockPaint = Paint()..color = const Color(0xFF1E1E24);
      final heatPeakPaint = Paint()..color = const Color(0xFFFF9100).withValues(alpha: 0.90 * detailAlpha);

      for (double rx = -(_scrollOffset % rockSpacing); rx < w + rockSpacing; rx += rockSpacing) {
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

    canvas.clipRect(Rect.fromLTWH(0, y, w, groundHeight));

    // Fallback small pebbles (deterministic scrolling positions)
    if (currentBiome != 'DESERT' && currentBiome != 'RAIN' && currentBiome != 'STORM' && currentBiome != 'COSMOS' && currentBiome != 'FOREST' && currentBiome != 'ICE' && currentBiome != 'VOLCANO') {
      final pebblePaint = Paint()..color = bottomColor.withValues(alpha: 0.3);
      for (int i = 0; i < 12; i++) {
        final seedX = (i * 127.0);
        final px = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
        final py = y + 14 + (i * 3.7) % (groundHeight - 24);
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

    // 3. Deep Molten Magma Reservoir Bed (Viscous incandescent basin at the bottom)
    final magmaBedY = y + 18.0;
    final magmaBedHeight = pitHeight - 18.0;
    final magmaBedPath = Path()..moveTo(leftX, y + pitHeight);
    magmaBedPath.lineTo(leftX, magmaBedY);

    for (double px = leftX; px <= rightX; px += 4.0) {
      final normX = (px - leftX) / pitWidth;
      final wave = math.sin(_time * 4.5 + normX * math.pi * 3) * 2.0;
      magmaBedPath.lineTo(px, magmaBedY + wave);
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
