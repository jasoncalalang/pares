import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/design_system/design_system.dart';

/// Hosts [child] the way the app does: themed, inside a Scaffold, at phone
/// width. Entrance animations are left on so tests exercise them; call
/// `tester.pumpAndSettle()` after pumping.
Widget host(Widget child) {
  return MaterialApp(
    theme: MpTheme.light(),
    home: Scaffold(body: child),
  );
}

/// A 390×844 phone surface, the size every mockup was drawn at.
Future<void> phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
