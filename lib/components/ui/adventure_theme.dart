import 'package:flutter/material.dart';
import 'menu_chrome.dart';
import 'illustrated_menu.dart';
import 'menu_motion.dart';

class AdventureTheme {
  static ThemeData get data => forAccent(MenuPalette.forest);
  static ThemeData forAccent(Color accent) => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      secondary: MenuPalette.gold,
      surface: MenuPalette.paper,
      onSurface: MenuPalette.ink,
    ),
    scaffoldBackgroundColor: MenuPalette.paper,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Nunito',
      bodyColor: MenuPalette.ink,
      displayColor: MenuPalette.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: adventureButtonStyle(accent),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MenuPalette.ink,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: accent.withValues(alpha: .5), width: 2),
        backgroundColor: accent.withValues(alpha: .07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ).copyWith(foregroundBuilder: adventureButtonMotion),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MenuPalette.ink,
        minimumSize: const Size(48, 48),
      ).copyWith(foregroundBuilder: adventureButtonMotion),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: MenuPalette.ink,
        minimumSize: const Size(48, 48),
      ).copyWith(foregroundBuilder: adventureButtonMotion),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: const Color(0xFFDEC9A3),
      overlayColor: accent.withValues(alpha: .16),
      trackHeight: 5,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? const Color(0xFFFFFDF6)
              : const Color(0xFF5D4C36)),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? accent
              : const Color(0xFFE3D5BA)),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Color.lerp(accent, const Color(0xFF1E140B), .45)!
              : const Color(0xFF9F8C6F)),
      trackOutlineWidth: const WidgetStatePropertyAll(1.6),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: MenuPalette.paper),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: MenuPalette.forest,
      contentTextStyle: TextStyle(color: MenuPalette.paper),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
