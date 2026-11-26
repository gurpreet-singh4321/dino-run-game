import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/components/ui/splash_screen.dart';

void main() {
  for (final size in [const Size(568, 320), const Size(1024, 600)]) {
    testWidgets('Startup and retry fit $size with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: SplashArtwork(
              progress: .5,
              error: 'Dino could not load. Try again.',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final viewport = tester.getSize(find.byType(Scaffold));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getSize(find.byType(Scaffold)), viewport);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getSize(find.byType(Scaffold)), viewport);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .5,
      );
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
