import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';

enum ObstacleType { cactusSmall, cactusTall, rock, bird, bush, pillar, ceilingPipe, pipePair, lavaPit }

class Obstacle extends PositionComponent with CollisionCallbacks, HasGameReference<DinoGame> {
  final ObstacleType type;
  final double speed; // kept for reference but we use live speed
  bool passed = false;
  bool nearMissTriggered = false;
  
  double age = 0;
  
  // Per-instance randomization seed
  late final int _seed;
  late final double _wobblePhase;
  late final double _wobbleSpeed;
  
  // Bird specifics
  int _birdFrame = 0;
  double _birdTimer = 0;
  bool _lockedHeight = false;

  // PipePair gap boundaries & dynamic oscillation
  double gapTopY = 0;
  double gapBottomY = 0;
  double liveGapTopY = 0;
  double liveGapBottomY = 0;
  double _pipeOscillationPhase = 0;
  RectangleHitbox? _topPipeHitbox;
  RectangleHitbox? _bottomPipeHitbox;

  // Falling pillar fields (dropping from sky!)
  bool isFallingFromSky = false;
  double targetGroundY = 0;
  double fallVelocityY = 0;
  bool hasLanded = false;

  Obstacle({required this.type, required this.speed}) {
    final rng = math.Random();
    _seed = rng.nextInt(99999);
    _wobblePhase = rng.nextDouble() * math.pi * 2;
    _wobbleSpeed = 1.5 + rng.nextDouble() * 2.0;
    
    switch (type) {
      case ObstacleType.cactusSmall:
        // Variable short cactus (48 - 85px high)
        size = Vector2(40 + rng.nextDouble() * 16, 48 + rng.nextDouble() * 37);
        break;
      case ObstacleType.cactusTall:
        // Variable tall cactus (105 - 170px high)
        size = Vector2(50 + rng.nextDouble() * 18, 105 + rng.nextDouble() * 65);
        break;
      case ObstacleType.rock:
        // Variable rocks (45 - 125px high)
        final isBigRock = rng.nextBool();
        if (isBigRock) {
          size = Vector2(95 + rng.nextDouble() * 35, 80 + rng.nextDouble() * 45);
        } else {
          size = Vector2(65 + rng.nextDouble() * 25, 45 + rng.nextDouble() * 20);
        }
        break;
      case ObstacleType.bush:
        // Variable bush (45 - 75px high)
        size = Vector2(70 + rng.nextDouble() * 25, 45 + rng.nextDouble() * 30);
        break;
      case ObstacleType.bird:
        size = Vector2(64, 48);
        break;
      case ObstacleType.pillar:
        // Variable stone column (85 - 165px high)
        size = Vector2(55 + rng.nextDouble() * 14, 85 + rng.nextDouble() * 80);
        break;
      case ObstacleType.ceilingPipe:
        size = Vector2(60 + rng.nextDouble() * 10, 150 + rng.nextDouble() * 50);
        break;
      case ObstacleType.pipePair:
        size = Vector2(65, 300);
        break;
      case ObstacleType.lavaPit:
        // 1 or 2 vents clustered (matching reference image)
        final isDoubleVent = rng.nextDouble() < 0.45;
        final w = isDoubleVent ? (88.0 + rng.nextDouble() * 16.0) : (52.0 + rng.nextDouble() * 10.0);
        final h = 65.0 + rng.nextDouble() * 35.0; // 65-100px eruption height
        size = Vector2(w, h);
        break;
    }
  }

