import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/transactions/expense_record.dart';

List<AccountBalance> balancesThroughToday(
  List<AccountBalance> balances,
  Iterable<LedgerRecord> records,
  DateTime today,
) {
  final nextDay = DateTime(today.year, today.month, today.day + 1);
  final futureDebits = <(String, String), BigInt>{};
  for (final record in records) {
    if (record.isPending || record.occurredAt.isBefore(nextDay)) continue;
    for (final posting in record.accountPostings) {
      final debit = BigInt.from(posting.debitMinor);
      futureDebits.update(
        (posting.accountId, posting.currencyCode),
        (amount) => amount + debit,
        ifAbsent: () => debit,
      );
    }
  }
  return [
    for (final balance in balances)
      AccountBalance(
        id: balance.id,
        name: balance.name,
        kind: balance.kind,
        openingBalanceMinor: balance.openingBalanceMinor,
        currentBalanceMinor:
            (BigInt.from(balance.currentBalanceMinor) -
                    (futureDebits[(balance.id, balance.currencyCode)] ??
                            BigInt.zero) *
                        (balance.kind.isLiability ? -BigInt.one : BigInt.one))
                .toInt(),
        currencyCode: balance.currencyCode,
      ),
  ];
}

BigInt availablePersonalCash(
  Iterable<AccountBalance> balances,
  Iterable<SavingsAccountAllocation> savings,
  String currency,
) {
  final reserved = {
    for (final allocation in savings)
      if (!allocation.archived && allocation.currency == currency)
        allocation.accountId: allocation.reservedMinor,
  };
  return balances
      .where(
        (account) =>
            account.kind.isPersonalCash && account.currencyCode == currency,
      )
      .fold(
        BigInt.zero,
        (sum, account) =>
            sum +
            savingsUnallocated(
              account.currentBalanceMinor,
              reserved[account.id] ?? BigInt.zero,
            ),
      );
}
