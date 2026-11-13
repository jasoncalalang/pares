import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  group('MpCalorieRing', () {
    testWidgets('counts up to its value', (tester) async {
      await tester.pumpWidget(
        host(const MpCalorieRing(percent: 81, fraction: 0.81)),
      );
      await tester.pump();
      expect(find.text('81%'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('81%'), findsOneWidget);
      expect(find.text('OF MAINTENANCE'), findsOneWidget);
    });

    testWidgets('says its centre once, as a sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const MpCalorieRing(percent: 81, fraction: 0.81)),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('81% of maintenance'), findsOneWidget);
      expect(find.bySemanticsLabel('81%'), findsNothing);
      expect(find.bySemanticsLabel('OF MAINTENANCE'), findsNothing);
      handle.dispose();
    });

    testWidgets('the arc is the light annatto, which clears 3:1 on the hero '
        'card', (tester) async {
      const c = MpColors.light;
      await tester.pumpWidget(
        host(const MpCalorieRing(percent: 81, fraction: 0.81)),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MpCalorieRing),
          matching: find.byType(CustomPaint),
        ),
        paints
          ..arc()
          ..arc(color: c.annattoFleck),
      );
      expect(contrast(c.annattoFleck, c.heroSurface), greaterThanOrEqualTo(3));
    });

    testWidgets('shows the final value at once under reduced motion',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const MpCalorieRing(percent: 81, fraction: 0.81)),
        ),
      );
      await tester.pump();
      expect(find.text('81%'), findsOneWidget);
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

    testWidgets('the selected day name uses heroMuted, not dimmed heroText',
        (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(MpDayStrip(
        days: Weekday.values,
        dayNumbers: const [20, 21, 22, 23, 24, 25, 26],
        selected: 3,
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();
      final color = paintedColor(tester, find.text('THU'));
      expect(color, MpColors.light.heroMuted);
      expect(color.a, 1.0);
      expect(contrast(color, MpColors.light.heroSurface),
          greaterThanOrEqualTo(4.5));
    });

    testWidgets('unselected day names clear 4.5:1 on the page', (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(MpDayStrip(
        days: Weekday.values,
        dayNumbers: const [20, 21, 22, 23, 24, 25, 26],
        selected: 3,
        onSelect: (_) {},
      )));
      await tester.pumpAndSettle();
      for (final d in ['MON', 'TUE', 'WED', 'FRI', 'SAT', 'SUN']) {
        expect(contrast(paintedColor(tester, find.text(d)), MpColors.light.paper),
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

    testWidgets('a fish item gets the fish glyph', (tester) async {
      await tester.pumpWidget(host(SingleChildScrollView(
        child: MpGrocerySection(
          section: const GrocerySection(
            storeId: 'palengke',
            name: 'Wet market',
            monogram: 'W',
            local: true,
            items: [
              GroceryItem(
                name: 'Daing na bangus',
                quantity: '300 g',
                pricePhp: 72,
                kind: GroceryKind.fish,
              ),
            ],
          ),
          expanded: true,
          onToggle: () {},
          checked: const {},
          onCheck: (_) {},
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.fish), findsOneWidget);
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
