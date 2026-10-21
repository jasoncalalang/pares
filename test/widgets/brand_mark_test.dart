import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/design_system/design_system.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  testWidgets('paints the Google and Apple marks at the requested size',
      (tester) async {
    await tester.pumpWidget(host(const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MpBrandMark(MpBrand.google, key: ValueKey('g'), size: 22),
        MpBrandMark(MpBrand.apple, key: ValueKey('a'), size: 20),
      ],
    )));
    expect(tester.getSize(find.byKey(const ValueKey('g'))), const Size(22, 22));
    expect(tester.getSize(find.byKey(const ValueKey('a'))), const Size(20, 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google paints its four colours; Apple takes the colour it is '
      'given', (tester) async {
    const c = MpColors.light;
    await tester.pumpWidget(host(Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MpBrandMark(MpBrand.google, key: ValueKey('g')),
        MpBrandMark(MpBrand.apple, key: const ValueKey('a'), color: c.cream),
        const MpBrandMark(MpBrand.apple, key: ValueKey('ink')),
      ],
    )));
    RenderObject mark(String k) => tester.renderObject(find.descendant(
        of: find.byKey(ValueKey(k)), matching: find.byType(CustomPaint)));

    // Google's own brand colours, not MealPal tokens.
    expect(
      mark('g'),
      paints
        ..path(color: const Color(0xFF4285F4))
        ..path(color: const Color(0xFF34A853))
        ..path(color: const Color(0xFFFBBC05))
        ..path(color: const Color(0xFFEA4335)),
    );
    expect(mark('a'), paints..path(color: c.cream));
    expect(mark('ink'), paints..path(color: c.ink));
  });

  test('every mark is built from real path data', () {
    for (final brand in MpBrand.values) {
      final bounds = MpBrandMark.bounds(brand);
      expect(bounds.width, greaterThan(10), reason: brand.name);
      expect(bounds.height, greaterThan(10), reason: brand.name);
      expect(bounds.right, lessThanOrEqualTo(24.5), reason: brand.name);
    }
  });
}
