import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'audio_manager.dart';

/// Applies preferences immediately and serializes writes in interaction order.
class SettingsManager {
  static const String _volumeKey = 'dino_audio_volume';
  static const String _vibrationKey = 'dino_vibration_enabled';
  static const String _motionKey = 'dino_reduce_motion';
  static const String _audibleVolumeKey = 'dino_last_audible_volume';

  static double _volume = 0.6;
  static double _lastAudibleVolume = 0.6;
  static bool _vibrationEnabled = true;
  static Future<void>? _writes;
  static final ValueNotifier<bool> reducedMotion = ValueNotifier(false);

  static double get volume => _volume;
  static bool get vibrationEnabled => _vibrationEnabled;
  static bool get reduceMotion => reducedMotion.value;

  static Future<void> load() async {
    final pending = _writes;
    if (pending != null) await pending;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVolume = prefs.getDouble(_volumeKey) ?? 0.6;
      _volume = storedVolume.isFinite ? storedVolume.clamp(0.0, 1.0) : 0.6;
      final audible = prefs.getDouble(_audibleVolumeKey) ?? 0.6;
      _lastAudibleVolume = audible.isFinite && audible > 0
          ? audible.clamp(0.05, 1.0)
          : 0.6;
      if (_volume > 0) _lastAudibleVolume = _volume;
      _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
      reducedMotion.value = prefs.getBool(_motionKey) ?? false;
      AudioManager.setVolume(_volume);
    } catch (_) {
      // Keep usable in-memory preferences when storage is unavailable.
    }
  }

  static Future<bool> _write(
    Future<bool> Function(SharedPreferences prefs) operation,
  ) {
    final result = (_writes ?? Future<void>.value()).then((_) async {
      try {
        return await operation(await SharedPreferences.getInstance());
      } catch (_) {
        return false;
      }
    });
    late final Future<void> tail;
    tail = result.then((_) {
      if (identical(_writes, tail)) _writes = null;
    });
    _writes = tail;
    return result;
  }

  static Future<bool> setVolume(double newVolume) {
    _volume = newVolume.isFinite ? newVolume.clamp(0.0, 1.0) : _volume;
    if (_volume > 0) _lastAudibleVolume = _volume;
    AudioManager.setVolume(_volume);
    return save();
  }

  static Future<bool> setSoundEnabled(bool enabled) {
    final result = setVolume(enabled ? _lastAudibleVolume : 0);
    if (enabled) AudioManager.ensureAudioPlaying();
    return result;
  }

  static Future<bool> setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    return save();
  }

  static Future<bool> setReduceMotion(bool enabled) {
    reducedMotion.value = enabled;
    return save();
  }

  /// Retry the actual current state, rather than an older failed change.
  static Future<bool> save() {
    final volume = _volume;
    final audible = _lastAudibleVolume;
    final vibration = _vibrationEnabled;
    final motion = reduceMotion;
    return _write((prefs) async {
      final results = <bool>[
        await prefs.setDouble(_volumeKey, volume),
        await prefs.setDouble(_audibleVolumeKey, audible),
        await prefs.setBool(_vibrationKey, vibration),
        await prefs.setBool(_motionKey, motion),
      ];
      return results.every((saved) => saved);
    });
  }

  static Future<void> triggerVibration({int duration = 40}) async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true && _vibrationEnabled) {
        await Vibration.vibrate(duration: duration);
      }
    } catch (_) {
      // Haptics are optional on web and unsupported devices.
    }
  }
}
