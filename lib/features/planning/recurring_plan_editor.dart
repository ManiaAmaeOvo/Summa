import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

String recurringKindLabel(BuildContext context, RecurringPlanKind kind) =>
    switch (kind) {
      RecurringPlanKind.subscription => context.l10n.recurringSubscription,
      RecurringPlanKind.expense => context.l10n.expense,
      RecurringPlanKind.income => context.l10n.income,
    };

String recurringCadenceLabel(BuildContext context, RecurringCadence cadence) =>
    switch (cadence) {
      RecurringCadence.daily => context.l10n.recurringDaily,
      RecurringCadence.weekly => context.l10n.recurringWeekly,
      RecurringCadence.monthly => context.l10n.spendingPlanMonthly,
      RecurringCadence.quarterly => context.l10n.recurringQuarterly,
      RecurringCadence.yearly => context.l10n.recurringYearly,
      RecurringCadence.custom => context.l10n.recurringCustom,
    };

class RecurringPlanEditor extends ConsumerStatefulWidget {
  const RecurringPlanEditor({super.key});

  @override
  ConsumerState<RecurringPlanEditor> createState() =>
      _RecurringPlanEditorState();
}

class _RecurringPlanEditorState extends ConsumerState<RecurringPlanEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _interval = TextEditingController();
  var _due = DateUtils.dateOnly(DateTime.now());
  var _kind = RecurringPlanKind.subscription;
  var _cadence = RecurringCadence.monthly;
  String? _accountId;
  String? _categoryId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts =
        ref
            .watch(accountsProvider)
            .value
            ?.where(
              (row) =>
                  _kind.supportsAccount(row.kind) &&
                  currencyMinorDigits.containsKey(row.currencyCode),
            )
            .toList() ??
        const [];
    final categories =
        ref
            .watch(
              _kind == RecurringPlanKind.income
                  ? incomeCategoriesProvider
                  : expenseCategoriesProvider,
            )
            .value ??
        const [];
    final parents = {
      for (final row in categories.where((row) => row.isParent))
        row.id: DefaultLedgerLabels.category(context, row),
    };
    final children = categories
        .where((row) => parents.containsKey(row.parentId))
        .toList();
    final account = accounts.where((row) => row.id == _accountId).firstOrNull;
    final category = children.where((row) => row.id == _categoryId).firstOrNull;
    final currency = account?.currencyCode ?? defaultCurrency;
    final custom = _cadence == RecurringCadence.custom;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringAddPlan)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.name),
                validator: (value) => isValidRecurringName(value ?? '')
                    ? null
                    : l10n.recurringInvalid,
              ),
              DropdownButtonFormField<RecurringPlanKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l10n.recurringPlanType),
                items: [
                  for (final kind in RecurringPlanKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(recurringKindLabel(context, kind)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _kind = value!;
                  _accountId = null;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(('account', account?.id)),
                initialValue: account?.id,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.account),
                items: [
                  for (final row in accounts)
                    DropdownMenuItem(
                      value: row.id,
                      child: Text(
                        '${DefaultLedgerLabels.account(context, row)} · ${row.currencyCode}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: accounts.isEmpty
                    ? null
                    : (id) => setState(() => _accountId = id),
                validator: (value) =>
                    value == null ? l10n.recurringInvalid : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(('category', category?.id)),
                initialValue: category?.id,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  for (final row in children)
                    DropdownMenuItem(
                      value: row.id,
                      child: Text(
                        '${parents[row.parentId]} / ${DefaultLedgerLabels.category(context, row)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: children.isEmpty
                    ? null
                    : (id) => setState(() => _categoryId = id),
                validator: (value) =>
                    value == null ? l10n.recurringInvalid : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.recurringExpectedAmount,
                  suffixText: currency,
                ),
                validator: (value) =>
                    recurringAmountError(context, value, currency),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurringCadence>(
                initialValue: _cadence,
                decoration: InputDecoration(labelText: l10n.recurringCadence),
                items: [
                  for (final cadence in RecurringCadence.values)
                    DropdownMenuItem(
                      value: cadence,
                      child: Text(recurringCadenceLabel(context, cadence)),
                    ),
                ],
                onChanged: (value) => setState(() => _cadence = value!),
              ),
              if (custom) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _interval,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.recurringIntervalDays,
                    helperText: '1–$maxCustomDays',
                  ),
                  validator: (value) {
                    final days = int.tryParse(value?.trim() ?? '');
                    return days == null || days < 1 || days > maxCustomDays
                        ? l10n.recurringInvalid
                        : null;
                  },
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.recurringFirstDue),
                subtitle: Text(
                  MaterialLocalizations.of(context).formatShortDate(_due),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              if (_error case final message?)
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : () => _save(currency),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(firstPlanningYear),
      lastDate: DateTime(lastPlanningYear, 12, 31),
    );
    if (mounted && chosen != null) setState(() => _due = chosen);
  }

  Future<void> _save(String currency) async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final plan = RecurringPlanDraft(
      name: _name.text.trim(),
      kind: _kind,
      cadence: _cadence,
      firstDueOn: planningDay(_due),
      currency: currency,
      expectedMinor: parseMoney(_amount.text, currency),
      accountId: _accountId!,
      categoryId: _categoryId!,
      customDays: _cadence == RecurringCadence.custom
          ? int.parse(_interval.text.trim())
          : null,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).addRecurringPlan(plan);
      if (mounted) Navigator.pop(context);
    } on RecurringPlanException {
      if (mounted) setState(() => _error = l10n.recurringInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String? recurringAmountError(
  BuildContext context,
  String? value,
  String currency,
) {
  try {
    parseMoney(value ?? '', currency);
    return null;
  } on MoneyInputException catch (error) {
    return localizedMoneyInputError(context, error, currency: currency);
  }
}
