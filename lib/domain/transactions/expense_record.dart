enum LedgerTransactionType { expense, income, transfer, borrowing, repayment }

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
  final String note;
}
