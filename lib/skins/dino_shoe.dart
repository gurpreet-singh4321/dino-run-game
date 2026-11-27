import 'dart:math' as math;
import 'dart:ui';

/// Kinematic leg-to-foot attachment geometry in foot-local coordinates so
/// footwear cosmetics hug the curved ankle and calf silhouette in every pose.
class DinoShoeMount {
  final Offset ankle;
  final double footAngle;
  final bool far;

  /// Foot-local X position where the curved back calf meets the collar rim.
  final double backX;

  /// Foot-local X position where the front shin meets the tongue/instep.
  final double frontX;

  const DinoShoeMount({
    required this.ankle,
    required this.footAngle,
    required this.far,
    required this.backX,
    required this.frontX,
  });

  /// Projects a world-space point into foot-local space centered at [ankle].
  static Offset toFootLocal(Offset worldPoint, Offset ankle, double footAngle) {
    final dx = worldPoint.dx - ankle.dx;
    final dy = worldPoint.dy - ankle.dy;
    final c = math.cos(-footAngle);
    final s = math.sin(-footAngle);
    return Offset(dx * c - dy * s, dx * s + dy * c);
  }
}

/// Color & material theme for pluggable footwear cosmetics.
class DinoShoeStyle {
  final List<Color> nearUpper;
  final List<Color> farUpper;
  final Color nearAccent;
  final Color farAccent;
  final Color nearTrim;
  final Color farTrim;
  final List<Color> nearCuff;
  final List<Color> farCuff;
  final List<Color> nearSole;
  final List<Color> farSole;
  final Color nearTread;
  final Color farTread;
  final Color nearLace;
  final Color farLace;

  const DinoShoeStyle({
    required this.nearUpper,
    required this.farUpper,
    required this.nearAccent,
    required this.farAccent,
    required this.nearTrim,
    required this.farTrim,
    required this.nearCuff,
    required this.farCuff,
    required this.nearSole,
    required this.farSole,
    required this.nearTread,
    required this.farTread,
    required this.nearLace,
    required this.farLace,
  });

  static const explorer = DinoShoeStyle(
    nearUpper: [Color(0xFFC97F46), Color(0xFF965326), Color(0xFF5E2F11)],
    farUpper: [Color(0xFF9C6034), Color(0xFF723F1E), Color(0xFF47230D)],
    nearAccent: Color(0xFF177E73),
    farAccent: Color(0xFF105D54),
    nearTrim: Color(0xDDF4C75C),
    farTrim: Color(0xAACBA048),
    nearCuff: [Color(0xFFFFF8E2), Color(0xFFE5C993)],
    farCuff: [Color(0xFFE3CEA3), Color(0xFFB59665)],
    nearSole: [Color(0xFFFFFAEB), Color(0xFFE5D2AE)],
    farSole: [Color(0xFFE6D5B4), Color(0xFFBBA37B)],
    nearTread: Color(0xFF3E2414),
    farTread: Color(0xFF2D190E),
    nearLace: Color(0xFFFFF7DF),
    farLace: Color(0xFFE6D4B2),
  );
}

/// Renders Dino's shoe anchored seamlessly onto the curved calf & ankle.
///
/// Splits the draw into a back collar pocket painted before the leg (`paintBackCollar`)
/// and the main rounded shoe body (`paintShoeBody`) so any footwear cosmetic
/// naturally encloses the curved leg with zero shelf gap or diagonal shear.
class DinoShoeRenderer {
  const DinoShoeRenderer._();

  static Path buildSilhouette(DinoShoeMount mount) {
    final backEdge = (mount.backX - 0.5).clamp(-6.8, -3.0);
    final frontCollar = (mount.frontX + 0.9).clamp(3.2, 5.8);
    final heelMidX = math.min(backEdge - 0.5, -5.2);
    // Bigger, plumper rounded silhouette: cushioned rounded back collar
    // touches the curved calf, soft arched tongue encloses front shin, and
    // chunky rounded toe bumper meets grounded outsole at y=+7.2.
    return Path()
      ..moveTo(backEdge, -3.1)
      ..quadraticBezierTo(heelMidX, 1.5, heelMidX + 0.5, 4.9)
      ..quadraticBezierTo(heelMidX + 0.7, 7.2, -2.6, 7.2)
      ..lineTo(10.6, 7.2)
      ..quadraticBezierTo(13.9, 7.1, 13.7, 3.8)
      ..quadraticBezierTo(13.0, 0.3, frontCollar + 2.6, -0.7)
      ..quadraticBezierTo(frontCollar + 0.9, -3.9, frontCollar - 0.8, -4.1)
      ..quadraticBezierTo((backEdge + frontCollar) * 0.45, -4.3, backEdge, -3.1)
      ..close();
  }