  @override
  Future<void> onLoad() async {
    if (type == ObstacleType.pipePair) {
      liveGapTopY = gapTopY > 0 ? gapTopY : 90;
      liveGapBottomY = gapBottomY > 0 ? gapBottomY : 265;

      // Forgiving inset padding on pipe hitboxes for fair, smooth jump clearance!
      _topPipeHitbox = RectangleHitbox(
        position: Vector2(8, 0),
        size: Vector2(math.max(10.0, size.x - 16), math.max(10.0, liveGapTopY - 10)),
      );
      _bottomPipeHitbox = RectangleHitbox(
        position: Vector2(8, liveGapBottomY + 10),
        size: Vector2(math.max(10.0, size.x - 16), math.max(10.0, size.y - liveGapBottomY - 10)),
      );
      add(_topPipeHitbox!);
      add(_bottomPipeHitbox!);
    } else if (type == ObstacleType.lavaPit) {
      // Inset hitbox for fair and clean jump clearance over volcanic eruption
      add(RectangleHitbox(
        position: Vector2(size.x * 0.12, size.y * 0.15),
        size: Vector2(size.x * 0.76, size.y * 0.85),
      ));
    } else {
      add(RectangleHitbox(size: size * 0.85, position: size * 0.075));
    }
    priority = 5;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state == GameState.playing || game.state == GameState.spaceMode) {
      // Use LIVE speed from speedManager so obstacles match the ground
      final liveSpeed = game.speedManager.currentSpeed;
      final moveSpeed = type == ObstacleType.bird ? liveSpeed * 1.15 : liveSpeed;
      position.x -= moveSpeed * dt;
      age += dt;

      // Sky Falling Pillar Physics (slamming down from sky!)
      if (isFallingFromSky && !hasLanded) {
        fallVelocityY += 1800 * dt;
        position.y += fallVelocityY * dt;

        if (position.y >= targetGroundY) {
          position.y = targetGroundY;
          hasLanded = true;
          fallVelocityY = 0;
          game.particlePool.emitJumpDust(position + Vector2(size.x / 2, size.y));
        }
      }

      // Pipe pair dynamic vertical oscillation (moving top & bottom pipes smoothly together!)
      if (type == ObstacleType.pipePair && gapBottomY > gapTopY) {
        _pipeOscillationPhase += dt * 2.2;
        final gapHeight = gapBottomY - gapTopY;
        final offset = math.sin(_pipeOscillationPhase + _wobblePhase) * 20.0; // Gentle 20px wave
        
        liveGapTopY = (gapTopY + offset).clamp(20.0, size.y - gapHeight - 20.0);
        liveGapBottomY = liveGapTopY + gapHeight;

        // Update child hitboxes live with forgiving inset padding
        if (_topPipeHitbox != null && _bottomPipeHitbox != null) {
          _topPipeHitbox!.position = Vector2(8, 0);
          _topPipeHitbox!.size = Vector2(math.max(10.0, size.x - 16), math.max(10.0, liveGapTopY - 10));
          _bottomPipeHitbox!.position = Vector2(8, liveGapBottomY + 10);
          _bottomPipeHitbox!.size = Vector2(math.max(10.0, size.x - 16), math.max(10.0, size.y - liveGapBottomY - 10));
        }
      }
    }

    if (type == ObstacleType.bird) {
      _birdTimer += dt;
      if (_birdTimer >= 0.15) {
        _birdTimer -= 0.15;
        _birdFrame = (_birdFrame + 1) % 2;
      }
      
      final playerX = game.player.position.x;
      final distToPlayer = position.x - playerX;
      
      if (distToPlayer > 400) {
        position.y += math.sin(position.x * 0.05) * 0.5;
      } else if (distToPlayer > 150 && !_lockedHeight) {
        final playerY = game.player.position.y;
        final diff = playerY - position.y;
        position.y += diff * 2.5 * dt; 
      } else if (distToPlayer <= 150 && !_lockedHeight) {
        _lockedHeight = true; 
      }
    }

    if (position.x + size.x < -20) {
      removeFromParent();
    }

