import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/design_system/design_system.dart';

/// Hosts [child] the way the app does: themed, inside a Scaffold, at phone
/// width. Data reveals still animate, so call `tester.pumpAndSettle()`
/// after pumping.
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

/// WCAG contrast ratio of [fg], alpha-blended over [bg], against [bg].
double contrast(Color fg, Color bg) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final a = luminance(Color.alphaBlend(fg, bg));
  final b = luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// The colour [text] is painted in, after DefaultTextStyle merging.
Color paintedColor(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!.color!;
