import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'audio_manager.dart';

/// Manages game settings including Audio Volume & Phone Vibration preferences.
class SettingsManager {
  static const String _volumeKey = 'dino_audio_volume';
  static const String _vibrationKey = 'dino_vibration_enabled';

  static double _volume = 0.6; // 60% default volume
  static bool _vibrationEnabled = true;

  static double get volume => _volume;
  static bool get vibrationEnabled => _vibrationEnabled;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(_volumeKey) ?? 0.6;
      _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
      AudioManager.setVolume(_volume);
    } catch (_) {}
  }

  static Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    AudioManager.setVolume(_volume);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumeKey, _volume);
    } catch (_) {}
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, _vibrationEnabled);
    } catch (_) {}
  }

  /// Trigger haptic phone vibration if enabled
  static Future<void> triggerVibration({int duration = 40}) async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: duration);
      }
    } catch (_) {
      // Haptics fallback on web / unsupported devices
    }
  }
}
