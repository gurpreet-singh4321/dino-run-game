import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Shared, downsampled session assets. No decode or file work inside render.
class GearAssets {
  static ui.Image? cart;
  static ui.Image? jetpack;
  static Future<void>? _loading;
  static Future<void> preload() =>
      _loading ??= _load().catchError((Object error) {
        _loading = null;
        throw error;
      });
  static Future<ui.Image> _decode(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static Future<void> _load() async {
    final images = await Future.wait([
      _decode('assets/images/cart_painted_v1.png', 384),
      _decode('assets/images/jetpack_painted_v2.png', 192),
    ]);
    cart = images[0];
    jetpack = images[1];
  }

  static void drawJetpack(ui.Canvas canvas, ui.Rect target) {
    final image = jetpack;
    if (image == null) return;
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      target,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  }
}
