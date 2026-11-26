import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/components/ui/menu_chrome.dart';

void main() {
  testWidgets(
    'Scenery keeps its opaque base and queues rapid epoch navigation',
    (tester) async {
      final selected = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (_, stage, _) => EpochScenery(stage: stage),
          ),
        ),
      );
      final context = tester.element(find.byType(EpochScenery));
      await tester.runAsync(() async {
        for (var stage = 0; stage < 4; stage++) {
          await precacheImage(EpochScenery.imageFor(stage), context);
        }
      });
      selected.value = 1;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('epoch-current-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('epoch-incoming-1')), findsOneWidget);
      for (final stage in [2, 3]) {
        selected.value = stage;
        await tester.pump();
        await tester.pump();
        expect(find.byType(Image).evaluate().length, lessThanOrEqualTo(2));
        expect(find.byKey(const ValueKey('epoch-current-0')), findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const ValueKey('epoch-current-3')), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      selected.dispose();
    },
  );
}
