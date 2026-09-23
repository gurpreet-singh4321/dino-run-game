import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/skins/dino_motion.dart';

void main() {
  void tick(DinoMotion motion, double dt, {bool grounded = true,
      double velocity = 0, double speed = 300}) => motion.update(dt,
      speed: speed, velocityY: velocity, grounded: grounded);

  test('Stance foot stays level and moves at uniform ground-relative speed', () {
    final samples = List.generate(6, (i) => DinoMotion.gaitFoot(i * .05));
    for (int i = 1; i < samples.length; i++) {
      expect(samples[i].dy, 113);
      expect(samples[i].dx - samples[i - 1].dx, closeTo(-26 / .32 * .05, 1e-8));
    }
  });

  test('Gait is continuous in position and velocity at lift-off and wrap', () {
    const epsilon = 1e-5;
    for (final boundary in [.32, 1.0]) {
      final before = DinoMotion.gaitFoot(boundary - epsilon);
      final at = DinoMotion.gaitFoot(boundary);
      final after = DinoMotion.gaitFoot(boundary + epsilon);
      expect((before - after).distance, lessThan(.01));
      final leftVelocity = (at - before) / epsilon;
      final rightVelocity = (after - at) / epsilon;
      expect((leftVelocity - rightVelocity).distance, lessThan(.1));
    }
  });

  test('Motion is stable at 30, 60 and 120 FPS', () {
    final results = <DinoMotion>[];
    for (final fps in [30, 60, 120]) {
      final motion = DinoMotion();
      for (int i = 0; i < fps * 2; i++) { tick(motion, 1 / fps); }
      results.add(motion);
    }
    for (final result in results.skip(1)) {
      expect(result.phase, closeTo(results.first.phase, 1e-8));
      expect(result.run, closeTo(results.first.run, 1e-8));
      expect((result.foot(false) - results.first.foot(false)).distance, lessThan(.001));
    }
  });

  test('Cadence stays readable at every speed and display size', () {
    for (final width in [40.0, 80.0, 240.0]) {
      for (final speed in [150.0, 300.0, 650.0, 1200.0]) {
        final motion = DinoMotion();
        for (int i = 0; i < 480; i++) {
          motion.update(1 / 120, speed: speed, velocityY: 0,
              grounded: true, characterWidth: width);
        }
        expect(motion.frequency, inInclusiveRange(1.8, 3.21));
      }
    }
  });

  test('Landing preserves stride phase and feet roll continuously', () {
    final motion = DinoMotion()..phase = .73;
    tick(motion, .01, grounded: false, velocity: 500);
    tick(motion, .01);
    expect(motion.phase, greaterThan(.73));
    motion.run = 1;
    motion.air = 0;
    for (final boundary in [.32, 1.0]) {
      motion.phase = boundary - .00001;
      final before = motion.footAngle(false);
      motion.phase = boundary + .00001;
      expect((motion.footAngle(false) - before).abs(), lessThan(.001));
    }
  });

  test('Jump tucks legs, descent reaches, landing recovers without a pop', () {
    final motion = DinoMotion();
    for (int i = 0; i < 120; i++) { tick(motion, 1 / 120); }
    final initial = motion.foot(false);
    motion.jump();
    tick(motion, 1 / 120, grounded: false, velocity: -650);
    expect((motion.foot(false) - initial).distance, lessThan(10));
    for (int i = 0; i < 36; i++) { tick(motion, 1 / 120, grounded: false, velocity: -300); }
    final tucked = motion.foot(false).dy;
    for (int i = 0; i < 60; i++) { tick(motion, 1 / 120, grounded: false, velocity: 600); }
    expect(motion.foot(false).dy, greaterThan(tucked + 4));
    tick(motion, 1 / 120);
    expect(motion.landing, greaterThan(0));
    for (int i = 0; i < 60; i++) { tick(motion, 1 / 120); }
    expect(motion.landing, 0);
    expect(motion.air, lessThan(.001));
  });

  test('IK keeps bone lengths and finite joints across an entire run', () {
    const hip = Offset(53, 94);
    for (int i = 0; i < 1000; i++) {
      final foot = DinoMotion.gaitFoot(i / 1000);
      final knee = DinoMotion.knee(hip, foot, 14, 14);
      expect(knee.dx.isFinite && knee.dy.isFinite, isTrue);
      expect((knee - hip).distance, closeTo(14, 1e-5));
      expect((knee - foot).distance, closeTo(14, 1e-5));
    }
  });

  test('Compact stride keeps both short legs under the body without stretching', () {
    for (int i = 0; i < 1000; i++) {
      final foot = DinoMotion.gaitFoot(i / 1000);
      expect(foot.dx, inInclusiveRange(40, 74));
      expect(foot.dy, inInclusiveRange(107, 113));
      for (final hipX in [53.0, 61.0]) {
        for (final bob in [0.0, 2.7, 5.0]) {
          final hip = Offset(hipX, 94 + bob);
          expect((foot - hip).distance, lessThan(28));
        }
      }
    }
  });
}