    _checkNearMiss();
  }

  void _checkNearMiss() {
    if (passed || nearMissTriggered) return;
    final player = game.player;
    final dx = (position.x + size.x / 2 - player.position.x - player.size.x / 2).abs();
    final dy = (position.y + size.y / 2 - player.position.y - player.size.y / 2).abs();

    // Adjusted near miss distance for bigger dino (80x96)
    if (dx < 60 && dy < 70) {
      final myRect = toRect();
      final playerRect = player.toRect();
      if (!myRect.overlaps(playerRect)) {
        nearMissTriggered = true;
        game.combo++;
        game.comboTimer = 1.6;
        game.score += game.combo * 12;
        game.comboDisplay.show(game.combo);
        game.particlePool.emitNearMiss(position + size / 2);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    switch (type) {
      case ObstacleType.cactusSmall:
        _renderCactus(canvas, size.x.toDouble(), size.y.toDouble(), false);
        break;
      case ObstacleType.cactusTall:
        _renderCactus(canvas, size.x.toDouble(), size.y.toDouble(), true);
        break;
      case ObstacleType.rock:
        _renderRock(canvas);
        break;
      case ObstacleType.bush:
        _renderBush(canvas);
        break;
      case ObstacleType.bird:
        _renderBird(canvas);
        break;
      case ObstacleType.pillar:
        _renderPillar(canvas);
        break;
      case ObstacleType.ceilingPipe:
        _renderCeilingPipe(canvas);
        break;
      case ObstacleType.pipePair:
        _renderPipePair(canvas);
        break;
      case ObstacleType.lavaPit:
        _renderLavaPit(canvas);
        break;
    }
  }

  void _renderCactus(Canvas canvas, double w, double h, bool tall) {
    final rng = math.Random(_seed);

    // Ground shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h - 4, w * 0.9, 6), shadowPaint);

    // Saguaro cactus green gradient body
    final trunkWidth = w * 0.44;
    final trunkRect = Rect.fromLTWH((w - trunkWidth) / 2, 0, trunkWidth, h);
    final cactusGradient = const LinearGradient(
      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32), Color(0xFF1B5E20)],
    );
    final paint = Paint()..shader = cactusGradient.createShader(trunkRect);

    // Main central trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        trunkRect,
        Radius.circular(trunkWidth * 0.45),
      ),
      paint,
    );

    // Vertical rib line highlights
    final ribPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.7)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.42, h * 0.05), Offset(w * 0.42, h * 0.95), ribPaint);
    canvas.drawLine(Offset(w * 0.58, h * 0.05), Offset(w * 0.58, h * 0.95), ribPaint);

    // Spine needle dot clusters
    final spinePaint = Paint()..color = const Color(0xFFDCEDC8);
    for (double sy = h * 0.15; sy < h * 0.85; sy += 16) {
      canvas.drawCircle(Offset((w - trunkWidth) / 2 - 1, sy), 1.5, spinePaint);
      canvas.drawCircle(Offset((w + trunkWidth) / 2 + 1, sy), 1.5, spinePaint);
    }

    // Branch growth: starts at 0.05 scale, grows to 1.0 over 2.5 seconds
    final double branchScale = (age / 2.0).clamp(0.05, 1.0);
    final branchCount = tall ? (2 + rng.nextInt(2)) : (1 + rng.nextInt(2));
    
    for (int i = 0; i < branchCount; i++) {
      final isRight = (i % 2 == 0);
      final yPos = h * (0.2 + i * 0.28);
      final branchLen = w * (0.32 + rng.nextDouble() * 0.3) * branchScale;
      final branchThickness = 11.0;
      final upLen = h * (0.18 + rng.nextDouble() * 0.15) * branchScale;
      
      canvas.save();
      canvas.translate(isRight ? w * 0.65 : w * 0.35, yPos);
      
      // Horizontal arm
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            isRight ? 0 : -branchLen, 
            -branchThickness / 2, 
            branchLen, 
            branchThickness,
          ),
          Radius.circular(branchThickness / 2),
        ),
        paint,
      );

      // Vertical arm tip going up
      final tipX = (isRight ? branchLen : -branchLen) + (isRight ? -branchThickness / 2 : -branchThickness / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            tipX, 
            -upLen - branchThickness / 2, 
            branchThickness, 
            upLen + branchThickness,
          ),
          Radius.circular(branchThickness / 2),
        ),
        paint,
      );

      // Arm flower blossom
      canvas.drawCircle(Offset(tipX + branchThickness / 2, -upLen - branchThickness / 2), 4.0, Paint()..color = const Color(0xFFFF4081));
      canvas.drawCircle(Offset(tipX + branchThickness / 2, -upLen - branchThickness / 2), 1.8, Paint()..color = const Color(0xFFFFEB3B));

      canvas.restore();
    }

    // Top main flower blossom
    canvas.drawCircle(Offset(w / 2, 0), 5.5, Paint()..color = const Color(0xFFFF4081));
    canvas.drawCircle(Offset(w / 2, 0), 2.2, Paint()..color = const Color(0xFFFFEB3B));
  }

  void _renderRock(Canvas canvas) {
    final rng = math.Random(_seed);
    
    // Dynamic wobble
    final wobble = math.sin(age * _wobbleSpeed + _wobblePhase) * 1.5;
    
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.rotate(wobble * math.pi / 180);
    canvas.translate(-size.x / 2, -size.y);

    // Chunky irregular rock vertices
    final pts = <Offset>[];
    final vertexCount = 8 + rng.nextInt(3);
    for (int i = 0; i < vertexCount; i++) {
      final angle = (i / vertexCount) * math.pi * 2 - math.pi / 2;
      final radiusX = size.x * 0.45 * (0.75 + rng.nextDouble() * 0.25);
      final radiusY = size.y * 0.45 * (0.75 + rng.nextDouble() * 0.25);
      pts.add(Offset(
        size.x / 2 + math.cos(angle) * radiusX,
        size.y / 2 + math.sin(angle) * radiusY,
      ));
    }

    // Normalize vertices so rock sits flush on ground [0, size.x] & [0, size.y]
    final maxY = pts.fold(0.0, (maxVal, p) => math.max(maxVal, p.dy));
    final minY = pts.fold(size.y, (minVal, p) => math.min(minVal, p.dy));
    final heightRange = (maxY - minY) > 0 ? (maxY - minY) : 1.0;

    final maxX = pts.fold(0.0, (maxVal, p) => math.max(maxVal, p.dx));
    final minX = pts.fold(size.x, (minVal, p) => math.min(minVal, p.dx));
    final widthRange = (maxX - minX) > 0 ? (maxX - minX) : 1.0;

    final adjustedPts = pts.map((p) {
      final normX = (p.dx - minX) / widthRange;
      final normY = (p.dy - minY) / heightRange;
      return Offset(normX * size.x, normY * size.y);
    }).toList();

    final path = Path();
    path.moveTo(adjustedPts[0].dx, adjustedPts[0].dy);
    for (int i = 1; i < adjustedPts.length; i++) {
      path.lineTo(adjustedPts[i].dx, adjustedPts[i].dy);
    }
    path.close();

    // 1. Soft Ground Contact AO Shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromLTWH(size.x * 0.05, size.y - 4, size.x * 0.9, 8), shadowPaint);

    // 2. Base Rock Body Gradient (3D Shading)
    final rockGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF8D6E63), // Lit top-left facet
        Color(0xFF5D4037), // Mid rock body
        Color(0xFF3E2723), // Shadowed bottom-right
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawPath(path, Paint()..shader = rockGradient.createShader(Rect.fromLTWH(0, 0, size.x, size.y)));

    // 3. 3D Facet Shading Lines (Chiseled Rock Planes)
    final centerPt = Offset(size.x * 0.45, size.y * 0.45);
    final shadowFacetPaint = Paint()
      ..color = const Color(0xFF261815).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Draw shaded facet triangles
    for (int i = 0; i < adjustedPts.length; i++) {
      final p1 = adjustedPts[i];
      final p2 = adjustedPts[(i + 1) % adjustedPts.length];
      if (p1.dx > size.x * 0.4 || p1.dy > size.y * 0.5) {
        final facetPath = Path()
          ..moveTo(centerPt.dx, centerPt.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close();
        canvas.drawPath(facetPath, shadowFacetPaint);
      }
    }

    // 4. Branching Fissures & Deep Cracks with Specular Edges
    final crackDarkPaint = Paint()
      ..color = const Color(0xFF1B0000)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final crackLitPaint = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final cx = size.x * (0.25 + (i * 0.25));
      final cy = size.y * (0.25 + rng.nextDouble() * 0.5);
      final cx2 = cx + (rng.nextDouble() - 0.5) * size.x * 0.35;
      final cy2 = cy + rng.nextDouble() * size.y * 0.35;

      canvas.drawLine(Offset(cx + 1, cy + 1), Offset(cx2 + 1, cy2 + 1), crackLitPaint);
      canvas.drawLine(Offset(cx, cy), Offset(cx2, cy2), crackDarkPaint);
    }

    // 5. Mineral Ore Gold & Quartz Micro-speckles
    final orePaint = Paint()..color = const Color(0xFFFFD54F);
    for (int k = 0; k < 4; k++) {
      final ox = size.x * (0.2 + rng.nextDouble() * 0.6);
      final oy = size.y * (0.2 + rng.nextDouble() * 0.6);
      canvas.drawCircle(Offset(ox, oy), 1.2 + rng.nextDouble() * 1.0, orePaint);
    }

    // 6. Sunlight Specular Edge Outline (Top-Left Edge Highlight)
    final highlightStroke = Paint()
      ..color = const Color(0xFFE0D7D3).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final hlPath = Path();
    hlPath.moveTo(adjustedPts[0].dx, adjustedPts[0].dy);
    for (int i = 1; i < adjustedPts.length / 2; i++) {
      hlPath.lineTo(adjustedPts[i].dx, adjustedPts[i].dy);
    }
    canvas.drawPath(hlPath, highlightStroke);

    canvas.restore();
  }

  void _renderBush(Canvas canvas) {
    final rng = math.Random(_seed);
    final sway = math.sin(age * 2.5 + _wobblePhase) * 2.0;
    
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.rotate(sway * math.pi / 180);
    canvas.translate(-size.x / 2, -size.y);

    // Soft ground contact shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    canvas.drawOval(Rect.fromLTWH(size.x * 0.05, size.y - 4, size.x * 0.9, 7), shadowPaint);

    // Low-lying dark base shadow foliage
    final basePaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawCircle(Offset(size.x * 0.22, size.y * 0.65), size.x * 0.28, basePaint);
    canvas.drawCircle(Offset(size.x * 0.78, size.y * 0.65), size.x * 0.28, basePaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.45), size.x * 0.36, basePaint);

    // Fluffy round main green bush foliage
    final mainPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(size.x * 0.25, size.y * 0.6), size.x * 0.25, mainPaint);
    canvas.drawCircle(Offset(size.x * 0.75, size.y * 0.6), size.x * 0.25, mainPaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.4), size.x * 0.33, mainPaint);

    // Top bright leaf highlights
    final highlightPaint = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.38), size.x * 0.18, highlightPaint);
    canvas.drawCircle(Offset(size.x * 0.65, size.y * 0.38), size.x * 0.18, highlightPaint);
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.28), size.x * 0.2, highlightPaint);

    // Little round berries/flowers
    final flowerPaint = Paint()..color = (rng.nextBool()) ? const Color(0xFFE91E63) : const Color(0xFFFFCA28);
    for (int i = 0; i < 5; i++) {
      final fx = size.x * (0.2 + (i * 0.15));
      final fy = size.y * (0.35 + (i % 2) * 0.2);
      canvas.drawCircle(Offset(fx, fy), 2.5, flowerPaint);
    }

    canvas.restore();
  }

  void _renderBird(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    canvas.save();

    // 1. Pterodactyl Body & Head Base
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Head with sharp beak & backward crest
    final headPath = Path()
      ..moveTo(w * 0.15, h * 0.45) // Beak tip (facing left towards player)
      ..lineTo(w * 0.35, h * 0.35) // Top snout
      ..lineTo(w * 0.55, h * 0.2)  // Head crest top spike
      ..quadraticBezierTo(w * 0.42, h * 0.4, w * 0.38, h * 0.52) // Head back
      ..lineTo(w * 0.15, h * 0.48) // Lower beak
      ..close();
    canvas.drawPath(headPath, bodyPaint);

    // Beak inner highlight
    final beakPaint = Paint()..color = const Color(0xFFFFB300);
    final beakPath = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..lineTo(w * 0.28, h * 0.4)
      ..lineTo(w * 0.28, h * 0.48)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Glowing menacing eye
    canvas.drawCircle(Offset(w * 0.32, h * 0.41), 3.0, Paint()..color = const Color(0xFFFFEB3B));
    canvas.drawCircle(Offset(w * 0.31, h * 0.41), 1.4, Paint()..color = Colors.black);

    // Sleek Torso
    final torsoPath = Path()
      ..moveTo(w * 0.38, h * 0.5)
      ..quadraticBezierTo(w * 0.55, h * 0.4, w * 0.72, h * 0.52)
      ..quadraticBezierTo(w * 0.55, h * 0.68, w * 0.38, h * 0.58)
      ..close();
    canvas.drawPath(torsoPath, bodyPaint);

    // 2. Leather Bat Wings with 2-Frame Flap Animation!
    final wingY = _birdFrame == 0 ? -h * 0.45 : h * 0.45;
    final wingMidY = _birdFrame == 0 ? -h * 0.15 : h * 0.2;

    final wingPath = Path()
      ..moveTo(w * 0.48, h * 0.48)
      ..quadraticBezierTo(w * 0.52, wingY, w * 0.82, wingY * 0.8) // Wing bone top
      ..quadraticBezierTo(w * 0.68, wingMidY, w * 0.58, h * 0.55) // Outer membrane arch
      ..quadraticBezierTo(w * 0.52, h * 0.58, w * 0.48, h * 0.48)
      ..close();

    final wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFAB47BC), const Color(0xFF6A1B9A)],
      ).createShader(Rect.fromLTWH(w * 0.4, -h, w * 0.5, h * 2));

    canvas.drawPath(wingPath, wingPaint);

    // Wing bone finger lines
    final bonePaint = Paint()
      ..color = const Color(0xFFE1BEE7).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.48, h * 0.48), Offset(w * 0.82, wingY * 0.8), bonePaint);
    canvas.drawLine(Offset(w * 0.55, h * 0.38), Offset(w * 0.68, wingMidY), bonePaint);

    canvas.restore();
  }

  void _renderPillar(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 1. Soft Ground Shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.30);
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h - 5, w * 0.9, 8), shadowPaint);

    // 2. Base Pillar Shaft (Stone / Pipe Column)
    final shaftWidth = w * 0.72;
    final shaftLeft = (w - shaftWidth) / 2;
    final shaftRect = Rect.fromLTWH(shaftLeft, 14, shaftWidth, h - 26);

    final shaftGradient = const LinearGradient(
      colors: [
        Color(0xFFB0BEC5), // Lit left face
        Color(0xFF78909C), // Mid shaft body
        Color(0xFF455A64), // Shadowed right face
      ],
      stops: [0.0, 0.45, 1.0],
    );
    canvas.drawRect(shaftRect, Paint()..shader = shaftGradient.createShader(shaftRect));

    // 3. Fluted Vertical Grooves / Pipe Lines
    final groovePaint = Paint()
      ..color = const Color(0xFF37474F).withValues(alpha: 0.5)
      ..strokeWidth = 2.0;
    final grooveHlPaint = Paint()
      ..color = const Color(0xFFECEFF1).withValues(alpha: 0.6)
      ..strokeWidth = 1.2;

    for (double gx = shaftLeft + 8; gx < shaftLeft + shaftWidth - 6; gx += 12) {
      canvas.drawLine(Offset(gx, 15), Offset(gx, h - 13), groovePaint);
      canvas.drawLine(Offset(gx + 1.5, 15), Offset(gx + 1.5, h - 13), grooveHlPaint);
    }

    // 4. Capital Top Cap & Base Trim (Classic Column / Pipe Lip)
    final capRect = Rect.fromLTWH(0, 0, w, 16);
    final capGradient = const LinearGradient(
      colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE), Color(0xFF37474F)],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient.createShader(capRect),
    );

    final baseRect = Rect.fromLTWH(0, h - 16, w, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(3)),
      Paint()..shader = capGradient.createShader(baseRect),
    );

    // Capital & Base Trim Highlights
    final capHlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(2, 2), Offset(w - 2, 2), capHlPaint);
    canvas.drawLine(Offset(2, h - 14), Offset(w - 2, h - 14), capHlPaint);
  }

  void _renderCeilingPipe(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 1. Pipe Shaft (Top to Bottom)
    final shaftWidth = w * 0.76;
    final shaftLeft = (w - shaftWidth) / 2;
    final shaftRect = Rect.fromLTWH(shaftLeft, 0, shaftWidth, h - 18);

    final shaftGradient = const LinearGradient(
      colors: [
        Color(0xFF4CAF50), // Bright green pipe highlight
        Color(0xFF2E7D32), // Deep green pipe body
        Color(0xFF1B5E20), // Dark green pipe shadow
      ],
      stops: [0.0, 0.5, 1.0],
    );
    canvas.drawRect(shaftRect, Paint()..shader = shaftGradient.createShader(shaftRect));

    // 2. Vertical Pipe Shine Line
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(shaftLeft + 6, 0), Offset(shaftLeft + 6, h - 18), shinePaint);

    // 3. Hanging Pipe Rim Cap at Bottom Lip
    final capRect = Rect.fromLTWH(0, h - 22, w, 22);
    final capGradient = const LinearGradient(
      colors: [Color(0xFF66BB6A), Color(0xFF388E3C), Color(0xFF1B5E20)],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(4)),
      Paint()..shader = capGradient.createShader(capRect),
    );

    // Cap Highlights & Rim Border
    final capBorderPaint = Paint()
      ..color = const Color(0xFF0D5314)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(4)), capBorderPaint);

    final capHlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(4, h - 20), Offset(w - 4, h - 20), capHlPaint);
  }

  void _renderPipePair(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final shaftWidth = w * 0.76;
    final shaftLeft = (w - shaftWidth) / 2;

    final gTop = liveGapTopY > 0 ? liveGapTopY : gapTopY;
    final gBottom = liveGapBottomY > 0 ? liveGapBottomY : gapBottomY;

    final shaftGradient = const LinearGradient(
      colors: [
        Color(0xFF4CAF50), // Bright green pipe highlight
        Color(0xFF2E7D32), // Deep green pipe body
        Color(0xFF1B5E20), // Dark green pipe shadow
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final capGradient = const LinearGradient(
      colors: [Color(0xFF66BB6A), Color(0xFF388E3C), Color(0xFF1B5E20)],
    );

    final capBorderPaint = Paint()
      ..color = const Color(0xFF0D5314)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final capHlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 3.0;

    // --- 1. TOP PIPE (Hanging down from top of screen y=0 to gTop) ---
    if (gTop > 15) {
      final topShaftRect = Rect.fromLTWH(shaftLeft, 0, shaftWidth, math.max(0.0, gTop - 18));
      canvas.drawRect(topShaftRect, Paint()..shader = shaftGradient.createShader(topShaftRect));
      canvas.drawLine(Offset(shaftLeft + 6, 0), Offset(shaftLeft + 6, math.max(0.0, gTop - 18)), shinePaint);

      // Top pipe bottom rim cap
      final topCapRect = Rect.fromLTWH(0, gTop - 22, w, 22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(topCapRect, const Radius.circular(4)),
        Paint()..shader = capGradient.createShader(topCapRect),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(topCapRect, const Radius.circular(4)), capBorderPaint);
      canvas.drawLine(Offset(4, gTop - 20), Offset(w - 4, gTop - 20), capHlPaint);
    }

    // --- 2. BOTTOM PIPE (Rising up from ground y=h to gBottom) ---
    if (gBottom < h - 15) {
      // Bottom pipe top rim cap
      final bottomCapRect = Rect.fromLTWH(0, gBottom, w, 22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bottomCapRect, const Radius.circular(4)),
        Paint()..shader = capGradient.createShader(bottomCapRect),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(bottomCapRect, const Radius.circular(4)), capBorderPaint);
      canvas.drawLine(Offset(4, gBottom + 2), Offset(w - 4, gBottom + 2), capHlPaint);

      final bottomShaftRect = Rect.fromLTWH(shaftLeft, gBottom + 22, shaftWidth, math.max(0.0, h - (gBottom + 22)));
      canvas.drawRect(bottomShaftRect, Paint()..shader = shaftGradient.createShader(bottomShaftRect));
      canvas.drawLine(Offset(shaftLeft + 6, gBottom + 22), Offset(shaftLeft + 6, h), shinePaint);

      // Soft Ground Shadow
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.30);
      canvas.drawOval(Rect.fromLTWH(w * 0.05, h - 4, w * 0.9, 8), shadowPaint);
    }
  }

  /// 🌋 Renders 1 or 2 clustered volcanic magma vents matching reference image
  void _renderLavaPit(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final rng = math.Random(_seed);
    final isDouble = w > 65;
    final ventCount = isDouble ? 2 : 1;

    final ventXs = isDouble ? [w * 0.32, w * 0.72] : [w * 0.50];
    final ventWidths = isDouble ? [w * 0.46, w * 0.44] : [w * 0.85];

    // 1. Dynamic Ground Fire Shimmer & Heat Glow
    final glowPulse = 0.85 + math.sin(age * 8.0) * 0.15;
    final glowShader = RadialGradient(
      center: Alignment.center,
      colors: [
        const Color(0xFFFF9100).withValues(alpha: 0.55 * glowPulse),
        const Color(0xFFFF3D00).withValues(alpha: 0.30 * glowPulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCenter(center: Offset(w / 2, h - 4), width: w * 1.5, height: 30));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h - 4), width: w * 1.5, height: 30), Paint()..shader = glowShader);

    // 2. Basalt Volcanic Crater Mounds & Radiating Fire Veins
    for (int v = 0; v < ventCount; v++) {
      final vx = ventXs[v];
      final vw = ventWidths[v];
      final vLeft = vx - vw / 2;
      final vRight = vx + vw / 2;
      final moundHeight = 14.0 + (rng.nextDouble() * 4.0);

      // Radiating Glowing Fire Cracks on Ground
      final crackPaint = Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      for (int c = 0; c < 4; c++) {
        final ang = (c / 4.0) * math.pi + 0.1;
        final cLen = vw * (0.45 + (c % 2) * 0.2);
        canvas.drawLine(
          Offset(vx, h - 2),
          Offset(vx + math.cos(ang) * cLen, h - 2 + math.sin(ang) * 6),
          crackPaint,
        );
      }

      // Dark Jagged Basalt Mound Crater Body
      final moundPath = Path()
        ..moveTo(vLeft - 8, h)
        ..lineTo(vLeft - 2, h - moundHeight * 0.6)
        ..lineTo(vx - 10, h - moundHeight)
        ..lineTo(vx + 10, h - moundHeight)
        ..lineTo(vRight + 2, h - moundHeight * 0.6)
        ..lineTo(vRight + 8, h)
        ..close();

      final moundShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF3E2723), // Dark basalt crater rim
          Color(0xFF211512),
          Color(0xFF140D0B),
        ],
      ).createShader(Rect.fromLTWH(vLeft - 8, h - moundHeight, vw + 16, moundHeight));
      canvas.drawPath(moundPath, Paint()..shader = moundShader);

      // Molten Glowing Crater Core Vent Opening
      final craterRimRect = Rect.fromCenter(center: Offset(vx, h - moundHeight + 2), width: vw * 0.55, height: 7);
      final craterCoreShader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFFFFF8D),
          Color(0xFFFF9100),
          Color(0xFFFF3D00),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(craterRimRect);
      canvas.drawOval(craterRimRect, Paint()..shader = craterCoreShader);
    }

    // 3. Dynamic Roaring Fire Flames & Magma Eruption Column
    for (int v = 0; v < ventCount; v++) {
      final vx = ventXs[v];
      final vw = ventWidths[v];
      final vh = h - 8.0 - (v * 12.0); // Flame column height
      final topY = h - vh;
      final halfW = vw * 0.26;

      // Multi-harmonic dancing fire flame physics
      final fPhase = age * (12.0 + v * 3.0) + _wobblePhase;
      final wave1 = math.sin(fPhase) * 4.0;
      final wave2 = math.cos(fPhase * 1.4) * 3.0;

      // Outer Flickering Roaring Fire Jet
      final outerFlamePath = Path()
        ..moveTo(vx - halfW - 3, h - 8)
        ..cubicTo(
          vx - halfW + wave1, h - vh * 0.35,
          vx - halfW * 0.7 + wave2, topY + vh * 0.3,
          vx + wave1 * 0.5, topY,
        )
        ..cubicTo(
          vx + halfW * 0.7 - wave2, topY + vh * 0.3,
          vx + halfW - wave1, h - vh * 0.35,
          vx + halfW + 3, h - 8,
        )
        ..close();

      final outerFlameShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFD54F), // Bright fiery tip
          Color(0xFFFF6D00), // Blazing solar orange mid
          Color(0xFFD50000), // Crimson flame base
          Color(0xFF7F0000),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(vx - halfW - 6, topY - 4, halfW * 2 + 12, vh + 8));
      canvas.drawPath(outerFlamePath, Paint()..shader = outerFlameShader);

      // Inner Licking Fire Core (Vibrant Yellow-Orange)
      final innerFlamePath = Path()
        ..moveTo(vx - halfW * 0.6, h - 8)
        ..cubicTo(
          vx - halfW * 0.4 + wave1, h - vh * 0.4,
          vx - halfW * 0.3 + wave2, topY + vh * 0.25,
          vx + wave1 * 0.3, topY + 4,
        )
        ..cubicTo(
          vx + halfW * 0.3 - wave2, topY + vh * 0.25,
          vx + halfW * 0.4 - wave1, h - vh * 0.4,
          vx + halfW * 0.6, h - 8,
        )
        ..close();

      final innerFlameShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFFFFF), // White flame core
          Color(0xFFFFFF8D), // White-gold fire
          Color(0xFFFFAB00), // Orange fire
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(vx - halfW * 0.6, topY + 2, halfW * 1.2, vh));
      canvas.drawPath(innerFlamePath, Paint()..shader = innerFlameShader);

      // White-Hot Intense Fire Spine
      canvas.drawLine(
        Offset(vx, h - 8),
        Offset(vx + wave1 * 0.4, topY + 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // 4. Leaping Fire Sparks & Fiery Globules leaping into the air
      final sparkYellow = Paint()..color = const Color(0xFFFFFF8D);
      final sparkOrange = Paint()..color = const Color(0xFFFF9100);
      final sparkRed = Paint()..color = const Color(0xFFFF3D00);

      for (int p = 0; p < 6; p++) {
        final cycle = (age * 3.4 + p * 0.30 + v) % 1.2;
        final prog = cycle / 1.2;
        final dir = (p % 2 == 0) ? 1.0 : -1.0;
        final spreadX = vx + dir * (6.0 + p * 3.8) * prog;
        final sparkY = topY - (16.0 * math.sin(prog * math.pi)) + prog * prog * 24.0;
        final r = (2.6 * (1.0 - prog)).clamp(0.6, 2.6);
        final pPaint = (p % 3 == 0) ? sparkYellow : (p % 2 == 0) ? sparkOrange : sparkRed;
        canvas.drawCircle(Offset(spreadX, sparkY), r, pPaint);
      }

      // 5. Billowing Rising Smoke Plumes from Flame Apex
      final smokePaint = Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.35);

      for (int s = 0; s < 3; s++) {
        final sCycle = (age * 1.8 + s * 0.4 + v) % 1.4;
        final sProg = sCycle / 1.4;
        final sX = vx + math.sin(age * 3.0 + s) * (4.0 + sProg * 12.0);
        final sY = topY - 8.0 - sProg * 32.0;
        final sR = 5.0 + sProg * 10.0;
        final sAlpha = (1.0 - sProg) * 0.35;
        canvas.drawCircle(Offset(sX, sY), sR, smokePaint..color = const Color(0xFF37474F).withValues(alpha: sAlpha));
      }
    }
  }
}
