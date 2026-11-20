import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/transactions/expense_record.dart';

class LedgerHistoryInputs {
  const LedgerHistoryInputs({
    required this.balances,
    required this.transactions,
  });

  final List<AccountBalance> balances;
  final List<LedgerRecord> transactions;
}

enum LedgerHistoryInterval { month, year }

typedef LedgerHistoryPoint = ({
  LedgerDateRange range,
  LedgerAnalysis analysis,
  BigInt netWorthMinor,
});

List<LedgerHistoryPoint> analyzeLedgerHistory(
  LedgerHistoryInputs inputs, {
  required DateTime today,
  required String currency,
  required LedgerHistoryInterval interval,
  LedgerFilter filter = const LedgerFilter(),
}) {
  final monthly = interval == LedgerHistoryInterval.month;
  final count = monthly ? 6 : 3;
  DateTime start(int offset) => monthly
      ? DateTime(today.year, today.month + offset)
      : DateTime(today.year + offset);
  final asOfEnd = DateTime(today.year, today.month, today.day + 1);
  final balanceRecords = inputs.transactions.where(
    (record) => !record.isPending,
  );
  final selectedAccounts = {
    for (final account in inputs.balances)
      if (account.currencyCode == currency &&
          account.group != AccountGroup.entrustedFunds &&
          account.group != AccountGroup.external &&
          (filter.accountId == null || account.id == filter.accountId))
        account.id: account,
  };
  final firstPostings = <String, DateTime>{};
  final movements = <({String accountId, DateTime date, BigInt debit})>[];
  for (final record in balanceRecords) {
    for (final posting in record.accountPostings) {
      if (posting.currencyCode != currency ||
          !selectedAccounts.containsKey(posting.accountId)) {
        continue;
      }
      final date = record.occurredAt;
      firstPostings.update(
        posting.accountId,
        (first) => date.isBefore(first) ? date : first,
        ifAbsent: () => date,
      );
      movements.add((
        accountId: posting.accountId,
        date: date,
        debit: BigInt.from(posting.debitMinor),
      ));
    }
  }
  movements.sort((a, b) => a.date.compareTo(b.date));
  final changes = <String, BigInt>{};
  var index = 0;

  // Include one extra prior point so every displayed period has a comparison.
  final history = <LedgerHistoryPoint>[];
  for (var offset = -count; offset <= 0; offset++) {
    final end = offset == 0 ? asOfEnd : start(offset + 1);
    while (index < movements.length && movements[index].date.isBefore(end)) {
      final movement = movements[index++];
      changes.update(
        movement.accountId,
        (amount) => amount + movement.debit,
        ifAbsent: () => movement.debit,
      );
    }
    var netWorth = BigInt.zero;
    for (final account in selectedAccounts.values) {
      final first = firstPostings[account.id];
      final created = account.createdAt;
      if ((created != null &&
              !created.isBefore(end) &&
              (first == null || !first.isBefore(end))) ||
          account.archivedAt?.isBefore(end) == true) {
        continue;
      }
      final opening = BigInt.from(account.openingBalanceMinor);
      netWorth +=
          (account.kind.isLiability ? -opening : opening) +
          (changes[account.id] ?? BigInt.zero);
    }
    final range = (start: start(offset), endExclusive: end);
    history.add((
      range: range,
      analysis: analyzeLedger(
        balanceRecords,
        currency,
        filter.scoped(range: range, currency: currency),
      ),
      netWorthMinor: netWorth,
    ));
  }
  return history;
}
