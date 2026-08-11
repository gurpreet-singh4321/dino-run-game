import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Helper to trigger direct hardware vibration on native devices with fallback to HapticFeedback.
class GameVibration {
  static void vibrate({int duration = 150, int amplitude = -1}) {
    try {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    } catch (_) {}
    try {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static void heavyImpact() {
    vibrate(duration: 250, amplitude: 255);
  }

  static void mediumImpact() {
    vibrate(duration: 160, amplitude: 180);
  }

  static void lightImpact() {
    vibrate(duration: 100, amplitude: 120);
  }
}
