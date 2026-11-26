import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Draw the actual rig across movement and idle gestures', () async {
    await NewDinoSkin.preload();
    // Ahem is Flutter's test font. For readable exported labels, use a local
    // system font without copying or redistributing it as a game asset.
    final fontFile = File('C:/Windows/Fonts/segoeui.ttf');
    if (const bool.fromEnvironment('DINO_CAPTURE')) {
      if (await fontFile.exists()) {
        final loader = FontLoader('EvidenceFont');
        loader.addFont(
          Future.value(ByteData.sublistView(await fontFile.readAsBytes())),
        );
        await loader.load();
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const labels = [
      'Idle',
      'Run / contact',
      'Run / recovery',
      'Jump',
      'Double jump',
      'Fall',
      'Land',
      'Damage',
      'Rocket',
      'Explorer outfit',
      'Idle / yawn',
      'Idle / look around',
      'Idle / wave',
    ];
    canvas.drawColor(const Color(0xFFFFF3DD), BlendMode.src);
    for (var i = 0; i < labels.length; i++) {
      final skin = NewDinoSkin();
      final idle = i == 0 || i >= 10;
      final air = i == 3 || i == 4 || i == 5 || i == 8;
      for (var step = 0; step < 120; step++) {
        skin.advanceMotion(
          1 / 120,
          speed: 200,
          velocityY: 0,
          grounded: true,
          idle: idle,
        );
      }
      if (i == 1) {
        skin.motion.phase = .1;
      }
      if (i == 2) {
        skin.motion.phase = .55;
      }
      if (i == 3 || i == 4) skin.onJump(doubleJump: i == 4);
      if (i == 6) {
        skin.advanceMotion(.1, speed: 200, velocityY: 500, grounded: false);
      }
      if (i == 7) {
        skin.onDamage();
      }
      if (i == 9) {
        skin.cosmetics = CosmeticCatalog.items
            .where(
              (item) => const [
                'explorer_hat',
                'red_scarf',
                'explorer_pack',
              ].contains(item.id),
            )
            .toList();
      }
      if (i >= 10) {
        final remaining = [3.5, 8.5, 12.5][i - 10];
        for (var step = 0; step < (remaining * 120).round(); step++) {
          skin.advanceMotion(
            1 / 120,
            speed: 0,
            velocityY: 0,
            grounded: true,
            idle: true,
          );
        }
      }
      if (i >= 3 && i < 10) {
        skin.advanceMotion(
          .07,
          speed: 200,
          velocityY: i == 5
              ? 450
              : air
              ? -400
              : 0,
          grounded: !air,
          space: i == 8,
        );
      }
      canvas.save();
      canvas.translate((i % 5) * 220.0, (i ~/ 5) * 240.0);
      final title = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            fontFamily: 'EvidenceFont',
            color: Color(0xFF553B2C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      title.paint(canvas, const Offset(12, 12));
      canvas.drawLine(
        const Offset(10, 214),
        const Offset(210, 214),
        Paint()
          ..color = const Color(0xFF97734D)
          ..strokeWidth = 1,
      );
      canvas.translate(42, 46);
      skin.renderCharacter(canvas, const Size(140, 168), 0);
      canvas.restore();
      expect(skin.motion.foot(false).dx.isFinite, isTrue);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1100, 720);
    if (const bool.fromEnvironment('DINO_CAPTURE')) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${Directory.current.path}/docs/dino-stage1-poses.png',
      ).writeAsBytes(png!.buffer.asUint8List());
    }
    image.dispose();
    picture.dispose();
  });
}
