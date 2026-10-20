import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  group('peso formatting', () {
    test('uses the ₱ sign, comma grouping and two decimals', () {
      expect(formatPeso(1234.5), '₱1,234.50');
    });

    test('groups large amounts', () {
      expect(formatPeso(1250000), '₱1,250,000.00');
    });

    test('formats zero', () {
      expect(formatPeso(0), '₱0.00');
    });

    test('rounds to centavos', () {
      expect(formatPeso(49.999), '₱50.00');
    });

    test('can drop decimals for whole-peso display', () {
      expect(formatPeso(80, decimals: 0), '₱80');
    });

    test('handles negative amounts (e.g. a refund) with the sign outside', () {
      expect(formatPeso(-75.5), '-₱75.50');
    });

    test('exposes the ISO currency code and symbol', () {
      expect(php.code, 'PHP');
      expect(php.symbol, '₱');
    });
  });

  group('formatThousands', () {
    test('groups digits without a symbol', () {
      expect(formatThousands(2087), '2,087');
      expect(formatThousands(157), '157');
      expect(formatThousands(1234567), '1,234,567');
      expect(formatThousands(-500), '-500');
    });
  });
}
