import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Compact painterly sculpted hill top beneath Dino's feet, shaded to blend
/// seamlessly into the illustrated game background across all six epochs.
class DinoHillTopPainter extends CustomPainter {
  final int stage;
  const DinoHillTopPainter(this.stage);

  // Palette per epoch: (sunlitCap, warmMid, earthShadow, deepStrata, rimGlow, detail)
  static const _palettes = [
    // 0: Desert sunlit canyon sandstone & golden sand matching Ground DESERT palette
    (
      Color(0xFFFFD88E),
      Color(0xFFD68D50),
      Color(0xFF9C5439),
      Color(0xFF5D342E),
      Color(0xFFFFF0C4),
      Color(0xFFE7AE6F),
    ),
    // 1: Monsoon mossy slate riverbank & rain puddle
    (
      Color(0xFF568A87),
      Color(0xFF335B5E),
      Color(0xFF1D383D),
      Color(0xFF0E1D22),
      Color(0xFFB5EDFF),
      Color(0xFF7AC0C4),
    ),
    // 2: Forest sunlit moss & lush turf over loamy earth
    (
      Color(0xFF6BC063),
      Color(0xFF3A8447),
      Color(0xFF523C2B),
      Color(0xFF281D16),
      Color(0xFFD6FAA8),
      Color(0xFF8BE27B),
    ),
    // 3: Glacial snowbank dome over crisp cerulean ice rock
    (
      Color(0xFFFFFFFF),
      Color(0xFFCDEBFD),
      Color(0xFF67A4CB),
      Color(0xFF24496B),
      Color(0xFFFFFFFF),
      Color(0xFF97DAFA),
    ),
    // 4: Volcano volcanic basalt mound with warm ember glow
    (
      Color(0xFF5E3F43),
      Color(0xFF382328),
      Color(0xFF1D1216),
      Color(0xFF0D0709),
      Color(0xFFFF984D),
      Color(0xFFFF5924),
    ),
    // 5: Cosmic moonstone crest & twilight violet rock
    (
      Color(0xFF7B73C9),
      Color(0xFF473F8A),
      Color(0xFF27225A),
      Color(0xFF110E2D),
      Color(0xFFCBE0FF),
      Color(0xFF8EF0FF),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = stage % 6;
    final (cap, mid, shadow, deep, rim, detail) = _palettes[s];
    final w = size.width;
    final h = size.height;
    final p = Paint();

    // 1. Soft grounding shadow dispersing beneath the hillside skirt.
    canvas.drawOval(
      Rect.fromLTWH(w * .04, h * .50, w * .92, h * .48),
      p
        ..shader = const RadialGradient(
          colors: [Color(0x66090E16), Color(0x28090E16), Color(0x00090E16)],
          stops: [0, .52, 1],
        ).createShader(Rect.fromLTWH(0, h * .42, w, h * .58)),
    );
    p.shader = null;

    // 2. Smooth bell-curved small hilltop dome melting seamlessly into the scene.
    final hillPath = Path()
      ..moveTo(0, h)
      ..cubicTo(w * .16, h * .72, w * .26, h * .18, w * .50, h * .18)
      ..cubicTo(w * .74, h * .18, w * .84, h * .72, w, h)
      ..close();

    final hillRect = Rect.fromLTWH(0, h * .14, w, h * .86);
    canvas.drawPath(
      hillPath,
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cap,
            mid,
            shadow.withValues(alpha: .84),
            deep.withValues(alpha: 0.0),
          ],
          stops: const [0, .30, .62, .96],
        ).createShader(hillRect),
    );
    p.shader = null;

    // 3. Clipped 3D dome light, painterly rock strata layers, ripples, grains & props.
    canvas.save();
    canvas.clipPath(hillPath);

