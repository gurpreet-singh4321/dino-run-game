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
      canvas.drawOval(r, paint..shader = null..color = color);
  void oval3d(Rect r, Color hi, Color mid, Color lo) => canvas.drawOval(
    r,
    paint
      ..color = const Color(0xFFFFFFFF)
      ..shader = linear3d(r, hi, mid, lo),
  );
  void box3d(Rect r, double radius, Color hi, Color mid, Color lo) =>
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(radius)),
        paint
          ..color = const Color(0xFFFFFFFF)
          ..shader = linear3d(r, hi, mid, lo),
      );
  switch (item.id) {
    case 'explorer_hat':
      oval(const Rect.fromLTWH(-28, -1, 56, 9), const Color(0x362E1404));
      oval3d(const Rect.fromLTWH(-34, -5, 68, 12),
          const Color(0xFFA06A3E), const Color(0xFF80502D), const Color(0xFF543018));
      box3d(const Rect.fromLTWH(-23, -24, 46, 25), 12,
          const Color(0xFFF0C684), const Color(0xFFD5A665), const Color(0xFF9C6E36));
      box3d(const Rect.fromLTWH(-23, -7, 46, 7), 2,
          const Color(0xFF8C5939), const Color(0xFF75472B), const Color(0xFF4B2B17));
      oval3d(const Rect.fromLTWH(-31, -2, 64, 7),
          const Color(0xFFF6D294), const Color(0xFFE5BB7C), const Color(0xFFB58648));
      oval3d(const Rect.fromLTWH(4, -15, 8, 8),
          const Color(0xFFFFF2B8), const Color(0xFFFFDB88), const Color(0xFFC28B2A));
    case 'winter_hat':
      oval(const Rect.fromLTWH(-28, 0, 56, 8), const Color(0x38132C44));
      oval3d(const Rect.fromLTWH(-26, -25, 52, 34),
          const Color(0xFF6AB2E2), const Color(0xFF4387B9), const Color(0xFF275880));
      box3d(const Rect.fromLTWH(-28, -4, 56, 10), 4,
          const Color(0xFFB0E4F7), const Color(0xFF86CEE5), const Color(0xFF539AB5));
      oval3d(const Rect.fromLTWH(-7, -34, 14, 14),
          const Color(0xFFFFFFFF), const Color(0xFFE1F5FA), const Color(0xFF9EC7D8));
      for (int i = -18; i <= 18; i += 9) {
        canvas.drawLine(
          Offset(i.toDouble(), -18),
          Offset(i.toDouble(), -7),
          paint
            ..shader = null
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
        paint
          ..color = const Color(0xFFFFFFFF)
          ..shader = Gradient.linear(
            const Offset(-43, -7),
            const Offset(-12, 10),
            mint
                ? const [Color(0xFF39CCC0), Color(0xFF087C80)]
                : const [Color(0xFFF36052), Color(0xFF9F2326)],
          ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-23, -1.5, 46, 11),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0x45380E08),
      );
      box3d(
        const Rect.fromLTWH(-23, -3, 46, 11),
        5,
        mint ? const Color(0xFF7BF2E4) : const Color(0xFFFF7A6A),
        mint ? const Color(0xFF36C8BA) : const Color(0xFFE75244),
        mint ? const Color(0xFF0A8583) : const Color(0xFFA72527),
      );
      final bib = Path()
        ..moveTo(0, 6)
        ..lineTo(21, 5)
        ..lineTo(12, 23)
        ..close();
      canvas.drawPath(
        bib,
        paint
          ..color = const Color(0xFFFFFFFF)
          ..shader = Gradient.linear(
            const Offset(0, 5),
            const Offset(18, 22),
            mint
                ? const [Color(0xFF42DBD0), Color(0xFF0D7C7B)]
                : const [Color(0xFFF46154), Color(0xFF9C2224)],
          ),
      );
    case 'leaf_crown':
      box3d(const Rect.fromLTWH(-27, -4, 54, 7), 3,
          const Color(0xFF42A872), const Color(0xFF277B52), const Color(0xFF164F33));
      for (var i = -2; i <= 2; i++) {
        final x = i * 11.0;
        final leaf = Path()
          ..moveTo(x, -1)
          ..quadraticBezierTo(x - 13, -13, x - 5, -24)
          ..quadraticBezierTo(x + 10, -17, x, -1);
        canvas.drawPath(
          leaf,
          paint
            ..color = const Color(0xFFFFFFFF)
            ..shader = Gradient.linear(
              Offset(x - 10, -24),
              Offset(x + 5, -1),
              i.isEven
                  ? const [Color(0xFF93E59C), Color(0xFF3D9E59)]
                  : const [Color(0xFFD1F7A3), Color(0xFF74BC5B)],
            ),
        );
        canvas.drawLine(
          Offset(x, -3),
          Offset(x - 4, -19),
          paint
            ..shader = null
            ..color = const Color(0xFF388957)
            ..strokeWidth = 1.4,
        );
      }
      oval3d(const Rect.fromLTWH(12, -9, 8, 8),
          const Color(0xFFFFF0A8), const Color(0xFFFFCB55), const Color(0xFFBD801E));
    case 'aviator_hat':
      oval(const Rect.fromLTWH(-27, -2, 54, 10), const Color(0x38281204));
      box3d(const Rect.fromLTWH(-25, -24, 50, 28), 13,
          const Color(0xFFBA8058), const Color(0xFF986441), const Color(0xFF5D371F));
      box3d(const Rect.fromLTWH(-28, -7, 12, 20), 5,
          const Color(0xFF966143), const Color(0xFF75452E), const Color(0xFF462516));
      box3d(const Rect.fromLTWH(17, -7, 12, 20), 5,
          const Color(0xFF966143), const Color(0xFF75452E), const Color(0xFF462516));
      box3d(const Rect.fromLTWH(-25, -8, 50, 6), 2,
          const Color(0xFFF6D196), const Color(0xFFE1B97E), const Color(0xFFA67C45));
      for (final x in [-17.0, 2.0]) {
        box3d(Rect.fromLTWH(x, -16, 16, 13), 5,
            const Color(0xFFF5D086), const Color(0xFFDBB36C), const Color(0xFF9B7233));
        box3d(Rect.fromLTWH(x + 2, -14, 12, 9), 3,
            const Color(0xFF9DF0F6), const Color(0xFF6ECBD4), const Color(0xFF358A94));
        oval(Rect.fromLTWH(x + 4, -13, 4, 3), const Color(0xDDFFFFFF));
      }
    case 'space_helmet':
      oval(const Rect.fromLTWH(-39, -16, 78, 70), const Color(0x288DEDF1));
      canvas.drawOval(
        const Rect.fromLTWH(-39, -16, 78, 70),
        Paint()
          ..color = const Color(0xFFCFF4F9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawArc(
        const Rect.fromLTWH(-34, -11, 68, 60),
        3.6,
        .8,
        false,
        Paint()
          ..color = const Color(0xEEFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      box3d(const Rect.fromLTWH(-33, 44, 66, 9), 5,
          const Color(0xFFFFFFFF), const Color(0xFFE5F4F5), const Color(0xFF9CB8C2));
      oval3d(const Rect.fromLTWH(-40, 18, 16, 20),
          const Color(0xFF83CCE0), const Color(0xFF5EA9BA), const Color(0xFF367385));
      oval3d(const Rect.fromLTWH(-37, 22, 10, 12),
          const Color(0xFFEEFCFF), const Color(0xFFCCEAF1), const Color(0xFF8BB7C4));
      box3d(const Rect.fromLTWH(18, 45, 9, 6), 2,
          const Color(0xFFFFE594), const Color(0xFFF4BA55), const Color(0xFFB3781F));
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
        paint
          ..color = const Color(0xFFFFFFFF)
          ..shader = Gradient.linear(
            const Offset(-28, -20),
            const Offset(4, 26),
            const [Color(0xFF58BC85), Color(0xFF318F61), Color(0xFF1A5A3A)],
            const [0, .5, 1],
          ),
      );
      canvas.drawLine(
        const Offset(-10, -17),
        const Offset(-14, 19),
        Paint()
          ..color = const Color(0xFF94D886)
          ..strokeWidth = 2,
      );
    case 'star_pack':
      box3d(const Rect.fromLTWH(-17, -16, 29, 38), 10,
          const Color(0xFF726BC4), const Color(0xFF504A99), const Color(0xFF2D2866));
      box3d(const Rect.fromLTWH(-14, -14, 23, 20), 7,
          const Color(0xFFABA3F0), const Color(0xFF8E85D4), const Color(0xFF5B53A3));
      box3d(const Rect.fromLTWH(-12, 9, 20, 10), 4,
          const Color(0xFF8880D4), const Color(0xFF6961B6), const Color(0xFF423C87));
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
        paint
          ..color = const Color(0xFFFFFFFF)
          ..shader = Gradient.linear(
            const Offset(-12, -11),
            const Offset(7, 7),
            const [Color(0xFFFFF4AE), Color(0xFFFFD96D), Color(0xFFD69A2B)],
            const [0, .5, 1],
          ),
      );
    case 'explorer_pack':
      box3d(const Rect.fromLTWH(-16, -15, 27, 35), 8,
          const Color(0xFF8C5C41), const Color(0xFF6C432E), const Color(0xFF422618));
      box3d(const Rect.fromLTWH(-13, -13, 22, 17), 6,
          const Color(0xFFDFAB71), const Color(0xFFC18B52), const Color(0xFF8A5D2E));
      box3d(const Rect.fromLTWH(-11, 7, 18, 11), 3,
          const Color(0xFFBD8556), const Color(0xFF9F6A3F), const Color(0xFF6C4221));
      box3d(const Rect.fromLTWH(-4, 0, 5, 8), 1,
          const Color(0xFFFFEFA6), const Color(0xFFF2CB77), const Color(0xFFAF7E28));
  }
  canvas.restore();
}
