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
        if (game.biomeManager.effectiveBiome.name == 'DESERT') {
          game.particlePool.emitDesertNearMiss(position + size / 2);
        } else {
          game.particlePool.emitNearMiss(position + size / 2);
        }
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

    // Smooth continuous 60fps wing flap physics
    final flapPhase = math.sin(age * 18.0);
    final wingFlexY = flapPhase * (h * 0.48);
    final wingTipFlexY = flapPhase * (h * 0.65);

    // 1. Far Back Wing (Darker depth layer)
    final backWingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF381452), const Color(0xFF1E0A2E)],
      ).createShader(Rect.fromLTWH(w * 0.4, -h * 0.8, w * 0.6, h * 2.2));

    final backWingPath = Path()
      ..moveTo(w * 0.52, h * 0.45)
      ..cubicTo(w * 0.60, h * 0.45 - wingFlexY * 0.8, w * 0.76, h * 0.40 - wingTipFlexY * 0.8, w * 0.90, h * 0.35 - wingTipFlexY * 0.8)
      ..quadraticBezierTo(w * 0.82, h * 0.50 - wingFlexY * 0.4, w * 0.74, h * 0.54)
      ..quadraticBezierTo(w * 0.66, h * 0.52 - wingFlexY * 0.2, w * 0.58, h * 0.58)
      ..close();
    canvas.drawPath(backWingPath, backWingPaint);

    // 2. Main Cute Bat Body & Belly
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF512DA8), Color(0xFF311B92), Color(0xFF1A0A3A)],
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.25, w * 0.65, h * 0.65));

    // Torso & Hind body
    final bodyPath = Path()
      ..moveTo(w * 0.32, h * 0.38)
      ..cubicTo(w * 0.58, h * 0.30, w * 0.75, h * 0.42, w * 0.72, h * 0.64)
      ..cubicTo(w * 0.70, h * 0.82, w * 0.48, h * 0.86, w * 0.32, h * 0.72)
      ..cubicTo(w * 0.24, h * 0.65, w * 0.22, h * 0.45, w * 0.32, h * 0.38)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Soft Violet/Lilac Belly Patch
    final bellyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
      ).createShader(Rect.fromLTWH(w * 0.35, h * 0.48, w * 0.28, h * 0.28));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.46, h * 0.60), width: w * 0.24, height: h * 0.22),
      bellyPaint,
    );

    // Tiny tucked feet talons
    final footPaint = Paint()..color = const Color(0xFFD1C4E9);
    canvas.drawCircle(Offset(w * 0.56, h * 0.74), 2.2, footPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.72), 2.2, footPaint);

    // 3. Bat Head, Pointy Ears & Expressive Cute Face
    final headCenter = Offset(w * 0.28, h * 0.48);
    canvas.drawCircle(headCenter, w * 0.16, bodyPaint);

    // Left & Right Pointy Bat Ears
    final earPaint = Paint()..color = const Color(0xFF311B92);
    final earInnerPaint = Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.85);

    // Front ear (facing viewer)
    final ear1 = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.18, h * 0.14)
      ..lineTo(w * 0.32, h * 0.32)
      ..close();
    canvas.drawPath(ear1, earPaint);

    final ear1Inner = Path()
      ..moveTo(w * 0.23, h * 0.34)
      ..lineTo(w * 0.20, h * 0.18)
      ..lineTo(w * 0.30, h * 0.32)
      ..close();
    canvas.drawPath(ear1Inner, earInnerPaint);

    // Back ear
    final ear2 = Path()
      ..moveTo(w * 0.34, h * 0.34)
      ..lineTo(w * 0.36, h * 0.16)
      ..lineTo(w * 0.44, h * 0.36)
      ..close();
    canvas.drawPath(ear2, earPaint);

    // Cute Snub Nose & Mouth
    final nosePaint = Paint()..color = const Color(0xFFFF80AB);
    canvas.drawCircle(Offset(w * 0.18, h * 0.50), 2.0, nosePaint);

    // Tiny Cute Vampire Fangs
    final fangPaint = Paint()..color = Colors.white;
    final fangPath = Path()
      ..moveTo(w * 0.17, h * 0.54)
      ..lineTo(w * 0.19, h * 0.60)
      ..lineTo(w * 0.21, h * 0.54)
      ..close();
    canvas.drawPath(fangPath, fangPaint);

    // Big Glowing Amber Eyes with Specular Sparkle Glint
    final eyeOuter = Paint()..color = const Color(0xFFFFD54F);
    final eyePupil = Paint()..color = const Color(0xFF1A0A3A);
    final eyeGlint = Paint()..color = Colors.white;

    // Left eye (closer, bigger)
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.22, h * 0.44), width: 7.0, height: 8.5), eyeOuter);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.21, h * 0.44), width: 4.5, height: 6.0), eyePupil);
    canvas.drawCircle(Offset(w * 0.20, h * 0.42), 1.5, eyeGlint);
    canvas.drawCircle(Offset(w * 0.23, h * 0.46), 0.7, eyeGlint);

    // Soft Blush Cheek
    canvas.drawCircle(
      Offset(w * 0.26, h * 0.54),
      3.0,
      Paint()..color = const Color(0xFFFF4081).withValues(alpha: 0.45),
    );

    // 4. Foreground Scalloped Leather Wing (Articulated with smooth Béziers)
    final foreWingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFBA68C8), const Color(0xFF7B1FA2), const Color(0xFF4A148C)],
      ).createShader(Rect.fromLTWH(w * 0.35, -h * 0.8, w * 0.65, h * 2.2));

    final wingOrigin = Offset(w * 0.44, h * 0.46);
    final wingElbow = Offset(w * 0.56, h * 0.40 + wingFlexY);
    final wingTip = Offset(w * 0.86, h * 0.30 + wingTipFlexY);

    final foreWingPath = Path()
      ..moveTo(wingOrigin.dx, wingOrigin.dy)
      ..quadraticBezierTo(wingElbow.dx, wingElbow.dy, wingTip.dx, wingTip.dy) // Top wing bone
      ..quadraticBezierTo(w * 0.76, h * 0.48 + wingFlexY * 0.6, w * 0.68, h * 0.64 + wingFlexY * 0.4) // Scallop 1
      ..quadraticBezierTo(w * 0.60, h * 0.56 + wingFlexY * 0.3, w * 0.52, h * 0.66) // Scallop 2
      ..quadraticBezierTo(w * 0.48, h * 0.58, wingOrigin.dx, wingOrigin.dy) // Scallop 3
      ..close();
    canvas.drawPath(foreWingPath, foreWingPaint);

    // Wing Bone Finger Struts & Highlights
    final wingBonePaint = Paint()
      ..color = const Color(0xFFE1BEE7).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Main forearm bone
    canvas.drawLine(wingOrigin, wingElbow, wingBonePaint);
    canvas.drawLine(wingElbow, wingTip, wingBonePaint);

    // Thumb claw
    canvas.drawLine(wingElbow, Offset(wingElbow.dx - 2, wingElbow.dy - 3), wingBonePaint);

    // Webbing rib struts
    final ribPaint = Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: 0.60)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(wingElbow, Offset(w * 0.68, h * 0.64 + wingFlexY * 0.4), ribPaint);
    canvas.drawLine(wingOrigin, Offset(w * 0.52, h * 0.66), ribPaint);

    // Tiny magical night trail sparkles behind bat
    final trailSparkle = Paint()..color = const Color(0xFFE1BEE7).withValues(alpha: 0.7);
    final t1 = (age * 6.0) % 1.0;
    canvas.drawCircle(Offset(w * 0.88 + t1 * 12.0, h * 0.36 + math.sin(age * 8.0) * 4.0), 1.2 * (1.0 - t1), trailSparkle);

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

  /// 🌋 Renders fluid, bubbling molten lava with organic splashing magma and basalt rim
  void _renderLavaPit(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 1. Ambient Pulsing Thermal Magma Glow
    final glowPulse = 0.85 + math.sin(age * 4.0) * 0.15;
    final glowRect = Rect.fromCenter(
      center: Offset(w * 0.5, h - 6),
      width: w * 1.6,
      height: 32,
    );
    final glowShader = RadialGradient(
      colors: [
        Color(0x66FF3D00).withValues(alpha: 0.55 * glowPulse),
        Color(0x33FF9100).withValues(alpha: 0.30 * glowPulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(glowRect);
    canvas.drawOval(glowRect, Paint()..shader = glowShader);

    // 2. Basalt Crust Pit Reservoir (Dark cooled magma rock rim with rounded organic edges)
    final basaltPath = Path()
      ..moveTo(2, h)
      ..quadraticBezierTo(w * 0.15, h - 12, w * 0.35, h - 9)
      ..quadraticBezierTo(w * 0.5, h - 13, w * 0.65, h - 9)
      ..quadraticBezierTo(w * 0.85, h - 12, w - 2, h)
      ..close();

    final basaltShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF2E1C14), // Charred volcanic rock
        Color(0xFF1B0E09),
        Color(0xFF0F0805),
      ],
    ).createShader(Rect.fromLTWH(0, h - 16, w, 16));
    canvas.drawPath(basaltPath, Paint()..shader = basaltShader);

    // Basalt jagged glowing crack lines
    final crackPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.80)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.16, h - 3), Offset(w * 0.28, h - 8), crackPaint);
    canvas.drawLine(Offset(w * 0.72, h - 4), Offset(w * 0.84, h - 8), crackPaint);

    // 3. Fluid Liquid Magma Pool Surface (Viscous undulating molten wave)
    final magmaPoolPath = Path()..moveTo(w * 0.10, h);
    for (double x = w * 0.10; x <= w * 0.90; x += 4.0) {
      final normX = (x - w * 0.10) / (w * 0.80);
      final wave = math.sin(age * 5.5 + normX * math.pi * 3) * 1.8;
      final y = h - 5 - math.sin(normX * math.pi) * 3.5 + wave;
      magmaPoolPath.lineTo(x, y);
    }
    magmaPoolPath.lineTo(w * 0.90, h);
    magmaPoolPath.close();

    final magmaShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFF176), // White-hot molten surface
        Color(0xFFFF9100), // Blazing liquid orange
        Color(0xFFD50000), // Viscous crimson magma
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(w * 0.10, h - 14, w * 0.80, 14));
    canvas.drawPath(magmaPoolPath, Paint()..shader = magmaShader);

    // 4. Fluid Magma Bubbles (Organic popping liquid domes)
    for (int b = 0; b < 3; b++) {
      final bubbleProgress = (age * (1.8 + b * 0.6) + b * 0.35) % 1.0;
      final bx = w * (0.26 + b * 0.24);
      final by = h - 6 - (bubbleProgress * 7.0);
      final br = (2.5 + b * 0.8) * math.sin(bubbleProgress * math.pi);
      if (br > 0.5) {
        canvas.drawCircle(Offset(bx, by), br, Paint()..color = const Color(0xFFFF9100));
        canvas.drawCircle(Offset(bx, by - br * 0.2), br * 0.55, Paint()..color = const Color(0xFFFFFDE7));
      }
    }

    // 5. Dynamic Liquid Magma Geyser Splash (Organic fluid splash tendrils)
    final splashHeight = (h * 0.65) + math.sin(age * 6.0) * 5.0;
    final spoutApexX = w * 0.5 + math.sin(age * 3.5) * 3.0;
    final spoutApexY = h - splashHeight;

    final fluidSpoutPath = Path()
      ..moveTo(w * 0.30, h - 5)
      ..cubicTo(
        w * 0.36 + math.sin(age * 7.0) * 3.5, h - splashHeight * 0.45,
        spoutApexX - 5 + math.cos(age * 8.0) * 2.5, spoutApexY + splashHeight * 0.25,
        spoutApexX, spoutApexY,
      )
      ..cubicTo(
        spoutApexX + 5 - math.cos(age * 8.0) * 2.5, spoutApexY + splashHeight * 0.25,
        w * 0.64 - math.sin(age * 7.0) * 3.5, h - splashHeight * 0.45,
        w * 0.70, h - 5,
      )
      ..close();

    final fluidSpoutShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFF9C4), // White-hot liquid tip
        Color(0xFFFFAB00), // Vibrant amber molten liquid
        Color(0xFFFF3D00), // Blazing red-orange magma
        Color(0xFFB71C1C), // Deep crimson base
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(w * 0.25, spoutApexY, w * 0.5, splashHeight));
    canvas.drawPath(fluidSpoutPath, Paint()..shader = fluidSpoutShader);

    // Inner bright hot fluid stream
    final innerFluidPath = Path()
      ..moveTo(w * 0.40, h - 5)
      ..quadraticBezierTo(
        spoutApexX + math.sin(age * 6.0) * 1.5, h - splashHeight * 0.5,
        spoutApexX, spoutApexY + 3,
      )
      ..quadraticBezierTo(
        spoutApexX - math.sin(age * 6.0) * 1.5, h - splashHeight * 0.5,
        w * 0.60, h - 5,
      )
      ..close();
    canvas.drawPath(
      innerFluidPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFF59D),
            Color(0xFFFF9100),
          ],
        ).createShader(Rect.fromLTWH(w * 0.38, spoutApexY + 3, w * 0.24, splashHeight - 3)),
    );

    // 6. Flying Liquid Magma Droplets & Embers (Arching in gravity)
    final sparkYellow = Paint()..color = const Color(0xFFFFF59D);
    final sparkOrange = Paint()..color = const Color(0xFFFF9100);
    final sparkRed = Paint()..color = const Color(0xFFFF3D00);

    for (int p = 0; p < 7; p++) {
      final pProg = ((age * 2.5 + p * 0.16) % 1.0);
      final side = (p % 2 == 0) ? 1.0 : -1.0;
      final px = spoutApexX + side * (p * 3.5 + 7.0) * pProg;
      final py = spoutApexY - (16.0 * math.sin(pProg * math.pi)) + (pProg * pProg * 24.0);
      final pr = (2.2 * (1.0 - pProg)).clamp(0.6, 2.2);
      final pPaint = (p % 3 == 0) ? sparkYellow : (p % 2 == 0) ? sparkOrange : sparkRed;
      canvas.drawCircle(Offset(px, py), pr, pPaint);
    }

    // 7. Billowing Ash & Smoke Wisps
    for (int s = 0; s < 3; s++) {
      final sProg = (age * 1.4 + s * 0.35) % 1.0;
      final sx = spoutApexX + math.sin(age * 2.5 + s) * (5.0 + sProg * 12.0);
      final sy = spoutApexY - 6.0 - sProg * 26.0;
      final sr = 4.0 + sProg * 7.0;
      final sAlpha = (1.0 - sProg) * 0.28;
      canvas.drawCircle(
        Offset(sx, sy),
        sr,
        Paint()..color = const Color(0xFF455A64).withValues(alpha: sAlpha),
      );
    }
  }
}
