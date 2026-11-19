import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

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
  TransferSettlement? settlement,
  bool isRefund = false,
  bool isCreditIncome = false,
  TransactionTerms terms = const TransactionTerms(),
}) {
  PostingLeg leg(
    String? id,
    int debit,
    LedgerPostingRole role, {
    String? currency,
  }) => (
    accountId: id,
    currencyCode: currency ?? currencyCode,
    debitMinor: debit,
    role: role,
    needsReview: isCreditIncome,
  );

  final charges = terms.feeMinor + terms.interestMinor;
  final postings = switch (type) {
    LedgerTransactionType.adjustment => [
      leg(accountId, amountMinor, LedgerPostingRole.account),
      leg(null, -amountMinor, LedgerPostingRole.equity),
    ],
    _ when terms.externalDebtPayment => [
      leg(accountId, amountMinor, LedgerPostingRole.account),
      leg(null, -amountMinor, LedgerPostingRole.equity),
    ],
    LedgerTransactionType.expense when isRefund => [
      leg(accountId, amountMinor, LedgerPostingRole.account),
      if (terms.advance case final advance?)
        leg(advance.accountId, -advance.amountMinor, LedgerPostingRole.account),
      for (final amount in _categoryAmounts(
        terms,
        amountMinor - (terms.advance?.amountMinor ?? 0),
      ))
        leg(null, -amount, LedgerPostingRole.expense),
    ],
    LedgerTransactionType.expense => [
      for (final payment in payments)
        leg(payment.accountId, -payment.amountMinor, LedgerPostingRole.account),
      if (terms.advance case final advance?)
        leg(advance.accountId, advance.amountMinor, LedgerPostingRole.account),
      for (final amount in _categoryAmounts(
        terms,
        amountMinor - (terms.advance?.amountMinor ?? 0),
      ))
        leg(null, amount, LedgerPostingRole.expense),
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
    LedgerTransactionType.transfer when settlement != null => [
      leg(accountId, -(amountMinor + charges), LedgerPostingRole.account),
      leg(
        targetAccountId!,
        settlement.amountMinor,
        LedgerPostingRole.account,
        currency: settlement.currencyCode,
      ),
      leg(null, amountMinor, LedgerPostingRole.exchange),
      leg(
        null,
        -settlement.amountMinor,
        LedgerPostingRole.exchange,
        currency: settlement.currencyCode,
      ),
    ],
    _ => [
      leg(accountId, -(amountMinor + charges), LedgerPostingRole.account),
      leg(targetAccountId!, amountMinor, LedgerPostingRole.account),
    ],
  };
  final withCharges = [
    ...postings,
    if (terms.feeMinor > 0)
      leg(null, terms.feeMinor, LedgerPostingRole.expense),
    if (terms.interestMinor > 0)
      leg(null, terms.interestMinor, LedgerPostingRole.expense),
  ];
  if (terms.reversalOfId == null) return withCharges;
  return [for (final posting in withCharges) oppositePosting(posting)];
}

PostingLeg oppositePosting(PostingLeg leg) => (
  accountId: leg.accountId,
  currencyCode: leg.currencyCode,
  debitMinor: -leg.debitMinor,
  role: leg.role,
  needsReview: leg.needsReview,
);

Iterable<int> _categoryAmounts(TransactionTerms terms, int defaultAmount) =>
    terms.categories.isEmpty
    ? [if (defaultAmount != 0) defaultAmount]
    : terms.categories.map((category) => category.amountMinor);

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
