import 'package:flutter/material.dart';

/// Shared storybook palette and generous touch targets across game menus.
class AdventureTheme {
  static ThemeData get data => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCF62),
      brightness: Brightness.dark, primary: const Color(0xFFFFCF62),
      secondary: const Color(0xFF8FE2CC), surface: const Color(0xFF183848)),
    scaffoldBackgroundColor: const Color(0xFF102B3B),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF245566),
      foregroundColor: const Color(0xFFFFE5A3),
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800))),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    chipTheme: ChipThemeData(backgroundColor: const Color(0xFF244A59),
      labelStyle: const TextStyle(color: Color(0xFFFFEDC1), fontWeight: FontWeight.w700),
      side: const BorderSide(color: Color(0xFF54737B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF183848)),
  );
}
