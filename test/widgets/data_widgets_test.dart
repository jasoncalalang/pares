import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
