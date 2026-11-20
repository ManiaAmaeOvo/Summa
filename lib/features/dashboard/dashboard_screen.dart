import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/features/accounts/account_overview_screen.dart';
import 'package:summa/features/import_export/csv_import_screen.dart';
import 'package:summa/features/import_export/structured_import_screen.dart';
import 'package:summa/features/planning/recurring_plans_screen.dart';
import 'package:summa/features/planning/spending_plans_screen.dart';
import 'package:summa/features/reports/report_screen.dart';
import 'package:summa/features/settings/settings_screen.dart';
import 'package:summa/features/transaction_editor/add_expense_sheet.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:summa/l10n/transaction_rule_labels.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          0 => 'Summa',
          1 => l10n.accountBalances,
          _ => l10n.reports,
        }),
        actions: [
          if (_selectedIndex != 0)
            IconButton(
              tooltip: l10n.recurringPlans,
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const RecurringPlansScreen()),
              ),
              icon: const Icon(Icons.event_repeat),
            ),
          if (_selectedIndex != 0)
            IconButton(
              tooltip: l10n.spendingPlans,
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SpendingPlansScreen()),
              ),
              icon: const Icon(Icons.pie_chart_outline),
            ),
          if (_selectedIndex == 0)
            IconButton(
              tooltip: l10n.csvImport,
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const CsvImportScreen()),
              ),
              icon: const Icon(Icons.upload_file_outlined),
            ),
          if (_selectedIndex == 0)
            IconButton(
              tooltip: l10n.codeImport,
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const StructuredImportScreen(),
                ),
              ),
              icon: const Icon(Icons.data_object),
            ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _TransactionBody(
            onOpenAccounts: () => setState(() => _selectedIndex = 1),
          ),
          const AccountOverviewScreen(),
          const ReportScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const TransactionEditorSheet(),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.addTransaction),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.accounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.reports,
          ),
        ],
      ),
    );
  }
}

class _TransactionBody extends ConsumerWidget {
  const _TransactionBody({required this.onOpenAccounts});

  final VoidCallback onOpenAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final balances = ref.watch(accountBalancesProvider);
    return transactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          _ErrorState(onRetry: () => ref.invalidate(transactionsProvider)),
      data: (items) => balances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _TransactionList(
          items: items,
          balances: const [],
          onOpenAccounts: onOpenAccounts,
        ),
        data: (accountItems) => _TransactionList(
          items: items,
          balances: accountItems,
          onOpenAccounts: onOpenAccounts,
        ),
      ),
    );
  }
}

class _TransactionList extends ConsumerStatefulWidget {
  const _TransactionList({
    required this.items,
    required this.balances,
    required this.onOpenAccounts,
  });

  final List<LedgerRecord> items;
  final List<AccountBalance> balances;
  final VoidCallback onOpenAccounts;

