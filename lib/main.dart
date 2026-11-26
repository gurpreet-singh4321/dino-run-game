import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'managers/coin_manager.dart';
import 'managers/settings_manager.dart';
import 'components/ui/splash_screen.dart';
import 'components/ui/adventure_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Browser viewport stays stable; native devices enter landscape once.
  if (!kIsWeb) {
    await Flame.device.fullScreen();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  final coinManager = CoinManager();
  await coinManager.load();
  await SettingsManager.load();

  runApp(
    MaterialApp(
      title: 'Dino Run Epochs',
      theme: AdventureTheme.data,
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: SettingsManager.reducedMotion,
        child: child,
        builder: (context, quiet, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: MediaQuery.disableAnimationsOf(context) || quiet,
          ),
          child: child!,
        ),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(coinManager: coinManager),
    ),
  );
}
