import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';

typedef ReconciliationCandidate = ({
  LedgerRecord record,
  BigInt effect,
  bool matchesDifference,
  bool similar,
});

List<ReconciliationCandidate> reconciliationCandidates(
  Iterable<LedgerRecord> records, {
  required BalanceCheckpoint checkpoint,
  required bool isLiability,
  DateTime? after,
}) {
  if (checkpoint.isBalanced || checkpoint.isVoided) return const [];
  final affected = <(LedgerRecord, BigInt)>[];
  final occurrences = <Object, int>{};
  Object key(LedgerRecord record, BigInt effect) => (
    record.type,
    record.isRefund,
    record.accountId,
    record.targetAccountId,
    record.categoryId,
    record.note.trim(),
    record.occurredAt.millisecondsSinceEpoch ~/ 60000,
    effect,
  );
  for (final record in records) {
    if (record.occurredAt.isAfter(checkpoint.observedAt) ||
        (after != null && !record.occurredAt.isAfter(after)) ||
        record.id == checkpoint.adjustmentId) {
      continue;
    }
    var effect = BigInt.zero;
    for (final posting in record.accountPostings) {
      if (posting.accountId == checkpoint.accountId &&
          posting.currencyCode == checkpoint.currencyCode) {
        effect += BigInt.from(posting.debitMinor);
      }
    }
    if (effect == BigInt.zero) continue;
    if (isLiability) effect = -effect;
    affected.add((record, effect));
    if (!record.isReversal && !record.hasReversal) {
      occurrences.update(
        key(record, effect),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  final candidates = [
    for (final (record, effect) in affected)
      (
        record: record,
        effect: effect,
        matchesDifference:
            (record.isPending ? effect : -effect) == checkpoint.differenceMinor,
        similar: (occurrences[key(record, effect)] ?? 0) > 1,
      ),
  ];
  int priority(ReconciliationCandidate item) {
    if (item.matchesDifference) return 0;
    if (item.record.isPending || item.similar || item.record.needsReview) {
      return 1;
    }
    return 2;
  }

  return candidates..sort((a, b) {
    final byPriority = priority(a).compareTo(priority(b));
    return byPriority != 0
        ? byPriority
        : b.record.occurredAt.compareTo(a.record.occurredAt);
  });
}
