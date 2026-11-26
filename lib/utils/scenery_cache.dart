import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Single-flight decoded scenery cache shared by startup and the game renderer.
class SceneryCache {
  static final Map<String, Future<ui.Image>> _images = {};
  static final Map<String, ui.Image> _resolved = {};
  static ui.Image? getCached(String name) => _resolved[name];
  static const paths = [
    'desert_fossil_canyon.png',
    'rain_painted_v1.png',
    'forest_painted_v1.png',
    'ice_painted_v1.png',
    'volcano_painted_v1.png',
    'cosmos_painted_v1.png',
    'orbit_painted_v1.png',
  ];
  static Future<ui.Image> load(String name) =>
      _images.putIfAbsent(name, () async {
        try {
          final bytes = await rootBundle.load('assets/images/biomes/$name');
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
            targetWidth: 1280,
            allowUpscaling: false,
          );
          try {
            final image = (await codec.getNextFrame()).image;
            _resolved[name] = image;
            return image;
          } finally {
            codec.dispose();
          }
        } catch (_) {
          _images.remove(name);
          rethrow;
        }
      });
}
