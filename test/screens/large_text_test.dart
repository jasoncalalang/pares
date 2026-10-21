import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/data/store_tiles.dart';
import 'package:mealpal_ph/screens/daily_target_screen.dart';
import 'package:mealpal_ph/screens/this_week_screen.dart';
import 'package:mealpal_ph/screens/welcome_screen.dart';
import 'package:mealpal_ph/screens/where_you_shop_screen.dart';
import 'package:mealpal_ph/state/plan_draft.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// Screens at the text sizes people set on their phones. The real fonts
/// are loaded by flutter_test_config.dart, so wrapping here is where
/// Fraunces and Plus Jakarta Sans actually wrap.
void main() {

  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(screen));
    await tester.pumpAndSettle();
  }

  RenderParagraph paragraph(WidgetTester tester, Finder f) =>
      tester.renderObject<RenderParagraph>(f);

  /// How many lines [text] (the whole of [f]'s text, or a slice) takes.
  int lines(WidgetTester tester, Finder f, [int start = 0, int? end]) {
    final p = paragraph(tester, f);
    final boxes = p.getBoxesForSelection(TextSelection(
      baseOffset: start,
      extentOffset: end ?? p.text.toPlainText().length,
    ));
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  /// No word of [f]'s text is broken across two lines.
  void expectWholeWords(WidgetTester tester, Finder f, {String? reason}) {
    final text = paragraph(tester, f).text.toPlainText();
    for (final m in RegExp(r'\S+').allMatches(text)) {
      expect(lines(tester, f, m.start, m.end), 1,
          reason: '${reason ?? text}: "${m.group(0)}" breaks mid-word');
    }
    expect(paragraph(tester, f).didExceedMaxLines, isFalse,
        reason: '${reason ?? text} is cut off');
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('Daily target keeps its number whole at ${scale}x',
        (tester) async {
      await pumpAt(
        tester,
        DailyTargetScreen(draft: PlanDraft(), onNext: () {}),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
      final numbers = find.text('2,087');
      expect(numbers, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        expect(lines(tester, numbers.at(i)), 1, reason: 'number $i');
      }
    });
  }

  testWidgets('Daily target goal buttons hold their labels at 2x on 360dp',
      (tester) async {
    await pumpAt(
      tester,
      DailyTargetScreen(draft: PlanDraft(), onNext: () {}),
      scale: 2.0,
      size: const Size(360, 844),
    );
    expect(tester.takeException(), isNull);
    for (final goal in ['Lose', 'Maintain', 'Gain']) {
      await tester.ensureVisible(find.text(goal));
      expectWholeWords(tester, find.text(goal));
    }
  });

  testWidgets('This week day strip grows with 2x text', (tester) async {
    await pumpAt(
      tester,
      ThisWeekScreen(draft: PlanDraft(), week: sampleWeek(), onGrocery: () {}),
      scale: 2.0,
    );
    expect(tester.takeException(), isNull);
    for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) {
      expect(lines(tester, find.text(d)), 1, reason: d);
    }
  });

  for (final size in [const Size(390, 844), const Size(360, 844)]) {
    testWidgets('Welcome CTA names its action in full at 2x, ${size.width}dp',
        (tester) async {
      await pumpAt(
        tester,
        WelcomeScreen(exampleDay: sampleWeek().first, onStart: () {}),
        scale: 2.0,
        size: size,
      );
      expect(tester.takeException(), isNull);
      expectWholeWords(tester, find.text('Find my calorie target'));
    });
  }

  for (final (scale, size) in [
    (1.0, const Size(360, 640)),
    (1.5, const Size(390, 844)),
    (2.0, const Size(390, 844)),
  ]) {
    testWidgets('store names stay whole at ${scale}x, ${size.width}dp',
        (tester) async {
      await pumpAt(
        tester,
        WhereYouShopScreen(draft: PlanDraft(), onNext: () {}),
        scale: scale,
        size: size,
      );
      expect(tester.takeException(), isNull);
      for (final t in [...chainTiles, ...localTiles]) {
        // The name, not the monogram ("S&R" is both).
        final name = find.text(t.name).last;
        await tester.ensureVisible(name);
        expectWholeWords(tester, name);
      }
    });
  }

  for (final (size, fullSize) in [
    (const Size(390, 844), true),
    (const Size(360, 640), false),
  ]) {
    testWidgets('at default text the store grid stays two a row, '
        '${size.width}dp', (tester) async {
      await pumpAt(
        tester,
        WhereYouShopScreen(draft: PlanDraft(), onNext: () {}),
        scale: 1.0,
        size: size,
      );
      final sm = tester.getRect(find.text('SM Supermarket'));
      final puregold = tester.getRect(find.text('Puregold'));
      expect(puregold.left, greaterThan(sm.right), reason: 'side by side');
      final fontSize = paragraph(tester, find.text('Puregold')).text.style!.fontSize!;
      if (fullSize) {
        expect(fontSize, 14);
      } else {
        expect(fontSize, inInclusiveRange(14 * MpStoreTile.minNameScale, 14));
      }
    });
  }
}
