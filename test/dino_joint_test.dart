import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Painted torso, knees, ankles and feet remain one connected silhouette',
    () async {
      await NewDinoSkin.preload();
      for (var sample = 0; sample < 18; sample++) {
        final skin = NewDinoSkin();
        final idle = sample >= 16;
        skin.advanceMotion(
          1,
          speed: 200,
          velocityY: 0,
          grounded: true,
          idle: idle,
        );
        skin.motion.phase = sample / 16;
        if (sample == 17) {
          for (var i = 0; i < 420; i++) {
            skin.advanceMotion(
              1 / 120,
              speed: 0,
              velocityY: 0,
              grounded: true,
              idle: true,
            );
          }
        }
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        skin.renderCharacter(canvas, const ui.Size(200, 240), 0);
        final picture = recorder.endRecording();
        final image = await picture.toImage(200, 240);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final bytes = data.buffer.asUint8List();
        final visited = <int>{};
        final queue = <int>[160 * 200 + 120]; // Interior of the torso.
        for (var cursor = 0; cursor < queue.length; cursor++) {
          final pixel = queue[cursor];
          if (pixel < 0 ||
              pixel >= 200 * 240 ||
              visited.contains(pixel) ||
              bytes[pixel * 4 + 3] < 100) {
            continue;
          }
          visited.add(pixel);
          final x = pixel % 200, y = pixel ~/ 200;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              if (x + dx >= 0 && x + dx < 200 && y + dy >= 0 && y + dy < 240) {
                queue.add((y + dy) * 200 + x + dx);
              }
            }
          }
        }
        for (final far in [false, true]) {
          final foot = skin.motion.foot(far);
          final pixel =
              ((foot.dy - 1) * 2).round() * 200 + (foot.dx * 2).round();
          expect(
            visited.contains(pixel),
            isTrue,
            reason: 'Detached ankle at sample $sample, far=$far',
          );
          // A connected toe can still hide a pinched or split ankle. Check
          // a solid band through the rotating shin-to-heel attachment too.
          final ankle = foot - const ui.Offset(0, 8);
          final angle = skin.motion.footAngle(far);
          for (var y = -2; y <= 4; y++) {
            for (var x = -2; x <= 2; x++) {
              final point =
                  ankle +
                  ui.Offset(
                    x * math.cos(angle) - y * math.sin(angle),
                    x * math.sin(angle) + y * math.cos(angle) + 8,
                  );
              final bandPixel =
                  (point.dy * 2).round() * 200 + (point.dx * 2).round();
              expect(
                bytes[bandPixel * 4 + 3],
                greaterThanOrEqualTo(240),
                reason: 'Split ankle band at sample $sample, far=$far ($x,$y)',
              );
            }
          }
        }
        image.dispose();
        picture.dispose();
      }
    },
  );
}
