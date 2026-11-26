import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import '../game/game_state.dart';
import '../game/hazard_contact.dart';
import '../utils/vibration_util.dart';

/// The cluster owns individual stones and has no collision shape of its own.
class FallingStone extends PositionComponent with HasGameReference<DinoGame> {
  final double initialSpeedX;
  final int stoneCount;
  final math.Random random;
  FallingStone({
    required this.initialSpeedX,
    this.stoneCount = 1,
    math.Random? random,
  }) : random = random ?? math.Random();

  @override
  Future<void> onLoad() async {
    var offset = 0.0;
    for (var i = 0; i < stoneCount; i++) {
      final diameter = 52 + random.nextDouble() * 18;
      await add(
        FallingRock(
          diameter: diameter,
          offsetX: offset,
          warningDuration: .75 + i * .25,
        ),
      );
      offset += diameter + 75;
    }
    size = Vector2(offset, 70);
    position = Vector2(
      math.min(
        game.size.x - 100,
        game.player.position.x + game.player.size.x + 200,
      ),
      0,
    );
    priority = 6;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    // Lock the telegraphed impact point in front of Dino until touchdown.
    if (children.whereType<FallingRock>().every(
      (rock) => rock.phase == RockPhase.landed,
    )) {
      position.x -= game.speedManager.currentSpeed * dt;
    }
    if (position.x + size.x < -40 || children.isEmpty) removeFromParent();
  }
}

enum RockPhase { warning, falling, landed }

class FallingRock extends PositionComponent
    with CollisionCallbacks, HasGameReference<DinoGame>, HazardContact {
  @override
  HazardMaterial get impactMaterial => HazardMaterial.stone;
  @override
  bool get impactReady => phase != RockPhase.warning;
  final double diameter;
  final double offsetX;
  final double warningDuration;
  RockPhase phase = RockPhase.warning;
  double age = 0;
  double velocityY = 0;
  late CircleHitbox hurtbox;
  FallingRock({
    required this.diameter,
    required this.offsetX,
    this.warningDuration = .75,
  }) : super(size: Vector2.all(diameter));

  @override
  Future<void> onLoad() async {
    position = Vector2(offsetX, -diameter);
    hurtbox = CircleHitbox(
      radius: diameter * .36,
      position: Vector2.all(diameter * .14),
      collisionType: CollisionType.inactive,
    );
    await add(hurtbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    age += dt;
    if (phase == RockPhase.warning && age >= warningDuration) {
      phase = RockPhase.falling;
      hurtbox.collisionType = CollisionType.active;
    }
    if (phase == RockPhase.falling) {
      velocityY += 700 * dt;
      position.y += velocityY * dt;
      final floor = game.ground.groundY - diameter;
      if (position.y >= floor) {
        position.y = floor;
        phase = RockPhase.landed;
        parent!.add(
          ImpactCrater(diameter: diameter)
            ..position = Vector2(offsetX + diameter / 2, game.ground.groundY)
            ..priority = -1,
        );
        GameVibration.lightImpact();
        game.triggerShake(duration: .10, intensity: 1.8);
        game.particlePool.emitJumpDust(
          absolutePosition + Vector2(diameter / 2, diameter),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final floor = game.ground.groundY - position.y;
    final proximity = (1 - (floor - diameter) / 360).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(diameter / 2, floor),
        width: diameter * (1.25 - proximity * .3),
        height: 10,
      ),
      Paint()
        ..color = const Color(0xFF2E1A14).withValues(alpha: .16 + proximity * .28),
    );
    if (phase == RockPhase.warning) {
      final pulse = 0.55 + math.sin(age * 14.0) * 0.45;
      final outerRing = Rect.fromCenter(
        center: Offset(diameter / 2, floor - 2),
        width: diameter + 16,
        height: 14,
      );
      canvas.drawOval(
        outerRing,
        Paint()
          ..color = Color(0xFFFF8F2B).withValues(alpha: .28 + pulse * .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.drawOval(
        outerRing.deflate(6),
        Paint()
          ..color = const Color(0xFFFFE082).withValues(alpha: .4 + pulse * .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Reentry wind-streak wake behind falling boulder.
    if (phase == RockPhase.falling) {
      final wakeRect = Rect.fromLTWH(diameter * .18, -diameter * .9, diameter * .64, diameter);
      canvas.drawPath(
        Path()
          ..moveTo(diameter * .18, diameter * .35)
          ..lineTo(diameter * .50, -diameter * .95)
          ..lineTo(diameter * .82, diameter * .35)
          ..close(),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0x99FF9436), Color(0x00FF5722)],
          ).createShader(wakeRect),
      );
    }

    canvas.save();
    canvas.translate(diameter / 2, diameter / 2);
    canvas.rotate(phase == RockPhase.falling ? age * 1.8 : 0);
    final radius = diameter / 2;
    final pts = <Offset>[];
    final path = Path();
    for (var i = 0; i < 9; i++) {
      final a = i * (math.pi * 2 / 9);
      final r = radius * (i % 3 == 0 ? 1.0 : (i.isEven ? .91 : .84));
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      pts.add(pt);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7BD84),
            Color(0xFFA86F48),
            Color(0xFF663F2B),
            Color(0xFF39231B),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    // Shaded rock facets on lower half + crater pit + crisp crack highlight.
    canvas.drawPath(
      Path()
        ..moveTo(-radius * .2, 0)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..lineTo(pts[3].dx, pts[3].dy)
        ..close(),
      Paint()..color = const Color(0x4021110C),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-radius * .26, -radius * .20), width: radius * .36, height: radius * .28),
      Paint()..color = const Color(0x453B2117),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-radius * .45, -radius * .22)
        ..lineTo(-radius * .04, radius * .06)
        ..lineTo(radius * .24, radius * .36),
      Paint()
        ..color = const Color(0xFF472B1F)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(pts[5].dx, pts[5].dy)
        ..lineTo(pts[6].dx, pts[6].dy)
        ..lineTo(pts[7].dx, pts[7].dy),
      Paint()
        ..color = const Color(0x88FFF0CC)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }
}

/// A persistent scorched impact scar travels with its landed boulder.
class ImpactCrater extends PositionComponent {
  final double diameter;
  ImpactCrater({required this.diameter});
  @override
  void render(Canvas canvas) {
    final outer = Rect.fromCenter(
      center: const Offset(0, 3),
      width: diameter * 1.85,
      height: 25,
    );
    canvas.drawOval(
      outer,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF281A18), Color(0xFF7B492D), Color(0x007B492D)],
          stops: [0.35, 0.78, 1.0],
        ).createShader(outer),
    );
    canvas.drawOval(outer.deflate(4), Paint()..color = const Color(0xFF33211E));
    canvas.drawArc(
      outer.deflate(2),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFFE7AA6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    // Radial fracture lines & shattered stone splinters.
    for (var i = 0; i < 6; i++) {
      final x = (i - 2.5) * diameter * .28;
      canvas.drawLine(
        Offset(x * .6, 8),
        Offset(x + (i.isEven ? 7 : -8), 18 + (i % 2) * 5),
        Paint()
          ..color = const Color(0xFF5E3927)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(x * 1.08, 15 + (i % 3) * 3.0),
        2.2 + (i % 2) * 1.0,
        Paint()..color = const Color(0xFF9E6B47),
      );
    }
  }
}
