import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

enum LedgerTransactionType {
  expense,
  income,
  transfer,
  borrowing,
  repayment,
  lending,
  advance,
  collection,
  reimbursement,
  adjustment;

  bool get originatesReceivable => this == lending || this == advance;
  bool get collectsReceivable => this == collection || this == reimbursement;
  bool get isReceivableFlow => originatesReceivable || collectsReceivable;
}

enum LedgerPostingStatus { posted, pending }

enum LedgerPostingRole {
  account,
  expense,
  income,
  unclassified,
  exchange,
  equity,
}

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

  AccountKind? get kind =>
      AccountKind.values.where((kind) => kind.name == accountKind).firstOrNull;
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
    this.terms = const TransactionTerms(),
    this.allocationLabels = const {},
    this.hasReversal = false,
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
  final TransactionTerms terms;
  final Map<String, ({String parentId, String parentName, String name})>
  allocationLabels;
  final bool hasReversal;
  final String note;

  bool get isPending => status == LedgerPostingStatus.pending;
  bool get isRefund => refundOfId != null;
  bool get isReversal => terms.reversalOfId != null;
  int get direction => isReversal ? -1 : 1;
  bool get needsReview => accountPostings.any((posting) => posting.needsReview);
  bool get canReverse =>
      !isPending && !isRefund && !isReversal && !hasReversal && !needsReview;
  int get chargesMinor => terms.feeMinor + terms.interestMinor;
  int get spendingMinor =>
      actualExpenseMinor + (isPending ? 0 : direction * chargesMinor);
  int get signedAmountMinor => direction * amountMinor;

  Iterable<CategoryAmount> get spendingCategories sync* {
    if (isPending) return;
    if (type == LedgerTransactionType.expense && actualExpenseMinor != 0) {
      if (terms.categories.isEmpty) {
        yield (categoryId: categoryId, amountMinor: actualExpenseMinor);
      } else {
        final sign = isRefund ? -1 : direction;
        for (final item in terms.categories) {
          yield (
            categoryId: item.categoryId,
            amountMinor: sign * item.amountMinor,
          );
        }
      }
    }
    if (terms.feeMinor > 0) {
      yield (
        categoryId: financialFeeCategoryId,
        amountMinor: direction * terms.feeMinor,
      );
    }
    if (terms.interestMinor > 0) {
      yield (
        categoryId: financialInterestCategoryId,
        amountMinor: direction * terms.interestMinor,
      );
    }
  }

  bool get isFamilyDirect => accountKind == AccountKind.familyDirect.name;
  bool get canRefund =>
      type == LedgerTransactionType.expense &&
      !isPending &&
      !isRefund &&
      !isReversal &&
      !hasReversal &&
      accountPostings.isNotEmpty &&
      !accountPostings.any((posting) => posting.needsReview);

  int get actualExpenseMinor =>
      isPending || type != LedgerTransactionType.expense
      ? 0
      : (isRefund ? -1 : direction) *
            (amountMinor - (terms.advance?.amountMinor ?? 0));
}
