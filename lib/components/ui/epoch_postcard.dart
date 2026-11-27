import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'illustrated_menu.dart';
import 'menu_chrome.dart';

class EpochPostcard extends StatelessWidget {
  static const descriptions = [
    'Fossil canyons & sunlit trails',
    'Rainy paths & fallen timber',
    'Ancient trees & winding roots',
    'Frozen cliffs & icy crossings',
    'Lava fissures & fiery rocks',
    'A trail beneath distant planets',
  ];
  final int stage, selected;
  final List<String> names;
  final IconData? icon;
  final ValueChanged<int> onSelect;
  const EpochPostcard({
    super.key,
    required this.stage,
    required this.selected,
    required this.names,
    required this.onSelect,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final targetHeight = bounds.maxWidth >= 380 ? 156.0 : 140.0;
      final height = bounds.hasBoundedHeight
          ? math.min(targetHeight, bounds.maxHeight)
          : targetHeight;
      final accent = MenuPalette.accents[stage % MenuPalette.accents.length];
      ButtonStyle arrowStyle(bool enabled) => IconButton.styleFrom(
        backgroundColor: enabled
            ? const Color(0xEB1B2B40)
            : const Color(0x6E121D2C),
        hoverColor: const Color(0xF5253A54),
        side: BorderSide(
          color: enabled ? const Color(0xFFE0B462) : const Color(0x45D7AB5E),
          width: 1.7,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFFFFF7E2),
        disabledForegroundColor: const Color(0x94FFF0CA),
        minimumSize: const Size(48, 48),
        fixedSize: const Size(48, 48),
      );
      final arrowPad = bounds.maxWidth < 340 ? 6.0 : 12.0;
      final tightCard = height < 134;
      return RepaintBoundary(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            foregroundPainter: _PostcardFramePainter(accent),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3E2D1A), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF2E2012),
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x700E1724),
                    offset: Offset(0, 9),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EpochBiomeImage(stage: stage),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x58172638),
                            Color(0xC8101C2B),
                            Color(0xEB0B1522),
                          ],
                          stops: [0, .52, 1],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: arrowPad),
                          child: IconButton(
                            tooltip: 'Previous epoch',
                            style: arrowStyle(selected > 0),
                            onPressed: selected > 0
                                ? () => onSelect(selected - 1)
                                : null,
                            icon: const MenuChevron(left: true, size: 26),
                          ),
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, inner) => Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: inner.maxWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: tightCard ? 2 : 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            MediaQuery.disableAnimationsOf(context)
                                                ? Duration.zero
                                                : const Duration(milliseconds: 220),
                                        child: Row(
                                          key: ValueKey(selected),
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            EpochEmblem(stage: stage, size: 22),
                                            const SizedBox(width: 7),
                                            Flexible(
                                              child: Text(
                                                names[selected],
                                                maxLines: 2,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Fredoka',
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black54,
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: tightCard ? 2 : 4),
                                      Text(
                                        descriptions[stage % 6],
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFFFF0CE),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: tightCard ? 5 : 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x8E101B29),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: const Color(0x4DDAB164),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              for (
                                                var i = 0;
                                                i < names.length;
                                                i++
                                              )
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                      ),
                                                  child: AnimatedContainer(
                                                    duration:
                                                        MediaQuery.disableAnimationsOf(
                                                              context,
                                                            )
                                                            ? Duration.zero
                                                            : const Duration(
                                                                milliseconds: 180,
                                                              ),
                                                    width: i == selected ? 20 : 8,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: i == selected
                                                          ? MenuPalette.gold
                                                          : const Color(0x72FFFFFF),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3.5,
                                                          ),
                                                      border: Border.all(
                                                        color: i == selected
                                                            ? const Color(
                                                                0xFFFFF1C1,
                                                              )
                                                            : const Color(
                                                                0x30FFFFFF,
                                                              ),
                                                        width: 0.9,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${selected + 1} / ${names.length}',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFF5DC),
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: arrowPad),
                        child: IconButton(
                          tooltip: 'Next epoch',
                          style: arrowStyle(selected < names.length - 1),
                          onPressed: selected < names.length - 1
                              ? () => onSelect(selected + 1)
                              : null,
                          icon: const MenuChevron(left: false, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      );
    },
  );
}

