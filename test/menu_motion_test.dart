import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dino_run_epochs/components/ui/adventure_theme.dart';
import 'package:dino_run_epochs/components/ui/illustrated_menu.dart';
import 'package:dino_run_epochs/components/ui/menu_motion.dart';

void main() {
  testWidgets(
    'Controls depress without moving their hit targets or double firing',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AdventureTheme.data,
          home: Scaffold(
            body: Center(
              child: MenuAction(
                symbol: MenuSymbol.play,
                label: 'Play',
                color: Colors.amber,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byType(FilledButton);
      final before = tester.getRect(target);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 170));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .94,
      );
      expect(tester.getRect(target), before);
      expect(taps, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    },
  );
  for (final quiet in [false, true]) {
    testWidgets('Disabled controls stay still; reduced motion=$quiet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AdventureTheme.data,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: quiet),
            child: const Scaffold(
              body: MenuAction(
                symbol: MenuSymbol.gift,
                label: 'Claimed',
                color: Colors.amber,
                onPressed: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MenuArrival), findsNothing);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });
  }
  testWidgets(
    'Reduced motion keeps enabled controls and panels immediately visible',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AdventureTheme.data,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: MenuArrival(
                child: MenuAction(
                  symbol: MenuSymbol.play,
                  label: 'Play',
                  color: Colors.amber,
                  onPressed: () => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(taps, 1);
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