    // Upper-left soft key light giving the small hill genuine spherical volume.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .40, h * .30), width: w * .68, height: h * .44),
      p
        ..shader = RadialGradient(
          colors: [rim.withValues(alpha: .38), rim.withValues(alpha: 0.0)],
        ).createShader(hillRect),
    );
    p.shader = null;

    // Sculpted layered earth/strata terrace curved beneath Dino's stance.
    final strata = Path()
      ..moveTo(0, h * .58)
      ..quadraticBezierTo(w * .32, h * .45, w * .56, h * .51)
      ..quadraticBezierTo(w * .78, h * .56, w, h * .49)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      strata,
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            shadow.withValues(alpha: .54),
            deep.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, h * .46, w, h * .54)),
    );
    p.shader = null;

    _paintEpochDetails(canvas, size, s, cap, mid, shadow, deep, rim, detail, p);

    // 4. Warm sunlit rim highlight clipped cleanly to the top crest curve.
    final crest = Path()
      ..moveTo(w * .14, h * .58)
      ..cubicTo(w * .20, h * .34, w * .30, h * .18, w * .50, h * .18)
      ..cubicTo(w * .70, h * .18, w * .80, h * .34, w * .86, h * .58);
    canvas.drawPath(
      crest,
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = rim.withValues(alpha: .54),
    );
    p.style = PaintingStyle.fill;
    canvas.restore();

    // 5. Flanking painted tuft / stone accents peeking softly along the crest silhouette.
    if (s == 0 || s == 1 || s == 2) {
      final leafDark = s == 0 ? const Color(0xFF476F48) : const Color(0xFF245F38);
      final leafLight = s == 0 ? const Color(0xFF83B370) : const Color(0xFF7BE079);
      _paintTuft(canvas, Offset(w * .21, h * .43), 0.9, leafDark, leafLight, p);
      _paintTuft(canvas, Offset(w * .79, h * .42), 1.0, leafDark, leafLight, p);
    } else if (s == 3) {
      _paintCrystal(canvas, Offset(w * .22, h * .42), 13, -.22, const Color(0xFF5FA8D3), Colors.white, p);
      _paintCrystal(canvas, Offset(w * .78, h * .41), 15, .20, const Color(0xFF5FA8D3), Colors.white, p);
    } else if (s == 5) {
      _paintCrystal(canvas, Offset(w * .23, h * .43), 12, -.24, const Color(0xFF505EC4), const Color(0xFFA7F4FF), p);
      _paintCrystal(canvas, Offset(w * .78, h * .41), 14, .22, const Color(0xFF724EC4), const Color(0xFFE7B8FF), p);
    }

    // 6. Grounded ambient contact shadow directly beneath Dino's soles.
    p.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * .50, h * .38), width: w * .44, height: h * .16),
      p
        ..shader = const RadialGradient(
          colors: [Color(0xC0090E17), Color(0x4A090E17), Color(0x00090E17)],
          stops: [0, .56, 1],
        ).createShader(hillRect),
    );
  }

  void _paintEpochDetails(
    Canvas c,
    Size size,
    int s,
    Color cap,
    Color mid,
    Color shadow,
    Color deep,
    Color rim,
    Color detail,
    Paint p,
  ) {
    final w = size.width;
    final h = size.height;

    switch (s) {
      case 0: // Desert: curved wind sand ripples, rich sand grains & soft sandstone pebbles
        p
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (final r in [
          (0.18, 0.42, 0.44, 0.36, 0.62, 0.40),
          (0.28, 0.56, 0.50, 0.50, 0.78, 0.55),
          (0.14, 0.68, 0.38, 0.62, 0.66, 0.67),
        ]) {
          final ripple = Path()
            ..moveTo(w * r.$1, h * r.$2)
            ..quadraticBezierTo(w * r.$3, h * r.$4, w * r.$5, h * r.$6);
          c.drawPath(ripple, p..strokeWidth = 1.4..color = shadow.withValues(alpha: .28));
          c.drawPath(ripple.shift(const Offset(0, -1.2)), p..strokeWidth = 1.1..color = rim.withValues(alpha: .36));
        }
        p.style = PaintingStyle.fill;
        _paintGrains(c, size, 120, shadow, mid, rim, p);
        for (final st in [(0.26, 0.52, 8.5), (0.71, 0.48, 9.5), (0.38, 0.66, 5.5), (0.64, 0.64, 6.0)]) {
          _paintRoundedRock(c, Offset(w * st.$1, h * st.$2), st.$3, detail, shadow, p);
        }

      case 1: // Monsoon: wet pool sheen, gentle water ripples, damp gravel
        final pool = Rect.fromCenter(center: Offset(w * .62, h * .43), width: w * .34, height: h * .18);
        c.drawOval(
          pool,
          p
            ..shader = const LinearGradient(
              colors: [Color(0x998BE6FF), Color(0x4D367B96)],
            ).createShader(pool),
        );
        p.shader = null;
        c.drawOval(
          pool.deflate(5),
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = rim.withValues(alpha: .60),
        );
        p.style = PaintingStyle.fill;
        _paintGrains(c, size, 75, deep, mid, rim, p);
        for (final st in [(0.24, 0.50, 8.0), (0.77, 0.54, 7.0)]) {
          _paintRoundedRock(c, Offset(w * st.$1, h * st.$2), st.$3, detail, deep, p);
        }

      case 2: // Forest: mossy cushions, warm earth pebbles & blade accents
        for (final m in [(0.28, 0.34, 26.0), (0.68, 0.32, 30.0), (0.48, 0.40, 22.0)]) {
          c.drawOval(
            Rect.fromCenter(center: Offset(w * m.$1, h * m.$2), width: m.$3 * 2, height: m.$3 * .42),
            p..color = detail.withValues(alpha: .34),
          );
        }
        _paintGrains(c, size, 65, shadow, mid, rim, p);
        for (final st in [(0.25, 0.52, 8.5), (0.72, 0.55, 7.5)]) {
          _paintRoundedRock(c, Offset(w * st.$1, h * st.$2), st.$3, const Color(0xFF91A895), const Color(0xFF3E4E43), p);
        }

      case 3: // Glacial Tundra: smooth snowdrift overhang & sparkling frost grains
        final drift = Path()
          ..moveTo(w * .08, h * .46)
          ..quadraticBezierTo(w * .30, h * .34, w * .52, h * .39)
          ..quadraticBezierTo(w * .74, h * .44, w * .92, h * .45)
          ..quadraticBezierTo(w * .66, h * .52, w * .48, h * .48)
          ..quadraticBezierTo(w * .26, h * .44, w * .08, h * .46)
          ..close();
        c.drawPath(drift, p..color = Colors.white.withValues(alpha: .42));
        _paintGrains(c, size, 85, shadow, detail, Colors.white, p);

      case 4: // Volcano Inferno: glowing molten cracks & ash embers
        p
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final cracks = [
          Path()
            ..moveTo(w * .22, h * .44)
            ..quadraticBezierTo(w * .31, h * .54, w * .36, h * .70),
          Path()
            ..moveTo(w * .74, h * .42)
            ..quadraticBezierTo(w * .66, h * .53, w * .61, h * .69),
        ];
        for (final crack in cracks) {
          c.drawPath(crack, p..strokeWidth = 6.5..color = detail.withValues(alpha: .44));
          c.drawPath(crack, p..strokeWidth = 2.1..color = const Color(0xFFFFE585).withValues(alpha: .94));
        }
        p.style = PaintingStyle.fill;
        _paintGrains(c, size, 80, deep, detail, const Color(0xFFFFD877), p);

      case 5: // Cosmic Orbit: shaded moon craters & iridescent stardust speckles
        for (final cr in [(0.26, 0.44, 15.0, 5.5), (0.72, 0.43, 17.0, 6.2), (0.60, 0.62, 10.5, 4.0)]) {
          final rect = Rect.fromCenter(center: Offset(w * cr.$1, h * cr.$2), width: cr.$3 * 2, height: cr.$4 * 2);
          c.drawOval(rect, p..color = const Color(0x660B0926));
          c.drawArc(
            rect,
            .25,
            2.65,
            false,
            p
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = detail.withValues(alpha: .58),
          );
          p.style = PaintingStyle.fill;
        }
        _paintGrains(c, size, 85, deep, mid, detail, p);
    }
  }

  void _paintGrains(
    Canvas c,
    Size size,
    int count,
    Color dark,
    Color mid,
    Color spark,
    Paint p,
  ) {
    for (var i = 0; i < count; i++) {
      final h1 = _hash(i, 17);
      final h2 = _hash(i, 41);
      final h3 = _hash(i, 73);
      final gx = size.width * (.13 + h1 * .74);
      final gy = size.height * (.22 + h2 * .44);
      final edgeFade = (1.0 - (h2 * .6)).clamp(0.35, 1.0);
      final r = 0.8 + h3 * 1.05;
      final col = h3 < .36
          ? dark.withValues(alpha: .38 * edgeFade)
          : (h3 < .78 ? mid.withValues(alpha: .52 * edgeFade) : spark.withValues(alpha: .56 * edgeFade));
      c.drawCircle(Offset(gx, gy), r, p..color = col);
    }
  }

  void _paintRoundedRock(
    Canvas c,
    Offset center,
    double radius,
    Color lit,
    Color shade,
    Paint p,
  ) {
    final rect = Rect.fromCenter(center: center, width: radius * 2.1, height: radius * 1.25);
    c.drawOval(
      rect.translate(1.2, 2.2),
      p..color = const Color(0x4F070B12),
    );
    c.drawOval(
      rect,
      p
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.45),
          radius: 1.0,
          colors: [lit, shade],
        ).createShader(rect),
    );
    p.shader = null;
  }

  void _paintTuft(Canvas c, Offset base, double scale, Color dark, Color light, Paint p) {
    for (var i = -2; i <= 2; i++) {
      final path = Path()
        ..moveTo(base.dx + i * 2.2 * scale, base.dy)
        ..quadraticBezierTo(
          base.dx + i * 5.5 * scale,
          base.dy - 9 * scale,
          base.dx + i * 7.8 * scale,
          base.dy - (12 - i.abs() * 1.8) * scale,
        )
        ..quadraticBezierTo(base.dx + i * 3.0 * scale, base.dy - 3.5 * scale, base.dx + (i * 2.2 + 2.4) * scale, base.dy)
        ..close();
      c.drawPath(path, p..color = i <= 0 ? light : dark);
    }
  }

  void _paintCrystal(
    Canvas c,
    Offset base,
    double h,
    double tilt,
    Color shade,
    Color highlight,
    Paint p,
  ) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(tilt);
    final left = Path()
      ..moveTo(-h * .28, 0)
      ..lineTo(-h * .16, -h * .70)
      ..lineTo(0, -h)
      ..lineTo(0, 0)
      ..close();
    final right = Path()
      ..moveTo(0, 0)
      ..lineTo(0, -h)
      ..lineTo(h * .20, -h * .64)
      ..lineTo(h * .28, 0)
      ..close();
    c.drawPath(left, p..color = highlight.withValues(alpha: .88));
    c.drawPath(right, p..color = shade.withValues(alpha: .90));
    c.restore();
  }

  static double _hash(int i, int salt) {
    final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(DinoHillTopPainter old) => old.stage != stage;
}
