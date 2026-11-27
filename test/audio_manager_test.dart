import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';

class _FakeBgmBackend implements BgmBackend {
  PlayerState _state = PlayerState.stopped;
  final StreamController<void> completeController =
      StreamController<void>.broadcast();
  final List<String> calls = <String>[];
  bool failPlay = false;

  @override
  PlayerState get state => _state;

  @override
  Stream<void> get onPlayerComplete => completeController.stream;

  @override
  Future<void> setVolume(double volume) async {
    calls.add('setVolume:${volume.toStringAsFixed(2)}');
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    calls.add('release:${mode.name}');
  }

  @override
  Future<void> play(Source source, {double? volume}) async {
    calls.add('play:$source');
    if (failPlay) {
      _state = PlayerState.stopped;
      throw StateError('Simulated browser autoplay block');
    }
    _state = PlayerState.playing;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    if (_state == PlayerState.playing) _state = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    if (_state == PlayerState.paused) _state = PlayerState.playing;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _state = PlayerState.stopped;
  }
}

void main() {
  setUp(() async {
    await AudioManager.resetForTest(initialVolume: 0.6);
  });

  tearDown(() async {
    await AudioManager.resetForTest(initialVolume: 0.6);
  });

  test('Pause keeps BGM paused on gestures and resumes without restarting', () async {
    final backend = _FakeBgmBackend();
    AudioManager.backendFactory = () => backend;

    await AudioManager.playGameplayBgm();
    expect(backend.state, PlayerState.playing);
    final playCallsBeforePause =
        backend.calls.where((c) => c.startsWith('play:')).length;
    expect(playCallsBeforePause, 1);

    await AudioManager.pauseBgm();
    expect(backend.state, PlayerState.paused);
    expect(AudioManager.isPausedForTest, isTrue);

    // Clicking buttons/settings while paused triggers ensureAudioPlaying(); it
    // must NOT unpause or restart BGM from 0:00.
    await AudioManager.ensureAudioPlaying();
    await AudioManager.ensureAudioPlaying();
    expect(backend.state, PlayerState.paused);
    expect(backend.calls.where((c) => c.startsWith('play:')).length, 1);
    expect(backend.calls.where((c) => c == 'stop').length, 0);

    // Resuming calls resume() rather than stop()+play().
    await AudioManager.resumeBgm();
    expect(backend.state, PlayerState.playing);
    expect(AudioManager.isPausedForTest, isFalse);
    expect(backend.calls.where((c) => c.startsWith('play:')).length, 1);
    expect(backend.calls.where((c) => c == 'resume').length, 1);
  });

  test('Menu music recovers after blocked autoplay and does not restart when active', () async {
    final backend = _FakeBgmBackend()..failPlay = true;
    AudioManager.backendFactory = () => backend;

    // Initial ungesture load blocks play().
    await AudioManager.playTitleBgm();
    expect(backend.state, PlayerState.stopped);

    // Clicking a menu button sends concurrent ensureAudioPlaying + playTitleBgm.
    backend.failPlay = false;
    await Future.wait([
      AudioManager.ensureAudioPlaying(),
      AudioManager.ensureAudioPlaying(),
      AudioManager.playTitleBgm(),
    ]);
    expect(backend.state, PlayerState.playing);
    expect(AudioManager.currentTrackForTest, 'pixel_jump_1.mp3');

    // Only one play succeeded after unblock, no stop() interruption race!
    final playsAfterUnblock = backend.calls.where((c) => c.startsWith('play:'));
    expect(playsAfterUnblock.length, 2); // 1 failed pre-gesture + 1 active start
    expect(backend.calls.where((c) => c == 'stop').length, 0);

    // Returning to title or tapping menu when already playing keeps current playback.
    await AudioManager.playTitleBgm();
    expect(backend.calls.where((c) => c.startsWith('play:')).length, 2);
  });

  test('Gameplay transitions to pixel_jump loop and resumes pixel_jump after pause', () async {
    final backend = _FakeBgmBackend();
    AudioManager.backendFactory = () => backend;

    await AudioManager.playGameplayBgm();
    expect(AudioManager.currentTrackForTest, 'pixel_jump_1.mp3');

    backend.completeController.add(null);
    await pumpEventQueue();
    await AudioManager.ensureAudioPlaying();
    expect(AudioManager.currentTrackForTest, 'pixel_jump.mp3');
    expect(backend.state, PlayerState.playing);

    await AudioManager.pauseBgm();
    await AudioManager.resumeBgm();
    expect(AudioManager.currentTrackForTest, 'pixel_jump.mp3');
    expect(backend.state, PlayerState.playing);
    expect(
      backend.calls.where((c) => c.contains('pixel_jump_1.mp3')).length,
      1,
    );
  });
}
