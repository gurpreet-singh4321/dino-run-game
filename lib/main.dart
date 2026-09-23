import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'managers/coin_manager.dart';
import 'managers/settings_manager.dart';
import 'components/ui/splash_screen.dart';
import 'components/ui/adventure_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final coinManager = CoinManager();
  await coinManager.load();
  await SettingsManager.load();

  runApp(
    MaterialApp(
      title: 'Dino Run Epochs',
      theme: AdventureTheme.data,
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus}),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(coinManager: coinManager),
    ),
  );
}
