import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Plugin platform fake verifies failed and delayed writes, not just cached state.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:dino_run_epochs/components/ui/settings_dialog.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/managers/audio_manager.dart';
import 'package:dino_run_epochs/managers/settings_manager.dart';

class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore() : super.empty();
  bool failWrites = false;
  Completer<void>? gate;
  int writes = 0;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    await gate?.future;
    if (failWrites) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsManager.load();
  });

  test('Old save keys survive and loaded volume is bounded', () async {
    SharedPreferences.setMockInitialValues({
      'dino_audio_volume': 1.5,
      'dino_vibration_enabled': false,
      'dino_reduce_motion': true,
      'dino_wallet': 345,
    });
    await SettingsManager.load();
    expect(SettingsManager.volume, 1);
    expect(AudioManager.volume, 1);
    expect(SettingsManager.vibrationEnabled, isFalse);
    expect(SettingsManager.reduceMotion, isTrue);
    await SettingsManager.save();
    expect((await SharedPreferences.getInstance()).getInt('dino_wallet'), 345);
  });

  test(
    'Rapid changes apply immediately and persist the latest complete state',
    () async {
      final store = _ControlledStore()..gate = Completer<void>();
      SharedPreferencesStorePlatform.instance = store;
      final first = SettingsManager.setVolume(.2);
      final second = SettingsManager.setVolume(.85);
      final third = SettingsManager.setVibrationEnabled(false);
      final fourth = SettingsManager.setReduceMotion(true);
      expect(SettingsManager.volume, .85);
      expect(SettingsManager.reduceMotion, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, 1);
      store.gate!.complete();
      expect(
        await Future.wait([first, second, third, fourth]),
        everyElement(isTrue),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getDouble('dino_audio_volume'), .85);
      expect(prefs.getBool('dino_vibration_enabled'), isFalse);
      expect(prefs.getBool('dino_reduce_motion'), isTrue);
      await SettingsManager.load();
      expect(SettingsManager.volume, .85);
      expect(SettingsManager.reduceMotion, isTrue);
    },
  );

  test(
    'Mute preserves the audible volume across reopening and storage failure can retry',
    () async {
      await SettingsManager.setVolume(.35);
      await SettingsManager.setSoundEnabled(false);
      await SettingsManager.load();
      expect(SettingsManager.volume, 0);
      // Avoid starting native audio in this logic-only test.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('dino_last_audible_volume'), .35);
      final store = _ControlledStore()..failWrites = true;
      SharedPreferencesStorePlatform.instance = store;
      expect(await SettingsManager.setVolume(.7), isFalse);
      expect(SettingsManager.volume, .7);
      store.failWrites = false;
      expect(await SettingsManager.save(), isTrue);
      await prefs.reload();
      expect(prefs.getDouble('dino_audio_volume'), .7);
    },
  );

  Widget app(VoidCallback close, {double scale = 1.3}) => MaterialApp(
    theme: AdventureTheme.data,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      child: child!,
    ),
    home: Scaffold(body: SettingsDialog(onClose: close)),
  );

  for (final size in [
    const Size(568, 320),
    const Size(360, 780),
    const Size(1024, 600),
  ]) {
    testWidgets(
      'Settings preferences scroll, Done stays reachable at $size with large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var closed = 0;
        await tester.pumpWidget(app(() => closed++));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('settings-done')).hitTestable(),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.text('Reduced motion'), 100);
        await tester.ensureVisible(find.text('Reduced motion'));
        await tester.pump();
        await tester.tap(find.text('Reduced motion'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(SettingsManager.reduceMotion, isTrue);
        expect(find.text('Changes saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('settings-done')));
        expect(closed, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Settings reports failed persistence and retries current preferences',
    (tester) async {
      final store = _ControlledStore()..failWrites = true;
      SharedPreferencesStorePlatform.instance = store;
      await tester.pumpWidget(app(() {}, scale: 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Sound'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(SettingsManager.volume, 0);
      expect(find.text('Applied here. Could not save.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      store.failWrites = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Changes saved'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Closing during a delayed save preserves the change safely', (
    tester,
  ) async {
    final store = _ControlledStore()..gate = Completer<void>();
    SharedPreferencesStorePlatform.instance = store;
    await tester.pumpWidget(app(() {}, scale: 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sound'));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    store.gate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    final values = await store.getAll();
    expect(values['flutter.dino_audio_volume'], 0);
  });
}
