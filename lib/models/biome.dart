import 'package:flutter/material.dart';

class Biome {
  final String name;
  final Color skyTop;
  final Color skyBottom;
  final Color groundTop;
  final Color groundBottom;

  const Biome({
    required this.name,
    required this.skyTop,
    required this.skyBottom,
    required this.groundTop,
    required this.groundBottom,
  });
}
