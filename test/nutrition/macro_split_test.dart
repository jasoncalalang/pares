import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  group('macro split', () {
    test('splits 2,087 kcal 30/45/25 into 157g / 235g / 58g', () {
      final m = macroSplit(2087);
      expect(m.proteinG, 157);
      expect(m.carbsG, 235);
      expect(m.fatG, 58);
    });

    test('exposes each macro\'s share of calories', () {
      final m = macroSplit(2000);
      expect(m.proteinShare, closeTo(0.30, 1e-9));
      expect(m.carbsShare, closeTo(0.45, 1e-9));
      expect(m.fatShare, closeTo(0.25, 1e-9));
    });

    test('rejects a non-positive target', () {
      expect(() => macroSplit(0), throwsArgumentError);
    });
  });
}
