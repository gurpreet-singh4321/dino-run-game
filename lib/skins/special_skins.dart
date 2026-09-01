import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'skin.dart';

/// ⚡ Cyberpunk Neon Dino with holographic visor & matrix energy trails
class CyberNeonDinoSkin extends CharacterSkin {
  @override
  String get id => 'cyber_dino';

  @override
  String get displayName => 'Cyber Dino';

  @override
  String get description => 'Equipped with a cybernetic holo-visor and neon matrix plating.';

  @override
  String get rarity => 'Rare';

  @override
  int get price => 250;

  @override
  Color get primaryColor => const Color(0xFF00E5FF);

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) {
    _renderCyberDino(canvas, size, animFrame, isJumping: false);
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    _renderCyberDino(canvas, size, 0, isJumping: true);
  }

  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) {
    _renderCyberDino(canvas, size, 0, isJumping: true, isSpace: true);
  }

  void _renderCyberDino(Canvas canvas, Size size, int frame, {bool isJumping = false, bool isSpace = false}) {
    canvas.save();
    if (!isJumping && frame % 2 == 1) {
      canvas.translate(0, 3);
    }

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // 1. Neon Aura Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.4, glowPaint);

    // 2. Dark Cyber Armor Body
    final bodyPaint = Paint()..color = const Color(0xFF0F172A);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: size.width * 0.65, height: size.height * 0.7),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Neon Cyber Circuit Stripes
    final strokePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(bodyRect, strokePaint);

    // 3. Cyber Head & Holo Visor
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 8, cy - 14), width: size.width * 0.55, height: size.height * 0.4),
      const Radius.circular(10),
    );
    canvas.drawRRect(headRect, bodyPaint);
    canvas.drawRRect(headRect, strokePaint);

    // Visor Glass (Glowing Neon Magenta / Cyan gradient)
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 14, cy - 14), width: size.width * 0.38, height: 12),
      const Radius.circular(4),
    );
    final visorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF007F), Color(0xFF00E5FF)],
      ).createShader(visorRect.outerRect);
    canvas.drawRRect(visorRect, visorPaint);

    // 4. Cybernetic Jet / Roller Feet
    final footPaint = Paint()..color = const Color(0xFF38BDF8);
    final legY = cy + size.height * 0.38;
    final legShift = (!isJumping && frame % 2 == 1) ? 5.0 : -5.0;
    canvas.drawCircle(Offset(cx - 10 + legShift, legY), 6, footPaint);
    canvas.drawCircle(Offset(cx + 10 - legShift, legY), 6, footPaint);

    canvas.restore();
  }
}

/// 👑 Pure 24K Golden Emperor Dino with shimmering crown
class GoldenEmperorSkin extends CharacterSkin {
  @override
  String get id => 'gold_dino';

  @override
  String get displayName => 'Golden Emperor';

  @override
  String get description => 'Forged in pure molten gold with a glowing diamond capstone.';

  @override
  String get rarity => 'Legendary';

  @override
  int get price => 500;

  @override
  Color get primaryColor => const Color(0xFFFFD700);

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) {
    _renderGoldDino(canvas, size, animFrame, isJumping: false);
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    _renderGoldDino(canvas, size, 0, isJumping: true);
  }

  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) {
    _renderGoldDino(canvas, size, 0, isJumping: true);
  }

  void _renderGoldDino(Canvas canvas, Size size, int frame, {bool isJumping = false}) {
    canvas.save();
    if (!isJumping && frame % 2 == 1) {
      canvas.translate(0, 3);
    }

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // 1. Golden Shimmer Radial Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, glowPaint);

    // 2. Gold Gradient Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: size.width * 0.65, height: size.height * 0.7),
      const Radius.circular(18),
    );
    final goldShader = const LinearGradient(
      colors: [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFB78103)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bodyRect.outerRect);

    canvas.drawRRect(bodyRect, Paint()..shader = goldShader);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFFFFFDE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 3. Head & Golden Crown
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 8, cy - 14), width: size.width * 0.55, height: size.height * 0.4),
      const Radius.circular(12),
    );
    canvas.drawRRect(headRect, Paint()..shader = goldShader);

    // Eye
    canvas.drawCircle(Offset(cx + 18, cy - 16), 4, Paint()..color = const Color(0xFF3E2723));
    canvas.drawCircle(Offset(cx + 19, cy - 17), 1.5, Paint()..color = Colors.white);

    // Emperor's Crown
    final crownPath = Path()
      ..moveTo(cx - 2, cy - 30)
      ..lineTo(cx + 4, cy - 42)
      ..lineTo(cx + 10, cy - 32)
      ..lineTo(cx + 16, cy - 42)
      ..lineTo(cx + 22, cy - 32)
      ..lineTo(cx + 28, cy - 42)
      ..lineTo(cx + 34, cy - 30)
      ..close();
    canvas.drawPath(crownPath, Paint()..shader = goldShader);
    canvas.drawPath(crownPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Crown Ruby Jewels
    canvas.drawCircle(Offset(cx + 4, cy - 39), 2, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(cx + 16, cy - 39), 2, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(cx + 28, cy - 39), 2, Paint()..color = const Color(0xFFFF1744));

    // Feet
    final legY = cy + size.height * 0.38;
    final legShift = (!isJumping && frame % 2 == 1) ? 6.0 : -6.0;
    canvas.drawCircle(Offset(cx - 10 + legShift, legY), 6, Paint()..color = const Color(0xFFB78103));
    canvas.drawCircle(Offset(cx + 10 - legShift, legY), 6, Paint()..color = const Color(0xFFB78103));

    canvas.restore();
  }
}

/// 🚀 Astronaut Dino with Deep Space Jetpack & Gold Bubble Visor
class AstronautDinoSkin extends CharacterSkin {
  @override
  String get id => 'astro_dino';

