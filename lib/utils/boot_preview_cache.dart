import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../components/ui/dino_hill_top.dart';
import '../skins/new_dino_skin.dart';
import '../skins/skin.dart';
import '../skins/skin_registry.dart';
import 'boot_handoff.dart';

Future<String?> _renderPng(
  double logicalW,
  double logicalH,
  void Function(Canvas canvas) paint, {
  double scale = 2.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(scale, scale);
  paint(canvas);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(
      (logicalW * scale).round(),
      (logicalH * scale).round(),
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return 'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}';
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

/// Bakes separated hilltop + open/blinking equipped Dino frames into JSON
/// data URLs so `web/index.html` plays a smooth living idle animation before
/// Flutter finishes initializing.
Future<void> cacheBootStagePreview(CharacterSkin skin, {int stage = 0}) async {
  if (!kIsWeb) return;
  try {
    await NewDinoSkin.preload();
    const dinoH = 196.0;
    const dinoW = dinoH * 0.86;
    final ledgeH = (dinoH * 0.26).clamp(24.0, 62.0);
    final ledgeW = dinoW * 1.54;

    final hillUrl = await _renderPng(
      ledgeW,
      ledgeH,
      (canvas) => DinoHillTopPainter(stage).paint(canvas, Size(ledgeW, ledgeH)),
    );
    if (hillUrl == null) return;

    final openSkin = SkinRegistry.createInstance(skin.id)
      ..cosmetics = List.of(skin.cosmetics);
    final openUrl = await _renderPng(
      dinoW,
      dinoH,
      (canvas) => openSkin.renderCharacter(canvas, const Size(dinoW, dinoH), 0),
    );
    if (openUrl == null) return;

    String? blinkUrl;
    if (openSkin is NewDinoSkin) {
      openSkin.setBlinkPose(1.0);
      blinkUrl = await _renderPng(
        dinoW,
        dinoH,
        (canvas) => openSkin.renderCharacter(canvas, const Size(dinoW, dinoH), 0),
      );
    }

    saveDinoBootStage(
      jsonEncode({
        'hill': hillUrl,
        'open': openUrl,
        'blink': ?blinkUrl,
      }),
    );
  } catch (_) {}
}
