import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';

class AccountOverviewScreen extends ConsumerWidget {
  const AccountOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);
    return balances.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('账户余额读取失败')),
      data: (items) => _AccountOverview(items: items),
    );
  }
}

class _AccountOverview extends ConsumerWidget {
  const _AccountOverview({required this.items});

  final List<AccountBalance> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void editBalance(AccountBalance account) {
      showDialog<void>(
        context: context,
        builder: (_) => _BalanceDialog(account: account),
      );
    }

    void addAccount() {
      showDialog<void>(
        context: context,
        builder: (_) => const AddAccountDialog(),
      );
    }

    Future<void> deleteAccount(AccountBalance account) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('停用${account.name}？'),
          content: const Text(
            '账户会从可选列表和余额汇总中移除，但历史账单仍会保留。默认账户之后可以通过“恢复默认账户”重新启用。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('停用'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(expenseRepositoryProvider).archiveAccount(account.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${account.name}已停用')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('停用失败，请重试')));
        }
      }
    }

    Future<void> restoreDefaults() async {
      try {
        await ref.read(expenseRepositoryProvider).restoreDefaultAccounts();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('默认账户已恢复，原有余额没有被重置')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('恢复失败，请重试')));
        }
      }
    }

    final personalAssets = _totalFor(AccountGroup.personalAsset);
    final entrustedFunds = _totalFor(AccountGroup.entrustedFunds);
    final liabilities = _totalFor(AccountGroup.liability);
    final netAssets = personalAssets - liabilities;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SummaryCard(label: '个人流动资产', amountMinor: personalAssets),
            _SummaryCard(label: '待偿负债', amountMinor: liabilities),
            _SummaryCard(label: '流动净资产', amountMinor: netAssets),
            _SummaryCard(label: '受托/授权资金', amountMinor: entrustedFunds),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: addAccount,
                icon: const Icon(Icons.add),
                label: const Text('添加账户'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: restoreDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('恢复默认'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AccountGroup(
          title: '个人账户',
          description: '属于你的现金、银行卡与钱包余额',
          items: _itemsFor(AccountGroup.personalAsset),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        _AccountGroup(
          title: '受托/授权资金',
          description: '可以使用，但不计入个人资产',
          items: _itemsFor(AccountGroup.entrustedFunds),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        _AccountGroup(
          title: '负债账户',
          description: '显示当前应偿还金额',
          items: _itemsFor(AccountGroup.liability),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        const SizedBox(height: 8),
        Text(
          '点击账户可校准当前余额。之后的支出会从资产账户扣除，或增加负债账户欠款。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  int _totalFor(AccountGroup group) => items
      .where((account) => account.group == group)
      .fold(0, (sum, account) => sum + account.currentBalanceMinor);

  List<AccountBalance> _itemsFor(AccountGroup group) =>
      items.where((account) => account.group == group).toList(growable: false);
}

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({super.key, this.initialKind = AccountKind.wallet});

  final AccountKind initialKind;

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '0.00');
  late AccountKind _kind;
  String? _nameError;
  String? _amountError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiability = _kind == AccountKind.creditLine;
    return AlertDialog(
      title: const Text('添加账户或负债'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 30,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: '名称',
                hintText: isLiability ? '例如：朋友欠款' : '例如：储蓄卡',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AccountKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: '核算类型'),
              items: AccountKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(_labelForKind(kind)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _kind = value);
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: isLiability ? '当前待偿金额' : '当前余额',
                prefixText: '¥ ',
                helperText: '可先填 0，之后随时校准',
                errorText: _amountError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '添加中…' : '添加'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    int amountMinor;
    setState(() {
      _nameError = name.isEmpty ? '请输入名称' : null;
      _amountError = null;
    });
    if (name.isEmpty) return;
    try {
      amountMinor = parseCnyMinorUnits(_amountController.text, allowZero: true);
    } on MoneyInputException catch (error) {
      setState(() => _amountError = error.message);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .addAccount(
            name: name,
            kind: _kind,
            currentBalanceMinor: amountMinor,
          );
      if (mounted) Navigator.pop(context);
    } on StateError {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _nameError = '这个名称已经存在';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _nameError = '添加失败，请重试';
      });
    }
  }
}

String _labelForKind(AccountKind kind) => switch (kind) {
  AccountKind.cash => '现金',
  AccountKind.bank => '银行卡',
  AccountKind.wallet => '支付钱包',
  AccountKind.entrustedFunds => '受托/授权资金',
  AccountKind.creditLine => '负债账户',
};

class _BalanceDialog extends ConsumerStatefulWidget {
  const _BalanceDialog({required this.account});

  final AccountBalance account;

  @override
  ConsumerState<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends ConsumerState<_BalanceDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.account.currentBalanceMinor / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.account.group == AccountGroup.liability
            ? '校准${widget.account.name}当前负债'
            : '校准${widget.account.name}当前余额',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '¥ ',
          errorText: _errorText,
          helperText: '不能为负数，最多两位小数',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '保存中…' : '保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    int amountMinor;
    try {
      amountMinor = parseCnyMinorUnits(_controller.text, allowZero: true);
    } on MoneyInputException catch (error) {
      setState(() => _errorText = error.message);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .setCurrentBalance(
            accountId: widget.account.id,
            amountMinor: amountMinor,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = '保存失败，请重试';
      });
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amountMinor});

  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCny(amountMinor),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({
    required this.title,
    required this.description,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String description;
  final List<AccountBalance> items;
  final ValueChanged<AccountBalance> onEdit;
  final ValueChanged<AccountBalance> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                ListTile(
                  title: Text(items[index].name),
                  subtitle: Text(
                    items[index].group == AccountGroup.liability ? '负债' : '余额',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCny(items[index].currentBalanceMinor),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      PopupMenuButton<_AccountAction>(
                        tooltip: '账户操作',
                        onSelected: (action) {
                          if (action == _AccountAction.editBalance) {
                            onEdit(items[index]);
                          } else {
                            onDelete(items[index]);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _AccountAction.editBalance,
                            child: Text('校准余额'),
                          ),
                          PopupMenuItem(
                            value: _AccountAction.delete,
                            child: Text('停用账户'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => onEdit(items[index]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum _AccountAction { editBalance, delete }
