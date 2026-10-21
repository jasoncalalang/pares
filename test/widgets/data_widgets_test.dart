import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  group('MpCalorieRing', () {
    testWidgets('counts up to its value', (tester) async {
      await tester.pumpWidget(
        host(const MpCalorieRing(value: 2087, fraction: 0.8)),
      );
      await tester.pump();
      expect(find.text('2,087'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('2,087'), findsOneWidget);
      expect(find.text('KCAL/DAY'), findsOneWidget);
    });

    testWidgets('shows the final value at once under reduced motion',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const MpCalorieRing(value: 2087, fraction: 0.8)),
        ),
      );
      await tester.pump();
      expect(find.text('2,087'), findsOneWidget);
    });
  });

  group('MpProgressSegments', () {
    testWidgets('exposes the step to assistive tech', (tester) async {
      await tester.pumpWidget(host(const MpProgressSegments(step: 2, of: 4)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);
    });
  });

  group('MpDayStrip', () {
    testWidgets('does not clip the focus ring drawn round each day',
        (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(Padding(
        padding: const EdgeInsets.all(22),
        child: MpDayStrip(
          days: Weekday.values,
          dayNumbers: const [20, 21, 22, 23, 24, 25, 26],
          selected: 0,
          onSelect: (_) {},
        ),
      )));
      final stack = tester.widget<Stack>(find.descendant(
          of: find.byType(MpDayStrip), matching: find.byType(Stack)));
      expect(stack.clipBehavior, Clip.none);
    });
  });
}
