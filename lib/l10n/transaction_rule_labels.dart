import 'package:flutter/widgets.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

String localizedTransactionRule(
  BuildContext context,
  TransactionRuleException exception,
) {
  final account = DefaultLedgerLabels.accountName(
    Localizations.localeOf(context),
    exception.accountId ?? '',
    exception.accountName ?? '',
  );
  return switch (exception.error) {
    TransactionRuleError.insufficientBalance =>
      context.l10n.insufficientBalance(
        account,
        formatMoney(exception.amountMinor ?? 0, exception.currencyCode),
      ),
    TransactionRuleError.overpayment => context.l10n.overpayment(
      account,
      formatMoney(exception.amountMinor ?? 0, exception.currencyCode),
    ),
    TransactionRuleError.invalidPaymentSplit =>
      context.l10n.invalidPaymentSplit,
    TransactionRuleError.refundLimitExceeded =>
      context.l10n.refundLimitExceeded(
        formatMoney(exception.amountMinor ?? 0, exception.currencyCode),
      ),
    TransactionRuleError.linkedRefunds => context.l10n.linkedRefunds,
    TransactionRuleError.archivedPostingAccount =>
      context.l10n.archivedPostingAccount,
    TransactionRuleError.invalidTransferSettlement =>
      context.l10n.invalidTransferSettlement,
    TransactionRuleError.receivableBalanceExceeded =>
      context.l10n.receivableBalanceExceeded,
    TransactionRuleError.currencyMismatch => context.l10n.currencyMismatch,
    TransactionRuleError.fixedOtherCategory => context.l10n.fixedOtherCategory,
    TransactionRuleError.otherCategoryRequired =>
      context.l10n.otherCategoryRequired,
  };
}
