import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_rive/flame_rive.dart';
import 'managers/coin_manager.dart';
import 'managers/settings_manager.dart';
import 'components/ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await RiveNative.init();

  final coinManager = CoinManager();
  await coinManager.load();
  await SettingsManager.load();

  runApp(
    MaterialApp(
      title: 'Dino Run Epochs',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(coinManager: coinManager),
    ),
  );
}
