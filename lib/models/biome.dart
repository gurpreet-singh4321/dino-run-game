import 'package:flutter/material.dart';

class Biome {
  final String name;
  final String displayName;
  final Color skyTop;
  final Color skyBottom;
  final Color groundTop;
  final Color groundBottom;
  final Color accentColor;

  const Biome({
    required this.name,
    required this.displayName,
    required this.skyTop,
    required this.skyBottom,
    required this.groundTop,
    required this.groundBottom,
    required this.accentColor,
  });
}
