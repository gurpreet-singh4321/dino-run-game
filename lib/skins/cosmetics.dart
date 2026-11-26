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
  void oval(Rect r, Color color) => canvas.drawOval(r, paint..color = color);
  void box(Rect r, double radius, Color color) => canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    paint..color = color,
  );
  switch (item.id) {
    case 'explorer_hat':
      oval(const Rect.fromLTWH(-34, -5, 68, 12), const Color(0xFF80502D));
      box(const Rect.fromLTWH(-23, -24, 46, 25), 12, const Color(0xFFD5A665));
      box(const Rect.fromLTWH(-23, -7, 46, 7), 2, const Color(0xFF75472B));
      oval(const Rect.fromLTWH(-31, -2, 64, 7), const Color(0xFFE5BB7C));
      oval(const Rect.fromLTWH(4, -15, 8, 8), const Color(0xFFFFDB88));
    case 'winter_hat':
      oval(const Rect.fromLTWH(-26, -25, 52, 34), const Color(0xFF4387B9));
      box(const Rect.fromLTWH(-28, -4, 56, 10), 4, const Color(0xFF86CEE5));
      oval(const Rect.fromLTWH(-7, -34, 14, 14), const Color(0xFFE1F5FA));
      for (int i = -18; i <= 18; i += 9) {
        canvas.drawLine(
          Offset(i.toDouble(), -18),
          Offset(i.toDouble(), -7),
          paint
            ..color = const Color(0xFF6EB1D5)
            ..strokeWidth = 2,
        );
      }
    case 'red_scarf':
    case 'mint_scarf':
      final mint = item.id == 'mint_scarf';
      final tail = Path()
        ..moveTo(-15, 0)
        ..lineTo(-43, -7)
        ..lineTo(-36, 4)
        ..lineTo(-43, 10)
        ..lineTo(-12, 7)
        ..close();
      canvas.drawPath(
        tail,
        paint..color = mint ? const Color(0xFF087C80) : const Color(0xFFBF3638),
      );
      box(
        const Rect.fromLTWH(-23, -3, 46, 11),
        5,
        mint ? const Color(0xFF55D9CA) : const Color(0xFFE75244),
      );
      final bib = Path()
        ..moveTo(0, 6)
        ..lineTo(21, 5)
        ..lineTo(12, 23)
        ..close();
      canvas.drawPath(
        bib,
        paint..color = mint ? const Color(0xFF24AEA9) : const Color(0xFFD84138),
      );
    case 'leaf_crown':
      box(const Rect.fromLTWH(-27, -4, 54, 7), 3, const Color(0xFF277B52));
      for (var i = -2; i <= 2; i++) {
        final x = i * 11.0;
        final leaf = Path()
          ..moveTo(x, -1)
          ..quadraticBezierTo(x - 13, -13, x - 5, -24)
          ..quadraticBezierTo(x + 10, -17, x, -1);
        canvas.drawPath(
          leaf,
          paint
            ..color = i.isEven
                ? const Color(0xFF63C778)
                : const Color(0xFFB2E684),
        );
        canvas.drawLine(
          Offset(x, -3),
          Offset(x - 4, -19),
          paint
            ..color = const Color(0xFF388957)
            ..strokeWidth = 1.4,
        );
      }
      oval(const Rect.fromLTWH(12, -9, 8, 8), const Color(0xFFFFCB55));
    case 'aviator_hat':
      box(const Rect.fromLTWH(-25, -24, 50, 28), 13, const Color(0xFF986441));
      box(const Rect.fromLTWH(-28, -7, 12, 20), 5, const Color(0xFF75452E));
      box(const Rect.fromLTWH(17, -7, 12, 20), 5, const Color(0xFF75452E));
      box(const Rect.fromLTWH(-25, -8, 50, 6), 2, const Color(0xFFE1B97E));
      for (final x in [-17.0, 2.0]) {
        box(Rect.fromLTWH(x, -16, 16, 13), 5, const Color(0xFFDBB36C));
        box(Rect.fromLTWH(x + 2, -14, 12, 9), 3, const Color(0xFF6ECBD4));
        oval(Rect.fromLTWH(x + 4, -13, 4, 3), const Color(0xCCFFFFFF));
      }
    case 'space_helmet':
      oval(const Rect.fromLTWH(-39, -16, 78, 70), const Color(0x228DEDF1));
      canvas.drawOval(
        const Rect.fromLTWH(-39, -16, 78, 70),
        Paint()
          ..color = const Color(0xFFB8EAF1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawArc(
        const Rect.fromLTWH(-34, -11, 68, 60),
        3.6,
        .8,
        false,
        Paint()
          ..color = const Color(0xDDFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      box(const Rect.fromLTWH(-33, 44, 66, 9), 5, const Color(0xFFE5F4F5));
      oval(const Rect.fromLTWH(-40, 18, 16, 20), const Color(0xFF5EA9BA));
      oval(const Rect.fromLTWH(-37, 22, 10, 12), const Color(0xFFCCEAF1));
      box(const Rect.fromLTWH(18, 45, 9, 6), 2, const Color(0xFFF4BA55));
    case 'leaf_cape':
      canvas.drawPath(
        Path()
          ..moveTo(-10, -22)
          ..quadraticBezierTo(-30, -5, -25, 25)
          ..lineTo(-17, 20)
          ..lineTo(-10, 27)
          ..lineTo(-3, 19)
          ..quadraticBezierTo(8, -7, -10, -22)
          ..close(),
        paint..color = const Color(0xFF318F61),
      );
      canvas.drawLine(
        const Offset(-10, -17),
        const Offset(-14, 19),
        Paint()
          ..color = const Color(0xFF94D886)
          ..strokeWidth = 2,
      );
    case 'star_pack':
      box(const Rect.fromLTWH(-17, -16, 29, 38), 10, const Color(0xFF504A99));
      box(const Rect.fromLTWH(-14, -14, 23, 20), 7, const Color(0xFF8E85D4));
      box(const Rect.fromLTWH(-12, 9, 20, 10), 4, const Color(0xFF6961B6));
      canvas.drawPath(
        Path()
          ..moveTo(-3, -11)
          ..lineTo(0, -5)
          ..lineTo(7, -4)
          ..lineTo(2, 0)
          ..lineTo(3, 7)
          ..lineTo(-3, 3)
          ..lineTo(-9, 7)
          ..lineTo(-8, 0)
          ..lineTo(-13, -4)
          ..lineTo(-6, -5)
          ..close(),
        paint..color = const Color(0xFFFFD96D),
      );
    case 'explorer_pack':
      box(const Rect.fromLTWH(-16, -15, 27, 35), 8, const Color(0xFF6C432E));
      box(const Rect.fromLTWH(-13, -13, 22, 17), 6, const Color(0xFFC18B52));
      box(const Rect.fromLTWH(-11, 7, 18, 11), 3, const Color(0xFF9F6A3F));
      box(const Rect.fromLTWH(-4, 0, 5, 8), 1, const Color(0xFFF2CB77));
  }
  canvas.restore();
}
