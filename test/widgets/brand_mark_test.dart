import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('every mark is built from real path data', () {
    for (final brand in MpBrand.values) {
      final bounds = MpBrandMark.bounds(brand);
      expect(bounds.width, greaterThan(10), reason: brand.name);
      expect(bounds.height, greaterThan(10), reason: brand.name);
      expect(bounds.right, lessThanOrEqualTo(24.5), reason: brand.name);
    }
  });
}
