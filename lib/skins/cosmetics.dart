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
  const CosmeticFit({this.head = const Offset(.56, .17),
    this.neck = const Offset(.53, .51),
    this.back = const Offset(.26, .57), this.scale = 1});

  Offset anchor(CosmeticSlot slot) => switch (slot) {
    CosmeticSlot.head => head,
    CosmeticSlot.neck => neck,
    CosmeticSlot.back => back,
  };
}

void drawCosmetic(Canvas canvas, Size size, CosmeticFit fit, CosmeticItem item) {
  final anchor = fit.anchor(item.slot);
  canvas.save();
  canvas.translate(size.width * anchor.dx, size.height * anchor.dy);
  canvas.scale(size.width / 100 * fit.scale);
  final paint = Paint();
  void oval(Rect r, Color color) => canvas.drawOval(r, paint..color = color);
  void box(Rect r, double radius, Color color) => canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)), paint..color = color);
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
        canvas.drawLine(Offset(i.toDouble(), -18), Offset(i.toDouble(), -7),
          paint..color = const Color(0xFF6EB1D5)..strokeWidth = 2);
      }
    case 'red_scarf':
      final tail = Path()..moveTo(-15, 0)..lineTo(-43, -7)
        ..lineTo(-36, 4)..lineTo(-43, 10)..lineTo(-12, 7)..close();
      canvas.drawPath(tail, paint..color = const Color(0xFFBF3638));
      box(const Rect.fromLTWH(-23, -3, 46, 11), 5, const Color(0xFFE75244));
      final bib = Path()..moveTo(0, 6)..lineTo(21, 5)..lineTo(12, 23)..close();
      canvas.drawPath(bib, paint..color = const Color(0xFFD84138));
    case 'explorer_pack':
      box(const Rect.fromLTWH(-16, -15, 27, 35), 8, const Color(0xFF6C432E));
      box(const Rect.fromLTWH(-13, -13, 22, 17), 6, const Color(0xFFC18B52));
      box(const Rect.fromLTWH(-11, 7, 18, 11), 3, const Color(0xFF9F6A3F));
      box(const Rect.fromLTWH(-4, 0, 5, 8), 1, const Color(0xFFF2CB77));
  }
  canvas.restore();
}
