import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Cached orbital painting: open starfield, distant planet and a curved horizon.
/// No landscape floor, per-frame blur, asset decode or steady-state saveLayer.
class OrbitalScenery {
  static final ui.Picture _painting = _record();
  static void draw(Canvas canvas, Size size, double opacity) {
    if (opacity <= 0) return;
    canvas.save();
    canvas.scale(size.width / 640, size.height / 360);
    if (opacity < .999) {
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, 640, 360),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
    canvas.drawPicture(_painting);
    if (opacity < .999) canvas.restore();
    canvas.restore();
  }

  static ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    const frame = Rect.fromLTWH(0, 0, 640, 360);
    c.drawRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF03091B), Color(0xFF101A3B), Color(0xFF251A43)],
        ).createShader(frame),
    );
    for (final glow in [
      (const Offset(210, 85), 210.0, const Color(0x5533409E)),
      (const Offset(420, 245), 230.0, const Color(0x333889B1)),
      (const Offset(580, 20), 160.0, const Color(0x445F2F85)),
    ]) {
      final rect = Rect.fromCircle(center: glow.$1, radius: glow.$2);
      c.drawCircle(
        glow.$1,
        glow.$2,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.$3, Colors.transparent],
          ).createShader(rect),
      );
    }
    // A ringed gas giant stays distant, leaving the playable coin lanes clear.
    c.save();
    c.translate(515, 91);
    c.rotate(-.28);
    const rings = Rect.fromLTWH(-102, -23, 204, 46);
    c.drawOval(
      rings,
      Paint()
        ..color = const Color(0x99779FB8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    c.drawOval(
      rings.inflate(5),
      Paint()
        ..color = const Color(0x445A7C9F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    const planet = Rect.fromLTWH(-47, -47, 94, 94);
    c.drawCircle(
      Offset.zero,
      47,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.55, -.55),
          radius: 1.2,
          colors: [
            Color(0xFFFFD998),
            Color(0xFFBA847C),
            Color(0xFF534663),
            Color(0xFF182741),
          ],
        ).createShader(planet),
    );
    c.save();
    c.clipPath(Path()..addOval(planet));
    for (var i = 0; i < 5; i++) {
      c.drawArc(
        Rect.fromLTWH(-70, -35 + i * 13, 145, 35),
        .1,
        2.8,
        false,
        Paint()
          ..color = const Color(0x5579516F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    c.restore();
    c.drawArc(
      rings,
      0,
      3.14159,
      false,
      Paint()
        ..color = const Color(0xCCABD1D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    c.restore();
    // The curved blue limb reads as orbit, rather than a rocky alien level.
    const earth = Rect.fromLTWH(-115, 292, 670, 670);
    c.drawOval(
      earth,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF277AAD), Color(0xFF102C60), Color(0xFF071528)],
        ).createShader(earth),
    );
    c.drawOval(
      earth,
      Paint()
        ..color = const Color(0x887ECDEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    c.drawOval(
      earth.inflate(5),
      Paint()
        ..color = const Color(0x2256ACD6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    return recorder.endRecording();
  }
}
