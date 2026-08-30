import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../utils/colors.dart';
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
    
    // Space mode: ground slides down off screen
    if (game.state == GameState.spaceMode) {
      _spaceSlideOffset += 450 * dt;
      if (_spaceSlideOffset > groundHeight + 200) {
        _spaceSlideOffset = groundHeight + 200;
      }
    } else {
      // Smoothly return ground when exiting space mode
      if (_spaceSlideOffset > 0) {
        _spaceSlideOffset -= 350 * dt;
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

    // Base lava layer underneath
    final lavaRect = Rect.fromLTWH(0, y + 20, w, groundHeight - 20);
    final lavaPaint = Paint()..color = GameColors.meteorBody;
    canvas.drawRect(lavaRect, lavaPaint);
    
    // Lava spray geyser effect in each gap
    for (final gap in _gaps) {
      if (gap.x > w || gap.x + gap.width < 0) continue;
      _renderLavaGeyser(canvas, gap, y, w);
    }

    // Draw ground segments (ignoring gaps)
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

    // Ground fill gradient
    final rect = Rect.fromLTWH(0, y, w, groundHeight);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Surface top highlight line
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..color = topColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.5,
    );

    final currentBiome = game.biomeManager.effectiveBiome.name;
    final detailAlpha = (game.biomeManager.isTransitioning
            ? (game.biomeManager.progress - 0.5).abs() * 2.0
            : 1.0)
        .clamp(0.0, 1.0);

    // Biome-specific ground surface details
    if (currentBiome == 'FOREST' && detailAlpha > 0.05) {
      // Grass tufts along ground surface
      final grassPaint = Paint()
        ..color = const Color(0xFF2E7D32).withValues(alpha: detailAlpha)
        ..strokeWidth = 2.0;
      for (double gx = -(_scrollOffset % 40.0); gx < w + 40; gx += 40.0) {
        canvas.drawLine(Offset(gx, y), Offset(gx - 3, y - 6), grassPaint);
        canvas.drawLine(Offset(gx, y), Offset(gx + 3, y - 8), grassPaint);
        canvas.drawLine(Offset(gx, y), Offset(gx + 6, y - 5), grassPaint);
      }
    } else if (currentBiome == 'ICE' && detailAlpha > 0.05) {
      // Frosty ice sheen top rim
      final frostPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 * detailAlpha)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(0, y + 1), Offset(w, y + 1), frostPaint);
    } else if (currentBiome == 'VOLCANO' && detailAlpha > 0.05) {
      // Glowing animated fire & lava cracks
      final crackPaint = Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: 0.75 * detailAlpha)
        ..strokeWidth = 1.8;
      final fireGlowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85 * detailAlpha)
        ..strokeWidth = 1.0;
      for (double cx = -(_scrollOffset % 60.0); cx < w + 60; cx += 60.0) {
        canvas.drawLine(Offset(cx, y + 10), Offset(cx + 15, y + 25), crackPaint);
        canvas.drawLine(Offset(cx + 15, y + 25), Offset(cx + 25, y + 18), crackPaint);
        canvas.drawLine(Offset(cx + 4, y + 12), Offset(cx + 14, y + 23), fireGlowPaint);
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
    }

    canvas.clipRect(Rect.fromLTWH(0, y, w, groundHeight));

    final dashPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 2;

    for (double x = -(_scrollOffset % 64.0); x < w + 64; x += 64) {
      canvas.drawLine(Offset(x + 10, y + 15), Offset(x + 30, y + 15), dashPaint);
      canvas.drawLine(Offset(x + 40, y + 30), Offset(x + 55, y + 30), dashPaint);
      canvas.drawLine(Offset(x + 5, y + 45), Offset(x + 25, y + 45), dashPaint);
    }

    // Small pebbles (deterministic scrolling positions)
    final pebblePaint = Paint()..color = bottomColor.withValues(alpha: 0.3);
    for (int i = 0; i < 12; i++) {
      final seedX = (i * 127.0);
      final px = (seedX - _scrollOffset) % (w + 40.0) - 20.0;
      final py = y + 14 + (i * 3.7) % (groundHeight - 24);
      canvas.drawCircle(Offset(px, py), 2.0, pebblePaint);
    }

    canvas.restore();
  }

  void _renderLavaGeyser(Canvas canvas, GroundGap gap, double y, double w) {
    if (gap.x > w || gap.x + gap.width < -50) return;

    _renderLavaPool(canvas, gap, y);

    if (gap.eruptionTimer > 0.05) {
      _renderLavaEruption(canvas, gap, y);
    }
  }

  void _renderLavaPool(Canvas canvas, GroundGap gap, double y) {
    final leftX = gap.x;
    final rightX = gap.x + gap.width;
    final pitWidth = gap.width;
    final pitHeight = groundHeight + 30.0;

    // 1. Molten Magma Reservoir Pit Fill
    final poolRect = Rect.fromLTWH(leftX, y + 16, pitWidth, pitHeight - 14);
    final magmaShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFFF8D), // White-hot molten gold surface
        Color(0xFFFF9800), // Blazing solar orange
        Color(0xFFD84315), // Fiery red magma layer
        Color(0xFF1B0000), // Deep basalt chamber base
      ],
      stops: const [0.0, 0.22, 0.60, 1.0],
    ).createShader(poolRect);
    canvas.drawRect(poolRect, Paint()..shader = magmaShader);

    // 2. Animated Licking Fire Tongues across the entire Lava Surface
    final tongueCount = math.max(6, (pitWidth / 12).floor());
    final fireTonguePath = Path();
    fireTonguePath.moveTo(leftX, y + 18);

    for (int t = 0; t <= tongueCount; t++) {
      final tx = leftX + (pitWidth * (t / tongueCount));
      final flamePhase = _time * 12.0 + t * 1.8;
      final flameHeight = 8.0 + math.sin(flamePhase).abs() * 12.0 + math.cos(flamePhase * 0.7) * 4.0;
      final tipX = tx + math.sin(flamePhase * 0.9) * 3.0;
      final tipY = (y + 16) - flameHeight;

      if (t == 0) {
        fireTonguePath.lineTo(tx, y + 16);
      } else {
        final prevX = leftX + (pitWidth * ((t - 1) / tongueCount));
        fireTonguePath.cubicTo(
          prevX + (tx - prevX) * 0.4, y + 16,
          tipX - 2, tipY + 4,
          tipX, tipY,
        );
        fireTonguePath.cubicTo(
          tipX + 2, tipY + 4,
          tx - (tx - prevX) * 0.4, y + 16,
          tx, y + 16,
        );
      }
    }
    fireTonguePath.lineTo(rightX, y + pitHeight);
    fireTonguePath.lineTo(leftX, y + pitHeight);
    fireTonguePath.close();

    final fireShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFFFFF), // White flame tip
        Color(0xFFFFFF8D), // Yellow fire
        Color(0xFFFF6D00), // Blazing orange
        Color(0xFFD50000), // Crimson flame base
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(Rect.fromLTWH(leftX, y - 10, pitWidth, pitHeight + 20));
    canvas.drawPath(fireTonguePath, Paint()..shader = fireShader);

    // 3. Glowing Fire Vein Line along surface
    final veinPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final veinPath = Path();
    veinPath.moveTo(leftX, y + 16);
    for (int t = 0; t <= tongueCount; t++) {
      final tx = leftX + (pitWidth * (t / tongueCount));
      final flamePhase = _time * 12.0 + t * 1.8;
      final flameHeight = 4.0 + math.sin(flamePhase).abs() * 5.0;
      veinPath.lineTo(tx, (y + 16) - flameHeight);
    }
    canvas.drawPath(veinPath, veinPaint);

    // 4. Popping Lava Bubbles & Fire Sparks
    final bubbleOffsets = [0.15, 0.32, 0.50, 0.68, 0.85];
    final yellowPaint = Paint()..color = const Color(0xFFFFFF8D);
    final orangePaint = Paint()..color = const Color(0xFFFF6D00);
    final whitePaint = Paint()..color = Colors.white;

    for (int b = 0; b < bubbleOffsets.length; b++) {
      final bx = leftX + pitWidth * bubbleOffsets[b];
      final cycle = (_time * (2.2 + b * 0.4) + b * 0.9) % 1.8;
      final progress = (cycle / 1.8).clamp(0.0, 1.0);

      final surfaceWaveY = y + 16.0;
      final maxBubbleRadius = 3.0 + (b % 3) * 1.2;
      final currentRadius = maxBubbleRadius * math.sin(progress * math.pi);
      final bubbleY = surfaceWaveY - currentRadius * 0.4;

      if (progress < 0.85) {
        canvas.drawCircle(Offset(bx, bubbleY), currentRadius, yellowPaint);
        canvas.drawCircle(Offset(bx - currentRadius * 0.25, bubbleY - currentRadius * 0.25), currentRadius * 0.3, whitePaint);
      } else {
        final popProgress = (progress - 0.85) / 0.15;
        for (int p = 0; p < 4; p++) {
          final dir = (p % 2 == 0) ? 1.0 : -1.0;
          final sparkX = bx + dir * (3 + p * 2.5) * popProgress;
          final sparkY = surfaceWaveY - (8 + p * 5) * popProgress;
          final sparkR = (2.2 * (1 - popProgress)).clamp(0.5, 2.2);
          final pPaint = (p % 2 == 0) ? whitePaint : orangePaint;
          canvas.drawCircle(Offset(sparkX, sparkY), sparkR, pPaint);
        }
      }
    }

    // 5. Rising Fiery Volcanic Embers
    for (int e = 0; e < 6; e++) {
      final ex = leftX + (pitWidth * ((e * 0.20 + (_time * 0.12)) % 1.0));
      final ey = y - 4 - ((_time * 40 + e * 18) % 50.0);
      final eAlpha = (1.0 - (y - ey) / 50.0).clamp(0.0, 0.85);
      final eRadius = 1.2 + (e % 2) * 0.8;

      canvas.drawCircle(
        Offset(ex, ey),
        eRadius,
        Paint()..color = (e % 2 == 0 ? const Color(0xFFFFFF8D) : const Color(0xFFFF9100)).withValues(alpha: eAlpha),
      );
    }
  }

  /// Roaring Eruption Fire Fountains & Magma Pillars
  void _renderLavaEruption(Canvas canvas, GroundGap gap, double y) {
    final eruptionScale = gap.eruptionTimer < 0.2
        ? (gap.eruptionTimer / 0.2) * 0.70
        : 0.70 + math.sin((gap.eruptionTimer - 0.2) / 0.8 * math.pi / 2) * 0.30;

    final pitLeft = gap.x;
    final pitWidth = gap.width;

    // Raging Fire Spout Columns
    final outerPath = Path();
    final innerPath = Path();
    final corePath = Path();

    outerPath.moveTo(pitLeft, y + 25);
    innerPath.moveTo(pitLeft, y + 25);
    corePath.moveTo(pitLeft, y + 25);

    final sproutOffsets = [0.08, 0.24, 0.40, 0.56, 0.72, 0.88];
    final eqFrequencies = [9.0, 14.0, 18.0, 15.0, 11.0, 16.0];
    final eqPhases = [0.0, 1.2, 2.5, 0.8, 3.1, 1.9];

    for (int s = 0; s < 6; s++) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s] * 0.70;
      final eqBounce = 0.40 + 0.60 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 15 - H;
      final halfW = 9.0 + (targetH / 200.0) * 5.0;

      final prevX = (s == 0) ? pitLeft : pitLeft + pitWidth * sproutOffsets[s - 1];

      // Dynamic flame wave
      final flameWave = math.sin(_time * 15.0 + s * 2.0) * 3.0;

      // Outer raging crimson & orange flame
      outerPath.cubicTo(
        prevX + (cx - prevX) * 0.5, y + 10,
        cx - halfW + flameWave, topY + H * 0.3,
        cx - halfW * 0.5, topY,
      );
      outerPath.cubicTo(
        cx + flameWave, topY - 8,
        cx + halfW * 0.5, topY,
        cx + halfW - flameWave, topY + H * 0.3,
      );

      // Inner fiery orange jet core
      innerPath.cubicTo(
        prevX + (cx - prevX) * 0.5, y + 12,
        cx - halfW * 0.6, topY + H * 0.35,
        cx, topY + 4,
      );
      innerPath.cubicTo(
        cx, topY + 4,
        cx + halfW * 0.6, topY + H * 0.35,
        cx + halfW * 0.6, y + 18,
      );

      // White-hot center vein
      corePath.lineTo(cx + flameWave * 0.5, topY + 5);
    }

    outerPath.lineTo(pitLeft + pitWidth, y + 25);
    outerPath.close();

    final maxH = 120.0;

    // Render Layered Fire Geyser Streams
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFF6D00),
            Color(0xFFFF3D00),
            Color(0xFFD50000),
            Color(0xFF7F0000),
          ],
          stops: const [0.0, 0.35, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(pitLeft, y - maxH, pitWidth, maxH + 30)),
    );

    canvas.drawPath(
      innerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFF8D),
            Color(0xFFFF9800),
            Color(0xFFFF3D00),
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(pitLeft, y - maxH, pitWidth, maxH + 30)),
    );

    // Glowing White-Hot Core Line
    canvas.drawPath(
      corePath,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 3. Leaping Fire Spark Particles
    final sparkYellow = Paint()..color = const Color(0xFFFFFF8D);
    final sparkOrange = Paint()..color = const Color(0xFFFF9800);
    final sparkRed = Paint()..color = const Color(0xFFFF3D00);

    for (int s = 0; s < 6; s++) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s] * 0.85;
      final eqBounce = 0.40 + 0.60 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 15 - H;

      final rng = math.Random((cx * 77 + s * 31).toInt());
      for (int p = 0; p < 4; p++) {
        final phase = (_time * 3.8 + p * 0.4 + s) % 1.5;
        final progress = phase / 1.5;
        final spreadX = (rng.nextDouble() - 0.5) * 32.0 * progress;
        final sparkY = topY - (22.0 * math.sin(progress * math.pi)) + progress * progress * 16.0;
        final sparkX = cx + spreadX;
        final r = (2.5 * (1.0 - progress)).clamp(0.6, 2.5);
        final pPaint = (p % 3 == 0) ? sparkYellow : (p % 2 == 0) ? sparkOrange : sparkRed;

        canvas.drawCircle(Offset(sparkX, sparkY), r, pPaint);
      }
    }

    // 4. Billowing Rising Smoke Plumes from Spouts
    final smokePaint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int s = 0; s < 6; s += 2) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      final targetH = gap.spikeTargetHeights[s] * 0.85;
      final eqBounce = 0.40 + 0.60 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 15 - H;

      final sCycle = (_time * 1.8 + s * 0.4) % 1.4;
      final sProg = sCycle / 1.4;
      final sX = cx + math.sin(_time * 3.0 + s) * (4.0 + sProg * 12.0);
      final sY = topY - 8.0 - sProg * 35.0;
      final sR = 5.0 + sProg * 12.0;
      final sAlpha = (1.0 - sProg) * 0.35;
      canvas.drawCircle(Offset(sX, sY), sR, smokePaint..color = const Color(0xFF37474F).withValues(alpha: sAlpha));
    }
  }
}
