import 'package:summa/domain/transactions/expense_record.dart';

typedef PostingLeg = ({
  String? accountId,
  String currencyCode,
  int debitMinor,
  LedgerPostingRole role,
  bool needsReview,
});

List<PostingLeg> transactionPostings({
  required LedgerTransactionType type,
  required int amountMinor,
  required String currencyCode,
  required String accountId,
  String? targetAccountId,
  List<AccountPayment> payments = const [],
  bool isRefund = false,
  bool isCreditIncome = false,
}) {
  PostingLeg leg(String? id, int debit, LedgerPostingRole role) => (
    accountId: id,
    currencyCode: currencyCode,
    debitMinor: debit,
    role: role,
    needsReview: isCreditIncome,
  );

  return switch (type) {
    LedgerTransactionType.expense when isRefund => [
      leg(accountId, amountMinor, LedgerPostingRole.account),
      leg(null, -amountMinor, LedgerPostingRole.expense),
    ],
    LedgerTransactionType.expense => [
      for (final payment in payments)
        leg(payment.accountId, -payment.amountMinor, LedgerPostingRole.account),
      leg(null, amountMinor, LedgerPostingRole.expense),
    ],
    LedgerTransactionType.income => [
      leg(accountId, amountMinor, LedgerPostingRole.account),
      leg(
        null,
        -amountMinor,
        isCreditIncome
            ? LedgerPostingRole.unclassified
            : LedgerPostingRole.income,
      ),
    ],
    _ => [
      leg(accountId, -amountMinor, LedgerPostingRole.account),
      leg(targetAccountId!, amountMinor, LedgerPostingRole.account),
    ],
  };
}

bool isValidPaymentSplit(List<AccountPayment> payments, int amountMinor) {
  final accounts = <String>{};
  var remaining = amountMinor;
  for (final payment in payments) {
    if (payment.amountMinor <= 0 ||
        payment.amountMinor > remaining ||
        !accounts.add(payment.accountId)) {
      return false;
    }
    remaining -= payment.amountMinor;
  }
  return remaining == 0;
}
