import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../utils/colors.dart';
import '../utils/vibration_util.dart';

/// A rain of meteor boulders with random staggered heights, speeds, and trajectories.
class FallingStone extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  final double initialSpeedX;
  final int stoneCount;
  @override
  bool isRemoved = false;
  bool passed = false;
  
  final List<_StoneData> _stones = [];

  FallingStone({required this.initialSpeedX, this.stoneCount = 4});

  @override
  Future<void> onLoad() async {
    final rng = math.Random();
    
    final tempStones = <_TempStone>[];
    double totalWidth = 0;
    double maxHeight = 0;

    for (int i = 0; i < stoneCount; i++) {
      final w = 55.0 + rng.nextDouble() * 70.0; // 55-125px random boulder size
      final h = 50.0 + rng.nextDouble() * 70.0; // 50-120px
      final offsetX = (i == 0) ? 0.0 : totalWidth + 15.0 + rng.nextDouble() * 35.0; // Staggered X spacing!
      
      tempStones.add(_TempStone(w, h, offsetX));
      totalWidth = math.max(totalWidth, offsetX + w);
      if (h > maxHeight) maxHeight = h;
    }

    size = Vector2(totalWidth, maxHeight);

    for (int i = 0; i < tempStones.length; i++) {
      final ts = tempStones[i];
      final w = ts.w;
      final h = ts.h;
      
      final pts = <Offset>[];
      final vertexCount = 6 + rng.nextInt(3);
      for (int v = 0; v < vertexCount; v++) {
        final angle = (v / vertexCount) * math.pi * 2 - math.pi / 2;
        final rx = w * 0.45 * (0.75 + rng.nextDouble() * 0.25);
        final ry = h * 0.45 * (0.75 + rng.nextDouble() * 0.25);
        pts.add(Offset(
          w / 2 + math.cos(angle) * rx,
          h / 2 + math.sin(angle) * ry,
        ));
      }

      final maxY = pts.fold(0.0, (maxVal, p) => math.max(maxVal, p.dy));
      final minY = pts.fold(h, (minVal, p) => math.min(minVal, p.dy));
      final heightRange = (maxY - minY) > 0 ? (maxY - minY) : 1.0;

      final maxX = pts.fold(0.0, (maxVal, p) => math.max(maxVal, p.dx));
      final minX = pts.fold(w, (minVal, p) => math.min(minVal, p.dx));
      final widthRange = (maxX - minX) > 0 ? (maxX - minX) : 1.0;

      final adjustedPts = pts.map((p) {
        final normX = (p.dx - minX) / widthRange;
        final normY = (p.dy - minY) / heightRange;
        return Offset(normX * w, normY * h);
      }).toList();

      final path = Path();
      path.moveTo(adjustedPts[0].dx, adjustedPts[0].dy);
      for (int v = 1; v < adjustedPts.length; v++) {
        path.lineTo(adjustedPts[v].dx, adjustedPts[v].dy);
      }
      path.close();

      final targetY = maxHeight - h;
      final startHeight = -250.0 - rng.nextDouble() * 300.0; // Staggered sky spawn heights!
      final angleVelocityX = -40.0 + (rng.nextDouble() - 0.5) * 80.0; // Random angled trajectory!

      _stones.add(_StoneData(
        offsetX: ts.offsetX,
        offsetY: targetY,
        currentY: startHeight,
        velocityY: 150.0 + rng.nextDouble() * 200.0,
        velocityX: angleVelocityX,
        width: w,
        height: h,
        path: path,
        color: Color.lerp(GameColors.rockDark, GameColors.rock, rng.nextDouble())!,
        highlightColor: GameColors.rock.withValues(alpha: 0.4),
      ));
    }
    
    // Position cluster at screen ground level
    position = Vector2(game.size.x + 40, game.ground.groundY - size.y);
    
    add(RectangleHitbox(size: size * 0.85, position: size * 0.075));
    priority = 6;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state == GameState.playing) {
      position.x -= game.speedManager.currentSpeed * dt;
      
      // Update each meteor boulder along its individual trajectory!
      for (final stone in _stones) {
        if (!stone.landed) {
          stone.velocityY += 700 * dt;
          stone.currentY += stone.velocityY * dt;
          stone.offsetX += stone.velocityX * dt;

          if (stone.currentY >= stone.offsetY) {
            stone.currentY = stone.offsetY;
            stone.landed = true;
            game.triggerShake(duration: 0.3, intensity: 5.5);
            GameVibration.mediumImpact();
            game.particlePool.emitJumpDust(position + Vector2(stone.offsetX + stone.width / 2, size.y));
          }
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
    for (final stone in _stones) {
      canvas.save();
      canvas.translate(stone.offsetX, stone.currentY);
      
      // Ground shadow once close to landing
      if (stone.currentY >= stone.offsetY - 20) {
        final shadowAlpha = ((stone.currentY - (stone.offsetY - 20)) / 20.0 * 0.35).clamp(0.0, 0.35);
        canvas.drawOval(
          Rect.fromLTWH(0, stone.height - 4, stone.width, 8),
          Paint()..color = Colors.black.withValues(alpha: shadowAlpha),
        );
      }

      canvas.drawPath(stone.path, Paint()..color = stone.color);
      
      // Highlight circle
      canvas.drawCircle(
        Offset(stone.width * 0.35, stone.height * 0.3),
        stone.width * 0.1,
        Paint()..color = stone.highlightColor,
      );
      canvas.restore();
    }
  }
}

class _TempStone {
  final double w, h, offsetX;
  _TempStone(this.w, this.h, this.offsetX);
}

class _StoneData {
  double offsetX;
  double offsetY;
  double currentY;
  double velocityY;
  double velocityX;
  final double width;
  final double height;
  final Path path;
  final Color color;
  final Color highlightColor;
  bool landed = false;
  
  _StoneData({
    required this.offsetX,
    required this.offsetY,
    required this.currentY,
    required this.velocityY,
    required this.velocityX,
    required this.width,
    required this.height,
    required this.path,
    required this.color,
    required this.highlightColor,
  });
}
