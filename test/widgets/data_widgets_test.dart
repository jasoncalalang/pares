import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
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

    testWidgets('unselected day names clear 4.5:1 on cream', (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(MpDayStrip(
        days: Weekday.values,
        dayNumbers: const [20, 21, 22, 23, 24, 25, 26],
        selected: 3,
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();
      for (final d in ['MON', 'TUE', 'WED', 'FRI', 'SAT', 'SUN']) {
        expect(contrast(paintedColor(tester, find.text(d)), MpColors.light.cream),
            greaterThanOrEqualTo(4.5),
            reason: d);
      }
    });
  });

  group('MpGrocerySection', () {
    testWidgets('the store header is a full 44px tap target', (tester) async {
      await tester.pumpWidget(host(MpGrocerySection(
        section: sampleGroceryList(budgetPhp: 2500).sections[1],
        expanded: false,
        onToggle: () {},
        checked: const {},
        onCheck: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MpPress)).height,
          greaterThanOrEqualTo(MpSize.tap));
    });

    testWidgets('a checked row dims its text to faint, not to half opacity',
        (tester) async {
      await tester.pumpWidget(host(SingleChildScrollView(
        child: MpGrocerySection(
          section: sampleGroceryList(budgetPhp: 2500).sections[1],
          expanded: true,
          onToggle: () {},
          checked: const {0},
          onCheck: (_) {},
        ),
      )));
      await tester.pumpAndSettle();
      final faded = find.byWidgetPredicate((w) =>
          (w is Opacity && w.opacity < 1) ||
          (w is AnimatedOpacity && w.opacity < 1));
      for (final t in ['Rice', '5 kg', '₱285']) {
        expect(find.ancestor(of: find.text(t), matching: faded), findsNothing,
            reason: t);
        expect(paintedColor(tester, find.text(t)), MpColors.light.faint, reason: t);
        expect(contrast(paintedColor(tester, find.text(t)), MpColors.light.surface),
            greaterThanOrEqualTo(4.5),
            reason: t);
      }
    });
  });
}
