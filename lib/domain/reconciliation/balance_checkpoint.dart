class BalanceCheckpoint {
  const BalanceCheckpoint({
    required this.id,
    required this.accountId,
    required this.currencyCode,
    required this.observedAt,
    required this.actualMinor,
    required this.recordedBookMinor,
    required this.bookMinor,
    required this.note,
    this.adjustmentId,
    this.voidedAt,
  });

  final String id;
  final String accountId;
  final String currencyCode;
  final DateTime observedAt;
  final int actualMinor;
  final int recordedBookMinor;
  final int bookMinor;
  final String note;
  final String? adjustmentId;
  final DateTime? voidedAt;

  BigInt get differenceMinor =>
      BigInt.from(actualMinor) - BigInt.from(bookMinor);
  bool get isVoided => voidedAt != null;
  bool get isBalanced => !isVoided && actualMinor == bookMinor;
  bool get bookChanged => recordedBookMinor != bookMinor;
}

enum ReconciliationError { changed, unavailable }

class ReconciliationException implements Exception {
  const ReconciliationException(this.error);

  final ReconciliationError error;
}