class _PostcardFramePainter extends CustomPainter {
  final Color accent;
  const _PostcardFramePainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 48 || size.height < 48) return;
    final outer = Offset.zero & size;
    final stroke = Paint()..style = PaintingStyle.stroke;
    // Beveled bronze/timber inner rim around the epoch vista.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(2.4), const Radius.circular(15.6)),
      stroke
        ..color = Color.lerp(const Color(0xFFD6AC64), accent, .30)!
        ..strokeWidth = 2.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(4.0), const Radius.circular(14.0)),
      stroke
        ..color = const Color(0x55FFF5D6)
        ..strokeWidth = 1.0,
    );
    // Brass rivets anchored at all four frame corners.
    final dot = Paint()..style = PaintingStyle.fill;
    for (final pt in [
      const Offset(9.0, 9.0),
      Offset(size.width - 9.0, 9.0),
      Offset(9.0, size.height - 9.0),
      Offset(size.width - 9.0, size.height - 9.0),
    ]) {
      canvas.drawCircle(pt, 2.2, dot..color = const Color(0xFF3E2C18));
      canvas.drawCircle(
        pt.translate(-0.3, -0.35),
        1.4,
        dot..color = const Color(0xFFFFD877),
      );
    }
  }

  @override
  bool shouldRepaint(_PostcardFramePainter old) => old.accent != accent;
}

/// Ambient epoch-specific weather: wind gusts, rain & splashes, leaves, snow,
/// rising volcanic embers, and cosmic starlight in one isolated repaint layer.
class CampAtmosphere extends StatefulWidget {
  final int stage;
  const CampAtmosphere({super.key, required this.stage});
  @override
  State<CampAtmosphere> createState() => _CampAtmosphereState();
}

class _CampAtmosphereState extends State<CampAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      clock.stop();
    } else if (!clock.isAnimating) {
      clock.repeat();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _AtmospherePainter(clock, widget.stage)),
    ),
  );
}

class _AtmospherePainter extends CustomPainter {
  final Animation<double> clock;
  final int stage;
  final Paint _paint = Paint()..strokeCap = StrokeCap.round;
  final Path _workPath = Path();
  _AtmospherePainter(this.clock, this.stage) : super(repaint: clock);

  static double _hash(int seed) =>
      ((math.sin(seed * 127.1 + 311.7) * 43758.5453) % 1.0).abs();

  @override
  void paint(Canvas c, Size size) {
    final t = clock.value;
    final p = _paint;
    switch (stage % 6) {
      case 0:
        _paintWindGusts(c, size, t, p, const Color(0xFFFFE5AE), count: 7, speed: 3);
        _paintDriftingDust(c, size, t, p);
      case 1:
        _paintWindGusts(c, size, t, p, const Color(0xFFD5EFFF), count: 5, speed: 4);
        _paintRain(c, size, t, p);
      case 2:
        _paintSunbeams(c, size, t, p);
        _paintWindGusts(c, size, t, p, const Color(0xFFDCF6CE), count: 4, speed: 2);
        _paintForestLeaves(c, size, t, p);
      case 3:
        _paintWindGusts(c, size, t, p, const Color(0xFFE6F6FF), count: 6, speed: 3);
        _paintSnow(c, size, t, p);
      case 4:
        _paintWindGusts(c, size, t, p, const Color(0xFFFFAE6B), count: 4, speed: 3);
        _paintEmbers(c, size, t, p);
      case 5:
        _paintCosmos(c, size, t, p);
    }
  }

