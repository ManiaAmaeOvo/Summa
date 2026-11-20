import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

Map<String, String> importRuleCategoryLabels(
  BuildContext context,
  WidgetRef ref,
) {
  final options = <String, String>{};
  for (final (label, categories) in [
    (
      context.l10n.expense,
      ref.watch(expenseCategoriesProvider).asData?.value ??
          const <LedgerCategory>[],
    ),
    (
      context.l10n.income,
      ref.watch(incomeCategoriesProvider).asData?.value ??
          const <LedgerCategory>[],
    ),
  ]) {
    final parents = {
      for (final item in categories)
        if (item.isParent) item.id: item,
    };
    for (final child in categories) {
      if (parents[child.parentId] case final parent?) {
        options[child.id] =
            '$label · ${DefaultLedgerLabels.category(context, parent)} / ${DefaultLedgerLabels.category(context, child)}';
      }
    }
  }
  return options;
}

String importRuleFieldLabel(BuildContext context, ImportRuleField field) =>
    switch (field) {
      ImportRuleField.merchant => context.l10n.importRuleMerchant,
      ImportRuleField.description => context.l10n.importRuleDescription,
      ImportRuleField.paymentChannel => context.l10n.importRulePayment,
      ImportRuleField.source => context.l10n.importRuleSource,
      ImportRuleField.account => context.l10n.csvSourceAccount,
      ImportRuleField.amount => context.l10n.amount,
    };

String importRuleOperatorLabel(
  BuildContext context,
  ImportRuleOperator operator,
) => switch (operator) {
  ImportRuleOperator.contains => context.l10n.importRuleContains,
  ImportRuleOperator.equals => context.l10n.importRuleEquals,
  ImportRuleOperator.startsWith => context.l10n.importRuleStartsWith,
  ImportRuleOperator.atLeast => context.l10n.importRuleAtLeast,
  ImportRuleOperator.atMost => context.l10n.importRuleAtMost,
};

String importRuleModeLabel(BuildContext context, ImportRuleMode mode) =>
    switch (mode) {
      ImportRuleMode.all => context.l10n.importRuleMatchAll,
      ImportRuleMode.any => context.l10n.importRuleMatchAny,
    };

String importRuleSummary(BuildContext context, ImportCategoryRule rule) => rule
    .conditions
    .map(
      (condition) => [
        importRuleFieldLabel(context, condition.field),
        importRuleOperatorLabel(context, condition.operator),
        ?condition.currency,
        condition.value,
      ].join(' '),
    )
    .join(rule.mode == ImportRuleMode.all ? ' + ' : ' / ');
