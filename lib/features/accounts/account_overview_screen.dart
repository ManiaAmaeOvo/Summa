import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/features/planning/savings_goals_screen.dart';
import 'package:summa/features/reports/report_screen.dart';
import 'package:summa/features/reconciliation/reconciliation_screen.dart';
import 'package:summa/features/valuation/valuation_screen.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

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

class _AccountOverview extends ConsumerStatefulWidget {
  const _AccountOverview({required this.items});

  final List<AccountBalance> items;

  @override
  ConsumerState<_AccountOverview> createState() => _AccountOverviewState();
}

class _AccountOverviewState extends ConsumerState<_AccountOverview> {
  String? _currency;
  AccountGroup? _group;
  List<AccountBalance> get items => widget.items;

  @override
  Widget build(BuildContext context) {
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

    final currencies = currencyOptions(
      items.map((account) => account.currencyCode),
    );
    final currency = currencies.contains(_currency)
        ? _currency!
        : currencies.first;
    int totalFor(AccountGroup group) => items
        .where(
          (account) =>
              account.currencyCode == currency && account.group == group,
        )
        .fold(0, (sum, account) => sum + account.currentBalanceMinor);
    final personalAssets = totalFor(AccountGroup.personalAsset);
    final entrustedFunds = totalFor(AccountGroup.entrustedFunds);
    final liabilities = totalFor(AccountGroup.liability);
    final netAssets = personalAssets - liabilities;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        NetWorthValuationCard(balances: items),
        const SizedBox(height: 8),
        if (currencies.length > 1) ...[
          CurrencySelector(
            currencies: currencies,
            value: currency,
            label: context.l10n.summaryCurrency,
            onChanged: (code) => setState(() => _currency = code),
          ),
          const SizedBox(height: 8),
        ],
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
              currency: currency,
            ),
            _SummaryCard(
              label: context.l10n.outstandingLiabilities,
              amountMinor: liabilities,
              currency: currency,
            ),
            _SummaryCard(
              label: context.l10n.liquidNetWorth,
              amountMinor: netAssets,
              currency: currency,
            ),
            _SummaryCard(
              label: context.l10n.entrustedFunds,
              amountMinor: entrustedFunds,
              currency: currency,
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
            ),
            icon: const Icon(Icons.savings_outlined),
            label: Text(context.l10n.savingsGoals),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PopupMenuButton<String>(
            tooltip: context.l10n.ledgerFilterAccountGroup,
            onSelected: (value) => setState(
              () => _group = value.isEmpty
                  ? null
                  : AccountGroup.values.byName(value),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: '',
                child: Text(context.l10n.ledgerFilterAllGroups),
              ),
              for (final group in _displayGroups)
                PopupMenuItem(
                  value: group.name,
                  child: Text(_groupLabel(context, group).$1),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _group == null
                          ? context.l10n.ledgerFilterAllGroups
                          : _groupLabel(context, _group!).$1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (final group in _displayGroups)
          if ((_group == null || _group == group) &&
              (_group != null ||
                  group != AccountGroup.prepaid &&
                      group != AccountGroup.receivable ||
                  _itemsFor(group, currency).isNotEmpty))
            _AccountGroup(
              title: _groupLabel(context, group).$1,
              description: _groupLabel(context, group).$2,
              items: _itemsFor(group, currency),
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

  List<AccountBalance> _itemsFor(AccountGroup group, String currency) => items
      .where(
        (account) => account.group == group && account.currencyCode == currency,
      )
      .toList(growable: false);
}

const _displayGroups = [
  AccountGroup.personalAsset,
  AccountGroup.prepaid,
  AccountGroup.entrustedFunds,
  AccountGroup.receivable,
  AccountGroup.liability,
];

(String, String) _groupLabel(BuildContext context, AccountGroup group) {
  final labels = context.l10n;
  return switch (group) {
    AccountGroup.personalAsset => (
      labels.personalAccounts,
      labels.personalAccountsDescription,
    ),
    AccountGroup.prepaid => (
      labels.prepaidAccounts,
      labels.prepaidAccountsDescription,
    ),
    AccountGroup.entrustedFunds => (
      labels.entrustedFunds,
      labels.entrustedFundsDescription,
    ),
    AccountGroup.receivable => (
      labels.receivableAccounts,
      labels.receivableAccountsDescription,
    ),
    AccountGroup.liability => (
      labels.liabilityAccounts,
      labels.liabilityAccountsDescription,
    ),
    AccountGroup.external => (labels.familyDirectFunding, ''),
  };
}

class AddAccountDialog extends ConsumerStatefulWidget {
  const AddAccountDialog({
    super.key,
    this.initialKind = AccountKind.wallet,
    this.initialCurrency = defaultCurrency,
  });

  final AccountKind initialKind;
  final String initialCurrency;

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  late String _currency;
  late AccountKind _kind;
  String? _nameError;
  String? _amountError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _currency = currencyMinorDigits.containsKey(widget.initialCurrency)
        ? widget.initialCurrency
        : defaultCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLiability = _kind.isLiability;
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
                  .where((kind) => kind != AccountKind.familyDirect)
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
            CurrencySelector(
              currencies: currencyOptions(currencyMinorDigits.keys),
              value: _currency,
              label: context.l10n.currencyLabel,
              onChanged: _saving
                  ? null
                  : (code) => setState(() {
                      _currency = code;
                      _amountError = null;
                    }),
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
                suffixText: _currency,
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
      amountMinor = parseMoney(
        _amountController.text,
        _currency,
        allowZero: true,
      );
    } on MoneyInputException catch (error) {
      setState(
        () => _amountError = localizedMoneyInputError(
          context,
          error,
          currency: _currency,
        ),
      );
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
            currencyCode: _currency,
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
  AccountKind.receivable => context.l10n.accountKindReceivable,
  AccountKind.thirdPartyPayable => context.l10n.accountKindThirdPartyPayable,
  AccountKind.familyDirect => context.l10n.familyDirectFunding,
  AccountKind.savings => context.l10n.accountKindSavings,
  AccountKind.prepaid => context.l10n.accountKindPrepaid,
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

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: moneyInputText(
        widget.account.currentBalanceMinor,
        widget.account.currencyCode,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _reasonController.dispose();
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                suffixText: widget.account.currencyCode,
                errorText: _errorText,
                helperText: context.l10n.balanceAdjustmentHint,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLength: 200,
              decoration: InputDecoration(labelText: context.l10n.noteOptional),
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
          child: Text(_saving ? context.l10n.saving : context.l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    int amountMinor;
    try {
      amountMinor = parseMoney(
        _controller.text,
        widget.account.currencyCode,
        allowZero: true,
      );
    } on MoneyInputException catch (error) {
      setState(
        () => _errorText = localizedMoneyInputError(
          context,
          error,
          currency: widget.account.currencyCode,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(expenseRepositoryProvider)
          .recordBalanceAdjustment(
            accountId: widget.account.id,
            amountMinor: amountMinor,
            note: _reasonController.text,
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
  const _SummaryCard({
    required this.label,
    required this.amountMinor,
    required this.currency,
  });

  final String label;
  final int amountMinor;
  final String currency;

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
                formatMoney(amountMinor, currency),
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
                  subtitle: Text(switch (items[index].kind) {
                    AccountKind.thirdPartyPayable =>
                      context.l10n.accountKindThirdPartyPayable,
                    AccountKind.receivable =>
                      context.l10n.accountKindReceivable,
                    AccountKind.creditLine => context.l10n.liability,
                    _ => context.l10n.balance,
                  }),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatMoney(
                          items[index].currentBalanceMinor,
                          items[index].currencyCode,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      PopupMenuButton<_AccountAction>(
                        tooltip: context.l10n.accountActions,
                        onSelected: (action) {
                          final account = items[index];
                          switch (action) {
                            case _AccountAction.analyze:
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(
                                        context
                                            .l10n
                                            .ledgerFilterAccountAnalysis,
                                      ),
                                    ),
                                    body: ReportScreen(
                                      initialFilter: LedgerFilter(
                                        accountId: account.id,
                                      ),
                                      initialCurrency: account.currencyCode,
                                    ),
                                  ),
                                ),
                              );
                            case _AccountAction.reconcile:
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReconciliationScreen(account: account),
                                ),
                              );
                            case _AccountAction.editBalance:
                              onEdit(account);
                            case _AccountAction.delete:
                              onDelete(account);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _AccountAction.analyze,
                            child: Text(
                              context.l10n.ledgerFilterAccountAnalysis,
                            ),
                          ),
                          PopupMenuItem(
                            value: _AccountAction.reconcile,
                            child: Text(context.l10n.reconciliation),
                          ),
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

enum _AccountAction { analyze, reconcile, editBalance, delete }