  @override
  ConsumerState<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<_TransactionList> {
  String? _currency;
  bool _reviewOnly = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final reviewCount = items.where((record) => record.needsReview).length;
    final visibleItems = _reviewOnly
        ? items.where((record) => record.needsReview).toList()
        : items;
    final balances = widget.balances;
    final currencies = currencyOptions([
      ...balances.map((account) => account.currencyCode),
      ...items.map((record) => record.currencyCode),
    ]);
    final currency = currencies.contains(_currency)
        ? _currency!
        : currencies.first;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final expenses = items
        .where(
          (item) => item.currencyCode == currency && item.spendingMinor != 0,
        )
        .toList(growable: false);
    final total = expenses.fold<int>(
      0,
      (sum, item) => sum + item.spendingMinor,
    );
    final monthTotal = _sumSince(expenses, monthStart);
    final weekTotal = _sumSince(expenses, weekStart);
    final personalAssets = balances
        .where(
          (account) =>
              account.currencyCode == currency &&
              account.group == AccountGroup.personalAsset,
        )
        .fold<int>(0, (sum, account) => sum + account.currentBalanceMinor);
    final liabilities = balances
        .where(
          (account) =>
              account.currencyCode == currency &&
              account.group == AccountGroup.liability,
        )
        .fold<int>(0, (sum, account) => sum + account.currentBalanceMinor);
    final netAssets = personalAssets - liabilities;

    final recordsById = {for (final record in items) record.id: record};
    final refundsByOriginal = <String, List<LedgerRecord>>{};
    for (final record in items) {
      final originalId = record.refundOfId;
      if (originalId != null) {
        (refundsByOriginal[originalId] ??= []).add(record);
      }
    }

    Map<String, int> refundableAmounts(
      LedgerRecord original, {
      String? excluding,
    }) {
      final remaining = {
        for (final leg in original.accountPostings)
          if (leg.debitMinor < 0) leg.accountId: -leg.debitMinor,
      };
      for (final refund
          in refundsByOriginal[original.id] ?? const <LedgerRecord>[]) {
        if (refund.id != excluding) {
          remaining.update(
            refund.accountId,
            (value) => value - refund.amountMinor,
          );
        }
      }
      return remaining;
    }

    void openEditor({LedgerRecord? record, LedgerRecord? refundFor}) {
      final original = refundFor ?? recordsById[record?.refundOfId];
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TransactionEditorSheet(
          record: record,
          refundFor: original,
          refundRemaining: original == null
              ? const {}
              : refundableAmounts(original, excluding: record?.id),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (currencies.length > 1)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: CurrencySelector(
                currencies: currencies,
                value: currency,
                label: context.l10n.summaryCurrency,
                onChanged: (code) => setState(() => _currency = code),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 104,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardSummaryCard(
                  label: context.l10n.expenseThisMonth,
                  amount: monthTotal,
                  currency: currency,
                  icon: Icons.calendar_month_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.expenseThisWeek,
                  amount: weekTotal,
                  currency: currency,
                  icon: Icons.date_range_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.expenseAllTime,
                  amount: total,
                  currency: currency,
                  icon: Icons.receipt_long_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.liquidNetWorth,
                  amount: netAssets,
                  currency: currency,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: widget.onOpenAccounts,
                ),
              ],
            ),
          ),
        ),
        if (reviewCount > 0 || _reviewOnly)
          SliverToBoxAdapter(
            child: SwitchListTile(
              value: _reviewOnly,
              title: Text('${context.l10n.fundingReviewFilter} ($reviewCount)'),
              onChanged: (value) => setState(() => _reviewOnly = value),
            ),
          ),
        if (visibleItems.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: 240, child: _EmptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverList.separated(
              itemCount: visibleItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final settlement = item.settlement;
                final price = item.terms.originalPrice;
                final readOnly =
                    item.isReversal ||
                    item.hasReversal ||
                    item.type == LedgerTransactionType.adjustment;
                final canReverse =
                    item.canReverse &&
                    (refundsByOriginal[item.id]?.isEmpty ?? true);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        item.isPending
                            ? Icons.schedule
                            : item.isRefund
                            ? Icons.undo
                            : _iconForType(item.type),
                      ),
                    ),
                    title: Text(_titleForRecord(context, item)),
                    subtitle: Text(
                      [
                        DateFormat.MMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_Hm().format(item.occurredAt),
                        if (item.isPending) context.l10n.pendingPosting,
                        if (item.needsReview) context.l10n.fundingReviewBadge,
                        if (item.hasReversal) context.l10n.reversedPosting,
                        if (item.isReversal) context.l10n.reversalPosting,
                        _accountDescription(context, item),
                        if (settlement != null) ...[
                          context.l10n.effectiveExchangeRateLabel(
                            item.currencyCode,
                            effectiveExchangeRate(
                              sourceMinor: item.amountMinor,
                              sourceCurrency: item.currencyCode,
                              settlementMinor: settlement.amountMinor,
                              settlementCurrency: settlement.currencyCode,
                            ),
                            settlement.currencyCode,
                          ),
                          if (settlement.quotedRate case final quote?)
                            context.l10n.quotedExchangeRateLabel(
                              item.currencyCode,
                              quote,
                              settlement.currencyCode,
                            ),
                        ],
                        if (price != null)
                          '${context.l10n.originalPrice} ${formatMoney(price.amountMinor, price.currencyCode)}',
                        if (item.terms.feeMinor > 0)
                          '${context.l10n.feeAmount} ${formatMoney(item.terms.feeMinor, item.currencyCode)}',
                        if (item.terms.interestMinor > 0)
                          '${context.l10n.interestAmount} ${formatMoney(item.terms.interestMinor, item.currencyCode)}',
                        if (item.note.isNotEmpty) item.note,
                      ].join(' · '),
                      maxLines: settlement == null && item.terms.isEmpty
                          ? 2
                          : 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 124),
                          child: Text(
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            _amountForRecord(item),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _colorForType(
                                    context,
                                    item.isRefund
                                        ? LedgerTransactionType.income
                                        : item.type,
                                  ),
                                ),
                          ),
                        ),
                        if (!readOnly || canReverse)
                          PopupMenuButton<_RecordAction>(
                            tooltip: context.l10n.transactionActions,
                            onSelected: (action) {
                              switch (action) {
                                case _RecordAction.edit:
                                  openEditor(record: item);
                                case _RecordAction.delete:
                                  _confirmDeleteRecord(context, ref, item);
                                case _RecordAction.refund:
                                  openEditor(refundFor: item);
                                case _RecordAction.post:
                                  _postRecord(context, ref, item);
                                case _RecordAction.reverse:
                                  _confirmReversal(context, ref, item);
                              }
                            },
                            itemBuilder: (_) => [
                              if (!readOnly)
                                PopupMenuItem(
                                  value: _RecordAction.edit,
                                  child: Text(context.l10n.edit),
                                ),
                              if (item.isPending)
                                PopupMenuItem(
                                  value: _RecordAction.post,
                                  child: Text(
                                    context.l10n.postTransactionAction,
                                  ),
                                ),
                              if (item.canRefund &&
                                  refundableAmounts(item).values
                                      .any((amount) => amount > 0))
                                PopupMenuItem(
                                  value: _RecordAction.refund,
                                  child: Text(context.l10n.recordRefund),
                                ),
                              if (canReverse)
                                PopupMenuItem(
                                  value: _RecordAction.reverse,
                                  child: Text(context.l10n.reverseTransaction),
                                ),
                              if (!readOnly)
                                PopupMenuItem(
                                  value: _RecordAction.delete,
                                  child: Text(context.l10n.delete),
                                ),
                            ],
                          ),
                      ],
                    ),
                    onTap: readOnly
                        ? () => _showPostingDetails(
                            context,
                            item,
                            recordsById[item.terms.reversalOfId],
                          )
                        : () => openEditor(record: item),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

