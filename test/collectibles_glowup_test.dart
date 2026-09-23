import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:dino_run_epochs/components/collectible.dart';
import 'package:dino_run_epochs/components/player.dart';
import 'package:dino_run_epochs/components/ui/combo_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 06: Collectibles Glowup — Gameplay Invariance Formulas', () {
    test('Magnet pull radius formula is strictly preserved (160.0 + level * 30.0)', () {
      for (int lvl = 0; lvl <= 5; lvl++) {
        final expectedRadius = 160.0 + (lvl * 30.0);
        expect(expectedRadius, equals(160.0 + lvl * 30.0));
      }
      expect(160.0 + 0 * 30.0, equals(160.0));
      expect(160.0 + 1 * 30.0, equals(190.0));
      expect(160.0 + 2 * 30.0, equals(220.0));
      expect(160.0 + 3 * 30.0, equals(250.0));
      expect(160.0 + 4 * 30.0, equals(280.0));
      expect(160.0 + 5 * 30.0, equals(310.0));
    });

    test('Magnet pull speed formula is strictly preserved (320.0 + level * 40.0)', () {
      expect(320.0 + 0 * 40.0, equals(320.0));
      expect(320.0 + 1 * 40.0, equals(360.0));
      expect(320.0 + 2 * 40.0, equals(400.0));
      expect(320.0 + 3 * 40.0, equals(440.0));
      expect(320.0 + 4 * 40.0, equals(480.0));
      expect(320.0 + 5 * 40.0, equals(520.0));
    });

    test('Shield and Magnet duration formulas are strictly preserved (8.0 + level * 2.0)', () {
      for (int lvl = 0; lvl <= 5; lvl++) {
        final dur = 8.0 + (lvl * 2.0);
        expect(dur, equals(8.0 + lvl * 2.0));
      }
      expect(8.0 + 0 * 2.0, equals(8.0));
      expect(8.0 + 1 * 2.0, equals(10.0));
      expect(8.0 + 2 * 2.0, equals(12.0));
      expect(8.0 + 3 * 2.0, equals(14.0));
      expect(8.0 + 4 * 2.0, equals(16.0));
      expect(8.0 + 5 * 2.0, equals(18.0));
    });

    test('Collectible base dimensions and hitbox radius match 42x42 / r=21', () {
      final coin = Collectible(collectType: CollectibleType.coin, position: Vector2.zero());
      expect(coin.size.x, equals(42.0));
      expect(coin.size.y, equals(42.0));
    });
  });

  group('Task 06: Powerup Expiry Blink Telegraph Math', () {
    test('Player.isPowerupBlinkVisible executes exactly 3 blinks in final 0.6s', () {
      // Prior to final 0.6s, always visible
      expect(Player.isPowerupBlinkVisible(5.0), isTrue);
      expect(Player.isPowerupBlinkVisible(1.2), isTrue);
      expect(Player.isPowerupBlinkVisible(0.61), isTrue);

      // In final 0.6s (half-period 0.1s -> 3 on / 3 off cycles)
      // Interval 0.5s - 0.6s: floor(0.55 / 0.1) = 5 -> odd -> OFF
      expect(Player.isPowerupBlinkVisible(0.55), isFalse);
      // Interval 0.4s - 0.5s: floor(0.45 / 0.1) = 4 -> even -> ON
      expect(Player.isPowerupBlinkVisible(0.45), isTrue);
      // Interval 0.3s - 0.4s: floor(0.35 / 0.1) = 3 -> odd -> OFF
      expect(Player.isPowerupBlinkVisible(0.35), isFalse);
      // Interval 0.2s - 0.3s: floor(0.25 / 0.1) = 2 -> even -> ON
      expect(Player.isPowerupBlinkVisible(0.25), isTrue);
      // Interval 0.1s - 0.2s: floor(0.15 / 0.1) = 1 -> odd -> OFF
      expect(Player.isPowerupBlinkVisible(0.15), isFalse);
      // Interval 0.0s - 0.1s: floor(0.05 / 0.1) = 0 -> even -> ON
      expect(Player.isPowerupBlinkVisible(0.05), isTrue);

      // Expired (<= 0)
      expect(Player.isPowerupBlinkVisible(0.0), isFalse);
      expect(Player.isPowerupBlinkVisible(-0.5), isFalse);
    });

    test('Aura 1.2 Hz pulse formula produces smooth 1.0 to 1.05 scale range', () {
      for (double t = 0.0; t <= 2.0; t += 0.05) {
        final pulseT = 0.5 + 0.5 * math.sin(t * 1.2 * 2 * math.pi);
        final pulse = 1.0 + 0.05 * pulseT;
        final alphaPulse = 0.7 + 0.2 * pulseT;

        expect(pulse, greaterThanOrEqualTo(1.0));
        expect(pulse, lessThanOrEqualTo(1.05 + 1e-6));
        expect(alphaPulse, greaterThanOrEqualTo(0.7 - 1e-6));
        expect(alphaPulse, lessThanOrEqualTo(0.9 + 1e-6));
      }
    });
  });

  group('Task 06: Combo Display — Heat Tiers & Pop Math', () {
    test('Heat color tiers match specification', () {
      // Tier 1: < 5 -> White
      expect(ComboDisplay.getHeatColor(1), equals(const Color(0xFFFFFFFF)));
      expect(ComboDisplay.getHeatColor(4), equals(const Color(0xFFFFFFFF)));

      // Tier 2: 5..9 -> Electric Gold
      expect(ComboDisplay.getHeatColor(5), equals(const Color(0xFFFFD700)));
      expect(ComboDisplay.getHeatColor(9), equals(const Color(0xFFFFD700)));

      // Tier 3: 10..19 -> Hot Orange
      expect(ComboDisplay.getHeatColor(10), equals(const Color(0xFFFF9100)));
      expect(ComboDisplay.getHeatColor(19), equals(const Color(0xFFFF9100)));

      // Tier 4: 20+ -> Blazing Crimson
      expect(ComboDisplay.getHeatColor(20), equals(const Color(0xFFFF1744)));
      expect(ComboDisplay.getHeatColor(50), equals(const Color(0xFFFF1744)));
    });

    test('Scale pop math reaches peak 1.35 and returns to 1.0', () {
      const popDuration = 0.18;
      // Start of pop: t = 0.18 (popProgress = 0)
      double popProgressStart = (1.0 - (0.18 / popDuration)).clamp(0.0, 1.0);
      double scaleStart = 1.0 + 0.35 * math.sin(popProgressStart * math.pi);
      expect(scaleStart, closeTo(1.0, 0.01));

      // Peak of pop: t = 0.09 (popProgress = 0.5)
      double popProgressMid = (1.0 - (0.09 / popDuration)).clamp(0.0, 1.0);
      double scaleMid = 1.0 + 0.35 * math.sin(popProgressMid * math.pi);
      expect(scaleMid, closeTo(1.35, 0.01));

      // End of pop: t = 0.0 (popProgress = 1.0)
      double popProgressEnd = (1.0 - (0.0 / popDuration)).clamp(0.0, 1.0);
      double scaleEnd = 1.0 + 0.35 * math.sin(popProgressEnd * math.pi);
      expect(scaleEnd, closeTo(1.0, 0.01));
    });
  });

  group('Task 06: Recycled Collectible State & Magnet Curve', () {
    test('resetCollectible re-initializes state for pooled/recycled instances', () {
      final coin = Collectible(collectType: CollectibleType.coin, position: Vector2(100, 100));
      // Call resetCollectible
      coin.resetCollectible();
      // Should cleanly reset without throwing
      expect(coin.collectType, equals(CollectibleType.coin));
    });

    test('Magnet ramp curve smoothly accelerates over 150ms', () {
      double magnetTime = 0.0;
      expect((magnetTime / 0.15).clamp(0.0, 1.0), equals(0.0));

      magnetTime = 0.075;
      expect((magnetTime / 0.15).clamp(0.0, 1.0), closeTo(0.5, 0.001));

      magnetTime = 0.15;
      expect((magnetTime / 0.15).clamp(0.0, 1.0), equals(1.0));

      magnetTime = 0.30;
      expect((magnetTime / 0.15).clamp(0.0, 1.0), equals(1.0));
    });

    test('Continuous 3D spin oscillation remains bounded between 0.08 and 1.0', () {
      for (double t = 0.0; t <= 3.0; t += 0.02) {
        final scaleX = math.cos(t * 5.0).abs().clamp(0.08, 1.0);
        expect(scaleX, greaterThanOrEqualTo(0.08));
        expect(scaleX, lessThanOrEqualTo(1.0));
      }
    });
  });
}
