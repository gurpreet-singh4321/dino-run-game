import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'menu_chrome.dart';
import 'menu_motion.dart';

enum MenuSymbol {
  wardrobe,
  upgrades,
  journal,
  gift,
  settings,
  play,
  home,
  close,
  trophy,
}

class EpochEmblem extends StatelessWidget {
  final int stage;
  final double size;
  const EpochEmblem({super.key, required this.stage, this.size = 24});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _EpochEmblemPainter(stage % 6)),
    ),
  );
}

/// Small painted objects share the Dino's warm highlights and rounded forms.
class MenuIllustration extends StatelessWidget {
  final MenuSymbol symbol;
  final double size;
  const MenuIllustration(this.symbol, {super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: MenuMotionCue.of(context)?.enabled == false
          ? CustomPaint(painter: _Illustration(symbol))
          : MenuArrival(
              key: ValueKey(MenuMotionCue.of(context)?.engaged ?? false),
              icon: true,
              direction: symbol == MenuSymbol.settings ? -1 : 1,
              child: CustomPaint(painter: _Illustration(symbol)),
            ),
    ),
  );
}

ButtonStyle adventureButtonStyle(
  Color accent, {
  bool gold = false,
  bool prominent = false,
}) =>
    FilledButton.styleFrom(
      foregroundColor: gold ? MenuPalette.ink : Colors.white,
      backgroundColor: accent,
      disabledForegroundColor: const Color(0xFF42382B),
      disabledBackgroundColor: const Color(0xFFD5C8B0),
      minimumSize: const Size(48, 48),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.fromLTRB(14, 3, 14, 8),
      elevation: 3,
      shadowColor: const Color(0x88161C26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    ).copyWith(
      foregroundBuilder: adventureButtonMotion,
      backgroundBuilder: (context, states, child) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered);
        final focused = states.contains(WidgetState.focused);
        return CustomPaint(
          painter: _AdventureButtonFace(
            accent,
            pressed: pressed,
            disabled: disabled,
            hovered: hovered,
            focused: focused,
            prominent: prominent,
          ),
          child: child,
        );
      },
    );

class MenuAction extends StatelessWidget {
  final MenuSymbol symbol;
  final String label;
  final Color color;
  final Color? badgeColor;
  final VoidCallback? onPressed;
  final bool prominent, showSymbol;
  const MenuAction({
    super.key,
    required this.symbol,
    required this.label,
    required this.color,
    required this.onPressed,
    this.badgeColor,
    this.prominent = false,
    this.showSymbol = true,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = !prominent && constraints.maxWidth < 180;
      final tallFace = prominent && constraints.maxHeight >= 54;
      final tallViewport = MediaQuery.sizeOf(context).height >= 420;
      final medallionColor = badgeColor ?? const Color(0xFFFFF4D2);
      final art = Container(
        padding: EdgeInsets.all(compact ? 2 : (tallFace ? 3.5 : 2.5)),
        decoration: BoxDecoration(
          color: medallionColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: badgeColor != null
                ? const Color(0xCCBA8432)
                : const Color(0xCC9C6C28),
            width: 1.7,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x55121822), offset: Offset(0, 1.5)),
          ],
        ),
        child: MenuIllustration(
          symbol,
          size: compact ? 16 : (tallFace ? 26 : 21),
        ),
      );
      final text = Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: tallFace ? 21 : (compact ? 12.5 : 15),
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      );
      return FilledButton(
        onPressed: onPressed,
        style:
            adventureButtonStyle(
              color,
              gold: prominent && color == MenuPalette.gold,
              prominent: prominent,
            ).copyWith(
              minimumSize: compact && tallViewport
                  ? const WidgetStatePropertyAll(Size(48, 56))
                  : null,
              padding: WidgetStatePropertyAll(
                EdgeInsets.fromLTRB(8, compact ? 2 : 3, 8, compact ? 6 : 8),
              ),
            ),
        child: !showSymbol
            ? FittedBox(fit: BoxFit.scaleDown, child: text)
            : compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  art,
                  const SizedBox(height: 1),
                  FittedBox(fit: BoxFit.scaleDown, child: text),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  art,
                  const SizedBox(width: 8),
                  Flexible(child: text),
                ],
              ),
      );
    },
  );
}

