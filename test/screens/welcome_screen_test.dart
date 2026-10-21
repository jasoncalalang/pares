import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/screens/welcome_screen.dart';

import '../helpers.dart';

const _headline = 'Filipino meals that fit your calorie goal and your weekly budget.';
const _sheetBody = 'Sign-in arrives with accounts. For now your plan stays on this '
    'device, and no account is needed.';

void main() {
  var starts = 0;

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    starts = 0;
    await tester.pumpWidget(
      host(WelcomeScreen(exampleDay: sampleWeek().first, onStart: () => starts++)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('states the job over the plate collage, with one primary action',
      (tester) async {
    await pump(tester);
    expect(find.text('MealPal '), findsNothing, reason: 'wordmark is one rich text');
    expect(find.text(_headline), findsOneWidget);
    expect(
      find.text('Your stats become a daily target. Your target becomes a week '
          'of real meals from the stores near you, with the grocery list to '
          'match.'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNWidgets(4));
    // Stickers come from the example day: its first plate and its total.
    expect(find.text('560 kcal'), findsOneWidget);
    expect(find.text('₱95'), findsOneWidget);
    expect(find.text('2,087 kcal / day'), findsOneWidget);
    expect(find.text('Find my calorie target'), findsOneWidget);
    expect(find.text('or continue with'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    expect(find.textContaining('STEP'), findsNothing);
  });

  testWidgets('the primary action starts the flow', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Find my calorie target'));
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  for (final provider in ['Google', 'Apple', 'email']) {
    testWidgets('Continue with $provider opens the honest sign-in sheet',
        (tester) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Continue with $provider'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text(_sheetBody), findsOneWidget);
      expect(starts, 0, reason: 'a provider never starts the flow by itself');

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text(_sheetBody), findsNothing);
    });
  }

  testWidgets('the sheet closes on Escape and on the scrim', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(_sheetBody), findsNothing);

    await tester.tap(find.bySemanticsLabel('Continue with Apple'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 80));
    await tester.pumpAndSettle();
    expect(find.text(_sheetBody), findsNothing);
  });

  testWidgets('on a small phone the content scrolls and the actions stay put',
      (tester) async {
    await pump(tester, size: const Size(360, 640));
    final cta = tester.getRect(find.text('Find my calorie target'));
    expect(cta.bottom, lessThanOrEqualTo(640));
    final google = tester.getRect(find.bySemanticsLabel('Continue with Google'));
    expect(google.bottom, lessThanOrEqualTo(640));
  });

  testWidgets('every provider button is a full tap target', (tester) async {
    await pump(tester);
    for (final provider in ['Google', 'Apple', 'email']) {
      final size = tester.getSize(find.bySemanticsLabel('Continue with $provider'));
      expect(size.height, greaterThanOrEqualTo(44), reason: provider);
    }
  });
}