  static void paintBackCollar(
    Canvas c,
    DinoShoeMount mount,
    DinoShoeStyle style,
  ) {
    final backEdge = (mount.backX - 0.5).clamp(-6.8, -3.0);
    final frontCollar = (mount.frontX + 0.9).clamp(3.2, 5.8);
    final width = (frontCollar - backEdge).clamp(6.8, 12.0);
    final centerX = (backEdge + frontCollar) * 0.5;
    c.save();
    c.translate(mount.ankle.dx, mount.ankle.dy);
    c.rotate(mount.footAngle);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, -3.3),
        width: width + 0.4,
        height: 2.9,
      ),
      Paint()
        ..color = mount.far
            ? style.farCuff.last
            : style.nearCuff.last,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, -3.1),
        width: width - 1.0,
        height: 2.1,
      ),
      Paint()
        ..color = mount.far
            ? const Color(0xFF3A1F0B)
            : const Color(0xFF522A0E),
    );
    c.restore();
  }

  static void paintShoeBody(
    Canvas c,
    DinoShoeMount mount,
    DinoShoeStyle style,
  ) {
    final far = mount.far;
    final backEdge = (mount.backX - 0.5).clamp(-6.8, -3.0);
    final frontCollar = (mount.frontX + 0.9).clamp(3.2, 5.8);
    final midCollarX = (backEdge + frontCollar) * 0.5;
    final shoeOutline = buildSilhouette(mount);

    c.save();
    c.translate(mount.ankle.dx, mount.ankle.dy);
    c.rotate(mount.footAngle);
    c.clipPath(shoeOutline);

    // Rich leather upper filling the bigger chunky boot/sneaker shape.
    c.drawRect(
      const Rect.fromLTWH(-8, -6, 24, 15),
      Paint()
        ..shader = Gradient.linear(
          const Offset(2, -4),
          const Offset(5, 7),
          far ? style.farUpper : style.nearUpper,
          const [0.0, 0.55, 1.0],
        ),
    );

    // Accent side flash curving smoothly along heel quarter + gold trim.
    final flash = Path()
      ..moveTo(backEdge - 1.2, 1.8)
      ..quadraticBezierTo(1.8, 0.2, 8.0, 4.8)
      ..lineTo(backEdge - 1.2, 5.2)
      ..close();
    c.drawPath(
      flash,
      Paint()..color = far ? style.farAccent : style.nearAccent,
    );
    c.drawPath(
      Path()
        ..moveTo(backEdge - 1.0, 1.8)
        ..quadraticBezierTo(1.8, 0.2, 7.6, 4.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..strokeCap = StrokeCap.round
        ..color = far ? style.farTrim : style.nearTrim,
    );

    // Plush rounded cuff wrapping tightly from back calf across front ankle/tongue.
    final collarRoll = Path()
      ..moveTo(backEdge - 0.8, -4.4)
      ..quadraticBezierTo(midCollarX, -2.5, frontCollar + 1.0, -4.3)
      ..quadraticBezierTo(frontCollar + 1.8, -1.6, frontCollar - 0.4, -0.8)
      ..quadraticBezierTo(midCollarX, 0.3, backEdge - 0.8, -0.9)
      ..close();
    c.drawPath(
      collarRoll,
      Paint()
        ..shader = Gradient.linear(
          const Offset(0, -4.3),
          const Offset(0, -0.3),
          far ? style.farCuff : style.nearCuff,
        ),
    );

    // Soft rounded leather tongue dome peeking above collar + crisp cross laces.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(frontCollar - 0.1, -2.5),
        width: 4.4,
        height: 3.4,
      ),
      Paint()
        ..shader = Gradient.linear(
          Offset(frontCollar - 2, -4.0),
          Offset(frontCollar + 2, -1.0),
          far ? style.farUpper : style.nearUpper,
          const [0.0, 0.55, 1.0],
        ),
    );
    final lacePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1
      ..color = far ? style.farLace : style.nearLace;
    c.drawLine(
      Offset(frontCollar + 0.5, -1.3),
      Offset(frontCollar + 2.4, -0.1),
      lacePaint,
    );
    c.drawLine(
      Offset(frontCollar + 2.1, -0.1),
      Offset(frontCollar + 4.0, 1.1),
      lacePaint,
    );

    // Chunky cream rubber midsole & rounded toe bumper + dark espresso outsole.
    c.drawPath(
      Path()
        ..moveTo(-8, 4.4)
        ..lineTo(9.4, 4.6)
        ..quadraticBezierTo(12.2, 1.2, 15.0, 2.5)
        ..lineTo(15.0, 8.0)
        ..lineTo(-8, 8.0)
        ..close(),
      Paint()
        ..shader = Gradient.linear(
          const Offset(4, 3.0),
          const Offset(4, 7.2),
          far ? style.farSole : style.nearSole,
        ),
    );
    c.drawRect(
      const Rect.fromLTWH(-8, 6.0, 23, 2.0),
      Paint()..color = far ? style.farTread : style.nearTread,
    );

    // Soft sunlit highlight along rounded toe upper.
    c.drawOval(
      const Rect.fromLTWH(6.2, 1.4, 5.5, 2.3),
      Paint()
        ..shader = Gradient.radial(
          const Offset(9.0, 2.4),
          3.2,
          [
            far ? const Color(0x28FFE4B8) : const Color(0x48FFE7BD),
            const Color(0x00FFE7BD),
          ],
        ),
    );
    c.restore();

    // Subtle crisp contour outline around the shoe in foot-local space.
    c.save();
    c.translate(mount.ankle.dx, mount.ankle.dy);
    c.rotate(mount.footAngle);
    c.drawPath(
      shoeOutline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = far ? const Color(0x70341A09) : const Color(0x7845230D),
    );
    c.restore();
  }
}
