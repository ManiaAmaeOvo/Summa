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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          0 => 'Summa',
          1 => '账户余额',
          _ => '报表',
        }),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: '代码块导入',
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => const StructuredImportScreen(),
                ),
              ),
              icon: const Icon(Icons.data_object),
            ),
          IconButton(
            tooltip: '设置',
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
              label: const Text('记一笔'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '账单',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: '账户',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '报表',
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
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardSummaryCard(
                  label: '本月支出',
                  amount: monthTotal,
                  icon: Icons.calendar_month_outlined,
                ),
                _DashboardSummaryCard(
                  label: '本周支出',
                  amount: weekTotal,
                  icon: Icons.date_range_outlined,
                ),
                _DashboardSummaryCard(
                  label: '累计支出',
                  amount: total,
                  icon: Icons.receipt_long_outlined,
                ),
                _DashboardSummaryCard(
                  label: '流动净资产',
                  amount: netAssets,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
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
                    title: Text(_titleForRecord(item)),
                    subtitle: Text(
                      [
                        DateFormat('MM月dd日 HH:mm').format(item.occurredAt),
                        _accountDescription(item),
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
                          tooltip: '账单操作',
                          onSelected: (action) {
                            if (action == _RecordAction.edit) {
                              editRecord(item);
                            } else {
                              _confirmDeleteRecord(context, ref, item);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _RecordAction.edit,
                              child: Text('编辑'),
                            ),
                            PopupMenuItem(
                              value: _RecordAction.delete,
                              child: Text('删除'),
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
      title: const Text('删除这笔记录？'),
      content: Text(
        '${_titleForRecord(record)}  ${formatCny(record.amountMinor)}'
        '\n删除后相关账户余额会自动回算。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(expenseRepositoryProvider).deleteTransaction(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('记录已删除')));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }
}

String _titleForRecord(LedgerRecord record) => switch (record.type) {
  LedgerTransactionType.expense || LedgerTransactionType.income =>
    '${record.parentCategoryName} · ${record.categoryName}',
  LedgerTransactionType.borrowing => '借入',
  LedgerTransactionType.repayment => '还款',
  LedgerTransactionType.transfer => '转账',
};

String _accountDescription(LedgerRecord record) => switch (record.type) {
  LedgerTransactionType.expense => record.accountName,
  LedgerTransactionType.income => '计入 ${record.accountName}',
  LedgerTransactionType.borrowing || LedgerTransactionType.repayment =>
    '${record.accountName} → ${record.targetAccountName}',
  LedgerTransactionType.transfer =>
    '${record.accountName} → ${record.targetAccountName}',
};

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
            Text('还没有账单', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('点击“记一笔”，添加第一条本地记录。'),
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
          const Text('账本读取失败'),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
