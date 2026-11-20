import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/features/accounts/account_overview_screen.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

class DebtContractEditor extends ConsumerStatefulWidget {
  const DebtContractEditor({super.key});

  @override
  ConsumerState<DebtContractEditor> createState() => _DebtContractEditorState();
}

class _DebtContractEditorState extends ConsumerState<DebtContractEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _party = TextEditingController();
  final _principal = TextEditingController();
  final _interest = TextEditingController(text: '0');
  final _installments = <DebtInstallment>[];
  var _due = planningDay(DateTime.now());
  String? _accountId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _party.dispose();
    _principal.dispose();
    _interest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final contracts = ref.watch(debtContractsProvider);
    final usedAccounts = {
      for (final contract in contracts.value ?? const <DebtContract>[])
        contract.draft.accountId,
    };
    final balances = ref.watch(accountBalancesProvider);
    final accounts =
        balances.value
            ?.where(
              (row) =>
                  DebtDirection.forAccount(row.kind) != null &&
                  currencyMinorDigits.containsKey(row.currencyCode) &&
                  !usedAccounts.contains(row.id),
            )
            .toList() ??
        const <AccountBalance>[];
    final account = accounts.where((row) => row.id == _accountId).firstOrNull;
    final currency = account?.currencyCode ?? defaultCurrency;
    return Scaffold(
      appBar: AppBar(title: Text(labels.debtAddContract)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: labels.name),
                maxLength: 60,
                validator: (value) =>
                    validDebtName(value ?? '') ? null : labels.debtInvalid,
              ),
              TextFormField(
                controller: _party,
                decoration: InputDecoration(labelText: labels.debtCounterparty),
                maxLength: 60,
                validator: (value) =>
                    validDebtName(value ?? '') ? null : labels.debtInvalid,
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(account?.id),
                initialValue: account?.id,
                isExpanded: true,
                decoration: InputDecoration(labelText: labels.account),
                items: [
                  for (final row in accounts)
                    DropdownMenuItem(
                      value: row.id,
                      child: Text(
                        '${DefaultLedgerLabels.balance(context, row)} · ${formatMoney(row.currentBalanceMinor, row.currencyCode)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: accounts.isEmpty
                    ? null
                    : (id) {
                        final selected = accounts.singleWhere(
                          (row) => row.id == id,
                        );
                        setState(() {
                          if (_accountId != selected.id) _installments.clear();
                          if (_principal.text.isEmpty &&
                              selected.currentBalanceMinor > 0) {
                            _principal.text = moneyInputText(
                              selected.currentBalanceMinor,
                              selected.currencyCode,
                            );
                          }
                          _accountId = selected.id;
                        });
                      },
                validator: (value) => value == null ? labels.debtInvalid : null,
              ),
              const SizedBox(height: 8),
              Text(
                accounts.isEmpty && !balances.isLoading && !contracts.isLoading
                    ? labels.debtNoAccounts
                    : labels.debtAccountHint,
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _addAccount(AccountKind.creditLine),
                    child: Text(labels.debtAddLiabilityAccount),
                  ),
                  TextButton(
                    onPressed: () => _addAccount(AccountKind.receivable),
                    child: Text(labels.debtAddReceivableAccount),
                  ),
                ],
              ),
              _AmountField(
                controller: _principal,
                label: labels.debtOriginalPrincipal,
                currency: currency,
              ),
              const SizedBox(height: 12),
              _AmountField(
                controller: _interest,
                label: labels.debtExpectedInterest,
                currency: currency,
                allowZero: true,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labels.debtDueDate),
                subtitle: Text(debtDateLabel(context, _due)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final chosen = await _pickDebtDay(context, _due);
                  if (mounted && chosen != null) setState(() => _due = chosen);
                },
              ),
              const Divider(),
              Text(
                labels.debtSchedule,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_installments.isEmpty) Text(labels.debtScheduleDefault),
              for (final (index, row) in _installments.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(debtDateLabel(context, row.dueOn)),
                  subtitle: Text(
                    '${labels.debtPrincipal} ${formatMoney(row.principalMinor, currency)} · ${labels.interestAmount} ${formatMoney(row.interestMinor, currency)}',
                  ),
                  trailing: IconButton(
                    tooltip: labels.delete,
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() => _installments.removeAt(index)),
                  ),
                  onTap: () => _editInstallment(currency, index: index),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed:
                      account == null ||
                          _installments.length >= maxDebtInstallments
                      ? null
                      : () => _editInstallment(currency),
                  icon: const Icon(Icons.add),
                  label: Text(labels.debtAddInstallment),
                ),
              ),
              if (_error case final message?)
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton(
                onPressed: _saving ? null : () => _save(account),
                child: Text(labels.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAccount(AccountKind kind) => showDialog<void>(
    context: context,
    builder: (_) => AddAccountDialog(initialKind: kind),
  );

  Future<void> _editInstallment(String currency, {int? index}) async {
    final row = await showDialog<DebtInstallment>(
      context: context,
      builder: (_) => _InstallmentDialog(
        currency: currency,
        due: _due,
        row: index == null ? null : _installments[index],
      ),
    );
    if (!mounted || row == null) return;
    setState(() {
      if (index == null) {
        _installments.add(row);
      } else {
        _installments[index] = row;
      }
      _installments.sort((a, b) => a.dueOn.compareTo(b.dueOn));
    });
  }

  Future<void> _save(AccountBalance? account) async {
    if (!_form.currentState!.validate() || account == null) return;
    final labels = context.l10n;
    final principal = parseMoney(_principal.text, account.currencyCode);
    final interest = parseMoney(
      _interest.text,
      account.currencyCode,
      allowZero: true,
    );
    final draft = DebtContractDraft(
      accountId: account.id,
      name: _name.text.trim(),
      counterparty: _party.text.trim(),
      direction: DebtDirection.forAccount(account.kind)!,
      currency: account.currencyCode,
      originalPrincipalMinor: principal,
      expectedInterestMinor: interest,
      dueOn: _due,
      installments: _installments.isEmpty
          ? [(dueOn: _due, principalMinor: principal, interestMinor: interest)]
          : List.of(_installments),
    );
    if (!draft.isValid) {
      setState(() => _error = labels.debtScheduleInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).addDebtContract(draft);
      if (mounted) Navigator.pop(context);
    } on DebtContractException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.error == DebtContractError.accountInUse
              ? labels.debtAccountInUse
              : labels.debtInvalid,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = labels.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _InstallmentDialog extends StatefulWidget {
  const _InstallmentDialog({
    required this.currency,
    required this.due,
    this.row,
  });

  final String currency;
  final DateTime due;
  final DebtInstallment? row;

  @override
  State<_InstallmentDialog> createState() => _InstallmentDialogState();
}

class _InstallmentDialogState extends State<_InstallmentDialog> {
  final _form = GlobalKey<FormState>();
  late final _principal = TextEditingController(
    text: moneyInputText(widget.row?.principalMinor ?? 0, widget.currency),
  );
  late final _interest = TextEditingController(
    text: moneyInputText(widget.row?.interestMinor ?? 0, widget.currency),
  );
  late DateTime _date = widget.row?.dueOn ?? widget.due;
  bool _empty = false;

  @override
  void dispose() {
    _principal.dispose();
    _interest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(labels.debtInstallment),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels.debtInstallmentDate),
              subtitle: Text(debtDateLabel(context, _date)),
              onTap: () async {
                final chosen = await _pickDebtDay(
                  context,
                  _date,
                  last: widget.due,
                );
                if (mounted && chosen != null) setState(() => _date = chosen);
              },
            ),
            _AmountField(
              controller: _principal,
              label: labels.debtPrincipal,
              currency: widget.currency,
              allowZero: true,
            ),
            const SizedBox(height: 12),
            _AmountField(
              controller: _interest,
              label: labels.interestAmount,
              currency: widget.currency,
              allowZero: true,
            ),
            if (_empty) Text(labels.debtInvalid),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final principal = parseMoney(
              _principal.text,
              widget.currency,
              allowZero: true,
            );
            final interest = parseMoney(
              _interest.text,
              widget.currency,
              allowZero: true,
            );
            if (principal == 0 && interest == 0) {
              setState(() => _empty = true);
              return;
            }
            Navigator.pop<DebtInstallment>(context, (
              dueOn: _date,
              principalMinor: principal,
              interestMinor: interest,
            ));
          },
          child: Text(labels.save),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.currency,
    this.allowZero = false,
  });

  final TextEditingController controller;
  final String label;
  final String currency;
  final bool allowZero;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: currency),
    validator: (value) {
      try {
        parseMoney(value ?? '', currency, allowZero: allowZero);
        return null;
      } on MoneyInputException catch (error) {
        return localizedMoneyInputError(context, error, currency: currency);
      }
    },
  );
}

Future<DateTime?> _pickDebtDay(
  BuildContext context,
  DateTime initial, {
  DateTime? last,
}) async {
  final end = last ?? DateTime(lastPlanningYear, 12, 31);
  final selected = await showDatePicker(
    context: context,
    initialDate: DateUtils.dateOnly(initial.isAfter(end) ? end : initial),
    firstDate: DateTime(firstPlanningYear),
    lastDate: DateUtils.dateOnly(end),
  );
  return selected == null ? null : planningDay(selected);
}

String debtDateLabel(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);
