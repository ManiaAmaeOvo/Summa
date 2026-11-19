import 'package:summa/core/money/money.dart';

enum LedgerTransactionType { expense, income, transfer, borrowing, repayment }

enum LedgerPostingStatus { posted, pending }

enum LedgerPostingRole { account, expense, income, unclassified, exchange }

class TransferSettlement {
  const TransferSettlement({
    required this.amountMinor,
    required this.currencyCode,
    this.quotedRate,
  });

  final int amountMinor;
  final String currencyCode;
  final String? quotedRate;
}

class AccountPayment {
  const AccountPayment(this.accountId, this.amountMinor);

  final String accountId;
  final int amountMinor;
}

class AccountPosting {
  const AccountPosting({
    required this.accountId,
    required this.accountName,
    required this.accountKind,
    required this.debitMinor,
    required this.needsReview,
    this.currencyCode = defaultCurrency,
  });

  final String accountId;
  final String accountName;
  final String accountKind;
  final int debitMinor;
  final bool needsReview;
  final String currencyCode;
}

class LedgerRecord {
  const LedgerRecord({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.parentCategoryId,
    required this.parentCategoryName,
    required this.categoryId,
    required this.categoryName,
    required this.accountId,
    required this.accountName,
    required this.accountKind,
    this.targetAccountId,
    this.targetAccountName,
    this.targetAccountKind,
    this.status = LedgerPostingStatus.posted,
    this.refundOfId,
    this.accountPostings = const [],
    this.currencyCode = defaultCurrency,
    this.settlement,
    required this.note,
  });

  final String id;
  final LedgerTransactionType type;
  final int amountMinor;
  final DateTime occurredAt;
  final String parentCategoryId;
  final String parentCategoryName;
  final String categoryId;
  final String categoryName;
  final String accountId;
  final String accountName;
  final String accountKind;
  final String? targetAccountId;
  final String? targetAccountName;
  final String? targetAccountKind;
  final LedgerPostingStatus status;
  final String? refundOfId;
  final List<AccountPosting> accountPostings;
  final String currencyCode;
  final TransferSettlement? settlement;
  final String note;

  bool get isPending => status == LedgerPostingStatus.pending;
  bool get isRefund => refundOfId != null;
  bool get canRefund =>
      type == LedgerTransactionType.expense &&
      !isPending &&
      !isRefund &&
      accountPostings.isNotEmpty &&
      !accountPostings.any((posting) => posting.needsReview);

  int get actualExpenseMinor =>
      isPending || type != LedgerTransactionType.expense
      ? 0
      : isRefund
      ? -amountMinor
      : amountMinor;
}
