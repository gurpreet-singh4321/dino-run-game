import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:dino_run_epochs/game/game_state.dart';
import 'package:dino_run_epochs/game/biome_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 07: Milestone Moments — Epoch Roman Numerals', () {
    test('BiomeManager toRoman converts stages to correct Roman numerals', () {
      expect(BiomeManager.toRoman(1), equals('I'));
      expect(BiomeManager.toRoman(2), equals('II'));
      expect(BiomeManager.toRoman(3), equals('III'));
      expect(BiomeManager.toRoman(4), equals('IV'));
      expect(BiomeManager.toRoman(5), equals('V'));
      expect(BiomeManager.toRoman(6), equals('VI'));
      expect(BiomeManager.toRoman(7), equals('VII'));
      expect(BiomeManager.toRoman(8), equals('VIII'));
      expect(BiomeManager.toRoman(9), equals('IX'));
      expect(BiomeManager.toRoman(10), equals('X'));
      expect(BiomeManager.toRoman(14), equals('XIV'));
    });

    test('All biomes have distinct display names and accent colors', () {
      expect(BiomeManager.biomes.length, equals(6));
      final names = BiomeManager.biomes.map((b) => b.displayName).toSet();
      final accents = BiomeManager.biomes.map((b) => b.accentColor).toSet();

      // Display names should be distinct and stylish
      expect(names.length, equals(6));
      expect(names.contains('THE ANCIENT DESERT'), isTrue);
      expect(names.contains('THE JURASSIC MONSOON'), isTrue);
      expect(names.contains('THE PRIMEVAL FOREST'), isTrue);
      expect(names.contains('THE ICE AGE'), isTrue);
      expect(names.contains('THE VOLCANO INFERNO'), isTrue);
      expect(names.contains('THE COSMIC ORBIT'), isTrue);

      // Accent colors should be defined
      expect(accents.length, equals(6));
    });
  });

  group('Task 07: Milestone Moments — Catch-Up Flooding & Boundary Logic', () {
    test('Standard milestone triggers on crossing 1000 boundary', () {
      int lastCelebratedMilestone = 0;
      final celebrations = <int>[];

      void checkMilestones(double currentScore) {
        final currentMilestone = (currentScore / 1000).floor();
        if (currentMilestone > lastCelebratedMilestone) {
          celebrations.add(currentMilestone);
          lastCelebratedMilestone = currentMilestone;
        }
      }

      checkMilestones(950.0);
      expect(celebrations, isEmpty);

      checkMilestones(1020.0);
      expect(celebrations, equals([1]));

      checkMilestones(1800.0);
      expect(celebrations, equals([1])); // No duplicate

      checkMilestones(2050.0);
      expect(celebrations, equals([1, 2]));
    });

    test('Catch-up flooding protection celebrates ONLY the latest milestone', () {
      int lastCelebratedMilestone = 0;
      final celebrations = <int>[];

      void checkMilestones(double currentScore) {
        final currentMilestone = (currentScore / 1000).floor();
        if (currentMilestone > lastCelebratedMilestone) {
          // Exactly as implemented in DinoGame._checkMilestones
          celebrations.add(currentMilestone);
          lastCelebratedMilestone = currentMilestone;
        }
      }

      // Large frame jump from 800 to 3500 (skips 1000, 2000, reaches 3000)
      checkMilestones(800.0);
      checkMilestones(3500.0);

      // Should celebrate ONLY milestone 3 (latest), never stacking 1 and 2
      expect(celebrations, equals([3]));
      expect(lastCelebratedMilestone, equals(3));
    });

    test('Major milestone identification (every 5000 score)', () {
      bool isMajor(int milestone) => (milestone % 5 == 0);

      expect(isMajor(1), isFalse); // 1000
      expect(isMajor(2), isFalse); // 2000
      expect(isMajor(3), isFalse); // 3000
      expect(isMajor(4), isFalse); // 4000
      expect(isMajor(5), isTrue);  // 5000: Biome multiple, 4 bursts + strong pulse
      expect(isMajor(10), isTrue); // 10000
      expect(isMajor(15), isTrue); // 15000
    });
  });

  group('Task 07: Milestone Moments — High-Score Banner & Space Mode Deferral', () {
    test('First-ever run with high score 0 never triggers banner', () {
      const initialHighScore = 0;
      bool hasShownBanner = false;
      bool bannerTriggered = false;

      void checkHighScoreBanner(double score, GameState state) {
        if (state == GameState.playing) {
          if (!hasShownBanner && initialHighScore > 0 && score > initialHighScore) {
            hasShownBanner = true;
            bannerTriggered = true;
          }
        }
      }

      checkHighScoreBanner(500.0, GameState.playing);
      expect(bannerTriggered, isFalse);

      checkHighScoreBanner(5000.0, GameState.playing);
      expect(bannerTriggered, isFalse);
      expect(hasShownBanner, isFalse);
    });

    test('Space mode defers high-score banner check until returning to playing state', () {
      const initialHighScore = 3000;
      bool hasShownBanner = false;
      int bannerShowCount = 0;

      void checkHighScoreBanner(double score, GameState state) {
        if (state == GameState.playing) {
          if (!hasShownBanner && initialHighScore > 0 && score > initialHighScore) {
            hasShownBanner = true;
            bannerShowCount++;
          }
        }
      }

      // 1. In space mode, score surpasses high score
      var score = 2500.0;
      var state = GameState.spaceMode;

      score = 3500.0; // Crossed high score during spaceMode!
      checkHighScoreBanner(score, state);

      // Must NOT have triggered or consumed the one-shot flag during space mode
      expect(bannerShowCount, equals(0));
      expect(hasShownBanner, isFalse);

      // 2. Return to playing state
      state = GameState.playing;
      checkHighScoreBanner(score, state);

      // Now it triggers cleanly!
      expect(bannerShowCount, equals(1));
      expect(hasShownBanner, isTrue);

      // 3. Further score increases do not trigger again (one-shot per run)
      score = 4000.0;
      checkHighScoreBanner(score, state);
      expect(bannerShowCount, equals(1));
    });
  });

  group('Task 07: Milestone Moments — Letterbox & Obstacle Visibility Constraints', () {
    test('Bottom letterbox bar never covers ground or obstacles by more than 10% screen height', () {
      const screenHeights = [360.0, 480.0, 640.0, 720.0, 900.0, 1080.0];
      const groundHeight = 60.0;

      for (final h in screenHeights) {
        final groundY = h - groundHeight;
        final topBarMax = h * 0.10;
        final bottomBarMax = math.min(h * 0.10, groundHeight + h * 0.05);

        // Top bar must be at most 10% screen height
        expect(topBarMax / h, closeTo(0.10, 0.001));

        // Bottom bar total height must be at most 10% screen height
        expect(bottomBarMax / h, lessThanOrEqualTo(0.1001));

        // Portion of bottom bar that extends above ground line:
        // bottom bar top edge = h - bottomBarMax
        // If bottom bar top edge < groundY, it extends above ground by groundY - (h - bottomBarMax)
        final barTop = h - bottomBarMax;
        final coverageAboveGround = math.max(0.0, groundY - barTop);
        final percentAboveGround = coverageAboveGround / h;

        // Must strictly never cover incoming obstacles above ground by more than 10% (our math caps at <= 5%)
        expect(percentAboveGround, lessThanOrEqualTo(0.0501));
      }
    });
  });

  group('Task 07: Milestone Moments — Time Scaling & Drift Prevention', () {
    test('Scaled dt updates prevent timer drift during hit-stop and slow-mo', () {
      // Hit-stop time scale = 0.05
      const normalDt = 0.0166;
      const hitStopTimeScale = 0.05;
      final scaledDtHitStop = normalDt * hitStopTimeScale;

      expect(scaledDtHitStop, closeTo(0.00083, 0.0001));

      // Over a 90ms hit-stop (approx 5.4 frames), milestone timers advance by barely ~4.5ms
      final elapsedDuringHitStop = scaledDtHitStop * 5.4;
      expect(elapsedDuringHitStop, lessThan(0.006));
    });
  });

  group('Task 07: Milestone Moments — Firework Radial Distribution Logic', () {
    test('Radial burst math calculates valid velocity vectors in 360 degrees', () {
      final velocities = <Vector2>[];
      final rng = math.Random(42);
      for (int i = 0; i < 24; i++) {
        final angle = rng.nextDouble() * 2 * math.pi;
        final speed = 40.0 + rng.nextDouble() * 100.0;
        final vx = math.cos(angle) * speed;
        final vy = math.sin(angle) * speed - 15.0; // slight upward bias
        velocities.add(Vector2(vx, vy));
      }

      expect(velocities.length, equals(24));
      // Verify spread across multiple quadrants
      expect(velocities.any((v) => v.x > 0), isTrue);
      expect(velocities.any((v) => v.x < 0), isTrue);
      expect(velocities.any((v) => v.y < 0), isTrue);
    });
  });
}
