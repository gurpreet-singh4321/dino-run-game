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
  String get description => 'A sunny little explorer. Make every epoch your own.';
  @override
  int get price => 0;
  @override
  Color get primaryColor => const Color(0xFFFFC83D);
  @override
  bool get hasArticulatedMotion => true;
  @override
  CosmeticFit get cosmeticFit => const CosmeticFit(
    head: Offset(.60, .16), neck: Offset(.60, .53),
    back: Offset(.37, .64), scale: .88);

  static Future<void> preload() async {
    await Flame.images.load('new_dino_rig.png');
  }

  @override
  void resetMotion() => motion = DinoMotion();
  @override
  void onJump() => motion.jump();
  @override
  void advanceMotion(double dt, {required double speed,
      required double velocityY, required bool grounded,
      bool idle = false, bool space = false, double characterWidth = 80}) {
    super.update(dt);
    _blinkMix = DinoMotion.follow(_blinkMix, isBlinking ? 1 : 0, 55, dt);
    motion.update(dt, speed: speed, velocityY: velocityY, grounded: grounded,
      idle: idle, space: space, characterWidth: characterWidth);
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
        ? const ColorFilter.mode(Color(0xFFDFB24F), BlendMode.modulate) : null;
    canvas.drawImageRect(Flame.images.fromCache('new_dino_rig.png'),
      _regions[part], destination, _paint);
  }

  void _bone(Canvas c, int part, Offset start, Offset end, double width,
      {bool far = false}) {
    final delta = end - start;
    c.save();
    c.translate(start.dx, start.dy);
    c.rotate(math.atan2(delta.dy, delta.dx) - math.pi / 2);
    _part(c, part, Rect.fromLTWH(-width / 2, -2, width, delta.distance + 4), far: far);
    c.restore();
  }

  void _leg(Canvas c, bool far) {
    final hip = Offset(far ? 61 : 53, 86 + motion.bodyY);
    final ankle = motion.foot(far) - const Offset(0, 8);
    final knee = DinoMotion.knee(hip, ankle, 14, 14);
    _bone(c, 4, hip, knee, far ? 15 : 18, far: far);
    _bone(c, 5, knee, ankle + const Offset(0, 2), far ? 11 : 13, far: far);
    // Bridge the transparent atlas margins at the ankle, behind the foot.
    // A rounded joint preserves contact as the painted foot rotates.
    c.drawOval(Rect.fromCenter(center: ankle + const Offset(1, 1), width: far ? 9 : 11, height: 9),
      Paint()..shader = Gradient.radial(ankle, 7,
        far ? [const Color(0xFFE8B43C), const Color(0xFFC88A20)]
            : [const Color(0xFFFFD438), const Color(0xFFEEB51B)]));
    c.save();
    c.translate(ankle.dx, ankle.dy);
    // Keep the sole flat through stance; airborne feet point gently down.
    c.rotate(motion.footAngle(far));
    _part(c, 6, const Rect.fromLTWH(-7, -4, 23, 11), far: far);
    c.restore();
  }

  void _arm(Canvas c, bool far) {
    final swing = math.sin(motion.phase * math.pi * 2 + (far ? math.pi : 0));
    c.save();
    c.translate(far ? 72 : 48, 66 + motion.bodyY);
    c.rotate(swing * .42 * motion.run - motion.air * .55);
    _part(c, 3, Rect.fromLTWH(-7, -3, far ? 14 : 18, 28), far: far);
    c.restore();
  }

  @override
  void renderCharacter(Canvas canvas, Size size, int frame,
      {CharacterPose pose = CharacterPose.running}) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 120);
    // Lower the body over compact legs; ankle targets remain on the floor.
    canvas.translate(0, 8);
    // Rear-to-front layering keeps joints hidden behind the torso.
    canvas.save();
    canvas.translate(45, 82 + motion.bodyY);
    canvas.rotate(motion.tailAngle);
    _part(canvas, 2, const Rect.fromLTWH(-43, -15, 48, 31));
    canvas.restore();
    _leg(canvas, true);
    _arm(canvas, true);
    canvas.save();
    canvas.translate(0, motion.bodyY);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.back)) {
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
    }
    canvas.restore();
    _leg(canvas, false);
    _part(canvas, 1, Rect.fromLTWH(35, 53 + motion.bodyY, 45,
      44 - motion.landing + motion.launch));
    _arm(canvas, false);
    canvas.save();
    canvas.translate(58, 54 + motion.headY);
    canvas.rotate(motion.headAngle);
    canvas.translate(-58, -54);
    _part(canvas, 0, const Rect.fromLTWH(18, 1, 80, 64));
    // Keep the head silhouette fixed while only the eyelid changes.
    if (_blinkMix > .001) {
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(53, 23, 25, 25), const Radius.circular(10)));
      _paint.color = Color.fromRGBO(255, 255, 255, _blinkMix);
      _part(canvas, 7, const Rect.fromLTWH(18, 1, 80, 64));
      _paint.color = const Color(0xFFFFFFFF);
      canvas.restore();
    }
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.head)) {
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
    }
    canvas.restore();
    canvas.save();
    canvas.translate(0, motion.bodyY);
    for (final item in cosmetics.where((i) => i.slot == CosmeticSlot.neck)) {
      drawCosmetic(canvas, const Size(100, 120), cosmeticFit, item);
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) => renderCharacter(canvas, size, animFrame);
  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) => renderCharacter(canvas, size, 0);
  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) => renderCharacter(canvas, size, animFrame);
}
