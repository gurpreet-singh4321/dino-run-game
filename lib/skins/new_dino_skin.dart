import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/flame.dart';
import 'cosmetics.dart';
import 'dino_motion.dart';
import 'skin.dart';

/// Painted cutout rig with continuous gait, two-bone legs and bone attachments.
class NewDinoSkin extends CharacterSkin {
  DinoMotion motion = DinoMotion();
  double _blinkMix = 0;
  @override
  String get id => 'new_dino';
  @override
  String get displayName => 'Dino';
  @override
  String get description =>
      'A sunny little explorer. Make every epoch your own.';
  @override
  int get price => 0;
  @override
  Color get primaryColor => const Color(0xFFFFC83D);
  @override
  bool get hasArticulatedMotion => true;
  @override
  CosmeticFit get cosmeticFit => const CosmeticFit(
    head: Offset(.60, .16),
    neck: Offset(.60, .53),
    back: Offset(.37, .64),
    scale: .88,
  );

  static Future<void> preload() async {
    await Flame.images.load('new_dino_rig.png');
  }

  @override
  void resetMotion() => motion = DinoMotion();
  @override
  void onJump({bool doubleJump = false}) => motion.jump(doubleJump: doubleJump);
  @override
  void onDamage() => motion.hit();
  @override
  void setPowerState({
    bool shield = false,
    bool magnet = false,
    bool giant = false,
  }) {
    motion.power = giant
        ? DinoPowerState.giant
        : magnet
        ? DinoPowerState.magnet
        : shield
        ? DinoPowerState.shield
        : DinoPowerState.none;
  }

  @override
  void advanceMotion(
    double dt, {
    required double speed,
    required double velocityY,
    required bool grounded,
    bool idle = false,
    bool space = false,
    double characterWidth = 80,
  }) {
    super.update(dt);
    _blinkMix = DinoMotion.follow(_blinkMix, isBlinking ? 1 : 0, 55, dt);
    motion.update(
      dt,
      speed: speed,
      velocityY: velocityY,
      grounded: grounded,
      idle: idle,
      space: space,
      characterWidth: characterWidth,
    );
  }

  // Atlas regions measured from the generated transparent art, not equal cells:
  // the head extends across the nominal grid boundary.
  static const _regions = [
    Rect.fromLTWH(0, 48, 490, 386),
    Rect.fromLTWH(508, 55, 379, 380),
    Rect.fromLTWH(921, 111, 409, 318),
    Rect.fromLTWH(1445, 75, 236, 331),
    Rect.fromLTWH(117, 447, 273, 405),
    Rect.fromLTWH(582, 488, 229, 345),
    Rect.fromLTWH(908, 541, 383, 272),
    Rect.fromLTWH(1303, 471, 471, 384),
  ];
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  void _part(Canvas canvas, int part, Rect destination, {bool far = false}) {
    _paint.colorFilter = far
        ? const ColorFilter.mode(Color(0xFFDFB24F), BlendMode.modulate)
        : null;
    canvas.drawImageRect(
      Flame.images.fromCache('new_dino_rig.png'),
      _regions[part],
      destination,
      _paint,
    );
  }