class MenuTool extends StatelessWidget {
  final String label;
  final MenuSymbol symbol;
  final Color color;
  final VoidCallback? onPressed;
  const MenuTool({
    super.key,
    required this.label,
    required this.symbol,
    required this.color,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: SizedBox.square(
      dimension: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: adventureButtonStyle(color).copyWith(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
        child: MenuIllustration(symbol, size: 32),
      ),
    ),
  );
}

class _Illustration extends CustomPainter {
  final MenuSymbol symbol;
  const _Illustration(this.symbol);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 40, size.height / 40);
    final p = Paint();
    final ink = Paint()
      ..color = const Color(0xFF1F2A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void box(Rect r, Color color, [double radius = 4, bool outline = false]) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
      c.drawRRect(rr, p..color = color);
      if (outline) c.drawRRect(rr, ink);
    }

    void circle(double x, double y, double radius, Color color, [bool outline = false]) {
      final pt = Offset(x, y);
      c.drawCircle(pt, radius, p..color = color);
      if (outline) c.drawCircle(pt, radius, ink);
    }

    const cream = Color(0xFFFFF5DC), gold = MenuPalette.gold;
    const dark = Color(0xFF263854);
    switch (symbol) {
      case MenuSymbol.wardrobe:
        // Explorer brimmed field hat with rich leather shading, crimson band & dark ink contour.
        c.drawOval(const Rect.fromLTWH(2, 26, 36, 9), p..color = const Color(0xFF7B3E1E));
        c.drawOval(const Rect.fromLTWH(2, 25, 36, 7.5), p..color = const Color(0xFFE39E46));
        c.drawOval(const Rect.fromLTWH(2, 25, 36, 7.5), ink);
        final crown = RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 9, 20, 19),
          const Radius.circular(8),
        );
        c.drawRRect(crown, p..color = const Color(0xFFC9732B));
        box(const Rect.fromLTWH(10, 21.5, 20, 5.5), const Color(0xFFB33834), 1.5);
        box(const Rect.fromLTWH(17, 22, 6, 4.5), gold, 1);
        c.drawRRect(crown, ink);
        box(const Rect.fromLTWH(13.5, 11.5, 4.5, 8.5), const Color(0x55FFF5D6), 2.5);
        final feather = Path()
          ..moveTo(27.5, 22.5)
          ..quadraticBezierTo(36.5, 9, 37.5, 11.5)
          ..quadraticBezierTo(39, 22.5, 27.5, 22.5)
          ..close();
        c.drawPath(feather, p..color = const Color(0xFF1A9E69));
        c.drawPath(feather, ink..strokeWidth = 1.6);
      case MenuSymbol.upgrades:
        // High-contrast expedition rocket: crisp ivory/silver hull, crimson cone & fins, roaring flame.
        final flame = Path()
          ..moveTo(15.5, 27.5)
          ..lineTo(20, 38.5)
          ..lineTo(24.5, 27.5)
          ..close();
        c.drawPath(flame, p..color = const Color(0xFFF39321));
        c.drawPath(
          Path()..moveTo(17.5, 28)..lineTo(20, 34.5)..lineTo(22.5, 28)..close(),
          p..color = const Color(0xFFFFE169),
        );
        c.drawPath(flame, ink..strokeWidth = 1.7);
        final leftFin = Path()..moveTo(13, 22)..lineTo(6, 32)..lineTo(14.5, 30)..close();
        final rightFin = Path()..moveTo(27, 22)..lineTo(34, 32)..lineTo(25.5, 30)..close();
        c.drawPath(leftFin, p..color = const Color(0xFFD6403E));
        c.drawPath(rightFin, p..color = const Color(0xFFD6403E));
        c.drawPath(leftFin, ink..strokeWidth = 1.8);
        c.drawPath(rightFin, ink);
        final hull = Path()
          ..moveTo(13, 28.5)
          ..quadraticBezierTo(9, 12.5, 20, 3)
          ..quadraticBezierTo(31, 12.5, 27, 28.5)
          ..close();
        c.drawPath(hull, p..color = const Color(0xFFF8FAFE));
        c.save();
        c.clipPath(hull);
        c.drawRect(const Rect.fromLTWH(9, 2, 22, 10.5), p..color = const Color(0xFFD6403E));
        c.drawRect(const Rect.fromLTWH(20, 2, 11, 28), p..color = const Color(0x221E2E44));
        box(const Rect.fromLTWH(13, 25.5, 14, 3.5), const Color(0xFF283C5A), 0);
        c.restore();
        c.drawPath(hull, ink..strokeWidth = 2.0);
        circle(20, 17.5, 4.8, const Color(0xFF1A70C7), true);
        circle(18.6, 16.0, 1.7, const Color(0xFFA7F1FA));
      case MenuSymbol.journal:
        // Embossed leather expedition field book with dark ink contour and dino footprint stamp.
        box(const Rect.fromLTWH(7, 7.5, 27, 29), dark, 5, true);
        box(const Rect.fromLTWH(8, 4.5, 26, 28), const Color(0xFFE88E34), 5, true);
        box(const Rect.fromLTWH(8, 4.5, 6.5, 28), const Color(0xFF8C3919), 3, true);
        box(const Rect.fromLTWH(14.5, 27, 19, 5.2), cream, 2, true);
        box(const Rect.fromLTWH(28, 15.5, 8, 5.8), const Color(0xFFD13F4C), 2, true);
        circle(23, 19, 3.5, const Color(0xFF116D74));
        for (final toe in [
          const Offset(19, 13),
          const Offset(23, 11.7),
          const Offset(27, 13),
        ]) {
          c.drawOval(
            Rect.fromCenter(center: toe, width: 2.8, height: 4.5),
            p..color = const Color(0xFF116D74),
          );
        }
        box(const Rect.fromLTWH(17, 7.5, 10, 2), const Color(0x88FFF6DE), 1);
      case MenuSymbol.gift:
        box(const Rect.fromLTWH(7, 17, 27, 20), const Color(0xFFF6B737), 4, true);
        box(const Rect.fromLTWH(5, 13, 31, 7.5), cream, 3, true);
        box(const Rect.fromLTWH(18, 13, 6, 24), const Color(0xFFC9364F), 1, true);
        final bow = Paint()
          ..color = const Color(0xFFD9435E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.8;
        c.drawOval(const Rect.fromLTWH(10, 4, 10, 9), bow);
        c.drawOval(const Rect.fromLTWH(21, 4, 10, 9), bow);
        circle(21, 12, 3.2, const Color(0xFFC9364F), true);
      case MenuSymbol.settings:
        for (var i = 0; i < 8; i++) {
          c.save();
          c.translate(20, 20);
          c.rotate(i * math.pi / 4);
          box(const Rect.fromLTWH(-4, -18, 8, 10), const Color(0xFFFFE7A8), 2, true);
          c.restore();
        }
        circle(20, 20, 12.8, const Color(0xFFFFEAAD), true);
        circle(20, 20, 6.8, const Color(0xFF176C78), true);
        circle(20, 20, 3.0, const Color(0xFF8BE8E0));
        c.drawArc(
          const Rect.fromLTWH(10, 10, 20, 20),
          3.8,
          1.3,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case MenuSymbol.home:
        box(const Rect.fromLTWH(8, 18, 25, 19), const Color(0xFFFFDF9B), 4, true);
        final roof = Path()
          ..moveTo(3, 20)
          ..lineTo(20, 4)
          ..lineTo(38, 20)
          ..lineTo(33, 23)
          ..lineTo(20, 12)
          ..lineTo(8, 23)
          ..close();
        c.drawPath(roof, p..color = const Color(0xFFD75534));
        c.drawPath(roof, ink..strokeWidth = 1.8);
        box(const Rect.fromLTWH(16, 25, 9, 12), const Color(0xFF8F5230), 3, true);
        box(const Rect.fromLTWH(10, 23, 5, 6), const Color(0xFF5FC3D8), 1, true);
        circle(22, 31, 1, const Color(0xFFFFD466));
      case MenuSymbol.close:
        final stroke = Paint()
          ..color = Colors.white
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(11, 11), const Offset(29, 29), stroke);
        c.drawLine(const Offset(29, 11), const Offset(11, 29), stroke);
      case MenuSymbol.play:
        circle(20, 20, 17, const Color(0xFFC27A25));
        circle(20, 18, 17, const Color(0xFFFFF4C7));
        final tri = Path()
          ..moveTo(15.5, 9.5)
          ..lineTo(29.5, 18)
          ..lineTo(15.5, 26.5)
          ..close();
        c.drawPath(tri, p..color = const Color(0xFF107A57));
        c.drawPath(tri, ink..strokeWidth = 1.5);
      case MenuSymbol.trophy:
        final rim = Paint()
          ..color = const Color(0xFFFFD666)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        c.drawArc(const Rect.fromLTWH(4, 10, 10, 11), 1.4, 3.2, false, rim);
        c.drawArc(const Rect.fromLTWH(26, 10, 10, 11), -1.4, 3.2, false, rim);
        final cup = Path()
          ..moveTo(10, 8)
          ..lineTo(30, 8)
          ..quadraticBezierTo(29, 24, 20, 26)
          ..quadraticBezierTo(11, 24, 10, 8)
          ..close();
        c.drawPath(cup, p..color = const Color(0xFFFFD45C));
        c.drawPath(cup, ink..strokeWidth = 1.6);
        box(const Rect.fromLTWH(17, 24, 6, 7), const Color(0xFFE09F2E), 2);
        box(const Rect.fromLTWH(12, 30, 16, 5), const Color(0xFFFFE7A1), 2, true);
        circle(16, 13, 2, const Color(0xFFFFF8DC));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Illustration old) => old.symbol != symbol;
}

