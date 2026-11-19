import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/transactions/expense_record.dart';

typedef FinancialActivity = ({
  BigInt grossSpending,
  BigInt personalSpending,
  BigInt familyDirectSpending,
  BigInt entrustedSpending,
  BigInt thirdPartyPayableSpending,
  BigInt unclassifiedSpending,
  BigInt familySupportReceived,
  BigInt personalCashInflow,
  BigInt personalCashOutflow,
});

FinancialActivity summarizeFinancialActivity(
  Iterable<LedgerRecord> records,
  String currency,
) {
  var gross = BigInt.zero;
  var personal = BigInt.zero;
  var familyDirect = BigInt.zero;
  var entrusted = BigInt.zero;
  var thirdPartyPayable = BigInt.zero;
  var familySupportReceived = BigInt.zero;
  var inflow = BigInt.zero;
  var outflow = BigInt.zero;

  for (final record in records) {
    if (record.isPending) continue;
    if (record.type == LedgerTransactionType.expense &&
        record.currencyCode == currency) {
      gross += BigInt.from(record.actualExpenseMinor);
      for (final posting in record.accountPostings) {
        if (posting.currencyCode != currency || posting.needsReview) continue;
        final amount = -BigInt.from(posting.debitMinor);
        switch (posting.kind) {
          case AccountKind.cash:
          case AccountKind.bank:
          case AccountKind.wallet:
          case AccountKind.creditLine:
            personal += amount;
          case AccountKind.thirdPartyPayable:
            personal += amount;
            thirdPartyPayable += amount;
          case AccountKind.familyDirect:
            familyDirect += amount;
          case AccountKind.entrustedFunds:
            entrusted += amount;
          case AccountKind.receivable:
          case null:
            break;
        }
      }
    }

    final isInternalTransfer =
        record.type == LedgerTransactionType.transfer &&
        record.accountPostings.length == 2 &&
        record.accountPostings.every(
          (posting) => posting.kind?.isPersonalCash == true,
        );
    if (isInternalTransfer) continue;
    for (final posting in record.accountPostings) {
      if (posting.currencyCode != currency ||
          posting.kind?.isPersonalCash != true) {
        continue;
      }
      final amount = BigInt.from(posting.debitMinor);
      if (amount.isNegative) {
        outflow -= amount;
      } else {
        inflow += amount;
        // The built-in family support category has a stable ID across locales.
        if (record.type == LedgerTransactionType.income &&
            record.parentCategoryId == 'income-parent-1') {
          familySupportReceived += amount;
        }
      }
    }
  }

  return (
    grossSpending: gross,
    personalSpending: personal,
    familyDirectSpending: familyDirect,
    entrustedSpending: entrusted,
    thirdPartyPayableSpending: thirdPartyPayable,
    unclassifiedSpending: gross - personal - familyDirect - entrusted,
    familySupportReceived: familySupportReceived,
    personalCashInflow: inflow,
    personalCashOutflow: outflow,
  );
}