enum _RecordAction { edit, post, refund, reverse, delete }

int _sumSince(List<LedgerRecord> items, DateTime start) => items
    .where((item) => !item.occurredAt.isBefore(start))
    .fold<int>(0, (sum, item) => sum + item.spendingMinor);

class _DashboardSummaryCard extends StatelessWidget {
  const _DashboardSummaryCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    this.onTap,
  });

  final String label;
  final int amount;
  final String currency;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMoney(amount, currency),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showPostingDetails(
  BuildContext context,
  LedgerRecord record,
  LedgerRecord? original,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(_titleForRecord(context, record)),
    content: Text(
      [
        _accountDescription(context, record),
        _amountForRecord(record),
        if (record.note.isNotEmpty) record.note,
        if (original != null)
          '${context.l10n.reversalPosting} · ${DateFormat.yMMMd().format(original.occurredAt)}',
      ].join('\n'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.close),
      ),
    ],
  ),
);

Future<void> _confirmReversal(
  BuildContext context,
  WidgetRef ref,
  LedgerRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.reverseTransaction),
      content: Text(context.l10n.confirmReversal),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.reverseTransaction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final now = DateTime.now();
  try {
    await ref
        .read(expenseRepositoryProvider)
        .reverseTransaction(
          record.id,
          occurredAt: now.isBefore(record.occurredAt) ? record.occurredAt : now,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.postedReversal)));
    }
  } on TransactionRuleException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedTransactionRule(context, error))),
      );
    }
  }
}

Future<void> _postRecord(
  BuildContext context,
  WidgetRef ref,
  LedgerRecord record,
) async {
  try {
    await ref.read(expenseRepositoryProvider).postTransaction(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.transactionPosted)));
    }
  } on TransactionRuleException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedTransactionRule(context, error))),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.saveLaterFailed)));
    }
  }
}

Future<void> _confirmDeleteRecord(
  BuildContext context,
  WidgetRef ref,
  LedgerRecord record,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.confirmDeleteTransaction),
      content: Text(
        '${_titleForRecord(context, record)}  ${formatMoney(record.amountMinor, record.currencyCode)}'
        '\n${context.l10n.deleteRecalculatesBalances}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(expenseRepositoryProvider).deleteTransaction(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.transactionDeleted)));
    }
  } on TransactionRuleException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedTransactionRule(context, error))),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed)));
    }
  }
}