  void _leg(Canvas c, bool far) {
    final hip = Offset(far ? 63 : 55, 89 + motion.bodyY);
    final ankle = motion.foot(far) - const Offset(0, 8);
    final knee = DinoMotion.knee(hip, ankle, 14, 14);
    // The ankle and foot share one outline. The atlas foot has a slanted cuff;
    // attaching that entire cutout leaves a second, visibly broken joint.
    final upper = knee - hip;
    final lower = ankle - knee;
    Offset normal(Offset direction) =>
        Offset(-direction.dy, direction.dx) / direction.distance;
    final n1 = normal(upper), n2 = normal(lower);
    final middle = (n1 + n2) / (n1 + n2).distance;
    final rootRadius = far ? 6.0 : 7.0;
    final kneeRadius = far ? 4.7 : 5.5;
    final a = hip + n1 * rootRadius, b = knee + middle * kneeRadius;
    final f = knee - middle * kneeRadius, g = hip - n1 * rootRadius;
    final angle = motion.footAngle(far);
    Offset footPoint(double x, double y) =>
        ankle +
        Offset(
          x * math.cos(angle) - y * math.sin(angle),
          x * math.sin(angle) + y * math.cos(angle),
        );
    final heelJoin = footPoint(-4.5, -2);
    final heel = footPoint(-7, 4);
    final sole = footPoint(-2, 7);
    final toe = footPoint(12, 7);
    final toeTop = footPoint(14.5, 1.5);
    final instep = footPoint(6, -.5);
    final shinJoin = footPoint(4.5, -4);
    final ankleRadius = far ? 4.0 : 4.5;
    final d = ankle + n2 * ankleRadius, e = ankle - n2 * ankleRadius;
    final cap = ankle + lower / lower.distance * ankleRadius * 1.5;
    final legOutline = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(b.dx, b.dy, d.dx, d.dy)
      ..quadraticBezierTo(cap.dx, cap.dy, e.dx, e.dy)
      ..quadraticBezierTo(f.dx, f.dy, g.dx, g.dy)
      ..quadraticBezierTo(hip.dx, hip.dy - 6, a.dx, a.dy)
      ..close();
    final footOutline = Path()
      ..moveTo(heelJoin.dx, heelJoin.dy)
      ..quadraticBezierTo(
        footPoint(-7, 0).dx,
        footPoint(-7, 0).dy,
        heel.dx,
        heel.dy,
      )
      ..quadraticBezierTo(
        footPoint(-7, 7).dx,
        footPoint(-7, 7).dy,
        sole.dx,
        sole.dy,
      )
      ..lineTo(toe.dx, toe.dy)
      ..quadraticBezierTo(
        footPoint(18, 6).dx,
        footPoint(18, 6).dy,
        toeTop.dx,
        toeTop.dy,
      )
      ..quadraticBezierTo(
        footPoint(12, -.5).dx,
        footPoint(12, -.5).dy,
        instep.dx,
        instep.dy,
      )
      ..quadraticBezierTo(
        footPoint(4.5, -.5).dx,
        footPoint(4.5, -.5).dy,
        shinJoin.dx,
        shinJoin.dy,
      )
      ..quadraticBezierTo(
        footPoint(0, -5).dx,
        footPoint(0, -5).dy,
        heelJoin.dx,
        heelJoin.dy,
      )
      ..close();
    // Union before painting prevents folded calves from cutting a wedge out
    // of the ankle when the foot swings behind the hip.
    final outline = Path.combine(PathOperation.union, legOutline, footOutline);
    c.save();
    c.clipPath(outline);
    // Reuse opaque painted thigh texture, without its detached cutout edges.
    _paint.colorFilter = far
        ? const ColorFilter.mode(Color(0xFFDBB35D), BlendMode.modulate)
        : null;
    c.drawImageRect(
      Flame.images.fromCache('new_dino_rig.png'),
      const Rect.fromLTWH(182, 516, 115, 135),
      outline.getBounds().inflate(1),
      _paint,
    );
    c.save();
    c.translate(ankle.dx, ankle.dy);
    c.rotate(angle);
    // Keep only the heel/toe painting, below the old cuff. The opaque thigh
    // underneath fills transparent atlas margins and the curved ankle fillet.
    c.drawImageRect(
      Flame.images.fromCache('new_dino_rig.png'),
      const Rect.fromLTWH(908, 632, 383, 181),
      const Rect.fromLTWH(-7, -.5, 23, 7.5),
      _paint,
    );
    c.restore();
    c.restore();
  }

  void _arm(Canvas c, bool far) {
    final swing = math.sin(motion.phase * math.pi * 2 + (far ? math.pi : 0));
    c.save();
    c.translate(far ? 72 : 48, 66 + motion.bodyY);
    c.rotate(
      swing * .42 * motion.run -
          motion.air * .55 -
          motion.damage * (far ? .25 : .7) -
          motion.drivingMix * (far ? .3 : 1.3) -
          motion.yawn * (far ? .3 : 1.8) -
          (far
              ? 0
              : motion.wave * (2.45 + .2 * math.sin(motion.idleTime * 13))),
    );
    _part(c, 3, Rect.fromLTWH(-7, -3, far ? 14 : 18, 28), far: far);
    c.restore();
  }

