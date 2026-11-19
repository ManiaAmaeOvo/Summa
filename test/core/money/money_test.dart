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

  test('uses native currency precision and validates decimal quotes', () {
    expect(parseMoney('1575', 'JPY'), 1575);
    expect(
      () => parseMoney('1575.1', 'JPY'),
      throwsA(isA<MoneyInputException>()),
    );
    expect(parseMoney('12.345', 'KWD'), 12345);
    expect(formatMoney(-12345, 'KWD'), '-KWD 12.345');
    expect(moneyInputText(1575, 'JPY'), '1575');
    expect(isValidExchangeQuote('0.012345678901234567'), isTrue);
    expect(isValidExchangeQuote('0.0000'), isFalse);
    expect(isValidExchangeQuote('2e-3'), isFalse);
    expect(
      effectiveExchangeRate(
        sourceMinor: 1050,
        sourceCurrency: 'USD',
        settlementMinor: 1575,
        settlementCurrency: 'JPY',
      ),
      '150',
    );
    expect(
      effectiveExchangeRate(
        sourceMinor: 3,
        sourceCurrency: 'JPY',
        settlementMinor: 1,
        settlementCurrency: 'KWD',
      ),
      '0.0003333333',
    );
  });

  test('formats minor units without floating point arithmetic', () {
    expect(formatCny(2850), '¥28.50');
    expect(formatCny(-5), '-¥0.05');
    expect(formatCny(-9223372036854775808), '-¥92233720368547758.08');
  });
}
