import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

String savingsPriorityLabel(BuildContext context, SavingsPriority priority) =>
    switch (priority) {
      SavingsPriority.high => context.l10n.savingsPriorityHigh,
      SavingsPriority.normal => context.l10n.savingsPriorityNormal,
      SavingsPriority.low => context.l10n.savingsPriorityLow,
    };

String? savingsAmountError(
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

class SavingsGoalEditor extends ConsumerStatefulWidget {
  const SavingsGoalEditor({super.key, this.goal});

  final SavingsGoal? goal;

  @override
  ConsumerState<SavingsGoalEditor> createState() => _SavingsGoalEditorState();
}

class _SavingsGoalEditorState extends ConsumerState<SavingsGoalEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _previous?.name ?? '');
  late final _amount = TextEditingController(
    text: _previous == null
        ? ''
        : moneyInputText(_previous!.targetMinor, _previous!.currency),
  );
  SavingsGoalDraft? get _previous => widget.goal?.draft;
  late SavingsPriority _priority =
      _previous?.priority ?? SavingsPriority.normal;
  late DateTime? _date = _previous?.targetOn;
  String? _accountId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final previous = _previous;
    final accounts =
        ref
            .watch(accountsProvider)
            .value
            ?.where(
              (account) =>
                  account.kind.isPersonalCash &&
                  currencyMinorDigits.containsKey(account.currencyCode),
            )
            .toList() ??
        const [];
    final account = accounts.where((item) => item.id == _accountId).firstOrNull;
    final currency =
        previous?.currency ?? account?.currencyCode ?? defaultCurrency;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          previous == null ? labels.savingsAddGoal : labels.savingsEditGoal,
        ),
      ),
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? labels.savingsInvalid
                    : null,
              ),
              if (previous == null) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey(account?.id),
                  initialValue: account?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: labels.account,
                    helperText: accounts.isEmpty
                        ? labels.savingsNoAccounts
                        : null,
                    helperMaxLines: 2,
                  ),
                  items: [
                    for (final item in accounts)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${DefaultLedgerLabels.account(context, item)} · ${item.currencyCode}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: accounts.isEmpty
                      ? null
                      : (value) => setState(() => _accountId = value),
                  validator: (value) =>
                      value == null ? labels.savingsInvalid : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: labels.savingsTarget,
                  suffixText: currency,
                ),
                validator: (value) =>
                    savingsAmountError(context, value, currency),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SavingsPriority>(
                initialValue: _priority,
                decoration: InputDecoration(labelText: labels.savingsPriority),
                items: [
                  for (final priority in SavingsPriority.values)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(savingsPriorityLabel(context, priority)),
                    ),
                ],
                onChanged: (value) => setState(() => _priority = value!),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labels.savingsTargetOn),
                subtitle: Text(
                  _date == null
                      ? labels.savingsNoDate
                      : MaterialLocalizations.of(context)
                            .formatShortDate(_date!),
                ),
                onTap: _pickDate,
                trailing: _date == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: labels.savingsClearDate,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _date = null),
                      ),
              ),
              if (_error case final message?)
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () => _save(previous?.accountId ?? account?.id, currency),
                child: Text(labels.save),
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
      initialDate: DateUtils.dateOnly(_date ?? DateTime.now()),
      firstDate: DateTime(firstPlanningYear),
      lastDate: DateTime(lastPlanningYear, 12, 31),
    );
    if (mounted && chosen != null) setState(() => _date = planningDay(chosen));
  }

  Future<void> _save(String? account, String currency) async {
    if (!_form.currentState!.validate() || account == null) return;
    final labels = context.l10n;
    final draft = SavingsGoalDraft(
      name: _name.text.trim(),
      accountId: account,
      currency: currency,
      targetMinor: parseMoney(_amount.text, currency),
      priority: _priority,
      targetOn: _date,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(expenseRepositoryProvider);
      if (widget.goal case final goal?) {
        await repository.updateSavingsGoal(goal.id, draft);
      } else {
        await repository.addSavingsGoal(draft);
      }
      if (mounted) Navigator.pop(context);
    } on SavingsGoalException {
      if (mounted) setState(() => _error = labels.savingsInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = labels.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