  @override
  String get displayName => 'Astro Dino';

  @override
  String get description => 'Equipped with pressurized lunar suit and cosmic thrusters.';

  @override
  String get rarity => 'Epic';

  @override
  int get price => 350;

  @override
  Color get primaryColor => const Color(0xFFB388FF);

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) {
    _renderAstroDino(canvas, size, animFrame, isJumping: false);
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    _renderAstroDino(canvas, size, 0, isJumping: true);
  }

  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) {
    _renderAstroDino(canvas, size, 0, isJumping: true);
  }

  void _renderAstroDino(Canvas canvas, Size size, int frame, {bool isJumping = false}) {
    canvas.save();
    if (!isJumping && frame % 2 == 1) {
      canvas.translate(0, 3);
    }

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // 1. Oxygen Tank Backpack
    final tankRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 20, cy + 2), width: 14, height: size.height * 0.55),
      const Radius.circular(6),
    );
    canvas.drawRRect(tankRect, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawRRect(tankRect, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // 2. White Space Suit Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: size.width * 0.65, height: size.height * 0.7),
      const Radius.circular(18),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // NASA/Space Badge on Chest
    canvas.drawCircle(Offset(cx - 4, cy + 6), 4.5, Paint()..color = const Color(0xFF0284C7));
    canvas.drawCircle(Offset(cx - 4, cy + 6), 2, Paint()..color = const Color(0xFFEF4444));

    // 3. Space Helmet Glass Visor
    final helmetCenter = Offset(cx + 8, cy - 14);
    final helmetRadius = size.width * 0.32;
    canvas.drawCircle(helmetCenter, helmetRadius, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawCircle(helmetCenter, helmetRadius, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Gold Mirrored Visor
    final visorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(Rect.fromCircle(center: helmetCenter, radius: helmetRadius * 0.75));
    canvas.drawCircle(helmetCenter, helmetRadius * 0.75, visorPaint);

    // Visor Glint Reflection
    canvas.drawArc(
      Rect.fromCircle(center: helmetCenter, radius: helmetRadius * 0.55),
      -math.pi * 0.8,
      math.pi * 0.4,
      false,
      Paint()..color = Colors.white.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );

    // Space Boots
    final legY = cy + size.height * 0.38;
    final legShift = (!isJumping && frame % 2 == 1) ? 5.0 : -5.0;
    canvas.drawCircle(Offset(cx - 10 + legShift, legY), 6.5, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(Offset(cx + 10 - legShift, legY), 6.5, Paint()..color = const Color(0xFF334155));

    canvas.restore();
  }
}

/// 🌋 Magma Dragon Dino with obsidian skin and flaming horns
class MagmaDragonSkin extends CharacterSkin {
  @override
  String get id => 'magma_dino';

  @override
  String get displayName => 'Magma Dragon';

  @override
  String get description => 'Born from volcanic infernos, surging with molten magma power.';

  @override
  String get rarity => 'Epic';

  @override
  int get price => 400;

  @override
  Color get primaryColor => const Color(0xFFFF5722);

  @override
  void renderRunning(Canvas canvas, Size size, int animFrame) {
    _renderMagmaDino(canvas, size, animFrame, isJumping: false);
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    _renderMagmaDino(canvas, size, 0, isJumping: true);
  }

  @override
  void renderSpace(Canvas canvas, Size size, int animFrame) {
    _renderMagmaDino(canvas, size, 0, isJumping: true);
  }

  void _renderMagmaDino(Canvas canvas, Size size, int frame, {bool isJumping = false}) {
    canvas.save();
    if (!isJumping && frame % 2 == 1) {
      canvas.translate(0, 3);
    }

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // 1. Lava Heat Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, glowPaint);

    // 2. Obsidian Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 6), width: size.width * 0.65, height: size.height * 0.7),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF1E1B1B));
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFF7043)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Glowing Lava Veins on Body
    final lavaVeinPaint = Paint()
      ..color = const Color(0xFFFFAB00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final veinPath = Path()
      ..moveTo(cx - 12, cy)
      ..lineTo(cx - 2, cy + 10)
      ..lineTo(cx + 10, cy + 4)
      ..lineTo(cx + 16, cy + 18);
    canvas.drawPath(veinPath, lavaVeinPaint);

    // 3. Head & Flaming Horns
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 8, cy - 14), width: size.width * 0.55, height: size.height * 0.4),
      const Radius.circular(10),
    );
    canvas.drawRRect(headRect, Paint()..color = const Color(0xFF1E1B1B));
    canvas.drawRRect(headRect, Paint()..color = const Color(0xFFFF5722)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Flaming Horns
    final hornPath = Path()
      ..moveTo(cx + 2, cy - 26)
      ..quadraticBezierTo(cx + 8, cy - 38, cx + 18, cy - 42)
      ..lineTo(cx + 12, cy - 28)
      ..close();
    canvas.drawPath(hornPath, Paint()..color = const Color(0xFFFF7043));
    canvas.drawPath(hornPath, Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Glowing Yellow Dragon Eye
    canvas.drawCircle(Offset(cx + 18, cy - 16), 4, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(cx + 18, cy - 16), 2, Paint()..color = const Color(0xFFBF360C));

    // Feet
    final legY = cy + size.height * 0.38;
    final legShift = (!isJumping && frame % 2 == 1) ? 5.0 : -5.0;
    canvas.drawCircle(Offset(cx - 10 + legShift, legY), 6, Paint()..color = const Color(0xFFBF360C));
    canvas.drawCircle(Offset(cx + 10 - legShift, legY), 6, Paint()..color = const Color(0xFFBF360C));

    canvas.restore();
  }
}
