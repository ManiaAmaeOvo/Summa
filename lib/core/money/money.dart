enum MoneyInputError { invalidFormat, negative, notPositive }

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

int parseCnyMinorUnits(String input, {bool allowZero = false}) {
  final normalized = input.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
    throw const MoneyInputException(MoneyInputError.invalidFormat);
  }

  final parts = normalized.split('.');
  final fraction = parts.length == 1 ? '' : parts.last;
  final minorUnits = int.tryParse(
    '${parts.first}${fraction.padRight(2, '0')}',
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

String formatCny(int minorUnits) {
  final sign = minorUnits < 0 ? '-' : '';
  final yuan = (minorUnits ~/ 100).abs();
  final fen = minorUnits.remainder(100).abs().toString().padLeft(2, '0');
  return '$sign¥$yuan.$fen';
}
