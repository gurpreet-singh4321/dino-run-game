import 'dart:math' as math;
import 'dart:ui';

/// Continuous motion in a 100 x 120 design space. No sprite-frame timer.
class DinoMotion {
  double phase = 0;
  double time = 0;
  double run = 0;
  double air = 0;
  double fall = 0;
  double landing = 0;
  double launch = 0;
  double frequency = 2.4;
  bool _grounded = true;
  double _landingAge = 1;
  double _launchAge = 1;

  static double ease(double x) => x * x * (3 - 2 * x);
  static double follow(double from, double to, double rate, double dt) =>
      to + (from - to) * math.exp(-rate * dt);

  void jump() => _launchAge = 0;

  void update(double dt, {required double speed, required double velocityY,
      required bool grounded, bool idle = false, bool space = false,
      double characterWidth = 80}) {
    if (dt <= 0) return;
    // Substeps keep landing envelopes and blends stable across frame rates.
    final steps = (dt / (1 / 120)).ceil().clamp(1, 120);
    final step = dt / steps;
    if (grounded && !_grounded && !idle) {
      _landingAge = 0;
      // Preserve the stride phase: resetting it makes the limbs pop on impact.
    }
    if (!grounded && _grounded && !space && !idle) jump();
    _grounded = grounded;
    for (int i = 0; i < steps; i++) {
      time += step;
      _landingAge += step;
      _launchAge += step;
      // Art-directed cadence: short legs must not turn into a high-speed blur.
      // Scenery speed is exaggerated; exact foot/world matching is secondary.
      final targetFrequency = (1.8 + speed / 500).clamp(1.8, 3.2);
      frequency = follow(frequency, targetFrequency, 10, step);
      run = follow(run, !idle && grounded && !space ? 1 : 0, 14, step);
      air = follow(air, !grounded && !idle ? 1 : 0, 20, step);
      // Smoothly extend legs before landing instead of snapping at the apex.
      fall = follow(fall, ((velocityY + 80) / 500).clamp(0, 1), 12, step);
      if (!idle && grounded && !space) phase = (phase + frequency * step) % 1;
    }
    landing = _landingAge < .24
        ? math.sin(math.pi * _landingAge / .24) * (1 - _landingAge / .24) : 0;
    launch = _launchAge < .18
        ? math.sin(math.pi * _launchAge / .18) * (1 - _launchAge / .18) : 0;
  }

  double get bodyY => math.sin(time * 2.4) * .65 * (1 - run) +
      (1 + math.cos((phase - .08) * math.pi * 4)) * .7 * run + landing * 2.5;
  double get headY => bodyY + math.sin((phase - .10) * math.pi * 4) * .3 * run;

  double footAngle(bool far) {
    final p = (phase + (far ? .5 : 0)) % 1;
    final t = ((p - .32) / .68).clamp(0.0, 1.0);
    // The toes follow the returning foot; the sole settles flat at contact.
    final swing = math.sin(math.pi * t);
    return .22 * swing * swing * math.sin(2 * math.pi * t) * run * (1 - air)
        + air * (1 - fall) * .12;
  }

  double get headAngle => math.sin(phase * math.pi * 2 - .45) * .022 * run
      - air * .045 + fall * air * .06;
  double get tailAngle => math.sin(phase * math.pi * 2 - .8) * .07 * run
      + math.sin(time * 2) * .04 * (1 - run) + air * .15;

  /// Stance moves backwards at a constant rate. Swing has zero vertical
  /// velocity at contact/lift-off and matches stance horizontal velocity.
  static Offset gaitFoot(double phase) {
    final p = phase % 1;
    if (p < .32) return Offset(70 - 26 * p / .32, 113);
    final t = (p - .32) / .68;
    final tangent = -26 / .32 * .68;
    final h00 = 2 * t * t * t - 3 * t * t + 1;
    final h10 = t * t * t - 2 * t * t + t;
    final h01 = -2 * t * t * t + 3 * t * t;
    final h11 = t * t * t - t * t;
    return Offset(h00 * 44 + h10 * tangent + h01 * 70 + h11 * tangent,
      113 - 6 * math.pow(math.sin(math.pi * t), 2).toDouble());
  }

  Offset foot(bool far) {
    final resting = Offset(far ? 62 : 51, 113);
    final running = gaitFoot(phase + (far ? .5 : 0));
    final grounded = Offset.lerp(resting, running, run)!;
    final tucked = Offset(far ? 54 : 60, 106);
    final reaching = Offset(far ? 53 : 65, 111);
    return Offset.lerp(grounded, Offset.lerp(tucked, reaching, fall)!, air)!;
  }

  /// Two-bone inverse kinematics, clamped to avoid straight-knee singularities.
  static Offset knee(Offset hip, Offset foot, double upper, double lower) {
    final delta = foot - hip;
    final distance = delta.distance.clamp(.001, upper + lower - .01);
    final direction = delta.distance > .001 ? delta / delta.distance : const Offset(0, 1);
    final along = (upper * upper - lower * lower + distance * distance) / (2 * distance);
    final bend = math.sqrt(math.max(0, upper * upper - along * along));
    return hip + direction * along + Offset(direction.dy, -direction.dx) * bend;
  }
}
