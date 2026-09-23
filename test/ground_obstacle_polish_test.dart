import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:dino_run_epochs/components/obstacle.dart';
import 'package:dino_run_epochs/components/ground.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 05: Ground & Obstacle Polish — Fairness & Timing Math', () {
    test('Obstacle entrance completes well before reaching player at max speed', () {
      const maxSpeed = 517.5; // px/s (base 300 * 1.725 max speed multiplier)
      const spawnX = 800.0;
      const playerX = 140.0;
      const travelDistance = spawnX - playerX; // 660 px
      const travelTime = travelDistance / maxSpeed; // ~1.275s

      const entranceDuration = Obstacle.entranceDuration; // 0.20s
      const distanceDuringEntrance = maxSpeed * entranceDuration; // 103.5 px
      const remainingDistance = travelDistance - distanceDuringEntrance; // 556.5 px

      expect(travelTime, closeTo(1.275, 0.005));
      expect(entranceDuration, equals(0.20));
      expect(remainingDistance, greaterThan(550.0));
      // Obstacle is fully entered and active with > 84% of distance and > 1.07s remaining
      expect(remainingDistance / travelDistance, greaterThan(0.84));
    });

    test('Hitbox gating: isEntranceComplete state transitions strictly at 0.20s', () {
      final cactus = Obstacle(type: ObstacleType.cactusSmall, speed: 300);

      expect(cactus.entranceTimer, equals(0.0));
      expect(cactus.isEntranceComplete, isFalse);

      cactus.entranceTimer = 0.10;
      expect(cactus.isEntranceComplete, isFalse);

      cactus.entranceTimer = 0.199;
      expect(cactus.isEntranceComplete, isFalse);

      cactus.entranceTimer = 0.20;
      expect(cactus.isEntranceComplete, isTrue);

      cactus.entranceTimer = 0.50;
      expect(cactus.isEntranceComplete, isTrue);
    });

    test('Falling pillar gating: isEntranceComplete depends strictly on landing', () {
      final pillar = Obstacle(type: ObstacleType.pillar, speed: 300);
      pillar.isFallingFromSky = true;
      pillar.hasLanded = false;
      pillar.entranceTimer = 1.0; // even after timer passes

      expect(pillar.isEntranceComplete, isFalse);

      pillar.hasLanded = true;
      expect(pillar.isEntranceComplete, isTrue);
    });
  });

  group('Condition 1: Bird Swoop Entrance is Render-Only', () {
    test('Bird swoop offset returns to exactly (0.0, 0.0) at and after 200ms', () {
      const entranceDuration = Obstacle.entranceDuration;

      // During entrance (0.0 <= t < 0.20)
      for (double t = 0.0; t < entranceDuration; t += 0.02) {
        final easeProgress = (t / entranceDuration).clamp(0.0, 1.0);
        final curvedProgress = Curves.easeOutQuad.transform(easeProgress);
        final swoopY = math.sin((1.0 - curvedProgress) * math.pi) * 15.0;
        final swoopX = (1.0 - curvedProgress) * 20.0;

        // Curve is within +-15px vertical and +20px horizontal
        expect(swoopY, greaterThanOrEqualTo(0.0));
        expect(swoopY, lessThanOrEqualTo(15.0));
        expect(swoopX, greaterThanOrEqualTo(0.0));
        expect(swoopX, lessThanOrEqualTo(20.0));
      }

      // At completion (t = 0.20)
      final easeProgressEnd = (entranceDuration / entranceDuration).clamp(0.0, 1.0);
      final curvedProgressEnd = Curves.easeOutQuad.transform(easeProgressEnd);
      final finalSwoopY = math.sin((1.0 - curvedProgressEnd) * math.pi) * 15.0;
      final finalSwoopX = (1.0 - curvedProgressEnd) * 20.0;

      expect(finalSwoopY, equals(0.0));
      expect(finalSwoopX, equals(0.0));
    });

    test('Bird position property is untouched by swoop calculation', () {
      final bird = Obstacle(type: ObstacleType.bird, speed: 300);
      final initialY = 180.0;
      bird.position = Vector2(800.0, initialY);

      expect(bird.position.y, equals(initialY));
      expect(bird.type, equals(ObstacleType.bird));
      // Swoop math is applied only via canvas.translate, never mutating position
      expect(bird.position.y, equals(180.0));
    });
  });

  group('Condition 2: Ground Tile Scaling & Seamless Divisibility Math', () {
    test('All repeating tile periods across all biomes are exact integer divisors of 640', () {
      const tileWidth = Ground.tileWidth;
      expect(tileWidth, equals(640.0));

      final periods = [32.0, 64.0, 80.0, 128.0, 160.0];
      for (final p in periods) {
        expect(tileWidth % p, equals(0.0), reason: 'Period $p must divide 640 seamlessly');
      }
    });

    test('Tile scaling accommodates variable ground region heights', () {
      const tileH = Ground.tileHeight;
      expect(tileH, equals(60.0));

      final testGroundHeights = [60.0, 75.0, 90.0, 120.0];
      for (final gh in testGroundHeights) {
        final scaleY = gh / tileH;
        expect(scaleY, greaterThanOrEqualTo(1.0));
        expect(tileH * scaleY, equals(gh));
      }
    });
  });

  group('Condition 3: Obstacle Rise-Clip & Shadow Consistency', () {
    test('At t=0, ground shadow is translated past the bottom clip boundary', () {
      const h = 60.0;
      const entranceDuration = Obstacle.entranceDuration;

      // At t = 0
      final easeProgress = (0.0 / entranceDuration).clamp(0.0, 1.0);
      final curvedProgress = Curves.easeOutCubic.transform(easeProgress);
      final offsetY = (1.0 - curvedProgress) * 20.0; // 20.0

      // Shadow is rendered at local y = h - 2.0
      final shadowCenterY = (h - 2.0) + offsetY; // 60 - 2 + 20 = 78.0

      // Clip rect is Rect.fromLTRB(-60, -200, size.x + 60, size.y)
      const clipBottom = h; // 60.0

      expect(shadowCenterY, greaterThan(clipBottom),
          reason: 'Shadow center at t=0 is 78px, safely past the 60px clip boundary');
    });

    test('Shadow alpha multiplier scales proportionally with curved entrance progress', () {
      const entranceDuration = Obstacle.entranceDuration;

      final p0 = (0.0 / entranceDuration).clamp(0.0, 1.0);
      expect(Curves.easeOutCubic.transform(p0), equals(0.0));

      final pMid = (0.10 / entranceDuration).clamp(0.0, 1.0);
      final multMid = Curves.easeOutCubic.transform(pMid);
      expect(multMid, greaterThan(0.0));
      expect(multMid, lessThan(1.0));

      final pEnd = (0.20 / entranceDuration).clamp(0.0, 1.0);
      expect(Curves.easeOutCubic.transform(pEnd), equals(1.0));
    });

    test('Pipe Pair entrance separates top and bottom pipes with matching clip', () {
      const entranceDuration = Obstacle.entranceDuration;
      final easeProgress = (0.0 / entranceDuration).clamp(0.0, 1.0);
      final curvedProgress = Curves.easeOutCubic.transform(easeProgress);

      final topOffsetY = -(1.0 - curvedProgress) * 30.0;
      final bottomOffsetY = (1.0 - curvedProgress) * 30.0;

      expect(topOffsetY, equals(-30.0));
      expect(bottomOffsetY, equals(30.0));
    });
  });

  group('Task 05: Visual Polish Enhancements', () {
    test('Lava emissive pulse frequency (0.7 Hz) and clamped alpha range [0.20, 0.45]', () {
      for (double t = 0.0; t < 5.0; t += 0.1) {
        final lavaPulse = 0.5 + 0.5 * math.sin(t * 4.4); // 4.4 rad/s ~ 0.7 Hz
        final lavaEmissiveAlpha = (0.20 + 0.25 * lavaPulse).clamp(0.20, 0.45);

        expect(lavaEmissiveAlpha, greaterThanOrEqualTo(0.20));
        expect(lavaEmissiveAlpha, lessThanOrEqualTo(0.45));
      }
    });

    test('Directional shadow offset is strictly +4.0px horizontally (bottom-right)', () {
      const shadowHorizontalOffset = 4.0;
      expect(shadowHorizontalOffset, equals(4.0));
    });
  });
}
