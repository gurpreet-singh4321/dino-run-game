import 'dart:math' as math;
import 'dart:ui';

enum CosmeticSlot { head, neck, back }

class CosmeticItem {
  final String id;
  final String name;
  final CosmeticSlot slot;
  final int price;
  const CosmeticItem(this.id, this.name, this.slot, this.price);
}

/// Ownership belongs to the wardrobe, never to a particular character.
class CosmeticCatalog {
  static const items = [
    CosmeticItem('explorer_hat', 'Explorer hat', CosmeticSlot.head, 250),
    CosmeticItem('winter_hat', 'Winter beanie', CosmeticSlot.head, 200),
    CosmeticItem('red_scarf', 'Red scarf', CosmeticSlot.neck, 0),
    CosmeticItem('explorer_pack', 'Trail backpack', CosmeticSlot.back, 300),
    CosmeticItem('leaf_crown', 'Fern crown', CosmeticSlot.head, 150),
    CosmeticItem('aviator_hat', 'Aviator cap', CosmeticSlot.head, 350),
    CosmeticItem('space_helmet', 'Moon explorer', CosmeticSlot.head, 450),
    CosmeticItem('mint_scarf', 'Lagoon scarf', CosmeticSlot.neck, 180),
    CosmeticItem('leaf_cape', 'Forest cape', CosmeticSlot.back, 280),
    CosmeticItem('star_pack', 'Starlight pack', CosmeticSlot.back, 400),
  ];

  static CosmeticItem? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// Normalized attachment coordinates in the character's drawing bounds.
/// New characters override this fit, while item artwork stays shared.
class CosmeticFit {
  final Offset head;
  final Offset neck;
  final Offset back;
  final double scale;
  const CosmeticFit({
    this.head = const Offset(.56, .17),
    this.neck = const Offset(.53, .51),
    this.back = const Offset(.26, .57),
    this.scale = 1,
  });

  Offset anchor(CosmeticSlot slot) => switch (slot) {
    CosmeticSlot.head => head,
    CosmeticSlot.neck => neck,
    CosmeticSlot.back => back,
  };
}

void drawCosmetic(
  Canvas canvas,
  Size size,
  CosmeticFit fit,
  CosmeticItem item,
) {
  final anchor = fit.anchor(item.slot);
  canvas.save();
  canvas.translate(size.width * anchor.dx, size.height * anchor.dy);
  canvas.scale(size.width / 100 * fit.scale);
  final paint = Paint();

  Shader linear3d(Rect r, Color top, Color mid, Color bottom) =>
      Gradient.linear(r.topLeft, r.bottomRight, [top, mid, bottom], const [0, .5, 1]);

  void oval(Rect r, Color color) =>
      canvas.drawOval(r, paint..shader = null..style = PaintingStyle.fill..color = color);

  void oval3d(Rect r, Color hi, Color mid, Color lo) => canvas.drawOval(
    r,
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFFFFF)
      ..shader = linear3d(r, hi, mid, lo),
  );

