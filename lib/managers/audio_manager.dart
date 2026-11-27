import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'settings_manager.dart';

enum _BgmMode { none, title, gameplay, gameOver }

/// Platform audio adapter so [AudioManager] playback state can be unit-tested
/// deterministically without hardware audio codecs.
abstract class BgmBackend {
  PlayerState get state;
  Stream<void> get onPlayerComplete;
  Future<void> setVolume(double volume);
  Future<void> setReleaseMode(ReleaseMode mode);
  Future<void> play(Source source, {double? volume});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

class _FlameBgmBackend implements BgmBackend {
  final AudioPlayer _player = AudioPlayer();

  @override
  PlayerState get state => _player.state;

  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setReleaseMode(ReleaseMode mode) => _player.setReleaseMode(mode);

  @override
  Future<void> play(Source source, {double? volume}) =>
      _player.play(source, volume: volume);

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();
}

/// Manages dual background music tracks & sequence for Dino Run Epochs:
/// - Title Screen Music: pixel_jump_1.mp3 (loops infinitely on title/menu)
/// - Gameplay Music Sequence: pixel_jump_1.mp3 -> pixel_jump.mp3 (loops infinitely during gameplay)
class AudioManager {
  static bool _initialized = false;
  static double _currentVolume = 0.6;
  static _BgmMode _mode = _BgmMode.none;
  static String? _currentTrack;
  static bool _paused = false;
  static bool _hasLoadedSource = false;
  static int _generation = 0;
  static Future<void> _opChain = Future<void>.value();
  static BgmBackend? _bgmPlayer;
  static StreamSubscription<void>? _playerCompleteSub;

  @visibleForTesting
  static BgmBackend Function() backendFactory = _FlameBgmBackend.new;

  static double get volume => _currentVolume;
  @visibleForTesting
  static bool get isPausedForTest => _paused;
  @visibleForTesting
  static String? get currentTrackForTest => _currentTrack;

  static Future<void> _enqueue(Future<void> Function() action) {
    final next = _opChain.then((_) async {
      try {
        await action();
      } catch (_) {}
    });
    _opChain = next;
    return next;
  }

  @visibleForTesting
  static Future<void> resetForTest({double initialVolume = 0.6}) async {
    await _opChain;
    await _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _bgmPlayer = null;
    _initialized = false;
    _currentVolume = initialVolume;
    _mode = _BgmMode.none;
    _currentTrack = null;
    _paused = false;
    _hasLoadedSource = false;
    _generation++;
    backendFactory = _FlameBgmBackend.new;
    _opChain = Future<void>.value();
  }

  static Future<void> preloadAll() async {
    await FlameAudio.audioCache.loadAll([
      'one_more_try.mp3',
      'pixel_jump_1.mp3',
      'pixel_jump.mp3',
      'biome_sting.wav',
      'milestone_chime.wav',
    ]);
  }

  static Future<void> _ensureBackend() async {
    if (_initialized || _currentVolume <= 0) return;
    _initialized = true;
    try {
      _bgmPlayer = backendFactory();
      await _bgmPlayer?.setVolume(_currentVolume);
    } catch (_) {
      _initialized = false;
    }
  }

  static Future<void> init() => _enqueue(_ensureBackend);

  static void setVolume(double newVolume) {
    final prev = _currentVolume;
    _currentVolume = newVolume.clamp(0.0, 1.0);
    _enqueue(() async {
      try {
        await _bgmPlayer?.setVolume(_currentVolume);
        if (prev <= 0 &&
            _currentVolume > 0 &&
            !_paused &&
            _mode != _BgmMode.none &&
            _bgmPlayer?.state != PlayerState.playing) {
          await _recoverPlayback();
        }
      } catch (_) {}
    });
  }

  static Future<void> _startTrack(
    String fileName, {
    required bool loop,
    required int generation,
  }) async {
    if (_currentVolume <= 0 || _paused || generation != _generation) return;
    await _ensureBackend();
    final player = _bgmPlayer;
    if (player == null || generation != _generation || _paused) return;

    await _playerCompleteSub?.cancel();
    _playerCompleteSub = null;

    if (_hasLoadedSource &&
        _currentTrack == fileName &&
        player.state == PlayerState.playing) {
      return;
    }

    _currentTrack = fileName;
    if (_hasLoadedSource &&
        (player.state == PlayerState.playing ||
            player.state == PlayerState.paused)) {
      await player.stop();
      _hasLoadedSource = false;
    }
    if (generation != _generation || _paused) return;

    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await player.play(AssetSource('audio/$fileName'), volume: _currentVolume);
    _hasLoadedSource = player.state == PlayerState.playing;

    if (_mode == _BgmMode.gameplay && fileName == 'pixel_jump_1.mp3') {
      _playerCompleteSub = player.onPlayerComplete.listen((_) {
        _enqueue(() async {
          if (generation != _generation ||
              _mode != _BgmMode.gameplay ||
              _paused) {
            return;
          }
          await _startTrack(
            'pixel_jump.mp3',
            loop: true,
            generation: generation,
          );
        });
      });
    }
  }

