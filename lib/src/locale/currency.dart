/// A currency the app can price in. MealPal PH prices only in PHP.
class Currency {
  const Currency({required this.code, required this.symbol, required this.minorUnit});

  /// ISO 4217 code, e.g. `PHP`.
  final String code;

  /// Display symbol, e.g. `₱`.
  final String symbol;

  /// Number of minor units per major unit (centavos per peso = 100).
  final int minorUnit;
}

/// Philippine peso.
const Currency php = Currency(code: 'PHP', symbol: '₱', minorUnit: 100);

/// Format an amount of pesos for display, e.g. `formatPeso(1234.5)` ->
/// `₱1,234.50`. Groups thousands with commas and, for negatives, places the
/// minus sign before the symbol (`-₱75.50`).
///
/// Implemented without `package:intl` so the domain core stays
/// dependency-free and needs no locale-data initialisation.
String formatPeso(num amount, {int decimals = 2}) {
  final negative = amount < 0;
  final value = amount.abs();

  final factor = _pow10(decimals);
  final totalMinor = (value * factor).round();
  final whole = decimals == 0 ? totalMinor : totalMinor ~/ factor;
  final frac = decimals == 0 ? 0 : totalMinor % factor;

  final grouped = _groupThousands(whole);
  final body = decimals == 0
      ? grouped
      : '$grouped.${frac.toString().padLeft(decimals, '0')}';

  return '${negative ? '-' : ''}${php.symbol}$body';
}

/// Group an integer's thousands with commas: `formatThousands(2087)` ->
/// `2,087`. Used for calorie and gram figures, which carry no symbol.
String formatThousands(int n) {
  final grouped = _groupThousands(n.abs());
  return n < 0 ? '-$grouped' : grouped;
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}

String _groupThousands(int whole) {
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