  void box3d(Rect r, double radius, Color hi, Color mid, Color lo) =>
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(radius)),
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFFFFFFF)
          ..shader = linear3d(r, hi, mid, lo),
      );

  Paint shaderFill(Shader shader) => paint
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFFFFF)
    ..shader = shader;

  switch (item.id) {
    case 'explorer_hat':
      // Soft brow contact shadow beneath curled brim.
      oval(const Rect.fromLTWH(-31, 0, 62, 10), const Color(0x3D2E1404));
      // Brim curling gently down at front-center brow with slight sunlit side tilt.
      final brim = Path()
        ..moveTo(-36, -3)
        ..quadraticBezierTo(-18, -5, 0, -2)
        ..quadraticBezierTo(18, -5, 36, -3)
        ..quadraticBezierTo(30, 6.5, 0, 7.5)
        ..quadraticBezierTo(-30, 6.5, -36, -3)
        ..close();
      canvas.drawPath(
        brim.shift(const Offset(0, 1.8)),
        shaderFill(linear3d(const Rect.fromLTWH(-36, -5, 72, 14),
            const Color(0xFF9C663B), const Color(0xFF6B4121), const Color(0xFF3E220E))),
      );
      canvas.drawPath(
        brim,
        shaderFill(Gradient.linear(
          const Offset(-34, -5),
          const Offset(34, 7),
          const [Color(0xFFFFE4A6), Color(0xFFE3B673), Color(0xFFA7753A)],
          const [0, .5, 1],
        )),
      );
      // Pinched safari crown sitting ABOVE the brim with curved sides and crease hollow.
      final crown = Path()
        ..moveTo(-22, -2)
        ..cubicTo(-23, -15, -19, -25, -8.5, -26)
        ..quadraticBezierTo(0, -22, 8.5, -26)
        ..cubicTo(19, -25, 23, -15, 22, -2)
        ..quadraticBezierTo(0, 1.5, -22, -2)
        ..close();
      canvas.drawPath(
        crown,
        shaderFill(Gradient.radial(
          const Offset(-7, -17),
          26,
          const [Color(0xFFFFE3A8), Color(0xFFD9A660), Color(0xFF94612B)],
          const [0, .55, 1],
        )),
      );
      oval(Rect.fromCenter(center: const Offset(0, -23.5), width: 13, height: 4.0),
          const Color(0x455E3411));
      // Side tucked crimson-gold expedition feather.
      final feather = Path()
        ..moveTo(-16, -7)
        ..quadraticBezierTo(-26, -19, -31, -24)
        ..quadraticBezierTo(-22, -19, -13, -8)
        ..close();
      canvas.drawPath(
        feather,
        shaderFill(Gradient.linear(
          const Offset(-31, -24),
          const Offset(-13, -7),
          const [Color(0xFFFFD86B), Color(0xFFE95B42)],
        )),
      );
      // Wrapped leather hatband cleanly visible around crown base.
      final band = Path()
        ..moveTo(-22.2, -8.2)
        ..quadraticBezierTo(0, -4.5, 22.2, -8.2)
        ..lineTo(22.4, -2.5)
        ..quadraticBezierTo(0, 1.0, -22.4, -2.5)
        ..close();
      canvas.drawPath(
        band,
        shaderFill(Gradient.linear(
          const Offset(-22, -7),
          const Offset(22, 0),
          const [Color(0xFF4D2A15), Color(0xFF8C5633), Color(0xFF63371D)],
          const [0, .5, 1],
        )),
      );
      // Subtle rim light along front edge of brim.
      canvas.drawPath(
        Path()
          ..moveTo(-33, -1.5)
          ..quadraticBezierTo(0, 6.2, 33, -1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x88FFF6D4),
      );
      // Embossed brass explorer compass pin nestled cleanly on upper-right crown.
      oval3d(const Rect.fromLTWH(6, -18, 9.5, 9.5),
          const Color(0xFFFFF6BF), const Color(0xFFF3BF49), const Color(0xFF9C6616));
      oval(const Rect.fromLTWH(9.0, -15.0, 3.5, 3.5), const Color(0xFF1A7C70));

    case 'winter_hat':
      oval(const Rect.fromLTWH(-28, 1, 56, 8), const Color(0x38132C44));
      // Knit dome with warm alpine shading & curved cable pattern.
      final beanie = Path()
        ..moveTo(-25, 0)
        ..cubicTo(-26, -22, -14, -30, 0, -30)
        ..cubicTo(14, -30, 26, -22, 25, 0)
        ..close();
      canvas.drawPath(
        beanie,
        shaderFill(Gradient.radial(
          const Offset(-8, -18),
          28,
          const [Color(0xFF83C9F4), Color(0xFF4387BA), Color(0xFF1E4C73)],
          const [0, .55, 1],
        )),
      );
      // Soft knit chevron motif lines across crown.
      final stitch = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x99E4F7FF);
      for (var i = -18.0; i <= 18.0; i += 9.0) {
        canvas.drawPath(
          Path()
            ..moveTo(i, -24 + i.abs() * .25)
            ..quadraticBezierTo(i * .7, -14, i * .9, -4),
          stitch..color = const Color(0x55224D70),
        );
        if (i.abs() <= 10) {
          canvas.drawPath(
            Path()
              ..moveTo(i - 3.5, -13)
              ..lineTo(i, -17)
              ..lineTo(i + 3.5, -13),
            stitch..color = const Color(0xAAE2F8FF),
          );
        }
      }
      // Curved plush ribbed cuff hugging Dino's brow.
      final cuff = Path()
        ..moveTo(-28, -5)
        ..quadraticBezierTo(0, -1, 28, -5)
        ..quadraticBezierTo(29, 3, 27, 6)
        ..quadraticBezierTo(0, 9.5, -27, 6)
        ..quadraticBezierTo(-29, 3, -28, -5)
        ..close();
      canvas.drawPath(
        cuff,
        shaderFill(Gradient.linear(
          const Offset(-28, -4),
          const Offset(28, 8),
          const [Color(0xFFDCF6FF), Color(0xFF8FD3EC), Color(0xFF4A92B0)],
          const [0, .5, 1],
        )),
      );
      for (var i = -20.0; i <= 20.0; i += 6.5) {
        canvas.drawLine(
          Offset(i, -3),
          Offset(i * .98, 5.5),
          Paint()..color = const Color(0x452A627D)..strokeWidth = 1.4..strokeCap = StrokeCap.round,
        );
      }
      // Fluffy multi-puff pom-pom on crown peak.
      for (final puff in [
        (-5.5, -31.5, 5.2, false),
        (5.5, -31.5, 5.2, true),
        (-3.5, -36.5, 5.4, false),
        (3.5, -36.5, 5.4, true),
        (0.0, -33.5, 6.8, false),
      ]) {
        final r = Rect.fromCircle(center: Offset(puff.$1, puff.$2), radius: puff.$3);
        canvas.drawOval(
          r,
          shaderFill(Gradient.radial(
            Offset(puff.$1 - 1.5, puff.$2 - 1.5),
            puff.$3 * 1.4,
            puff.$4
                ? const [Color(0xFFF5FCFF), Color(0xFFCCE7F2), Color(0xFF91BCD0)]
                : const [Color(0xFFFFFFFF), Color(0xFFE6F6FC), Color(0xFFACCFE0)],
            const [0, .55, 1],
          )),
        );
      }

    case 'red_scarf':
    case 'mint_scarf':
      final mint = item.id == 'mint_scarf';
      final hi = mint ? const Color(0xFF87F6EA) : const Color(0xFFFF8372);
      final mid = mint ? const Color(0xFF34C4B6) : const Color(0xFFE34D41);
      final lo = mint ? const Color(0xFF0A7D7D) : const Color(0xFF9A1F23);
      // Wind-swept fluttering tail with curved fabric crease.
      final tail = Path()
        ..moveTo(-14, -1)
        ..quadraticBezierTo(-29, -8, -45, -7)
        ..lineTo(-37, 2)
        ..lineTo(-43, 10)
        ..quadraticBezierTo(-26, 11, -11, 7)
        ..close();
      canvas.drawPath(
        tail,
        paint
          ..shader = Gradient.linear(const Offset(-44, -7), const Offset(-12, 10), [hi, mid, lo], const [0, .45, 1]),
      );
      canvas.drawPath(
        Path()..moveTo(-16, 3)..quadraticBezierTo(-27, 4, -37, 2),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..color = lo.withValues(alpha: .55),
      );
      // Draped triangular bandana fold tucked behind collar loop.
      final bib = Path()
        ..moveTo(-2, 5)
        ..quadraticBezierTo(10, 7, 22, 4)
        ..quadraticBezierTo(19, 17, 11, 24)
        ..quadraticBezierTo(2, 16, -2, 5)
        ..close();
      canvas.drawPath(bib.shift(const Offset(0, 1.2)), Paint()..color = const Color(0x3D260A08));
      canvas.drawPath(
        bib,
        paint
          ..shader = Gradient.linear(const Offset(1, 5), const Offset(16, 23), [hi, mid, lo], const [0, .5, 1]),
      );
      // Collar wrap hugging Dino's neck curve + knotted front fold.
      final collar = Path()
        ..moveTo(-24, -3)
        ..quadraticBezierTo(0, 2.5, 24, -3)
        ..cubicTo(25.5, 3, 24, 9, 18, 9.5)
        ..quadraticBezierTo(0, 12.5, -19, 9.5)
        ..cubicTo(-24.5, 8.5, -25.5, 3, -24, -3)
        ..close();
      canvas.drawPath(collar.shift(const Offset(0, 1.5)), Paint()..color = const Color(0x452A0908));
      canvas.drawPath(
        collar,
        paint..shader = linear3d(const Rect.fromLTWH(-24, -3, 48, 15), hi, mid, lo),
      );
      canvas.drawPath(
        Path()..moveTo(-20, -1)..quadraticBezierTo(0, 4.2, 20, -1),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = hi.withValues(alpha: .72),
      );
      // Sculpted rounded scarf knot under chin.
      oval3d(Rect.fromCenter(center: const Offset(10, 6.5), width: 11, height: 8.5), hi, mid, lo);

    case 'leaf_crown':
      // Woven curved twin vine headband hugging brow contour.
      final vine = Path()
        ..moveTo(-27, -2)
        ..quadraticBezierTo(0, 4.5, 27, -2);
      canvas.drawPath(
        vine,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF1B5737),
      );
      canvas.drawPath(
        vine,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF4CAE6E),
      );
      // Layered botanical leaves fanning around crown with midrib veins & dew gleams.
      for (var i = -2; i <= 2; i++) {
        final x = i * 10.5;
        final lean = i * 3.0;
        final yBase = -1.5 + (i == 0 ? 1.5 : 0.0);
        final leaf = Path()
          ..moveTo(x, yBase)
          ..quadraticBezierTo(x - 13 + lean, yBase - 12, x - 4 + lean, yBase - 24 + i.abs() * 2.0)
          ..quadraticBezierTo(x + 11 + lean, yBase - 16, x, yBase)
          ..close();
        canvas.drawPath(
          leaf,
          paint
            ..shader = Gradient.linear(
              Offset(x - 8, yBase - 23),
              Offset(x + 6, yBase),
              i.isEven
                  ? const [Color(0xFFA8F19F), Color(0xFF3E9C57), Color(0xFF1D6237)]
                  : const [Color(0xFFD9F9A2), Color(0xFF6DBE59), Color(0xFF2D763E)],
              const [0, .55, 1],
            ),
        );
        canvas.drawLine(
          Offset(x, yBase - 2),
          Offset(x - 3 + lean * .9, yBase - 19 + i.abs() * 1.5),
          Paint()..color = const Color(0x99E8FFD4)..strokeWidth = 1.2..strokeCap = StrokeCap.round,
        );
      }
      // Golden sunlit wildflower blossom tucked into the right vine.
      const fc = Offset(15, -5.5);
      for (var k = 0; k < 5; k++) {
        final a = k * (math.pi * 2 / 5) - .3;
        oval3d(
          Rect.fromCenter(center: fc + Offset(math.cos(a) * 4.5, math.sin(a) * 4.5), width: 6.2, height: 6.2),
          const Color(0xFFFFF8C7), const Color(0xFFFFCE52), const Color(0xFFC5821C),
        );
      }
      oval3d(Rect.fromCenter(center: fc, width: 5.5, height: 5.5),
          const Color(0xFFFFAD5C), const Color(0xFFDC6524), const Color(0xFF8C310C));

    case 'aviator_hat':
      oval(const Rect.fromLTWH(-28, 0, 56, 9), const Color(0x38281204));
      // Warm shearling fleece earflaps & espresso stitched leather bomber dome.
      for (final side in [-1.0, 1.0]) {
        final flap = Path()
          ..moveTo(side * 20, -4)
          ..quadraticBezierTo(side * 30, 1, side * 28, 14)
          ..quadraticBezierTo(side * 22, 18, side * 16, 11)
          ..close();
        canvas.drawPath(
          flap,
          shaderFill(linear3d(Rect.fromLTWH(side < 0 ? -30 : 16, -4, 15, 22),
              const Color(0xFFA86F4B), const Color(0xFF7B4A2E), const Color(0xFF452414))),
        );
        oval(Rect.fromCircle(center: Offset(side * 23, 8), radius: 2.3),
            const Color(0xFFF3C86F));
      }
      final dome = Path()
        ..moveTo(-25, -1)
        ..cubicTo(-26, -20, -14, -27, 0, -27)
        ..cubicTo(14, -27, 26, -20, 25, -1)
        ..close();
      canvas.drawPath(
        dome,
        shaderFill(Gradient.radial(
          const Offset(-8, -17),
          27,
          const [Color(0xFFC88B61), Color(0xFF8D5736), Color(0xFF4F2B17)],
          const [0, .55, 1],
        )),
      );
      // Stitched crown center seam.
      canvas.drawPath(
        Path()..moveTo(0, -26.5)..quadraticBezierTo(2, -16, 1, -6),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0x88E7B989),
      );
      // Fluffy cream shearling fleece brow roll.
      final fleece = Path()
        ..moveTo(-26, -4)
        ..quadraticBezierTo(0, -1, 26, -4)
        ..quadraticBezierTo(27, 3, 24, 4)
        ..quadraticBezierTo(0, 6.5, -24, 4)
        ..quadraticBezierTo(-27, 3, -26, -4)
        ..close();
      canvas.drawPath(
        fleece,
        shaderFill(Gradient.linear(
          const Offset(-26, -4),
          const Offset(26, 5),
          const [Color(0xFFFFF4DC), Color(0xFFE7C792), Color(0xFFA77E49)],
          const [0, .5, 1],
        )),
      );
      // Dark goggle strap + brass-framed rounded glass aviator goggles.
      canvas.drawPath(
        Path()..moveTo(-25.5, -9)..quadraticBezierTo(0, -6.5, 25.5, -9),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..color = const Color(0xFF3E2213),
      );
      for (final gx in [-8.5, 9.5]) {
        final frame = Rect.fromCenter(center: Offset(gx, -9.5), width: 15.5, height: 12.5);
        oval3d(frame, const Color(0xFFFFE096), const Color(0xFFD6A756), const Color(0xFF875B20));
        final lens = frame.deflate(2.0);
        canvas.drawOval(
          lens,
          paint
            ..shader = Gradient.radial(
              Offset(gx - 2, -11.5),
              8,
              const [Color(0xFFC8FBFF), Color(0xFF5DC4CF), Color(0xFF236E7A)],
              const [0, .5, 1],
            ),
        );
        oval(Rect.fromLTWH(gx - 4.2, -13.2, 4.4, 2.5), const Color(0xE6FFFFFF));
      }

    case 'space_helmet':
      // Volumetric glass visor sphere + rim catchlight.
      const sphere = Rect.fromLTWH(-39, -16, 78, 70);
      canvas.drawOval(
        sphere,
        shaderFill(Gradient.radial(
          const Offset(-14, 2),
          44,
          const [Color(0x0DFFFFFF), Color(0x1E87EAF2), Color(0x475CC9DC)],
          const [0, .65, 1],
        )),
      );
      canvas.drawOval(
        sphere,
        Paint()
          ..color = const Color(0xFFE0FAFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
      canvas.drawArc(
        const Rect.fromLTWH(-33, -11, 66, 58),
        3.55,
        0.95,
        false,
        Paint()
          ..color = const Color(0xEEFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        const Rect.fromLTWH(-31, -8, 62, 54),
        4.75,
        0.28,
        false,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      // Curved astro neck collar seal with status telemetry badge.
      final neckSeal = Path()
        ..moveTo(-34, 43)
        ..quadraticBezierTo(0, 50, 34, 43)
        ..quadraticBezierTo(35, 51, 30, 53)
        ..quadraticBezierTo(0, 58, -30, 53)
        ..quadraticBezierTo(-35, 51, -34, 43)
        ..close();
      canvas.drawPath(
        neckSeal,
        paint..shader = linear3d(const Rect.fromLTWH(-34, 43, 68, 15),
            const Color(0xFFFFFFFF), const Color(0xFFD9ECF0), const Color(0xFF83A4B3)),
      );
      box3d(const Rect.fromLTWH(14, 46, 11, 5.5), 2.5,
          const Color(0xFFFFF0A8), const Color(0xFFF3B748), const Color(0xFF9E6414));
      oval(const Rect.fromLTWH(-20, 47, 5, 4), const Color(0xFF2CE6D0));
      // Comms ear-module + antenna beacon.
      canvas.drawLine(
        const Offset(-34, 19),
        const Offset(-36, 4),
        Paint()..color = const Color(0xFF9AC5D6)..strokeWidth = 2.4..strokeCap = StrokeCap.round,
      );
      oval3d(const Rect.fromLTWH(-39.5, 0, 7, 7),
          const Color(0xFFFFFFFF), const Color(0xFF5CF6FF), const Color(0xFF1589A3));
      oval3d(const Rect.fromLTWH(-41, 18, 16, 20),
          const Color(0xFF8AD4E8), const Color(0xFF57A3B8), const Color(0xFF2F697D));
      oval3d(const Rect.fromLTWH(-38, 22, 10, 12),
          const Color(0xFFFFFFFF), const Color(0xFFCEEAF2), const Color(0xFF81AFC0));

    case 'leaf_cape':
      // Multi-layered lush forest cloak of overlapping veined fronds.
      final backFrond = Path()
        ..moveTo(-10, -21)
        ..quadraticBezierTo(-32, -8, -30, 21)
        ..quadraticBezierTo(-19, 17, -12, 26)
        ..quadraticBezierTo(-3, 18, 5, 19)
        ..quadraticBezierTo(6, -8, -10, -21)
        ..close();
      canvas.drawPath(
        backFrond,
        paint..shader = linear3d(const Rect.fromLTWH(-32, -21, 38, 48),
            const Color(0xFF47A670), const Color(0xFF26784E), const Color(0xFF13482D)),
      );
      final mainFrond = Path()
        ..moveTo(-8, -22)
        ..quadraticBezierTo(-26, -3, -24, 24)
        ..lineTo(-16, 19)
        ..lineTo(-10, 27)
        ..lineTo(-3, 19)
        ..quadraticBezierTo(9, -6, -8, -22)
        ..close();
      canvas.drawPath(
        mainFrond,
        paint..shader = linear3d(const Rect.fromLTWH(-26, -22, 35, 49),
            const Color(0xFF7BE092), const Color(0xFF399E64), const Color(0xFF1A5B3A)),
      );
      canvas.drawPath(
        Path()..moveTo(-8, -17)..quadraticBezierTo(-13, 2, -11, 23),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = const Color(0xFFB7F59E),
      );
      for (final vein in [(-11.0, -5.0, -21.0, 2.0), (-12.0, 5.0, -21.0, 13.0)]) {
        canvas.drawLine(
          Offset(vein.$1, vein.$2),
          Offset(vein.$3, vein.$4),
          Paint()..color = const Color(0x88BFF7AC)..strokeWidth = 1.2..strokeCap = StrokeCap.round,
        );
      }
      oval3d(const Rect.fromLTWH(-12, -23, 8, 8),
          const Color(0xFFFFF4B8), const Color(0xFFE6AD45), const Color(0xFF8C5A16));

    case 'star_pack':
      // Sleek cosmic astral thruster pack with brass wing fins & glowing core.
      for (final dy in [-4.0, 6.0]) {
        final fin = Path()
          ..moveTo(-13, dy)
          ..lineTo(-26, dy + 6)
          ..lineTo(-20, dy + 11)
          ..lineTo(-12, dy + 7)
          ..close();
        canvas.drawPath(
          fin,
          paint..shader = linear3d(Rect.fromLTWH(-26, dy, 14, 11),
              const Color(0xFFFFE594), const Color(0xFFCF933A), const Color(0xFF784A14)),
        );
      }
      box3d(const Rect.fromLTWH(-17, -16, 29, 38), 10,
          const Color(0xFF7B73CF), const Color(0xFF4C4596), const Color(0xFF25205C));
      box3d(const Rect.fromLTWH(-14, -14, 23, 20), 7,
          const Color(0xFFB7B0F7), const Color(0xFF8980D4), const Color(0xFF52499E));
      // Twin lower copper thruster bells with warm starlight ember cores.
      for (final nx in [-12.0, -1.0]) {
        box3d(Rect.fromLTWH(nx, 20, 7, 6), 2,
            const Color(0xFFE0B46C), const Color(0xFF9C6934), const Color(0xFF573312));
        oval(Rect.fromLTWH(nx + 1.5, 24.5, 4, 3), const Color(0xAA78F5FF));
      }
      // Sculpted glowing astral star crest.
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 - math.pi / 2;
        final rad = i.isEven ? 9.5 : 4.3;
        final pt = Offset(-3 + math.cos(a) * rad, -2 + math.sin(a) * rad);
        if (i == 0) {
          star.moveTo(pt.dx, pt.dy);
        } else {
          star.lineTo(pt.dx, pt.dy);
        }
      }
      star.close();
      canvas.drawPath(
        star,
        paint..shader = Gradient.radial(
          const Offset(-5, -4),
          11,
          const [Color(0xFFFFFFFF), Color(0xFFFFDF78), Color(0xFFD08C20)],
          const [0, .5, 1],
        ),
      );
      oval(Rect.fromCenter(center: const Offset(-3, -2), width: 4.5, height: 4.5),
          const Color(0xFF75F6FF));

    case 'explorer_pack':
      // Field canvas rucksack + rolled bedroll on top + stitched pocket + canteen.
      oval3d(const Rect.fromLTWH(-17, -21, 30, 10),
          const Color(0xFFE07D5C), const Color(0xFFB94D35), const Color(0xFF75261A));
      box3d(const Rect.fromLTWH(-16, -15, 28, 36), 8,
          const Color(0xFF986649), const Color(0xFF6F452E), const Color(0xFF422517));
      // Top flap with stitched edge & bedroll leather keeper straps.
      box3d(const Rect.fromLTWH(-14, -13, 24, 17), 6,
          const Color(0xFFF0BE82), const Color(0xFFC99156), const Color(0xFF8B5D2E));
      for (final sx in [-10.0, 2.0]) {
        box3d(Rect.fromLTWH(sx, -21, 3.6, 16), 1.5,
            const Color(0xFF8B5738), const Color(0xFF693E25), const Color(0xFF3E2212));
      }
      // Lower utility pouch + brass buckle + side canteen.
      oval3d(const Rect.fromLTWH(-22, 4, 9, 14),
          const Color(0xFF73B2AE), const Color(0xFF3F7D7B), const Color(0xFF1F4B4B));
      box3d(const Rect.fromLTWH(-11, 7, 19, 11), 3,
          const Color(0xFFC89060), const Color(0xFFA06A3E), const Color(0xFF683E1E));
      box3d(const Rect.fromLTWH(-4, 0, 5.5, 8.5), 1.5,
          const Color(0xFFFFF2AD), const Color(0xFFF2C257), const Color(0xFFA8701D));
  }
  canvas.restore();
}
