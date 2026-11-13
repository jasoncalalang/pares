import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// A box decorated with the 2px annatto focus ring.
Finder focusRing() => find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final d = w.foregroundDecoration;
      if (d is! BoxDecoration) return false;
      final side = d.border?.top;
      return side != null &&
          side.width == MpStroke.focus &&
          side.color == MpColors.light.annatto;
    });

void main() {
  group('MpBigValueField', () {
    Widget field() => host(Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: MpBigValueField(
              label: 'Weight',
              value: 70,
              unit: 'kg',
              fieldKey: const ValueKey('field-weight'),
              onChanged: (_) {},
            ),
          ),
        ));

    bool focused(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(const ValueKey('field-weight')))
        .focusNode!
        .hasFocus;

    testWidgets('shows the annatto focus ring while it has focus, and only then',
        (tester) async {
      await phone(tester);
      await tester.pumpWidget(field());
      expect(focusRing(), findsNothing);

      await tester.tap(find.byKey(const ValueKey('field-weight')));
      await tester.pump();
      expect(focused(tester), isTrue);
      expect(focusRing(), findsOneWidget);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(focusRing(), findsNothing);
    });

    testWidgets('the whole 64px box takes the tap, not just the digits',
        (tester) async {
      await phone(tester);
      await tester.pumpWidget(field());
      final box = tester.getRect(find
          .ancestor(
            of: find.byKey(const ValueKey('field-weight')),
            matching: find.byType(Container),
          )
          .first);
      expect(box.height, MpSize.bigInput);

      await tester.tapAt(box.topLeft + const Offset(20, 4));
      await tester.pump();
      expect(focused(tester), isTrue, reason: 'top edge of the box');

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(focused(tester), isFalse);

      await tester.tap(find.text('kg'));
      await tester.pump();
      expect(focused(tester), isTrue, reason: 'the unit');
    });
  });

  group('MpPage', () {
    testWidgets('the scroll areas reach the screen edge, so a focus ring or '
        'selection halo at the gutter is not clipped', (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(MpPage(
        content: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 60, child: Text('row $i')),
        ],
        footer: const SizedBox(height: 54, child: Text('cta')),
      )));
      for (final view in tester.widgetList(find.byType(SingleChildScrollView))) {
        final rect = tester.getRect(find.byWidget(view));
        expect(rect.left, 0);
        expect(rect.right, 390);
      }
      // The content still sits on the 22px gutters.
      expect(tester.getRect(find.text('row 0')).left, MpSpacing.gutter);
      expect(tester.getRect(find.text('cta')).left, MpSpacing.gutter);
    });

    testWidgets('holds the column to one phone width on a tablet',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(MpPage(
        content: const [SizedBox(height: 60, child: Text('row'))],
        footer: MpCta(label: 'Go', onPressed: () {}),
      )));
      final cta = tester.getRect(find.byType(MpCta));
      expect(cta.width, MpSize.pageMax - 2 * MpSpacing.gutter);
      expect(cta.center.dx, 768 / 2);
      final row = tester.getRect(find.byType(SizedBox).first);
      expect(row.width, lessThanOrEqualTo(MpSize.pageMax));
    });
  });

  group('MpCta', () {
    testWidgets('a disabled label still clears 4.5:1 on its fill',
        (tester) async {
      await tester.pumpWidget(host(const MpCta(label: 'Wait', onPressed: null)));
      final color = paintedColor(tester, find.text('Wait'));
      expect(color, MpColors.light.muted);
      expect(contrast(color, MpColors.light.hairline), greaterThanOrEqualTo(4.5));
    });
  });

  group('MpProgressSegments', () {
    testWidgets('only the step just reached fills; earlier steps are already '
        'full on the first frame', (tester) async {
      await phone(tester);
      await tester.pumpWidget(host(const MpProgressSegments(step: 3)));
      // First frame, before any animation has run.
      final filled = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == MpColors.light.annatto,
      );
      final widths = [
        for (final e in filled.evaluate()) (e.renderObject! as RenderBox).size.width,
      ];
      expect(widths.length, 3);
      expect(widths[0], greaterThan(50));
      expect(widths[1], greaterThan(50));
      expect(widths[2], 0);

      await tester.pumpAndSettle();
      final settled = [
        for (final e in filled.evaluate()) (e.renderObject! as RenderBox).size.width,
      ];
      expect(settled[2], settled[0]);
    });
  });
}
