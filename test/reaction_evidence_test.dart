import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';
import 'package:dino_run_epochs/components/particle.dart';
import 'package:dino_run_epochs/game/hazard_contact.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Export production stumble poses and material impacts', () async {
    await NewDinoSkin.preload();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFFFF3DD), BlendMode.src);
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 6; column++) {
        final skin = NewDinoSkin();
        skin.cosmetics = CosmeticCatalog.items
            .where((i) => i.id == 'red_scarf')
            .toList();
        skin.advanceMotion(
          1,
          speed: 300,
          velocityY: row == 0 ? 0 : -300,
          grounded: row == 0,
        );
        skin.onDamage();
        skin.advanceMotion(
          .008 + column * .075,
          speed: 300,
          velocityY: row == 0 ? 0 : -300,
          grounded: row == 0,
        );
        canvas.save();
        canvas.translate(column * 170.0 + 10, row * 205.0 + 10);
        canvas.drawLine(
          const Offset(0, 180),
          const Offset(160, 180),
          Paint()..color = const Color(0xFFBA9772),
        );
        skin.renderCharacter(canvas, const Size(145, 174), 0);
        canvas.restore();
      }
    }
    for (var i = 0; i < HazardMaterial.values.length; i++) {
      final pool = ParticlePool();
      pool.emitSmash(Vector2(60, 60), HazardMaterial.values[i]);
      pool.update(.12);
      canvas.save();
      canvas.translate(i * 125.0, 420);
      pool.render(canvas);
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1020, 550);
    if (const bool.fromEnvironment('DINO_CAPTURE')) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'docs/reactions-phase2-poses.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    }
    image.dispose();
    picture.dispose();
  });
}
