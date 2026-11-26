import '../managers/settings_manager.dart';

/// Shared gameplay feedback respects the persistent vibration preference.
class GameVibration {
  static void vibrate({int duration = 150, int amplitude = -1}) {
    SettingsManager.triggerVibration(duration: duration);
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