  void _paintWindGusts(
    Canvas c,
    Size size,
    double t,
    Paint p,
    Color color, {
    required int count,
    required int speed,
  }) {
    p.style = PaintingStyle.stroke;
    for (var i = 0; i < count; i++) {
      final phase = (t * speed + _hash(i * 13 + 3)) % 1.0;
      final fade = math.sin(phase * math.pi);
      if (fade <= .02) continue;
      final yBase = (.16 + _hash(i * 29 + 7) * .68) * size.height;
      final len = size.width * (.12 + _hash(i * 19 + 5) * .12);
      final x = -len + phase * (size.width + len * 2);
      final wave = math.sin(t * math.pi * 4 + i * 1.9) * 6;
      _workPath
        ..reset()
        ..moveTo(x, yBase)
        ..quadraticBezierTo(
          x + len * .45,
          yBase - 6 + wave,
          x + len,
          yBase - 2 - wave * .4,
        );
      c.drawPath(
        _workPath,
        p
          ..strokeWidth = 1.4 + (i % 2) * .6
          ..color = color.withValues(alpha: fade * .22),
      );
      // Little curl at the tail of occasional gusts.
      if (i.isEven) {
        c.drawArc(
          Rect.fromCenter(
            center: Offset(x + len + 4, yBase - 4 - wave * .4),
            width: 11,
            height: 9,
          ),
          math.pi * .8,
          math.pi * 1.15,
          false,
          p..color = color.withValues(alpha: fade * .16),
        );
      }
    }
  }

