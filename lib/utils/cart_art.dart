import '../skins/cart_skins.dart';
import 'gear_assets.dart';
import 'dart:ui';
import 'dart:math' as math;

/// Shared recorded chassis; wheels and charge lights are the only moving parts.
class CartArt {
  static final Picture _body = _record();
  static Picture _record() {
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final rect = const Rect.fromLTWH(3, 17, 93, 23);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = Gradient.linear(const Offset(0, 17), const Offset(90, 40), [
          const Color(0xFFFFD785),
          const Color(0xFFC37A38),
        ]),
    );
    for (var i = 0; i < 3; i++) {
      c.drawLine(
        Offset(10, 22.0 + i * 5),
        Offset(84, 22.0 + i * 5),
        Paint()
          ..color = const Color(0xFF9B5D31)
          ..strokeWidth = 1,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 15, 92, 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF218D8F),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(89, 19, 14, 19),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFE45A4C),
    );
    c.drawLine(
      const Offset(94, 22),
      const Offset(98, 22),
      Paint()
        ..color = const Color(0xFFFFB19A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final x in [9.0, 81.0]) {
      c.drawCircle(Offset(x, 18), 2, Paint()..color = const Color(0xFFFFE7AA));
    }
    return recorder.endRecording();
  }

  static Path _frontShellPath() => Path()
    ..moveTo(-5, 13.5)
    ..lineTo(28, 14.2)
    ..quadraticBezierTo(36, 17.2, 44, 18.0)
    ..quadraticBezierTo(48, 18.4, 52, 18.4)
    ..quadraticBezierTo(57.5, 18.3, 61.5, 17.8)
    ..quadraticBezierTo(63.2, 15.2, 64.5, 13.2)
    ..quadraticBezierTo(66, 11.4, 68, 11.4)
    ..lineTo(108, 11.4)
    ..lineTo(108, 56)
    ..lineTo(-5, 56)
    ..close();

  /// Clips a seated occupant above the curved cockpit door lip and behind the
  /// front dashboard cowl (called in `CartArt` coordinate space).
  static void clipOccupant(Canvas c) {
    final p = Path()
      ..moveTo(-12, -100)
      ..lineTo(115, -100)
      ..lineTo(115, 12.2)
      ..lineTo(68, 12.2)
      ..quadraticBezierTo(65.5, 12.6, 64.2, 14.5)
      ..quadraticBezierTo(63, 16.4, 61.5, 18.6)
      ..quadraticBezierTo(57.5, 19.2, 52, 19.3)
      ..quadraticBezierTo(48, 19.3, 44, 18.9)
      ..quadraticBezierTo(36, 18.1, 28, 15.2)
      ..lineTo(-12, 14.5)
      ..close();
    c.clipPath(p);
  }

  static void rear(Canvas c, {String skinId = 'fossil_rover'}) {
    final image = GearAssets.cart;
    if (image != null) {
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height * .36),
        const Rect.fromLTWH(0, 3.1, 103, 17.68),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = CartSkinCatalog.filter(skinId),
      );
      return;
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 5, 14, 20),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF33797A),
    );
    c.drawLine(
      const Offset(68, 20),
      const Offset(76, 5),
      Paint()
        ..color = const Color(0xFF3E4651)
        ..strokeWidth = 3,
    );
    c.drawOval(
      const Rect.fromLTWH(68, 1, 17, 7),
      Paint()..color = const Color(0xFFDB9F54),
    );
  }

  static void front(
    Canvas c, {
    required int charges,
    required double distance,
    String skinId = 'fossil_rover',
  }) {
    final image = GearAssets.cart;
    if (image != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height * .955,
      );
      const dst = Rect.fromLTWH(0, 3.1, 103, 46.88);
      c.save();
      c.clipPath(_frontShellPath());
      c.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = CartSkinCatalog.filter(skinId),
      );
      for (var i = 0; i < 3; i++) {
        if (i < charges) {
          c.drawCircle(
            Offset(40.0 + i * 8.6, 28.4),
            2.2,
            Paint()..color = const Color(0xFFFFCF59),
          );
          c.drawCircle(
            Offset(39.4 + i * 8.6, 27.7),
            .6,
            Paint()..color = const Color(0xFFFFF2BE),
          );
        }
      }
      // Rotate the actual painted wheel regions around their true circular hubs.
      for (final hub in const [Offset(16.95, 35.80), Offset(76.84, 36.93)]) {
        c.save();
        c.clipPath(
          Path()..addOval(Rect.fromCircle(center: hub, radius: 13.6)),
        );
        c.translate(hub.dx, hub.dy);
        c.rotate(distance / 13.6);
        c.translate(-hub.dx, -hub.dy);
        c.drawImageRect(
          image,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..colorFilter = CartSkinCatalog.filter(skinId),
        );
        c.restore();
      }
      c.restore();
      return;
    }
    c.drawPicture(_body);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(45.0 + i * 11, 29),
        4,
        Paint()
          ..color = i < charges
              ? const Color(0xFFFFE076)
              : const Color(0xFF795636),
      );
    }
    for (final x in [20.0, 80.0]) {
      c.save();
      c.translate(x, 38);
      c.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xFF293C49));
      c.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF55717C));
      c.rotate(distance / 12);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        c.drawLine(
          Offset.zero,
          Offset(math.cos(a) * 7, math.sin(a) * 7),
          Paint()
            ..color = const Color(0xFFCEDBD6)
            ..strokeWidth = 2,
        );
      }
      c.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFFFFC85B));
      c.restore();
    }
  }
}
