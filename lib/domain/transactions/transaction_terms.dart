import 'package:summa/domain/transactions/expense_record.dart';

typedef CategoryAmount = ({String categoryId, int amountMinor});

/// Amounts other than the original price use the payment account's currency.
class TransactionTerms {
  const TransactionTerms({
    this.originalPrice,
    this.categories = const [],
    this.advance,
    this.feeMinor = 0,
    this.interestMinor = 0,
    this.externalDebtPayment = false,
    this.reversalOfId,
  });

  final TransferSettlement? originalPrice;
  final List<CategoryAmount> categories;
  final AccountPayment? advance;
  final int feeMinor;
  final int interestMinor;
  final bool externalDebtPayment;
  final String? reversalOfId;

  bool get isEmpty =>
      originalPrice == null &&
      categories.isEmpty &&
      advance == null &&
      feeMinor == 0 &&
      interestMinor == 0 &&
      !externalDebtPayment &&
      reversalOfId == null;

  Map<String, Object?> toJson() => {
    if (originalPrice case final price?)
      'original_price': {
        'amount_minor': price.amountMinor,
        'currency_code': price.currencyCode,
        if (price.quotedRate != null) 'quoted_rate': price.quotedRate,
      },
    if (categories.isNotEmpty)
      'categories': [
        for (final category in categories)
          {'id': category.categoryId, 'amount_minor': category.amountMinor},
      ],
    if (advance case final receivable?)
      'advance': {
        'account_id': receivable.accountId,
        'amount_minor': receivable.amountMinor,
      },
    if (feeMinor != 0) 'fee_minor': feeMinor,
    if (interestMinor != 0) 'interest_minor': interestMinor,
    if (externalDebtPayment) 'external_debt_payment': true,
    if (reversalOfId != null) 'reversal_of_id': reversalOfId,
  };

  factory TransactionTerms.fromJson(Map<String, dynamic> json) {
    final price = json['original_price'] as Map<String, dynamic>?;
    final advance = json['advance'] as Map<String, dynamic>?;
    final terms = TransactionTerms(
      originalPrice: price == null
          ? null
          : TransferSettlement(
              amountMinor: price['amount_minor'] as int,
              currencyCode: price['currency_code'] as String,
              quotedRate: price['quoted_rate'] as String?,
            ),
      categories: [
        for (final row in (json['categories'] as List<dynamic>? ?? const []))
          (
            categoryId: row['id'] as String,
            amountMinor: row['amount_minor'] as int,
          ),
      ],
      advance: advance == null
          ? null
          : AccountPayment(
              advance['account_id'] as String,
              advance['amount_minor'] as int,
            ),
      feeMinor: json['fee_minor'] as int? ?? 0,
      interestMinor: json['interest_minor'] as int? ?? 0,
      externalDebtPayment: json['external_debt_payment'] as bool? ?? false,
      reversalOfId: json['reversal_of_id'] as String?,
    );
    if (json.keys.any((key) => !terms.toJson().containsKey(key))) {
      throw const FormatException('Unrecognized transaction details');
    }
    return terms;
  }
}

const financialChargesCategoryId = 'expense-financial-charges';
const financialFeeCategoryId = 'expense-financial-fee';
const financialInterestCategoryId = 'expense-financial-interest';
