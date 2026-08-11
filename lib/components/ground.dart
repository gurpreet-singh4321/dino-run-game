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
      _scrollOffset %= 64; // tile repeat

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
      for (double gx = -(_scrollOffset % 40); gx < w; gx += 40) {
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
      // Glowing orange/red lava cracks
      final crackPaint = Paint()
        ..color = const Color(0xFFFF5722).withValues(alpha: 0.7 * detailAlpha)
        ..strokeWidth = 1.8;
      for (double cx = -(_scrollOffset % 60); cx < w; cx += 60) {
        canvas.drawLine(Offset(cx, y + 10), Offset(cx + 15, y + 25), crackPaint);
        canvas.drawLine(Offset(cx + 15, y + 25), Offset(cx + 25, y + 18), crackPaint);
      }
    } else if ((currentBiome == 'RAIN' || currentBiome == 'STORM') && detailAlpha > 0.05) {
      // Reflective water puddles
      final puddlePaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.35 * detailAlpha);
      for (double px = 80 - (_scrollOffset % 160); px < w; px += 160) {
        canvas.drawOval(Rect.fromLTWH(px, y - 2, 45, 5), puddlePaint);
      }
    }

    canvas.clipRect(Rect.fromLTWH(0, y, w, groundHeight));

    final dashPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 2;

    for (double x = -_scrollOffset; x < w + 64; x += 64) {
      canvas.drawLine(Offset(x + 10, y + 15), Offset(x + 30, y + 15), dashPaint);
      canvas.drawLine(Offset(x + 40, y + 30), Offset(x + 55, y + 30), dashPaint);
      canvas.drawLine(Offset(x + 5, y + 45), Offset(x + 25, y + 45), dashPaint);
    }

    // Small pebbles
    final pebblePaint = Paint()..color = bottomColor.withValues(alpha: 0.3);
    final rng = math.Random(42); 
    for (int i = 0; i < 15; i++) {
      final px = (rng.nextDouble() * w * 2 - _scrollOffset) % (w + 20) - 10;
      final py = y + 12 + rng.nextDouble() * (groundHeight - 20);
      canvas.drawCircle(Offset(px, py), 1.5 + rng.nextDouble() * 2, pebblePaint);
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

    // 1. Molten Magma Reservoir Pit Fill (Seated cleanly inside ground trench - zero artifacts!)
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

    // 2. 6-Bar Music Equalizer Wave Surface
    final wavePath = Path();
    wavePath.moveTo(leftX, y + pitHeight);
    wavePath.lineTo(leftX, y + 18);

    final stepCount = 24;
    for (int i = 0; i <= stepCount; i++) {
      final px = leftX + (pitWidth * (i / stepCount));
      final barIndex = ((i / stepCount) * 5.99).floor();
      final eqBeat = math.sin(_time * (8.0 + barIndex * 1.5) + barIndex * 1.2).abs() * 4.0;
      final waveY = (y + 16) - eqBeat;
      wavePath.lineTo(px, waveY);
    }
    wavePath.lineTo(rightX, y + pitHeight);
    wavePath.close();

    final waveShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFFF8D),
        Color(0xFFFF6D00),
      ],
    ).createShader(Rect.fromLTWH(leftX, y + 10, pitWidth, 30));
    canvas.drawPath(wavePath, Paint()..shader = waveShader);

    // Glowing Equalizer Music-Note Lava Fractures
    final veinPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final veinPath = Path();
    veinPath.moveTo(leftX, y + 16);
    for (int i = 0; i <= stepCount; i++) {
      final px = leftX + (pitWidth * (i / stepCount));
      final barIndex = ((i / stepCount) * 5.99).floor();
      final eqBeat = math.sin(_time * (8.0 + barIndex * 1.5) + barIndex * 1.2).abs() * 4.0;
      final waveY = (y + 16) - eqBeat;
      veinPath.lineTo(px, waveY);
    }
    canvas.drawPath(veinPath, veinPaint);

    // 3. Subtle Flush Lava Bubbles & Surface Sparks
    final bubbleOffsets = [0.15, 0.32, 0.50, 0.68, 0.85];
    final yellowPaint = Paint()..color = const Color(0xFFFFFF8D);
    final orangePaint = Paint()..color = const Color(0xFFFF6D00);
    final whitePaint = Paint()..color = Colors.white;

    for (int b = 0; b < bubbleOffsets.length; b++) {
      final bx = leftX + pitWidth * bubbleOffsets[b];
      final cycle = (_time * (2.0 + b * 0.4) + b * 0.9) % 1.8;
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
          final sparkY = surfaceWaveY - (8 + p * 4) * popProgress;
          final sparkR = (2.0 * (1 - popProgress)).clamp(0.5, 2.0);
          final pPaint = (p % 2 == 0) ? whitePaint : orangePaint;
          canvas.drawCircle(Offset(sparkX, sparkY), sparkR, pPaint);
        }
      }
    }

    // 4. Rising Volcanic Embers
    for (int e = 0; e < 5; e++) {
      final ex = leftX + (pitWidth * ((e * 0.22 + (_time * 0.08)) % 1.0));
      final ey = y - 5 - ((_time * 35 + e * 20) % 45.0);
      final eAlpha = (1.0 - (y - ey) / 45.0).clamp(0.0, 0.8);
      final eRadius = 1.0 + (e % 2) * 0.6;

      canvas.drawCircle(
        Offset(ex, ey),
        eRadius,
        Paint()..color = const Color(0xFFFFF59D).withValues(alpha: eAlpha),
      );
    }
  }

  /// Organic Eruption Magma Fountains with 6-Bar Music Equalizer Movement
  void _renderLavaEruption(Canvas canvas, GroundGap gap, double y) {
    final eruptionScale = gap.eruptionTimer < 0.2
        ? (gap.eruptionTimer / 0.2) * 0.70
        : 0.70 + math.sin((gap.eruptionTimer - 0.2) / 0.8 * math.pi / 2) * 0.30;

    final pitLeft = gap.x;
    final pitWidth = gap.width;

    // Fluid 6-Bar Music Equalizer Magma Surging Paths (Zero background glow artifacts!)
    final outerPath = Path();
    final innerPath = Path();
    final corePath = Path();

    outerPath.moveTo(pitLeft, y + 25);
    innerPath.moveTo(pitLeft, y + 25);
    corePath.moveTo(pitLeft, y + 25);

    final sproutOffsets = [0.08, 0.24, 0.40, 0.56, 0.72, 0.88];
    final eqFrequencies = [8.0, 12.0, 16.0, 14.0, 10.0, 15.0];
    final eqPhases = [0.0, 1.2, 2.5, 0.8, 3.1, 1.9];

    for (int s = 0; s < 6; s++) {
      final cx = pitLeft + pitWidth * sproutOffsets[s];
      // Tighter peak height (between 60px and 105px max height)
      final targetH = gap.spikeTargetHeights[s] * 0.65;
      final eqBounce = 0.40 + 0.60 * math.sin(_time * eqFrequencies[s] + eqPhases[s]).abs();
      final H = targetH * eruptionScale * eqBounce;
      final topY = y + 15 - H;
      final halfW = 9.0 + (targetH / 200.0) * 5.0;

      final prevX = (s == 0) ? pitLeft : pitLeft + pitWidth * sproutOffsets[s - 1];

      // Outer crimson magma wave
      outerPath.cubicTo(
        prevX + (cx - prevX) * 0.5, y + 10,
        cx - halfW, topY + H * 0.3,
        cx - halfW * 0.5, topY,
      );
      outerPath.cubicTo(
        cx, topY - 6,
        cx + halfW * 0.5, topY,
        cx + halfW, topY + H * 0.3,
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
      corePath.lineTo(cx, topY + 6);
    }

    outerPath.lineTo(pitLeft + pitWidth, y + 25);
    outerPath.close();

    final maxH = 110.0;

    // Render Layered Magma Geyser Streams
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFF3D00),
            Color(0xFFDD2C00),
            Color(0xFF8D0000),
          ],
        ).createShader(Rect.fromLTWH(pitLeft, y - maxH, pitWidth, maxH + 30)),
    );

    canvas.drawPath(
      innerPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFFF8D),
            Color(0xFFFF9800),
            Color(0xFFFF3D00),
          ],
        ).createShader(Rect.fromLTWH(pitLeft, y - maxH, pitWidth, maxH + 30)),
    );

    // Glowing White-Hot Core Line
    canvas.drawPath(
      corePath,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 3. Cascading Bursting Magma Spark Particles
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
        final phase = (_time * 3.5 + p * 0.4 + s) % 1.5;
        final progress = phase / 1.5;
        final spreadX = (rng.nextDouble() - 0.5) * 28.0 * progress;
        final sparkY = topY - (20.0 * math.sin(progress * math.pi)) + progress * progress * 14.0;
        final sparkX = cx + spreadX;
        final r = (2.5 * (1.0 - progress)).clamp(0.6, 2.5);
        final pPaint = (p % 3 == 0) ? sparkYellow : (p % 2 == 0) ? sparkOrange : sparkRed;

        canvas.drawCircle(Offset(sparkX, sparkY), r, pPaint);
      }
    }
  }
}