/// Carved expedition plaques: dark wood contour, warm bevel, bronze rim & brass rivets.
class _AdventureButtonFace extends CustomPainter {
  final Color color;
  final bool pressed, disabled, hovered, focused, prominent;
  const _AdventureButtonFace(
    this.color, {
    required this.pressed,
    required this.disabled,
    this.hovered = false,
    this.focused = false,
    this.prominent = false,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = disabled
        ? const Color(0xFFD0C3AA)
        : (hovered ? Color.lerp(color, Colors.white, .08)! : color);
    final outline = disabled
        ? const Color(0xFF7B6F5E)
        : Color.lerp(base, const Color(0xFF101216), prominent ? .74 : .68)!;
    final lip = disabled
        ? const Color(0xFF9C8E78)
        : Color.lerp(base, const Color(0xFF14110E), prominent ? .56 : .48)!;
    final drop = pressed ? 1.5 : (prominent ? 5.5 : 5.0);
    final face = Rect.fromLTWH(
      1.2,
      1.2 + (pressed ? 2.5 : 0),
      size.width - 2.4,
      size.height - drop - 2.4,
    );
    final radius = Radius.circular(math.min(15, size.height * .28));
    final innerRadius = Radius.circular(math.max(4, radius.x - 2.5));
    final p = Paint();
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), p..color = outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.0), radius),
      p..color = lip,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, radius),
      p
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: disabled
              ? const [Color(0xFFE3D8C2), Color(0xFFCEC0A6), Color(0xFFBBAE94)]
              : prominent
              ? [
                  Color.lerp(base, const Color(0xFFFFF2C8), hovered ? .22 : .15)!,
                  base,
                  Color.lerp(base, const Color(0xFF0D171F), .38)!,
                ]
              : [
                  Color.lerp(base, const Color(0xFFFFF4D6), hovered ? .32 : .24)!,
                  base,
                  Color.lerp(base, const Color(0xFF161820), .24)!,
                ],
          stops: const [0, .45, 1],
        ).createShader(face),
    );
    p.shader = null;
    final inset = face.deflate(2.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, innerRadius),
      p
        ..color = focused
            ? const Color(0xF5FFF5CC)
            : disabled
            ? const Color(0x45FFF9EA)
            : prominent
            ? const Color(0xDCE0B45A)
            : const Color(0x78FFE296)
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 2.2 : (prominent ? 1.8 : 1.3),
    );
    p.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          face.left + 10,
          face.top + 3.5,
          math.max(0, face.width - 20),
          2.2,
        ),
        const Radius.circular(1.5),
      ),
      p..color = disabled ? const Color(0x40FFFFFF) : const Color(0x42FFF9E6),
    );
    if (!disabled) {
      if (size.width >= 150 && face.height >= 42) {
        final dx = 9.0, dy = 8.5;
        for (final pt in [
          Offset(face.left + dx, face.top + dy),
          Offset(face.right - dx, face.top + dy),
          Offset(face.left + dx, face.bottom - dy),
          Offset(face.right - dx, face.bottom - dy),
        ]) {
          canvas.drawCircle(pt, 2.1, p..color = outline);
          canvas.drawCircle(
            pt.translate(-0.3, -0.35),
            1.3,
            p..color = const Color(0xFFFFD875),
          );
        }
      } else if (size.width >= 122) {
        for (final x in [face.left + 8.5, face.right - 8.5]) {
          canvas.drawCircle(Offset(x, face.center.dy), 2.0, p..color = outline);
          canvas.drawCircle(
            Offset(x - .3, face.center.dy - .4),
            1.2,
            p..color = const Color(0xFFFFD875),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AdventureButtonFace old) =>
      color != old.color ||
      pressed != old.pressed ||
      disabled != old.disabled ||
      hovered != old.hovered ||
      focused != old.focused ||
      prominent != old.prominent;
}

class _EpochEmblemPainter extends CustomPainter {
  final int stage;
  const _EpochEmblemPainter(this.stage);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 28, size.height / 28);
    final p = Paint();
    switch (stage) {
      case 0: // Ancient Desert: canyon mesa + blazing sun
        c.drawCircle(const Offset(16, 10), 6.5, p..color = const Color(0xFFFFD863));
        c.drawPath(
          Path()
            ..moveTo(2, 23)
            ..lineTo(8, 14)
            ..lineTo(14, 14)
            ..lineTo(18, 20)
            ..lineTo(26, 23)
            ..close(),
          p..color = const Color(0xFFD97236),
        );
        c.drawOval(const Rect.fromLTWH(2, 20, 24, 5), p..color = const Color(0xFFF2AA52));
      case 1: // Jurassic Monsoon: storm cloud + luminous drop
        c.drawCircle(const Offset(11, 11), 5, p..color = const Color(0xFFD8E9F8));
        c.drawCircle(const Offset(16.5, 10), 5.5, p);
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(6, 10, 16, 7), const Radius.circular(4)),
          p,
        );
        c.drawPath(
          Path()
            ..moveTo(14, 18)
            ..quadraticBezierTo(18, 22.5, 14, 25.5)
            ..quadraticBezierTo(10, 22.5, 14, 18)
            ..close(),
          p..color = const Color(0xFF69E0E6),
        );
      case 2: // Primeval Forest: layered fern canopy
        c.drawOval(const Rect.fromLTWH(6, 5, 16, 14), p..color = const Color(0xFF47CE85));
        c.drawOval(const Rect.fromLTWH(4, 11, 12, 10), p..color = const Color(0xFF289D68));
        c.drawOval(const Rect.fromLTWH(12, 11, 12, 10), p..color = const Color(0xFF34B876));
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(12.2, 17, 3.6, 8), const Radius.circular(1.5)),
          p..color = const Color(0xFF8B5836),
        );
      case 3: // Glacial Tundra: faceted ice crystal peak
        c.drawPath(
          Path()..moveTo(14, 3)..lineTo(23, 14)..lineTo(14, 25)..lineTo(5, 14)..close(),
          p..color = const Color(0xFF9CEBFF),
        );
        c.drawPath(
          Path()..moveTo(14, 3)..lineTo(23, 14)..lineTo(14, 25)..close(),
          p..color = const Color(0xFF5DC4ED),
        );
        c.drawCircle(const Offset(11, 11), 2, p..color = Colors.white);
      case 4: // Volcano Inferno: cone + magma plume
        c.drawCircle(const Offset(14, 9), 5, p..color = const Color(0xFFFFCE59));
        c.drawCircle(const Offset(14, 11), 4, p..color = const Color(0xFFFF7A3B));
        c.drawPath(
          Path()..moveTo(3, 24)..lineTo(10, 12)..lineTo(18, 12)..lineTo(25, 24)..close(),
          p..color = const Color(0xFF4A3138),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(11, 11.5, 6, 3.5), const Radius.circular(1.5)),
          p..color = const Color(0xFFFF5938),
        );
      default: // Cosmic Orbit: ringed planet + stars
        c.drawCircle(const Offset(14, 14), 7, p..color = const Color(0xFFFFC859));
        c.drawCircle(const Offset(12, 12), 2.5, p..color = const Color(0xFFFFF2B8));
        c.save();
        c.translate(14, 14);
        c.rotate(-0.42);
        c.drawOval(
          const Rect.fromLTWH(-12.5, -3.5, 25, 7),
          Paint()
            ..color = const Color(0xFF7BE7E6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.3,
        );
        c.restore();
        c.drawCircle(const Offset(23, 6), 1.5, p..color = Colors.white);
        c.drawCircle(const Offset(5, 21), 1.2, p..color = const Color(0xFFFFE599));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_EpochEmblemPainter old) => old.stage != stage;
}

class MenuChevron extends StatelessWidget {
  final bool left;
  final double size;
  final Color? color;
  const MenuChevron({
    super.key,
    this.left = false,
    this.size = 24,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.white;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ChevronPainter(left: left, color: resolved)),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final bool left;
  final Color color;
  const _ChevronPainter({required this.left, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.145
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final xNear = left ? size.width * 0.62 : size.width * 0.38;
    final xTip = left ? size.width * 0.36 : size.width * 0.64;
    final path = Path()
      ..moveTo(xNear, size.height * 0.24)
      ..lineTo(xTip, size.height * 0.50)
      ..lineTo(xNear, size.height * 0.76);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.left != left || old.color != color;
}

class MenuCheckmark extends StatelessWidget {
  final double size;
  final Color color;
  const MenuCheckmark({
    super.key,
    this.size = 12,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CheckPainter(color)),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  final Color color;
  const _CheckPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width * 0.84, size.height * 0.26);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
