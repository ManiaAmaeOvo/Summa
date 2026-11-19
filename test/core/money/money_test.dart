import 'package:flutter_test/flutter_test.dart';
import 'package:summa/core/money/money.dart';

void main() {
  group('parseCnyMinorUnits', () {
    test('parses whole yuan and decimal input exactly', () {
      expect(parseCnyMinorUnits('28'), 2800);
      expect(parseCnyMinorUnits('28.5'), 2850);
      expect(parseCnyMinorUnits('28.50'), 2850);
    });

    test('rejects zero, negative, and excessive decimals', () {
      expect(
        () => parseCnyMinorUnits('0'),
        throwsA(isA<MoneyInputException>()),
      );
      expect(
        () => parseCnyMinorUnits('-1'),
        throwsA(isA<MoneyInputException>()),
      );
      expect(
        () => parseCnyMinorUnits('1.234'),
        throwsA(isA<MoneyInputException>()),
      );
    });

    test('allows zero for account opening balances', () {
      expect(parseCnyMinorUnits('0', allowZero: true), 0);
    });

    test('rejects amounts outside the integer minor-unit range', () {
      expect(parseCnyMinorUnits('92233720368547758.07'), 9223372036854775807);
      expect(
        () => parseCnyMinorUnits('92233720368547758.08'),
        throwsA(isA<MoneyInputException>()),
      );
    });
  });

  test('formats minor units without floating point arithmetic', () {
    expect(formatCny(2850), '¥28.50');
    expect(formatCny(-5), '-¥0.05');
    expect(formatCny(-9223372036854775808), '-¥92233720368547758.08');
  });
}
