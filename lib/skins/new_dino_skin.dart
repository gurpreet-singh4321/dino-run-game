import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/flame.dart';
import 'cosmetics.dart';
import 'dino_motion.dart';
import 'dino_shoe.dart';
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

  static Image? _dressedTorsoImage;
  static final Picture _starterBandanaPic = _recordStarterBandana();
  static final Picture _headCastShadowPic = _recordHeadCastShadow();
  static final Picture _armCastShadowPic = _recordArmCastShadow();

  static Future<void> preload() async {
    await Flame.images.load('new_dino_rig.png');
    if (_dressedTorsoImage == null) {
      // Bake at 8x (360x352) to preserve the full 379x380 atlas detail and
      // keep vector vest/belt edges crisp on high-DPI & main-menu hero sizes.
      const scale = 8.0;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.save();
      canvas.scale(scale, scale);
      canvas.translate(-35, -53);
      final rig = Flame.images.fromCache('new_dino_rig.png');
      canvas.drawImageRect(
        rig,
        _regions[1],
        const Rect.fromLTWH(35, 53, 45, 44),
        Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true,
      );
      _drawDefaultCostume(canvas, 0, 0);
      canvas.restore();
      final picture = recorder.endRecording();
      try {
        _dressedTorsoImage = await picture.toImage(
          (45 * scale).round(),
          (44 * scale).round(),
        );
      } finally {
        picture.dispose();
      }
    }
  }

  /// Forces the blink eyelid amount for offline/boot preview frame baking.
  void setBlinkPose(double value) => _blinkMix = value.clamp(0.0, 1.0);

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
  final Paint _paint = Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  void _part(
    Canvas canvas,
    int part,
    Rect destination, {
    bool far = false,
    Color farTint = const Color(0xFFCC9838),
  }) {
    _paint.colorFilter = far
        ? ColorFilter.mode(farTint, BlendMode.modulate)
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
    // Keep resting knees gently upright so legs enter the sneaker cuffs cleanly,
    // while scaling smoothly for full athletic knee bend during running strides.
    final segLen = math.max(9.5, (ankle - hip).distance * 0.56);
    final knee = DinoMotion.knee(hip, ankle, segLen, segLen);
    final upper = knee - hip;
    final lower = ankle - knee;
    Offset normal(Offset direction) =>
        Offset(-direction.dy, direction.dx) / direction.distance;
    final n1 = normal(upper), n2 = normal(lower);
    final middle = (n1 + n2) / (n1 + n2).distance;
    final rootRadius = far ? 5.8 : 6.6;
    final kneeRadius = far ? 4.4 : 5.0;
    final a = hip + n1 * rootRadius, b = knee + middle * kneeRadius;
    final f = knee - middle * kneeRadius, g = hip - n1 * rootRadius;
    final angle = motion.footAngle(far);
    final ankleRadius = far ? 3.5 : 3.8;
    final d = ankle + n2 * ankleRadius, e = ankle - n2 * ankleRadius;
    final cap = ankle + lower / lower.distance * ankleRadius * 1.5;
    final legOutline = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(b.dx, b.dy, d.dx, d.dy)
      ..quadraticBezierTo(cap.dx, cap.dy, e.dx, e.dy)
      ..quadraticBezierTo(f.dx, f.dy, g.dx, g.dy)
      ..quadraticBezierTo(hip.dx, hip.dy - 6, a.dx, a.dy)
      ..close();

    // Sample where the curved back calf and front shin meet the shoe collar
    // height (-3.1 in foot-local space) so the shoe back & rounded top hug the leg.
    final backLocalAtAnkle = DinoShoeMount.toFootLocal(d, ankle, angle);
    final backLocalAtKnee = DinoShoeMount.toFootLocal(b, ankle, angle);
    final frontLocalAtAnkle = DinoShoeMount.toFootLocal(e, ankle, angle);
    final frontLocalAtKnee = DinoShoeMount.toFootLocal(f, ankle, angle);
    double xAtCollar(Offset low, Offset high) {
      final span = high.dy - low.dy;
      if (span.abs() < 0.001) return low.dx;
      final t = ((-3.1 - low.dy) / span).clamp(0.0, 1.0);
      return low.dx + (high.dx - low.dx) * t;
    }

    final mount = DinoShoeMount(
      ankle: ankle,
      footAngle: angle,
      far: far,
      backX: xAtCollar(backLocalAtAnkle, backLocalAtKnee),
      frontX: xAtCollar(frontLocalAtAnkle, frontLocalAtKnee),
    );
    const shoeStyle = DinoShoeStyle.explorer;

    // Back collar pocket behind ankle so the leg enters inside the shoe.
    DinoShoeRenderer.paintBackCollar(c, mount, shoeStyle);

    // Paint leg entering inside the collar pocket.
    c.save();
    c.clipPath(legOutline);
    c.drawPath(
      legOutline,
      Paint()
        ..isAntiAlias = true
        ..shader = Gradient.linear(
          Offset(hip.dx + 6, hip.dy - 2),
          Offset(ankle.dx - 5, ankle.dy + 6),
          far
              ? const [Color(0xFFEBC348), Color(0xFFD59D28), Color(0xFFAF7314)]
              : const [
                  Color(0xFFFFEE46),
                  Color(0xFFFFD818),
                  Color(0xFFF6A713),
                  Color(0xFFD97D0C),
                ],
          far ? const [0.0, 0.55, 1.0] : const [0.0, 0.40, 0.78, 1.0],
        ),
    );
    // Soft belly overhang shadow on upper thigh.
    c.drawCircle(
      hip + const Offset(0, -1),
      9.8,
      Paint()
        ..shader = Gradient.radial(
          hip + const Offset(0, -1),
          9.8,
          [
            far ? const Color(0x555E2A04) : const Color(0x456E3204),
            const Color(0x006E3204),
          ],
        ),
    );
    // Soft sunlit highlight along front shin.
    c.drawPath(
      Path()
        ..moveTo(hip.dx + 2.4, hip.dy + 2)
        ..quadraticBezierTo(knee.dx + 2.0, knee.dy, ankle.dx + 1.8, ankle.dy - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = far ? 1.5 : 2.1
        ..color = far ? const Color(0x26FFE788) : const Color(0x44FFF9AD),
    );
    c.restore();

    DinoShoeRenderer.paintShoeBody(c, mount, shoeStyle);
  }

  void _arm(Canvas c, bool far) {
    final swing = math.sin(motion.phase * math.pi * 2 + (far ? math.pi : 0));
    if (far) {
      // Anchor the far shoulder cleanly under the right collar/chest edge so
      // it joins the torso naturally while the full forearm & 4-fingered paw
      // extend clear past the vest/belly at proportional scale.
      c.save();
      c.translate(75.8, 64.5 + motion.bodyY);
      c.rotate(
        swing * .42 * motion.run -
            .24 * (1 - motion.drivingMix) -
            motion.air * .48 -
            motion.damage * .25 -
            motion.drivingMix * .28 -
            motion.yawn * .25 -
            motion.stretch * .55 -
            motion.bounce * .32,
      );
      _part(
        c,
        3,
        const Rect.fromLTWH(-6.4, -2.6, 16.8, 25.8),
        far: true,
        farTint: const Color(0xFFF6D26E),
      );
      c.restore();
      return;
    }
    c.save();
    c.translate(48, 66 + motion.bodyY);
    c.rotate(
      swing * .42 * motion.run -
          motion.air * .55 -
          motion.damage * .7 -
          motion.drivingMix * 1.3 -
          motion.yawn * 1.8 -
          motion.stretch * 1.15 -
          motion.bounce * .55 -
          (motion.wave * (2.45 + .2 * math.sin(motion.idleTime * 13)) +
              motion.wag * math.sin(motion.idleTime * 12) * .25),
    );
    _part(
      c,
      3,
      const Rect.fromLTWH(-7, -3, 18, 28),
    );
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
    final torsoRect = Rect.fromLTWH(
      35,
      53 + motion.bodyY,
      45,
      44 - motion.landing + motion.launch + motion.stretch * 1.4,
    );
    final dressed = _dressedTorsoImage;
    if (dressed != null) {
      _paint.colorFilter = null;
      canvas.drawImageRect(
        dressed,
        const Rect.fromLTWH(0, 0, 360, 352),
        torsoRect,
        _paint,
      );
    } else {
      canvas.saveLayer(torsoRect.inflate(2), _workPaint);
      _part(canvas, 1, torsoRect);
      _drawDefaultCostume(
        canvas,
        motion.bodyY,
        -motion.landing + motion.launch + motion.stretch * 1.4,
      );
      canvas.restore();
    }
    _drawStarterBandana(canvas);
    _drawHeadCastShadow(canvas);
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
    _drawArmCastShadow(canvas);
    // The front arm and hand always sit above neckwear, including when raised
    // across the scarf during a yawn or greeting.
    _arm(canvas, false);
    canvas.restore();
  }

  static final Paint _workPaint = Paint();

  /// Renders Dino's built-in 3D explorer vest, stitched utility belt, and
  /// gold compass buckle masked via `srcATop` onto the torso silhouette so
  /// the costume wraps 100% flush around every curve with zero edge gap.
  static void _drawDefaultCostume(Canvas canvas, double dy, double squash) {
    final p = Paint()..blendMode = BlendMode.srcATop;

    // Subtle tail-junction ambient occlusion on the lower left hip.
    canvas.drawOval(
      Rect.fromLTWH(31, 70 + dy, 16, 22),
      p
        ..shader = Gradient.radial(
          Offset(36, 81 + dy),
          12,
          [const Color(0x445E2B04), const Color(0x005E2B04)],
        ),
    );
    p.shader = null;

    // 3D open-front forest-teal Explorer Vest hugging both shoulders and flanks
    // all the way past the outer contour (`32..83`), clipped cleanly by srcATop.
    final leftPanel = Path()
      ..moveTo(32, 52 + dy)
      ..lineTo(57.2, 52 + dy)
      ..quadraticBezierTo(51.5, 68 + dy, 51, 86 + dy + squash * .6)
      ..lineTo(32, 86 + dy + squash * .6)
      ..close();
    final rightPanel = Path()
      ..moveTo(67.2, 52 + dy)
      ..lineTo(83, 52 + dy)
      ..lineTo(83, 86 + dy + squash * .6)
      ..lineTo(72, 86 + dy + squash * .6)
      ..quadraticBezierTo(72.5, 68 + dy, 67.2, 52 + dy)
      ..close();

    // Soft cast shadow from vest lapels onto Dino's cream belly.
    canvas.save();
    canvas.translate(1.2, 1.4);
    final lapelShadow = Paint()
      ..blendMode = BlendMode.srcATop
      ..color = const Color(0x385A2B08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawPath(leftPanel, lapelShadow);
    canvas.drawPath(rightPanel, lapelShadow);
    canvas.restore();

    // Horizontal cylindrical 3D wrap shading darkens the far outer flanks so
    // the vest visibly curves around Dino's body.
    canvas.drawPath(
      leftPanel,
      p
        ..color = const Color(0xFFFFFFFF)
        ..shader = Gradient.linear(
          Offset(35, 68 + dy),
          Offset(56, 68 + dy),
          const [Color(0xFF07312E), Color(0xFF157F74), Color(0xFF2FA897)],
          const [0, .45, 1],
        ),
    );
    canvas.drawPath(
      rightPanel,
      p
        ..color = const Color(0xFFFFFFFF)
        ..shader = Gradient.linear(
          Offset(68, 68 + dy),
          Offset(80, 68 + dy),
          const [Color(0xFF289F8F), Color(0xFF13796E), Color(0xFF07312E)],
          const [0, .55, 1],
        ),
    );
    p.shader = null;

    // Gold braided trim & 3D brass lapel buttons.
    final trim = Paint()
      ..blendMode = BlendMode.srcATop
      ..color = const Color(0xFFF6CB65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(57, 54.5 + dy)
        ..quadraticBezierTo(51.5, 68.5 + dy, 51, 84.5 + dy + squash * .6),
      trim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(67.6, 54.5 + dy)
        ..quadraticBezierTo(72.5, 68 + dy, 72.2, 84.5 + dy + squash * .6),
      trim,
    );
    for (final pos in [Offset(46.5, 69 + dy), Offset(46.5, 77 + dy)]) {
      canvas.drawCircle(
        pos + const Offset(.4, .7),
        1.7,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = const Color(0x55082622),
      );
      canvas.drawCircle(
        pos,
        1.6,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = Gradient.radial(
            pos - const Offset(.5, .5),
            2.1,
            const [Color(0xFFFFF3BA), Color(0xFFF2B642), Color(0xFF8C5A14)],
            const [0, .55, 1],
          ),
      );
    }

    // 3D curved leather utility belt wrapping completely around both flanks.
    final beltY = 82.0 + dy + squash * .72;
    final beltPath = Path()
      ..moveTo(32, beltY - 1.2)
      ..quadraticBezierTo(59, beltY + 4.8, 83, beltY - 1.5)
      ..lineTo(83, beltY + 5.6)
      ..quadraticBezierTo(59, beltY + 11.4, 32, beltY + 5.8)
      ..close();
    canvas.drawPath(
      beltPath.shift(const Offset(0, 1.5)),
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = const Color(0x3D471F04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawPath(
      beltPath,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = Gradient.linear(
          Offset(35, beltY + 4),
          Offset(80, beltY + 4),
          const [
            Color(0xFF3E1D0A),
            Color(0xFF8E562C),
            Color(0xFFA86A3A),
            Color(0xFF724120),
            Color(0xFF3A1A08),
          ],
          const [0, .25, .55, .8, 1],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, beltY)
        ..quadraticBezierTo(59, beltY + 5.8, 83, beltY - .3),
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = const Color(0x66FFCE8A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9,
    );

    // 3D beveled Gold Compass/Paw belt buckle at front-center.
    final bx = 61.5, by = beltY + 5.2;
    final buckle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bx, by), width: 10.5, height: 8.4),
      const Radius.circular(2.6),
    );
    canvas.drawRRect(
      buckle.shift(const Offset(.5, 1.1)),
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = const Color(0x552B1304)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );
    canvas.drawRRect(
      buckle,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = Gradient.linear(
          Offset(bx - 5, by - 4),
          Offset(bx + 5, by + 4),
          const [Color(0xFFFFF2AD), Color(0xFFF5BC45), Color(0xFF965E15)],
          const [0, .5, 1],
        ),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by), width: 5.5, height: 4.0),
        const Radius.circular(1.3),
      ),
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = const Color(0xFF157A70),
    );
  }

  /// Starter Crimson Trail Bandana at the collar unless a Neck cosmetic overrides it.
  void _drawStarterBandana(Canvas canvas) {
    if (cosmetics.any((c) => c.slot == CosmeticSlot.neck)) return;
    canvas.save();
    canvas.translate(0, motion.bodyY);
    canvas.drawPicture(_starterBandanaPic);
    canvas.restore();
  }

  static Picture _recordStarterBandana() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const ny = 58.0;
    final tail = Path()
      ..moveTo(46, ny + 1)
      ..lineTo(31, ny - 3.5)
      ..lineTo(35.5, ny + 2.2)
      ..lineTo(31.5, ny + 6.5)
      ..lineTo(48, ny + 5.5)
      ..close();
    canvas.drawPath(
      tail,
      Paint()
        ..shader = Gradient.linear(
          const Offset(31, ny - 3),
          const Offset(48, ny + 6),
          const [Color(0xFFEC594A), Color(0xFFAE2A2D)],
        ),
    );
    final collar = Path()
      ..moveTo(46, ny - .5)
      ..quadraticBezierTo(60, ny + 4.8, 72.5, ny - .5)
      ..quadraticBezierTo(73.5, ny + 4.8, 62, ny + 7.6)
      ..quadraticBezierTo(47.5, ny + 6.2, 45.5, ny + 3.2)
      ..close();
    canvas.drawPath(
      collar.shift(const Offset(0, 1.4)),
      Paint()..color = const Color(0x2E451208),
    );
    canvas.drawPath(
      collar,
      Paint()
        ..shader = Gradient.linear(
          const Offset(46, ny),
          const Offset(72, ny + 7),
          const [Color(0xFFFF725E), Color(0xFFDD3F34), Color(0xFF9F2323)],
          const [0, .55, 1],
        ),
    );
    final bib = Path()
      ..moveTo(56, ny + 4.6)
      ..lineTo(68.2, ny + 4.2)
      ..lineTo(62.8, ny + 14.0)
      ..close();
    canvas.drawPath(
      bib,
      Paint()
        ..shader = Gradient.linear(
          const Offset(56, ny + 4),
          const Offset(67, ny + 14),
          const [Color(0xFFF35B4C), Color(0xFFB32C2C)],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(49, ny + 1)
        ..quadraticBezierTo(60, ny + 5.2, 70, ny + .8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x88FFB8AE),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(62.2, ny + 5.2), width: 6.2, height: 4.8),
      Paint()
        ..shader = Gradient.radial(
          const Offset(61.0, ny + 4.2),
          3.8,
          const [Color(0xFFFF8876), Color(0xFFD13430), Color(0xFF8C1C1C)],
          const [0, .55, 1],
        ),
    );
    return recorder.endRecording();
  }

  /// Dynamic 3D ambient shadow cast by the head onto Dino's chest and collar.
  void _drawHeadCastShadow(Canvas canvas) {
    final cy = 62.5 + motion.headY * .65 + motion.bodyY * .35;
    canvas.save();
    canvas.translate(60, cy);
    canvas.drawPicture(_headCastShadowPic);
    canvas.restore();
  }

  static Picture _recordHeadCastShadow() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 32, height: 11),
      Paint()
        ..shader = Gradient.radial(
          const Offset(0, -1),
          17,
          const [Color(0x524A1E04), Color(0x224A1E04), Color(0x004A1E04)],
          const [0, .55, 1],
        ),
    );
    return recorder.endRecording();
  }

  /// Soft 3D cast shadow beneath the near arm onto Dino's torso/vest.
  void _drawArmCastShadow(Canvas canvas) {
    if (motion.yawn > .15 || motion.wave > .15) return;
    final swing = math.sin(motion.phase * math.pi * 2);
    canvas.save();
    canvas.translate(50, 74 + motion.bodyY);
    canvas.rotate(swing * .42 * motion.run);
    canvas.drawPicture(_armCastShadowPic);
    canvas.restore();
  }

  static Picture _recordArmCastShadow() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawOval(
      const Rect.fromLTWH(-4, -1, 13, 21),
      Paint()
        ..shader = Gradient.radial(
          const Offset(2.5, 9),
          11,
          const [Color(0x38502306), Color(0x00502306)],
        ),
    );
    return recorder.endRecording();
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
        motion.power == DinoPowerState.magnet ||
        motion.wag > .25 ||
        motion.bounce > .25;
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
