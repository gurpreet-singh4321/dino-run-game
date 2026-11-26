import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_run_epochs/utils/vibration_util.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Disabling vibration suppresses every gameplay and audio helper', () async {
    SharedPreferences.setMockInitialValues({});
    final calls = <String>[];
    const channel = MethodChannel('vibration');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method); return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await SettingsManager.setVibrationEnabled(false);
    AudioManager.setVolume(0);
    GameVibration.heavyImpact(); GameVibration.mediumImpact(); GameVibration.lightImpact();
    AudioManager.playCoin(); AudioManager.playHit(); AudioManager.playButton();
    await SettingsManager.triggerVibration();
    expect(calls, isEmpty);
  });
}