  @override
  void renderCharacter(
    Canvas canvas,
    Size size,
    int frame, {
    CharacterPose pose = CharacterPose.running,
    void Function(Canvas, Size)? backEquipment,
  }) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 120);
    // Lower the body over compact legs; ankle targets remain on the floor.
    canvas.translate(0, 8 - motion.drivingMix * 6);
    // Rear-to-front layering keeps joints hidden behind the torso.
    if (!motion.driving && motion.drivingMix < .01) {
      canvas.save();
      canvas.translate(45, 82 + motion.bodyY);
      canvas.rotate(motion.tailAngle + motion.drivingMix * .18);
      canvas.scale(1 - motion.drivingMix * .28, 1 - motion.drivingMix * .12);
      _part(canvas, 2, const Rect.fromLTWH(-43, -15, 48, 31));
      canvas.restore();
    }
    if (backEquipment != null) {
      canvas.save();
      canvas.translate(0, motion.bodyY);
      backEquipment(canvas, const Size(100, 120));
      canvas.restore();
    }
    _leg(canvas, true);
    _arm(canvas, true);
    canvas.save();
    canvas.translate(0, motion.bodyY);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.back)) {
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
    }
    canvas.restore();
    _leg(canvas, false);
    _part(
      canvas,
      1,
      Rect.fromLTWH(
        35,
        53 + motion.bodyY,
        45,
        44 - motion.landing + motion.launch,
      ),
    );
    canvas.save();
    canvas.translate(58, 54 + motion.headY);
    canvas.rotate(motion.headAngle);
    canvas.translate(-58, -54);
    _part(canvas, 0, const Rect.fromLTWH(18, 1, 80, 64));

    // Keep the head silhouette fixed while only the eyelid changes.
    final eyelid = math.max(_blinkMix, motion.yawn);
    if (eyelid > .001) {
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 23, 25, 25),
          const Radius.circular(10),
        ),
      );
      _paint.color = Color.fromRGBO(255, 255, 255, eyelid);
      _part(canvas, 7, const Rect.fromLTWH(18, 1, 80, 64));
      _paint.color = const Color(0xFFFFFFFF);
      canvas.restore();
    }
    _expression(canvas);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.head)) {
      canvas.save();
      canvas.translate(60, 19.2);
      canvas.rotate(motion.accessoryLag * .25);
      canvas.translate(-60, -19.2);
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
      canvas.restore();
    }
    canvas.restore();
    canvas.save();
    canvas.translate(0, motion.bodyY);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.neck)) {
      canvas.save();
      canvas.translate(60, 63.6);
      canvas.rotate(motion.accessoryLag * .4);
      canvas.translate(-60, -63.6);
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
      canvas.restore();
    }
    canvas.restore();
    // The front arm and hand always sit above neckwear, including when raised
    // across the scarf during a yawn or greeting.
    _arm(canvas, false);
    canvas.restore();
  }

  void _expression(Canvas canvas) {
    if (motion.yawn > .01) {
      // Replace the painted smile at its actual atlas location before opening
      // the mouth; drawing an additional mouth would leave two expressions.
      final mix = (motion.yawn * 5).clamp(0.0, 1.0);
      canvas.save();
      canvas.drawOval(
        const Rect.fromLTWH(63, 45, 28, 16),
        Paint()
          ..shader = Gradient.linear(
            const Offset(66, 46),
            const Offset(86, 58),
            [
              Color.fromRGBO(255, 220, 47, mix),
              Color.fromRGBO(255, 209, 36, mix),
            ],
          ),
      );
      final mouth = Rect.fromCenter(
        center: const Offset(78, 52),
        width: 9 * motion.yawn,
        height: 15 * motion.yawn,
      );
      canvas.drawOval(mouth, Paint()..color = const Color(0xFF75391C));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(78, mouth.bottom - 2),
          width: mouth.width * .65,
          height: mouth.height * .25,
        ),
        Paint()..color = const Color(0xFFEA8B71),
      );
      canvas.restore();
      return;
    }
    if (motion.damage > .02) {
      final mix = (motion.damage * 4).clamp(0.0, 1.0);
      canvas.drawOval(
        const Rect.fromLTWH(63, 45, 28, 16),
        Paint()
          ..shader = Gradient.linear(
            const Offset(66, 46),
            const Offset(86, 58),
            [
              Color.fromRGBO(255, 220, 47, mix),
              Color.fromRGBO(255, 209, 36, mix),
            ],
          ),
      );
      canvas.drawPath(
        Path()
          ..moveTo(73, 54)
          ..quadraticBezierTo(78, 49, 83, 54),
        Paint()
          ..color = Color.fromRGBO(114, 65, 33, mix)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
    final state = motion.state;
    if ((state == DinoAnimationState.idle || state == DinoAnimationState.run) &&
        motion.power == DinoPowerState.none) {
      return;
    }
    final brow = Paint()
      ..color = const Color(0xFF724121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final delighted =
        state == DinoAnimationState.doubleJump ||
        state == DinoAnimationState.rocket ||
        motion.power == DinoPowerState.magnet;
    canvas.drawPath(
      Path()
        ..moveTo(
          57,
          state == DinoAnimationState.damage
              ? 20
              : delighted
              ? 22
              : 24,
        )
        ..quadraticBezierTo(64, delighted ? 17 : 21, 71, 22),
      brow,
    );
  }

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) =>
      renderCharacter(canvas, size, animFrame);
  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) =>
      renderCharacter(canvas, size, 0);
  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) =>
      renderCharacter(canvas, size, animFrame);
}
