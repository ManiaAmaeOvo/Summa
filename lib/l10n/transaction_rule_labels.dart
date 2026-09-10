import 'package:flutter/widgets.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';
import 'package:ledger_pro/l10n/default_ledger_labels.dart';
import 'package:ledger_pro/l10n/l10n.dart';

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
        formatCny(exception.amountMinor ?? 0),
      ),
    TransactionRuleError.overpayment => context.l10n.overpayment(
      account,
      formatCny(exception.amountMinor ?? 0),
    ),
    TransactionRuleError.fixedOtherCategory => context.l10n.fixedOtherCategory,
    TransactionRuleError.otherCategoryRequired =>
      context.l10n.otherCategoryRequired,
  };
}
