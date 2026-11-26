import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';
import 'package:dino_run_epochs/skins/cosmetics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Yawning forearm stays in front of the neck scarf', () async {
    await NewDinoSkin.preload();
    final skin = NewDinoSkin();
    for (var i = 0; i < 540; i++) {
      skin.advanceMotion(
        1 / 120,
        speed: 0,
        velocityY: 0,
        grounded: true,
        idle: true,
      );
    }
    Future<List<int>> forearmPixel() async {
      final recorder = ui.PictureRecorder();
      skin.renderCharacter(ui.Canvas(recorder), const ui.Size(200, 240), 0);
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 240);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final angle = -skin.motion.yawn * 1.8;
      final x = 48 + 2 * math.cos(angle) - 12 * math.sin(angle);
      final y =
          66 +
          skin.motion.bodyY +
          2 * math.sin(angle) +
          12 * math.cos(angle) +
          8;
      final index = ((y * 2).round() * 200 + (x * 2).round()) * 4;
      final result = data.buffer.asUint8List().sublist(index, index + 4);
      image.dispose();
      picture.dispose();
      return result;
    }

    final bare = await forearmPixel();
    skin.cosmetics = [CosmeticCatalog.find('red_scarf')!];
    final dressed = await forearmPixel();
    for (var channel = 0; channel < 4; channel++) {
      expect(
        dressed[channel],
        closeTo(bare[channel], 3),
        reason: 'Scarf must not overpaint the raised forearm',
      );
    }
    expect(dressed[1], greaterThan(110));
    expect(dressed[3], 255);
  });
}
