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
        width: diameter * (1.2 - proximity * .3),
        height: 9,
      ),
      Paint()
        ..color = const Color(
          0xFF3B251C,
        ).withValues(alpha: .12 + proximity * .22),
    );
    if (phase == RockPhase.warning) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(diameter / 2, floor - 2),
          width: diameter + 12,
          height: 12,
        ),
        Paint()
          ..color = const Color(0xFFE6AD4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.save();
    canvas.translate(diameter / 2, diameter / 2);
    canvas.rotate(phase == RockPhase.falling ? age * 1.8 : 0);
    final radius = diameter / 2;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = radius * (i.isEven ? 1 : .89);
      final x = math.cos(a) * r, y = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4AC78), Color(0xFF956747), Color(0xFF553B2C)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.drawLine(
      Offset(-radius * .4, -radius * .2),
      Offset(radius * .1, radius * .3),
      Paint()
        ..color = const Color(0xFF62422E)
        ..strokeWidth = 2,
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
      width: diameter * 1.7,
      height: 23,
    );
    canvas.drawOval(outer, Paint()..color = const Color(0xFF8D5738));
    canvas.drawOval(outer.deflate(3), Paint()..color = const Color(0xFF3D2C2B));
    canvas.drawArc(
      outer,
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFE0A364)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var i = 0; i < 5; i++) {
      final x = (i - 2) * diameter * .3;
      canvas.drawLine(
        Offset(x, 11),
        Offset(x + (i.isEven ? 7 : -8), 18 + i % 2 * 5),
        Paint()
          ..color = const Color(0xFF65412D)
          ..strokeWidth = 2,
      );
    }
  }
}
