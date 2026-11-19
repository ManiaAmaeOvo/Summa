enum MoneyInputError { invalidFormat, negative, notPositive }

const defaultCurrency = 'CNY';

// ISO 4217 minor-unit digits for currencies available when adding an account.
const currencyMinorDigits = {
  'CNY': 2,
  'USD': 2,
  'EUR': 2,
  'JPY': 0,
  'HKD': 2,
  'GBP': 2,
  'AUD': 2,
  'CAD': 2,
  'CHF': 2,
  'SGD': 2,
  'NZD': 2,
  'KRW': 0,
  'TWD': 2,
  'THB': 2,
  'VND': 0,
  'MYR': 2,
  'IDR': 2,
  'INR': 2,
  'AED': 2,
  'KWD': 3,
  'BHD': 3,
};

int _currencyDigits(String currency) => currencyMinorDigits[currency] ?? 0;

class MoneyInputException implements Exception {
  const MoneyInputException(this.error);

  final MoneyInputError error;

  String get message => switch (error) {
    MoneyInputError.invalidFormat => '请输入正确金额，最多保留两位小数',
    MoneyInputError.negative => '金额不能小于 0',
    MoneyInputError.notPositive => '金额必须大于 0',
  };

  @override
  String toString() => error.name;
}

int parseCnyMinorUnits(String input, {bool allowZero = false}) =>
    parseMoney(input, defaultCurrency, allowZero: allowZero);

int parseMoney(String input, String currency, {bool allowZero = false}) {
  final normalized = input.trim();
  final digits = _currencyDigits(currency);
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) {
    throw const MoneyInputException(MoneyInputError.invalidFormat);
  }

  final parts = normalized.split('.');
  final fraction = parts.length == 1 ? '' : parts.last;
  if (fraction.length > digits) {
    throw const MoneyInputException(MoneyInputError.invalidFormat);
  }
  final minorUnits = int.tryParse(
    '${parts.first}${fraction.padRight(digits, '0')}',
    radix: 10,
  );
  if (minorUnits == null) {
    throw const MoneyInputException(MoneyInputError.invalidFormat);
  }
  if (!allowZero && minorUnits == 0) {
    throw const MoneyInputException(MoneyInputError.notPositive);
  }
  return minorUnits;
}

String formatCny(int minorUnits) => formatMoney(minorUnits, defaultCurrency);

String moneyInputText(int minorUnits, String currency) {
  return _decimal(BigInt.from(minorUnits), _currencyDigits(currency));
}

String formatMoney(int minorUnits, String currency) {
  final value = BigInt.from(minorUnits);
  final sign = value.isNegative ? '-' : '';
  final prefix = currency == defaultCurrency ? '¥' : '$currency ';
  return '$sign$prefix${_decimal(value.abs(), _currencyDigits(currency))}';
}

String _decimal(BigInt scaled, int digits) {
  final sign = scaled.isNegative ? '-' : '';
  final text = scaled.abs().toString().padLeft(digits + 1, '0');
  if (digits == 0) return '$sign$text';
  final point = text.length - digits;
  return '$sign${text.substring(0, point)}.${text.substring(point)}';
}

// A quote is stored as decimal text. The actual amounts remain authoritative.
bool isValidExchangeQuote(String quote) =>
    RegExp(r'^\d{1,18}(\.\d{1,18})?$').hasMatch(quote) &&
    RegExp(r'[1-9]').hasMatch(quote);

String effectiveExchangeRate({
  required int sourceMinor,
  required String sourceCurrency,
  required int settlementMinor,
  required String settlementCurrency,
}) {
  const precision = 10;
  final numerator =
      BigInt.from(settlementMinor) *
      BigInt.from(10).pow(precision + _currencyDigits(sourceCurrency));
  final denominator =
      BigInt.from(sourceMinor) *
      BigInt.from(10).pow(_currencyDigits(settlementCurrency));
  final rounded = (numerator + denominator ~/ BigInt.two) ~/ denominator;
  if (rounded == BigInt.zero) return '<0.0000000001';
  return _decimal(rounded, precision).replaceFirst(RegExp(r'\.?0+$'), '');
}
