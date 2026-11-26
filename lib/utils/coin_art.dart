import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// One cached stamped coin face for the wallet, HUD and spinning pickups.
class CoinArt {
  static final ui.Picture _face = _record();
  static ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    _paint(Canvas(recorder), const Size(28, 28));
    return recorder.endRecording();
  }

  static void draw(Canvas canvas, Rect bounds) {
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width / 28, bounds.height / 28);
    canvas.drawPicture(_face);
    canvas.restore();
  }

  static void _paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    canvas.drawOval(
      const Rect.fromLTWH(2, 4, 24, 23),
      Paint()..color = const Color(0xFFA67128),
    );
    canvas.drawOval(
      const Rect.fromLTWH(2, 1, 24, 23),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDD79), Color(0xFFDDA43A)],
        ).createShader(const Rect.fromLTWH(2, 1, 24, 23)),
    );
    canvas.drawCircle(
      const Offset(14, 12),
      8.5,
      Paint()
        ..color = const Color(0xFFBA8430)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final stamp = Paint()..color = const Color(0xFFAF7829);
    canvas.drawOval(const Rect.fromLTWH(10, 11, 8, 7), stamp);
    for (final point in [
      const Offset(9, 9),
      const Offset(14, 7),
      const Offset(19, 9),
    ]) {
      canvas.drawCircle(point, 2, stamp);
    }
    canvas.restore();
  }
}