  void _paintDriftingDust(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 22; i++) {
      final px = (t * (1 + i % 2) + _hash(i * 7 + 11)) % 1.0;
      final py = _hash(i * 17 + 5);
      final x = px * size.width;
      final y = (.14 + py * .74) * size.height + math.sin(px * math.pi * 2 + i) * 10;
      final alpha = math.sin(px * math.pi) * (.22 + (i % 3) * .10);
      c.drawCircle(
        Offset(x, y),
        1.2 + (i % 3) * .7,
        p..color = const Color(0xFFFFE5A6).withValues(alpha: alpha),
      );
    }
  }

  void _paintRain(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.stroke;
    for (var i = 0; i < 58; i++) {
      final speed = 5 + (i % 3) * 2;
      final phase = (t * speed + _hash(i * 23 + 1)) % 1.0;
      final startX = _hash(i * 31 + 9) * (size.width + 140) - 70;
      final y = -40 + phase * (size.height + 60);
      final slant = 18.0 + (i % 3) * 4.0;
      final len = 16.0 + (i % 4) * 5.0;
      final x = startX + phase * slant * 4;
      final alpha = .18 + (i % 3) * .09;
      c.drawLine(
        Offset(x, y),
        Offset(x + slant * .32, y + len),
        p
          ..strokeWidth = 1.1 + (i % 2) * .45
          ..color = const Color(0xFFD8F0FF).withValues(alpha: alpha),
      );
    }
    // Raindrop splash ripples near the ground horizon.
    for (var i = 0; i < 10; i++) {
      final phase = (t * 6 + _hash(i * 41 + 2)) % 1.0;
      final rx = (.06 + _hash(i * 47 + 4) * .88) * size.width;
      final ry = (.78 + _hash(i * 53 + 6) * .16) * size.height;
      final r = 2 + phase * 11;
      c.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: r * 2, height: r * .55),
        p
          ..strokeWidth = 1.0
          ..color = const Color(0xFFDFF4FF).withValues(alpha: (1 - phase) * .30),
      );
    }
  }

  void _paintSunbeams(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    final sway = math.sin(t * math.pi * 2) * 18;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (.18 + i * .28) + sway * (i.isEven ? 1 : -.7);
      _workPath
        ..reset()
        ..moveTo(x - 24, 0)
        ..lineTo(x + 28, 0)
        ..lineTo(x + 120, size.height)
        ..lineTo(x - 6, size.height)
        ..close();
      c.drawPath(
        _workPath,
        p..color = const Color(0xFFFFF3C6).withValues(alpha: .045),
      );
    }
  }

  void _paintForestLeaves(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 16; i++) {
      final phase = (t * (1 + i % 2) + _hash(i * 19 + 3)) % 1.0;
      final x = (_hash(i * 29 + 1) * size.width + phase * 140) % (size.width + 40) - 20;
      final y = -20 + phase * (size.height + 40);
      final flutter = math.sin(phase * math.pi * 4 + i);
      final glow = i % 3 == 0;
      if (glow) {
        c.drawCircle(
          Offset(x + flutter * 12, y),
          2.1,
          p..color = const Color(0xFFFFEC8E).withValues(alpha: math.sin(phase * math.pi) * .55),
        );
      } else {
        c.save();
        c.translate(x + flutter * 14, y);
        c.rotate(flutter * .8 + i);
        c.drawOval(
          const Rect.fromLTWH(-4.5, -2.2, 9, 4.4),
          p
            ..color = (i.isEven
                    ? const Color(0xFF9EE77F)
                    : const Color(0xFF66C974))
                .withValues(alpha: math.sin(phase * math.pi) * .52),
        );
        c.restore();
      }
    }
  }

  void _paintSnow(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 36; i++) {
      final speed = 1 + (i % 3);
      final phase = (t * speed + _hash(i * 17 + 8)) % 1.0;
      final baseX = _hash(i * 37 + 5) * size.width;
      final drift = phase * (45 + (i % 3) * 20) + math.sin(phase * math.pi * 4 + i) * 14;
      final x = (baseX + drift) % (size.width + 20) - 10;
      final y = -12 + phase * (size.height + 24);
      final r = 1.4 + (i % 4) * .85;
      final alpha = math.sin(phase * math.pi) * (.35 + (i % 3) * .16);
      c.drawCircle(
        Offset(x, y),
        r,
        p..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _paintEmbers(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 28; i++) {
      final speed = 2 + (i % 3);
      final phase = (t * speed + _hash(i * 11 + 6)) % 1.0;
      final x = _hash(i * 23 + 9) * size.width + math.sin(phase * math.pi * 4 + i) * 18 + phase * 35;
      final y = size.height * 1.02 - phase * size.height * .92;
      final alpha = math.sin(phase * math.pi) * (.45 + (i % 3) * .18);
      final r = 1.4 + (i % 3) * .8;
      c.drawCircle(
        Offset(x % (size.width + 20), y),
        r * 2.1,
        p..color = const Color(0xFFFF6D2D).withValues(alpha: alpha * .35),
      );
      c.drawCircle(
        Offset(x % (size.width + 20), y),
        r,
        p..color = const Color(0xFFFFD670).withValues(alpha: alpha),
      );
    }
  }

  void _paintCosmos(Canvas c, Size size, double t, Paint p) {
    p.style = PaintingStyle.fill;
    for (var i = 0; i < 26; i++) {
      final twinkle = .35 + .65 * (.5 + .5 * math.sin(t * math.pi * (4 + i % 4) + i * 1.7));
      final x = (_hash(i * 19 + 4) * size.width + t * (18 + (i % 3) * 12)) % size.width;
      final y = (.06 + _hash(i * 31 + 2) * .76) * size.height;
      final r = i % 5 == 0 ? 2.2 : 1.3;
      c.drawCircle(
        Offset(x, y),
        r,
        p
          ..color = (i % 4 == 0 ? const Color(0xFF9DF2FF) : Colors.white)
              .withValues(alpha: twinkle * .55),
      );
    }
    // Occasional gentle shooting star streak.
    final shoot = (t * 2) % 1.0;
    if (shoot < .28) {
      final u = shoot / .28;
      final sx = size.width * (.20 + u * .45);
      final sy = size.height * (.10 + u * .22);
      final fade = math.sin(u * math.pi);
      p.style = PaintingStyle.stroke;
      c.drawLine(
        Offset(sx, sy),
        Offset(sx - 44, sy - 20),
        p
          ..strokeWidth = 1.8
          ..color = const Color(0xFFFFF4C8).withValues(alpha: fade * .65),
      );
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) => old.stage != stage;
}
