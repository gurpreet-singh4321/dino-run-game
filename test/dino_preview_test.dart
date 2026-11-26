import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/components/ui/animated_dino_preview.dart';
import 'package:dino_run_epochs/skins/new_dino_skin.dart';

void main() {
  testWidgets(
    'Previews own advancing clocks and never mutate gameplay motion',
    (tester) async {
      await tester.runAsync(NewDinoSkin.preload);
      final gameplay = NewDinoSkin();
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              AnimatedDinoPreview(template: gameplay, interactive: true),
              AnimatedDinoPreview(template: gameplay),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((widget) => widget.painter != null)
          .map((widget) => widget.painter)
          .toList();
      final first = (painters[0] as dynamic).skin as NewDinoSkin;
      final second = (painters[1] as dynamic).skin as NewDinoSkin;
      expect(identical(first, second), isFalse);
      expect(identical(first, gameplay), isFalse);
      expect(first.motion.time, greaterThan(0));
      expect(second.motion.time, greaterThan(0));
      expect(gameplay.motion.time, 0);
      await tester.tap(find.byType(AnimatedDinoPreview).first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(first.motion.wave, greaterThan(.1));
      expect(second.motion.wave, 0);
      expect(gameplay.motion.wave, 0);
      final beforeBlur = first.motion.time;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(milliseconds: 100));
      expect(first.motion.time, greaterThan(beforeBlur));
      first.onJump(doubleJump: true);
      expect(second.motion.launch, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
