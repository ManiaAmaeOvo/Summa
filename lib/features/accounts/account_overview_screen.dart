import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/l10n/default_ledger_labels.dart';
import 'package:ledger_pro/l10n/input_error_labels.dart';
import 'package:ledger_pro/l10n/l10n.dart';

class AccountOverviewScreen extends ConsumerWidget {
  const AccountOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);
    return balances.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          Center(child: Text(context.l10n.accountBalanceReadFailed)),
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
      final accountName = DefaultLedgerLabels.balance(context, account);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.archiveAccountTitle(accountName)),
          content: Text(context.l10n.archiveAccountDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.archive),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(expenseRepositoryProvider).archiveAccount(account.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.accountArchived(accountName))),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.archiveFailed)));
        }
      }
    }

    Future<void> restoreDefaults() async {
      try {
        await ref.read(expenseRepositoryProvider).restoreDefaultAccounts();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.defaultAccountsRestored)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.restoreFailed)));
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
          mainAxisExtent: 104,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SummaryCard(
              label: context.l10n.personalLiquidAssets,
              amountMinor: personalAssets,
            ),
            _SummaryCard(
              label: context.l10n.outstandingLiabilities,
              amountMinor: liabilities,
            ),
            _SummaryCard(
              label: context.l10n.liquidNetWorth,
              amountMinor: netAssets,
            ),
            _SummaryCard(
              label: context.l10n.entrustedFunds,
              amountMinor: entrustedFunds,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: addAccount,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addAccount),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: restoreDefaults,
                icon: const Icon(Icons.restore),
                label: Text(context.l10n.restoreDefaults),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AccountGroup(
          title: context.l10n.personalAccounts,
          description: context.l10n.personalAccountsDescription,
          items: _itemsFor(AccountGroup.personalAsset),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        _AccountGroup(
          title: context.l10n.entrustedFunds,
          description: context.l10n.entrustedFundsDescription,
          items: _itemsFor(AccountGroup.entrustedFunds),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        _AccountGroup(
          title: context.l10n.liabilityAccounts,
          description: context.l10n.liabilityAccountsDescription,
          items: _itemsFor(AccountGroup.liability),
          onEdit: editBalance,
          onDelete: deleteAccount,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.accountCalibrationHint,
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
      title: Text(context.l10n.addAccountOrLiability),
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
                labelText: context.l10n.name,
                hintText: isLiability
                    ? context.l10n.liabilityNameExample
                    : context.l10n.assetNameExample,
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AccountKind>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: context.l10n.accountingType,
              ),
              items: AccountKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(_labelForKind(context, kind)),
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
                labelText: isLiability
                    ? context.l10n.currentAmountOwed
                    : context.l10n.currentBalance,
                prefixText: '¥ ',
                helperText: context.l10n.zeroThenCalibrate,
                errorText: _amountError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? context.l10n.adding : context.l10n.add),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    int amountMinor;
    setState(() {
      _nameError = name.isEmpty ? context.l10n.enterName : null;
      _amountError = null;
    });
    if (name.isEmpty) return;
    try {
      amountMinor = parseCnyMinorUnits(_amountController.text, allowZero: true);
    } on MoneyInputException catch (error) {
      setState(() => _amountError = localizedMoneyInputError(context, error));
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
        _nameError = context.l10n.nameAlreadyExists;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _nameError = context.l10n.addFailed;
      });
    }
  }
}

String _labelForKind(BuildContext context, AccountKind kind) => switch (kind) {
  AccountKind.cash => context.l10n.accountKindCash,
  AccountKind.bank => context.l10n.accountKindBank,
  AccountKind.wallet => context.l10n.accountKindWallet,
  AccountKind.entrustedFunds => context.l10n.accountKindEntrustedFunds,
  AccountKind.creditLine => context.l10n.accountKindLiability,
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
    final accountName = DefaultLedgerLabels.balance(context, widget.account);
    return AlertDialog(
      title: Text(
        widget.account.group == AccountGroup.liability
            ? context.l10n.calibrateLiability(accountName)
            : context.l10n.calibrateBalance(accountName),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '¥ ',
          errorText: _errorText,
          helperText: context.l10n.nonNegativeTwoDecimals,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? context.l10n.saving : context.l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    int amountMinor;
    try {
      amountMinor = parseCnyMinorUnits(_controller.text, allowZero: true);
    } on MoneyInputException catch (error) {
      setState(() => _errorText = localizedMoneyInputError(context, error));
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
        _errorText = context.l10n.saveFailed;
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
            Flexible(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            const SizedBox(height: 4),
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
                  title: Text(
                    DefaultLedgerLabels.balance(context, items[index]),
                  ),
                  subtitle: Text(
                    items[index].group == AccountGroup.liability
                        ? context.l10n.liability
                        : context.l10n.balance,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCny(items[index].currentBalanceMinor),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      PopupMenuButton<_AccountAction>(
                        tooltip: context.l10n.accountActions,
                        onSelected: (action) {
                          if (action == _AccountAction.editBalance) {
                            onEdit(items[index]);
                          } else {
                            onDelete(items[index]);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _AccountAction.editBalance,
                            child: Text(context.l10n.calibrateBalanceAction),
                          ),
                          PopupMenuItem(
                            value: _AccountAction.delete,
                            child: Text(context.l10n.archiveAccount),
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