String _titleForRecord(
  BuildContext context,
  LedgerRecord record,
) => switch (record.type) {
  LedgerTransactionType.expense || LedgerTransactionType.income =>
    '${record.isRefund ? '${context.l10n.refund} · ' : ''}'
        '${DefaultLedgerLabels.categoryName(Localizations.localeOf(context), record.parentCategoryId, record.parentCategoryName)} · '
        '${DefaultLedgerLabels.categoryName(Localizations.localeOf(context), record.categoryId, record.categoryName)}',
  LedgerTransactionType.borrowing => context.l10n.borrowing,
  LedgerTransactionType.repayment => context.l10n.repayment,
  LedgerTransactionType.transfer => context.l10n.transfer,
  LedgerTransactionType.lending => context.l10n.lending,
  LedgerTransactionType.advance => context.l10n.advance,
  LedgerTransactionType.collection => context.l10n.collection,
  LedgerTransactionType.reimbursement => context.l10n.reimbursement,
  LedgerTransactionType.adjustment => context.l10n.balanceAdjustment,
};

String _accountDescription(BuildContext context, LedgerRecord record) {
  final locale = Localizations.localeOf(context);
  final source = record.isFamilyDirect
      ? context.l10n.familyDirectFunding
      : DefaultLedgerLabels.accountName(
          locale,
          record.accountId,
          record.accountName,
        );
  final sourceDescription = switch (record.accountKind) {
    'thirdPartyPayable' =>
      '$source · ${context.l10n.accountKindThirdPartyPayable}',
    'entrustedFunds' => '$source · ${context.l10n.accountKindEntrustedFunds}',
    _ => source,
  };
  final target = record.targetAccountId == null
      ? null
      : DefaultLedgerLabels.accountName(
          locale,
          record.targetAccountId!,
          record.targetAccountName!,
        );
  if (record.terms.externalDebtPayment) {
    return '${context.l10n.externalDebtPayment} · $source';
  }
  return switch (record.type) {
    LedgerTransactionType.adjustment => source,
    LedgerTransactionType.expense =>
      record.accountPostings
                  .where((leg) => leg.kind != AccountKind.receivable)
                  .length >
              1
          ? record.accountPostings
                .where((leg) => leg.kind != AccountKind.receivable)
                .map(
                  (leg) =>
                      '${DefaultLedgerLabels.accountName(locale, leg.accountId, leg.accountName)} ${formatMoney(leg.debitMinor.abs(), leg.currencyCode)}',
                )
                .join(' + ')
          : sourceDescription,
    LedgerTransactionType.income => context.l10n.creditedTo(source),
    _ => '$source → $target',
  };
}

String _amountForRecord(LedgerRecord record) {
  final amount = formatMoney(record.amountMinor.abs(), record.currencyCode);
  if (record.type == LedgerTransactionType.adjustment) {
    final kind = record.accountPostings.firstOrNull?.kind;
    final change =
        record.signedAmountMinor * (kind?.isLiability == true ? -1 : 1);
    return '${change > 0 ? '+' : '-'}$amount';
  }
  final settlement = record.settlement;
  if (settlement != null) {
    return '$amount\n→ ${formatMoney(settlement.amountMinor, settlement.currencyCode)}';
  }
  return switch (record.type) {
    LedgerTransactionType.expense =>
      '${record.isRefund || record.isReversal ? '+' : '-'}$amount',
    LedgerTransactionType.income => '${record.isReversal ? '-' : '+'}$amount',
    _ => amount,
  };
}

IconData _iconForType(LedgerTransactionType type) => switch (type) {
  LedgerTransactionType.expense => Icons.receipt_long_outlined,
  LedgerTransactionType.income => Icons.south_west,
  LedgerTransactionType.borrowing => Icons.call_received,
  LedgerTransactionType.repayment => Icons.call_made,
  LedgerTransactionType.adjustment => Icons.tune,
  LedgerTransactionType.transfer => Icons.swap_horiz,
  LedgerTransactionType.lending ||
  LedgerTransactionType.advance => Icons.call_made,
  LedgerTransactionType.collection ||
  LedgerTransactionType.reimbursement => Icons.call_received,
};

Color _colorForType(BuildContext context, LedgerTransactionType type) =>
    switch (type) {
      LedgerTransactionType.expense => Theme.of(context).colorScheme.error,
      LedgerTransactionType.income => Theme.of(context).colorScheme.primary,
      LedgerTransactionType.borrowing ||
      LedgerTransactionType.adjustment ||
      LedgerTransactionType.repayment ||
      LedgerTransactionType.lending ||
      LedgerTransactionType.advance ||
      LedgerTransactionType.collection ||
      LedgerTransactionType.reimbursement => Theme.of(
        context,
      ).colorScheme.onSurface,
      LedgerTransactionType.transfer => Theme.of(context).colorScheme.secondary,
    };

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.noTransactions,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.noTransactionsHint),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.ledgerReadFailed),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
