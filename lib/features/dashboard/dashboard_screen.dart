import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/features/accounts/account_overview_screen.dart';
import 'package:ledger_pro/features/import_export/structured_import_screen.dart';
import 'package:ledger_pro/features/reports/report_screen.dart';
import 'package:ledger_pro/features/settings/settings_screen.dart';
import 'package:ledger_pro/features/transaction_editor/add_expense_sheet.dart';
import 'package:ledger_pro/l10n/default_ledger_labels.dart';
import 'package:ledger_pro/l10n/l10n.dart';

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
        children: const [
          _TransactionBody(),
          AccountOverviewScreen(),
          ReportScreen(),
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
  const _TransactionBody();

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
        error: (_, _) => _TransactionList(items: items, balances: const []),
        data: (accountItems) =>
            _TransactionList(items: items, balances: accountItems),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.items, required this.balances});

  final List<LedgerRecord> items;
  final List<AccountBalance> balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final expenses = items
        .where((item) => item.type == LedgerTransactionType.expense)
        .toList(growable: false);
    final total = expenses.fold<int>(0, (sum, item) => sum + item.amountMinor);
    final monthTotal = _sumSince(expenses, monthStart);
    final weekTotal = _sumSince(expenses, weekStart);
    final personalAssets = balances
        .where((account) => account.group == AccountGroup.personalAsset)
        .fold<int>(0, (sum, account) => sum + account.currentBalanceMinor);
    final liabilities = balances
        .where((account) => account.group == AccountGroup.liability)
        .fold<int>(0, (sum, account) => sum + account.currentBalanceMinor);
    final netAssets = personalAssets - liabilities;

    void editRecord(LedgerRecord record) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TransactionEditorSheet(record: record),
      );
    }

    return CustomScrollView(
      slivers: [
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
                  icon: Icons.calendar_month_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.expenseThisWeek,
                  amount: weekTotal,
                  icon: Icons.date_range_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.expenseAllTime,
                  amount: total,
                  icon: Icons.receipt_long_outlined,
                ),
                _DashboardSummaryCard(
                  label: context.l10n.liquidNetWorth,
                  amount: netAssets,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: 240, child: _EmptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_iconForType(item.type))),
                    title: Text(_titleForRecord(context, item)),
                    subtitle: Text(
                      [
                        DateFormat.MMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_Hm().format(item.occurredAt),
                        _accountDescription(context, item),
                        if (item.note.isNotEmpty) item.note,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _amountForRecord(item),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _colorForType(context, item.type),
                              ),
                        ),
                        PopupMenuButton<_RecordAction>(
                          tooltip: context.l10n.transactionActions,
                          onSelected: (action) {
                            if (action == _RecordAction.edit) {
                              editRecord(item);
                            } else {
                              _confirmDeleteRecord(context, ref, item);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _RecordAction.edit,
                              child: Text(context.l10n.edit),
                            ),
                            PopupMenuItem(
                              value: _RecordAction.delete,
                              child: Text(context.l10n.delete),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => editRecord(item),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

enum _RecordAction { edit, delete }

int _sumSince(List<LedgerRecord> items, DateTime start) => items
    .where((item) => !item.occurredAt.isBefore(start))
    .fold<int>(0, (sum, item) => sum + item.amountMinor);

class _DashboardSummaryCard extends StatelessWidget {
  const _DashboardSummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
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
                formatCny(amount),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
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
        '${_titleForRecord(context, record)}  ${formatCny(record.amountMinor)}'
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
    '${DefaultLedgerLabels.categoryName(Localizations.localeOf(context), record.parentCategoryId, record.parentCategoryName)} · '
        '${DefaultLedgerLabels.categoryName(Localizations.localeOf(context), record.categoryId, record.categoryName)}',
  LedgerTransactionType.borrowing => context.l10n.borrowing,
  LedgerTransactionType.repayment => context.l10n.repayment,
  LedgerTransactionType.transfer => context.l10n.transfer,
};

String _accountDescription(BuildContext context, LedgerRecord record) {
  final locale = Localizations.localeOf(context);
  final source = DefaultLedgerLabels.accountName(
    locale,
    record.accountId,
    record.accountName,
  );
  final target = record.targetAccountId == null
      ? null
      : DefaultLedgerLabels.accountName(
          locale,
          record.targetAccountId!,
          record.targetAccountName!,
        );
  return switch (record.type) {
    LedgerTransactionType.expense => source,
    LedgerTransactionType.income => context.l10n.creditedTo(source),
    LedgerTransactionType.borrowing ||
    LedgerTransactionType.repayment => '$source → $target',
    LedgerTransactionType.transfer => '$source → $target',
  };
}

String _amountForRecord(LedgerRecord record) => switch (record.type) {
  LedgerTransactionType.expense => '-${formatCny(record.amountMinor)}',
  LedgerTransactionType.income => '+${formatCny(record.amountMinor)}',
  LedgerTransactionType.borrowing ||
  LedgerTransactionType.repayment ||
  LedgerTransactionType.transfer => formatCny(record.amountMinor),
};

IconData _iconForType(LedgerTransactionType type) => switch (type) {
  LedgerTransactionType.expense => Icons.receipt_long_outlined,
  LedgerTransactionType.income => Icons.south_west,
  LedgerTransactionType.borrowing => Icons.call_received,
  LedgerTransactionType.repayment => Icons.call_made,
  LedgerTransactionType.transfer => Icons.swap_horiz,
};

Color _colorForType(BuildContext context, LedgerTransactionType type) =>
    switch (type) {
      LedgerTransactionType.expense => Theme.of(context).colorScheme.error,
      LedgerTransactionType.income => Theme.of(context).colorScheme.primary,
      LedgerTransactionType.borrowing || LedgerTransactionType.repayment =>
        Theme.of(context).colorScheme.onSurface,
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
