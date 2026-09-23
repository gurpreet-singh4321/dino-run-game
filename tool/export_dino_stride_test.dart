import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Export full stride for visual review', () async {
    await NewDinoSkin.preload();
    final dino = NewDinoSkin();
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    c.drawPaint(ui.Paint()..color = const ui.Color(0xFF203345));
    for (var i = 0; i < 8; i++) {
      dino.motion.run = 1;
      dino.motion.phase = i / 8;
      c.save();
      c.translate((i % 4) * 250.0, (i ~/ 4) * 305.0);
      dino.renderCharacter(c, const ui.Size(240, 288), 0);
      c.drawLine(const ui.Offset(0, 288), const ui.Offset(245, 288),
          ui.Paint()..color = const ui.Color(0xFF95BBA4));
      c.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1000, 610);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/new-dino-stride-review.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
