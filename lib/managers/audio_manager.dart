import 'dart:async';
import 'package:flame_audio/flame_audio.dart';

/// Manages dual background music tracks & sequence for Dino Run Epochs:
/// - Title Screen Music: pixel_jump_title.mp3 (loops infinitely on title/menu)
/// - Gameplay Music Sequence: pixel_jump_1.mp3 -> pixel_jump.mp3 (loops infinitely during gameplay)
class AudioManager {
  static bool _initialized = false;
  static double _currentVolume = 0.6;
  static String? _currentTrack;
  static AudioPlayer? _bgmPlayer;
  static StreamSubscription? _playerCompleteSub;

  static double get volume => _currentVolume;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer?.setVolume(_currentVolume);
    } catch (_) {}
  }

  static void setVolume(double newVolume) {
    _currentVolume = newVolume.clamp(0.0, 1.0);
    try {
      _bgmPlayer?.setVolume(_currentVolume);
    } catch (_) {}
  }

  static Future<void> _playSingle(String fileName, {bool loop = true}) async {
    if (_currentVolume <= 0) return;
    try {
      await init();
      _playerCompleteSub?.cancel();
      _playerCompleteSub = null;

      _currentTrack = fileName;
      await _bgmPlayer?.stop();
      await _bgmPlayer?.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _bgmPlayer?.play(AssetSource('audio/$fileName'), volume: _currentVolume);
    } catch (_) {}
  }

  /// Play title screen song (pixel_jump_title.mp3) looping indefinitely
  static void playTitleBgm() {
    _playSingle('pixel_jump_title.mp3', loop: true);
  }

  /// Play game over song (one_more_try.mp3) looping indefinitely
  static Future<void> playGameOverBgm() async {
    if (_currentVolume <= 0) return;
    try {
      await init();
      _playerCompleteSub?.cancel();
      _playerCompleteSub = null;

      _currentTrack = 'one_more_try.mp3';
      try {
        await _bgmPlayer?.stop();
      } catch (_) {}

      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer?.play(AssetSource('audio/one_more_try.mp3'), volume: _currentVolume);
    } catch (_) {}
  }

  /// Play gameplay music sequence: "Pixel Jump 1.mp3" FIRST, then switch to "pixel_jump.mp3" looping!
  static Future<void> playGameplayBgm() async {
    if (_currentVolume <= 0) return;
    try {
      await init();
      _playerCompleteSub?.cancel();
      _playerCompleteSub = null;

      _currentTrack = 'pixel_jump_1.mp3';
      await _bgmPlayer?.stop();
      await _bgmPlayer?.setReleaseMode(ReleaseMode.stop);
      await _bgmPlayer?.play(AssetSource('audio/pixel_jump_1.mp3'), volume: _currentVolume);

      // Listen for completion of pixel_jump_1.mp3 -> transition to pixel_jump.mp3
      _playerCompleteSub = _bgmPlayer?.onPlayerComplete.listen((_) async {
        _playerCompleteSub?.cancel();
        _playerCompleteSub = null;
        _currentTrack = 'pixel_jump.mp3';
        await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer?.play(AssetSource('audio/pixel_jump.mp3'), volume: _currentVolume);
      });
    } catch (_) {}
  }

  /// Ensure audio plays/resumes on ANY user gesture (Web browser gesture requirement)
  static Future<void> ensureAudioPlaying() async {
    if (_currentVolume <= 0) return;
    try {
      await init();
      if (_bgmPlayer?.state == PlayerState.playing) return;

      final track = _currentTrack ?? 'pixel_jump_title.mp3';
      if (track == 'pixel_jump_1.mp3') {
        await playGameplayBgm();
      } else {
        await _playSingle(track, loop: true);
      }
    } catch (_) {}
  }

  static void pauseBgm() {
    try {
      _bgmPlayer?.pause();
    } catch (_) {}
  }

  static void resumeBgm() {
    if (_currentVolume <= 0) return;
    try {
      if (_bgmPlayer?.state == PlayerState.playing) return;
      _bgmPlayer?.resume();
    } catch (_) {}
  }

  static void stopBgm() {
    try {
      _playerCompleteSub?.cancel();
      _playerCompleteSub = null;
      _currentTrack = null;
      _bgmPlayer?.stop();
    } catch (_) {}
  }
}
