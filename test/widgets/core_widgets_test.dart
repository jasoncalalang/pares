import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// A box decorated with the 2px annatto keyboard focus ring.
Finder focusRing() => find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final d = w.foregroundDecoration;
      if (d is! BoxDecoration) return false;
      final side = d.border?.top;
      return side != null &&
          side.width == 2 &&
          side.color == MpColors.light.annatto;
    });

void main() {
  group('MpPress', () {
    testWidgets('activates from the keyboard with Enter and Space',
        (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(MpPress(onTap: () => taps++, focusNode: node, child: const Text('go'))),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('activates on the web, where Enter is a ButtonActivateIntent',
        (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(Shortcuts(
          // WidgetsApp maps Enter this way on web; Android maps it to
          // ActivateIntent, so pin the web mapping explicitly here.
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
          },
          child: MpPress(onTap: () => taps++, focusNode: node, child: const Text('go')),
        )),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('shows a visible focus ring only for keyboard focus',
        (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(MpPress(onTap: () {}, focusNode: node, child: const Text('go'))),
      );
      expect(focusRing(), findsNothing);
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(focusRing(), findsNothing, reason: 'touch focus shows no ring');
      // A key press is what flips Flutter into keyboard-highlight mode.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pump();
      expect(focusRing(), findsOneWidget);
    });

    testWidgets('autofocus takes primary focus on the first frame',
        (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(MpPress(
          onTap: () {},
          focusNode: node,
          autofocus: true,
          child: const Text('go'),
        )),
      );
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('a disabled press is announced as disabled and skipped by '
        'keyboard focus', (tester) async {
      final first = FocusNode();
      final off = FocusNode();
      final last = FocusNode();
      addTearDown(first.dispose);
      addTearDown(off.dispose);
      addTearDown(last.dispose);
      await tester.pumpWidget(
        host(Column(children: [
          MpPress(onTap: () {}, focusNode: first, child: const Text('first')),
          MpPress(onTap: null, focusNode: off, child: const Text('nope')),
          MpPress(onTap: () {}, focusNode: last, child: const Text('last')),
        ])),
      );
      final semantics = tester.getSemantics(find.text('nope'));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(off.hasFocus, isFalse);
      expect(last.hasFocus, isTrue);
    });
  });

  group('MpCta', () {
    testWidgets('a disabled CTA loses the accent fill and takes no focus',
        (tester) async {
      final before = FocusNode();
      addTearDown(before.dispose);
      await tester.pumpWidget(
        host(Column(children: [
          MpPress(onTap: () {}, focusNode: before, child: const Text('before')),
          const MpCta(label: 'Wait', onPressed: null),
        ])),
      );
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        find.descendant(of: find.widgetWithText(MpCta, 'Wait'), matching: focusRing()),
        findsNothing,
      );
      final disabled = tester.widget<Container>(
        find.ancestor(of: find.text('Wait'), matching: find.byType(Container)).first,
      );
      final box = disabled.decoration! as BoxDecoration;
      expect(box.color, MpColors.light.hairline);
    });
  });

  group('tap targets and control boundaries', () {
    testWidgets('pill buttons reserve the 44px tap height', (tester) async {
      await tester.pumpWidget(
        host(Align(
          alignment: Alignment.topLeft,
          child: MpPillButton(
            label: 'Grocery list',
            icon: LucideIcons.shoppingCart,
            onTap: () {},
          ),
        )),
      );
      expect(tester.getSize(find.byType(MpPillButton)).height,
          greaterThanOrEqualTo(MpSize.tap));
    });

    testWidgets('an unselected choice draws the 3:1 outline, not the hairline',
        (tester) async {
      await tester.pumpWidget(
        host(MpChoiceButton(label: 'Light', selected: false, onTap: () {})),
      );
      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final border = (box.decoration! as BoxDecoration).border!.top;
      expect(border.color, MpColors.light.outline);
    });

    testWidgets('a stepper button is a full tap target', (tester) async {
      await tester.pumpWidget(
        host(Align(
          alignment: Alignment.topLeft,
          child: MpStepperButton(
            icon: LucideIcons.plus,
            semanticLabel: 'Increase budget',
            onTap: () {},
          ),
        )),
      );
      final size = tester.getSize(find.byType(MpStepperButton));
      expect(size.width, greaterThanOrEqualTo(MpSize.tap));
      expect(size.height, greaterThanOrEqualTo(MpSize.tap));
    });
  });
}
