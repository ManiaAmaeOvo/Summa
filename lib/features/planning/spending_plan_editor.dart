import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

String spendingScopeLabel(BuildContext context, SpendingScope scope) {
  final l10n = context.l10n;
  return switch (scope) {
    SpendingScope.total => l10n.grossSpending,
    SpendingScope.personal => l10n.personalSpending,
    SpendingScope.familyDirect => l10n.familyDirectFunding,
    SpendingScope.entrusted => l10n.entrustedSpending,
    SpendingScope.category => l10n.category,
    SpendingScope.account => l10n.account,
    SpendingScope.allowance => l10n.spendingPlanAllowance,
  };
}

class SpendingPlanEditor extends ConsumerStatefulWidget {
  const SpendingPlanEditor({super.key, required this.allowance});

  final bool allowance;

  @override
  ConsumerState<SpendingPlanEditor> createState() => _SpendingPlanEditorState();
}

class _SpendingPlanEditorState extends ConsumerState<SpendingPlanEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _today = DateUtils.dateOnly(DateTime.now());
  late DateTime _starts = DateUtils.addDaysToDate(_today, 1 - _today.day);
  late DateTime _ends = DateTime(_today.year, _today.month + 1, 0);
  String _currency = defaultCurrency;
  String? _account;
  String? _category;
  bool _fixed = false;
  bool _rollover = false;
  bool _saving = false;
  String? _error;
  late SpendingScope _scope = widget.allowance
      ? SpendingScope.allowance
      : SpendingScope.total;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accountState = ref.watch(accountsProvider);
    final categoryState = ref.watch(expenseCategoriesProvider);
    final planState = ref.watch(spendingPlansProvider);
    final used = {
      for (final plan in planState.value ?? const <SpendingPlan>[])
        if (!plan.archived && plan.draft.scope == SpendingScope.allowance)
          plan.draft.accountId,
    };
    final accounts = (accountState.value ?? const <LedgerAccount>[])
        .where(
          (account) =>
              currencyMinorDigits.containsKey(account.currencyCode) &&
              (_scope == SpendingScope.allowance
                  ? account.kind == AccountKind.entrustedFunds &&
                        !used.contains(account.id)
                  : account.kind != AccountKind.receivable),
        )
        .toList();
    final selected = accounts.where((item) => item.id == _account).firstOrNull;
    final categories = categoryState.value ?? const [];
    final categoryOptions = {
      for (final category in categories)
        category.id: DefaultLedgerLabels.category(context, category),
    };
    final dateLabels = MaterialLocalizations.of(context);
    final currency = selected?.currencyCode ?? _currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.allowance ? l10n.addAllowance : l10n.addBudget),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.name),
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                validator: (text) =>
                    text!.trim().isEmpty ? l10n.spendingPlanInvalid : null,
              ),
              if (!widget.allowance) ...[
                DropdownButtonFormField<SpendingScope>(
                  initialValue: _scope,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.spendingPlanScope,
                  ),
                  items: [
                    for (final scope in SpendingScope.values)
                      if (scope != SpendingScope.allowance)
                        DropdownMenuItem(
                          value: scope,
                          child: Text(spendingScopeLabel(context, scope)),
                        ),
                  ],
                  onChanged: (value) => setState(() {
                    _scope = value!;
                    _account = null;
                    _category = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],
              if (_scope.usesAccount)
                DropdownButtonFormField<String>(
                  key: ValueKey(selected?.id),
                  initialValue: selected?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.account,
                    helperText: accounts.isEmpty
                        ? accountState.hasError
                              ? l10n.accountLoadFailed
                              : accountState.isLoading || planState.isLoading
                              ? l10n.loading
                              : l10n.spendingPlanNoAccounts
                        : null,
                  ),
                  items: [
                    for (final account in accounts)
                      DropdownMenuItem(
                        value: account.id,
                        child: Text(
                          '${DefaultLedgerLabels.account(context, account)} · ${account.currencyCode}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: accounts.isEmpty
                      ? null
                      : (id) => setState(() => _account = id),
                  validator: (id) =>
                      id == null ? l10n.spendingPlanInvalid : null,
                )
              else ...[
                if (_scope == SpendingScope.category) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(_category),
                    initialValue: categoryOptions.containsKey(_category)
                        ? _category
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      helperText: categories.isEmpty
                          ? categoryState.hasError
                                ? l10n.categoryLoadFailed
                                : categoryState.isLoading
                                ? l10n.loading
                                : l10n.spendingPlanNoCategories
                          : null,
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.isParent
                                ? categoryOptions[category.id]!
                                : '${categoryOptions[category.parentId]} / ${categoryOptions[category.id]}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: categories.isEmpty
                        ? null
                        : (id) => setState(() => _category = id),
                    validator: (id) =>
                        id == null ? l10n.spendingPlanInvalid : null,
                  ),
                  const SizedBox(height: 12),
                ],
                CurrencySelector(
                  currencies: currencyOptions(currencyMinorDigits.keys),
                  value: _currency,
                  label: l10n.currencyLabel,
                  onChanged: (value) => setState(() => _currency = value),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.spendingPlanLimit,
                  suffixText: currency,
                ),
                validator: (value) {
                  try {
                    parseMoney(value ?? '', currency);
                    return null;
                  } on MoneyInputException catch (error) {
                    return localizedMoneyInputError(
                      context,
                      error,
                      currency: currency,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                initialValue: _fixed,
                items: [
                  DropdownMenuItem(
                    value: false,
                    child: Text(l10n.spendingPlanMonthly),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(l10n.spendingPlanFixedPeriod),
                  ),
                ],
                onChanged: (value) => setState(() => _fixed = value!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.spendingPlanStart),
                subtitle: Text(dateLabels.formatShortDate(_starts)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(start: true),
              ),
              if (_fixed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.spendingPlanEnd),
                  subtitle: Text(dateLabels.formatShortDate(_ends)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickDate(start: false),
                )
              else ...[
                Text(l10n.spendingPlanMonthlyHint),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.spendingPlanRollover),
                  value: _rollover,
                  onChanged: (value) => setState(() => _rollover = value),
                ),
              ],
              if (_error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
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

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _starts : _ends,
      firstDate: start ? DateTime(firstPlanningYear) : _starts,
      lastDate: DateTime(lastPlanningYear, 12, 31),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (start) {
        _starts = selected;
        if (_ends.isBefore(selected)) _ends = selected;
      } else {
        _ends = selected;
      }
    });
  }

  Future<void> _save(String currency) async {
    if (!_form.currentState!.validate()) return;
    final draft = SpendingPlanDraft(
      name: _name.text.trim(),
      currency: currency,
      scope: _scope,
      limitMinor: parseMoney(_amount.text, currency),
      startsOn: planningDay(_starts),
      endsOn: _fixed ? planningDay(_ends) : null,
      rollover: !_fixed && _rollover,
      accountId: _scope.usesAccount ? _account : null,
      categoryId: _scope == SpendingScope.category ? _category : null,
    );
    final l10n = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).addSpendingPlan(draft);
      if (mounted) Navigator.pop(context);
    } on SpendingPlanException {
      if (mounted) setState(() => _error = l10n.spendingPlanInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
