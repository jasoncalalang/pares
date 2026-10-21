import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/screens/welcome_screen.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

const _headline = 'Filipino meals that fit your calorie goal and your weekly budget.';
const _sheetBody = 'Sign-in is coming soon. For now no account is needed, and '
    'your plan is not kept after you close the app.';
const _comingSoon = 'Sign-in is coming soon. No account is needed to plan.';

Finder _image(String meal) =>
    find.byWidgetPredicate((w) => w is Image && w.semanticLabel == meal);

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
    expect(find.text('MealPal PH'), findsOneWidget, reason: 'wordmark is one rich text');
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
    expect(find.text(_comingSoon), findsOneWidget,
        reason: 'placeholder buttons say so before anyone taps');
    expect(find.text('Get started'), findsNothing);
    expect(find.textContaining('STEP'), findsNothing);
  });

  testWidgets('the peso sticker sits on the plate whose price it quotes',
      (tester) async {
    await pump(tester);
    final lead = tester.getRect(_image('Tapsilog: beef tapa, garlic rice and egg'));
    final sticker = tester.getRect(
        find.ancestor(of: find.text('₱95'), matching: find.byType(Container)).first);
    expect(lead.contains(sticker.center), isTrue);
    for (final other in [
      'Chicken tinola with moringa and rice',
      'Ginisang munggo with tofu, water spinach and rice',
      'Saba banana and peanuts',
    ]) {
      expect(tester.getRect(_image(other)).overlaps(sticker), isFalse, reason: other);
    }
  });

  testWidgets('the plates and provider glyphs follow their tokens',
      (tester) async {
    await pump(tester);
    // A plate's photo sits inside its 1px hairline border.
    expect(tester.getSize(_image('Tapsilog: beef tapa, garlic rice and egg')),
        const Size.square(MpSize.collageTile - 2));
    Size mark(MpBrand brand) => tester.getSize(
        find.byWidgetPredicate((w) => w is MpBrandMark && w.brand == brand));
    expect(mark(MpBrand.google), const Size.square(MpSize.brandMark));
    // The Apple mark and mail glyph sit a touch smaller so all three read
    // as the same size.
    expect(mark(MpBrand.apple), const Size.square(MpSize.brandMark - 2));
    expect(
      tester.widget<Icon>(find.byIcon(LucideIcons.mail)).size,
      MpSize.brandMark - 1,
    );
  });

  testWidgets('at the largest text size the sheet scrolls and Close stays on '
      'screen', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.1;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    expect(tester.takeException(), isNull);
    // At this size the actions scroll inside their half of the screen.
    await tester.ensureVisible(find.bySemanticsLabel('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text(_sheetBody), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('Close')).bottom, lessThanOrEqualTo(844));
  });

  testWidgets('"or continue with" sits on one line between the rules',
      (tester) async {
    await pump(tester);
    final label = tester.renderObject<RenderParagraph>(find.text('or continue with'));
    final boxes = label.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 16));
    expect(boxes.map((b) => b.top).toSet(), hasLength(1));
    final rule = find.byWidgetPredicate(
        (w) => w is Container && w.color == MpColors.light.hairline);
    expect(tester.getSize(rule).width, 390 - 2 * MpSpacing.gutter,
        reason: 'the rule runs the full width behind the label');
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

  testWidgets('Close holds focus when the sheet opens, so Enter closes it',
      (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text(_sheetBody), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(_sheetBody), findsNothing,
        reason: 'Close takes focus as the sheet opens');
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
