class MoneyInputException implements Exception {
  const MoneyInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

int parseCnyMinorUnits(String input, {bool allowZero = false}) {
  final normalized = input.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
    throw const MoneyInputException('请输入正确金额，最多保留两位小数');
  }

  final parts = normalized.split('.');
  final yuan = int.parse(parts.first);
  final fraction = parts.length == 1 ? '' : parts.last;
  final fen = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  final minorUnits = yuan * 100 + fen;
  if (minorUnits < 0 || (!allowZero && minorUnits == 0)) {
    throw MoneyInputException(allowZero ? '金额不能小于 0' : '金额必须大于 0');
  }
  return minorUnits;
}

String formatCny(int minorUnits) {
  final absolute = minorUnits.abs();
  final sign = minorUnits < 0 ? '-' : '';
  final yuan = absolute ~/ 100;
  final fen = (absolute % 100).toString().padLeft(2, '0');
  return '$sign¥$yuan.$fen';
}
