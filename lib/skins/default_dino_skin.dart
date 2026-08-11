import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'skin.dart';
import 'dart:math' as math;

class DefaultDinoSkin extends CharacterSkin {
  Sprite? _dinoSprite;

  @override
  String get id => 'default';

  @override
  String get displayName => 'Cute Dino';

  @override
  int get price => 0; 
  
  @override
  Color get primaryColor => const Color(0xFF81C784);

  void _loadSprite() {
    if (_dinoSprite != null) return;
    try {
      final image = Flame.images.fromCache('dino_sprite.png');
      _dinoSprite = Sprite(image);
    } catch (e) {
      // Ignored if not found in cache
    }
  }

  @override
  void renderRunning(Canvas canvas, Size size, int frame) {
    _loadSprite();
    _renderBaseDino(canvas, size, frame, false);
  }

  @override
  void renderJumping(Canvas canvas, Size size, bool isFalling) {
    _loadSprite();
    _renderBaseDino(canvas, size, 0, true);
  }

  @override
  void renderSpace(Canvas canvas, Size size, int frame) {
    _loadSprite();
    _renderBaseDino(canvas, size, 0, true);

    // Cute Space Helmet
    final glassPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final glassStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width * 0.65, size.height * 0.35);
    final radius = size.width * 0.45;
    
    canvas.drawCircle(center, radius, glassPaint);
    canvas.drawCircle(center, radius, glassStroke);
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -math.pi * 0.9, math.pi * 0.4,
      false, highlightPaint,
    );
  }

  void _renderBaseDino(Canvas canvas, Size size, int frame, bool isJumping) {
    if (_dinoSprite == null) return;
    
    canvas.save();
    
    // Bobbing animation when running
    if (!isJumping && frame % 2 == 1) {
      canvas.translate(0, size.height * 0.05);
    }
    
    // The sprite is facing right. Let's just draw it in the bounding box.
    // It's a single frame sprite now!
    _dinoSprite!.render(
      canvas,
      size: Vector2(size.width, size.height),
    );

    canvas.restore();
  }
}