  static Future<void> _recoverPlayback() async {
    if (_currentVolume <= 0 || _paused || _mode == _BgmMode.none) return;
    await _ensureBackend();
    final player = _bgmPlayer;
    if (player == null) return;
    if (player.state == PlayerState.playing) return;

    if (_hasLoadedSource && player.state == PlayerState.paused) {
      await player.resume();
      if (player.state == PlayerState.playing) return;
    }

    final gen = _generation;
    switch (_mode) {
      case _BgmMode.none:
        return;
      case _BgmMode.title:
        await _startTrack('pixel_jump_1.mp3', loop: true, generation: gen);
      case _BgmMode.gameplay:
        final track = _currentTrack == 'pixel_jump.mp3'
            ? 'pixel_jump.mp3'
            : 'pixel_jump_1.mp3';
        await _startTrack(
          track,
          loop: track == 'pixel_jump.mp3',
          generation: gen,
        );
      case _BgmMode.gameOver:
        await _startTrack('one_more_try.mp3', loop: true, generation: gen);
    }
  }

  /// Play title screen song (pixel_jump_1.mp3) looping indefinitely.
  static Future<void> playTitleBgm() {
    if (_mode == _BgmMode.title && !_paused && _hasLoadedSource) {
      return ensureAudioPlaying();
    }
    _mode = _BgmMode.title;
    _paused = false;
    final gen = ++_generation;
    return _enqueue(() async {
      await _startTrack('pixel_jump_1.mp3', loop: true, generation: gen);
    });
  }

  /// Play game over song (one_more_try.mp3) looping indefinitely.
  static Future<void> playGameOverBgm() {
    _mode = _BgmMode.gameOver;
    _paused = false;
    final gen = ++_generation;
    return _enqueue(() async {
      await _startTrack('one_more_try.mp3', loop: true, generation: gen);
    });
  }

  /// Play gameplay music sequence: `pixel_jump_1.mp3` -> `pixel_jump.mp3` loop.
  static Future<void> playGameplayBgm() {
    _mode = _BgmMode.gameplay;
    _paused = false;
    _currentTrack = 'pixel_jump_1.mp3';
    final gen = ++_generation;
    return _enqueue(() async {
      await _startTrack('pixel_jump_1.mp3', loop: false, generation: gen);
    });
  }

  /// Ensures active BGM plays/resumes on user gesture unless intentionally paused.
  static Future<void> ensureAudioPlaying() {
    if (_currentVolume <= 0 || _paused || _mode == _BgmMode.none) {
      return Future<void>.value();
    }
    if (_bgmPlayer?.state == PlayerState.playing && _hasLoadedSource) {
      return Future<void>.value();
    }
    return _enqueue(_recoverPlayback);
  }

  static Future<void> pauseBgm() {
    _paused = true;
    return _enqueue(() async {
      if (!_paused) return;
      await _bgmPlayer?.pause();
    });
  }

  static Future<void> resumeBgm() {
    _paused = false;
    if (_currentVolume <= 0 || _mode == _BgmMode.none) {
      return Future<void>.value();
    }
    return _enqueue(_recoverPlayback);
  }

  static Future<void> stopBgm() {
    _mode = _BgmMode.none;
    _paused = false;
    _currentTrack = null;
    _hasLoadedSource = false;
    _generation++;
    return _enqueue(() async {
      await _playerCompleteSub?.cancel();
      _playerCompleteSub = null;
      await _bgmPlayer?.stop();
    });
  }

  // --- Sound Effects & UI Audio Helpers ---

  static void playButton() {
    ensureAudioPlaying();
    SettingsManager.triggerVibration(duration: 15);
  }

  static void playCoin() {
    ensureAudioPlaying();
    SettingsManager.triggerVibration(duration: 25);
  }

  static void playJump() {
    ensureAudioPlaying();
    SettingsManager.triggerVibration(duration: 20);
  }

  static void playHit() {
    ensureAudioPlaying();
    SettingsManager.triggerVibration(duration: 50);
  }

  static void playUpgrade() {
    ensureAudioPlaying();
    SettingsManager.triggerVibration(duration: 40);
  }

  static void playBiomeSting() {
    if (_currentVolume <= 0) return;
    try {
      FlameAudio.play('biome_sting.wav', volume: _currentVolume);
    } catch (_) {}
    SettingsManager.triggerVibration(duration: 40);
  }

  static void playMilestoneChime() {
    if (_currentVolume <= 0) return;
    try {
      FlameAudio.play('milestone_chime.wav', volume: _currentVolume);
    } catch (_) {}
    SettingsManager.triggerVibration(duration: 25);
  }
}

