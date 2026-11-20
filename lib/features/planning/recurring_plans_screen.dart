import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/features/planning/ledger_link_picker.dart';
import 'package:summa/features/planning/recurring_plan_editor.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:summa/l10n/transaction_rule_labels.dart';

class RecurringPlansScreen extends ConsumerWidget {
  const RecurringPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.recurringPlans)),
      body: SafeArea(
        child: ref
            .watch(recurringPlansProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(labels.recurringLoadFailed),
                    TextButton(
                      onPressed: () => ref.invalidate(recurringPlansProvider),
                      child: Text(labels.retry),
                    ),
                  ],
                ),
              ),
              data: (plans) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurringPlanEditor(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(labels.recurringAddPlan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (plans.isEmpty) Text(labels.recurringEmpty),
                  for (final plan in plans)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          plan.paused
                              ? Icons.pause_circle_outline
                              : Icons.event_repeat,
                        ),
                        title: Text(plan.draft.name),
                        subtitle: _PlanSummary(plan: plan),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _RecurringDetails(id: plan.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final RecurringPlan plan;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final due = plan.nextDueOn;
    final amount = formatMoney(plan.draft.expectedMinor, plan.draft.currency);
    final date = due == null
        ? labels.recurringScheduleEnded
        : '${labels.recurringNextDue}  ${_displayDate(context, due)}';
    final status = plan.paused
        ? labels.recurringPaused
        : due != null && due.isBefore(planningDay(DateTime.now()))
        ? labels.recurringOverdue
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(date),
        Text('${labels.recurringExpectedAmount}  $amount'),
        if (status != null) Text(status),
      ],
    );
  }
}

class _RecurringDetails extends ConsumerStatefulWidget {
  const _RecurringDetails({required this.id});

  final String id;

  @override
  ConsumerState<_RecurringDetails> createState() => _RecurringDetailsState();
}

class _RecurringDetailsState extends ConsumerState<_RecurringDetails> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final plans = ref.watch(recurringPlansProvider);
    final plan = plans.value?.where((item) => item.id == widget.id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(plan?.draft.name ?? labels.recurringPlans)),
      body: SafeArea(
        child: plan != null
            ? _buildPlan(plan, plans.value!)
            : plans.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(labels.recurringLoadFailed)),
      ),
    );
  }

  Widget _buildPlan(RecurringPlan plan, List<RecurringPlan> plans) {
    final labels = context.l10n;
    final draft = plan.draft;
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(
      draft.kind == RecurringPlanKind.income
          ? incomeCategoriesProvider
          : expenseCategoriesProvider,
    );
    final account = accounts.value
        ?.where(
          (item) =>
              item.id == draft.accountId && item.currencyCode == draft.currency,
        )
        .firstOrNull;
    final category = categories.value
        ?.where((item) => item.id == draft.categoryId)
        .firstOrNull;
    final txns = ref.watch(transactionsProvider);
    final canResolve = !_saving && !plan.paused && plan.nextDueOn != null;
    final byId = {
      for (final record in txns.value ?? const <LedgerRecord>[])
        record.id: record,
    };
    final kind = recurringKindLabel(context, draft.kind);
    final cadence = draft.customDays == null
        ? recurringCadenceLabel(context, draft.cadence)
        : '${labels.recurringIntervalDays} ${draft.customDays}';
    final theme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$kind · $cadence · ${draft.currency}', style: theme.titleMedium),
        if (account != null)
          Text(DefaultLedgerLabels.account(context, account)),
        if (category != null)
          Text(DefaultLedgerLabels.category(context, category)),
        if (!accounts.isLoading &&
            !categories.isLoading &&
            (account == null || category == null))
          Text(labels.recurringUnavailableTarget),
        const SizedBox(height: 12),
        _PlanSummary(plan: plan),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: canResolve && account != null && category != null
                  ? () => _review(plan, posting: true)
                  : null,
              child: Text(labels.recurringConfirmPosting),
            ),
            OutlinedButton(
              onPressed: canResolve && txns.hasValue
                  ? () => _link(plan, plans, txns.value!)
                  : null,
              child: Text(labels.recurringLink),
            ),
            TextButton(
              onPressed: _saving ? null : () => _review(plan, posting: false),
              child: Text(labels.recurringChangeAmount),
            ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => _mutate(
                      (repo) =>
                          repo.setRecurringPlanPaused(plan.id, !plan.paused),
                    ),
              child: Text(
                plan.paused ? labels.recurringResume : labels.recurringPause,
              ),
            ),
          ],
        ),
        const Divider(height: 36),
        Text(labels.recurringHistory, style: theme.titleMedium),
        if (plan.occurrences.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(labels.recurringNoHistory),
          )
        else if (txns.hasError)
          TextButton(
            onPressed: () => ref.invalidate(transactionsProvider),
            child: Text(labels.retry),
          )
        else if (!txns.hasValue)
          const LinearProgressIndicator()
        else
          for (final item in plan.occurrences.reversed)
            _HistoryTile(
              plan: plan,
              occurrence: item,
              record: byId[item.entryId],
            ),
      ],
    );
  }

  Future<void> _review(RecurringPlan plan, {required bool posting}) async {
    final result = await showDialog<_Review>(
      context: context,
      builder: (_) => _RecurringAmountDialog(plan: plan, posting: posting),
    );
    if (!mounted || result == null) return;
    await _mutate(
      (repo) => posting
          ? repo.confirmRecurringOccurrence(
              plan.id,
              plan.nextIndex,
              amountMinor: result.amount,
              occurredAt: result.date,
              note: result.note,
            )
          : repo.setRecurringPlanExpectedAmount(plan.id, result.amount),
    );
  }

  Future<void> _link(
    RecurringPlan plan,
    List<RecurringPlan> plans,
    List<LedgerRecord> records,
  ) async {
    final linked = {
      for (final other in plans)
        for (final occurrence in other.occurrences) occurrence.entryId,
    };
    final now = DateTime.now();
    final candidates = records
        .where(
          (record) =>
              !linked.contains(record.id) &&
              !record.occurredAt.isAfter(now) &&
              plan.draft.matches(record),
        )
        .toList();

    final chosen = await pickLedgerLink(
      context,
      title: context.l10n.recurringLink,
      emptyLabel: context.l10n.recurringNoMatches,
      candidates: candidates,
    );
    if (!mounted || chosen == null) return;
    await _mutate(
      (repo) => repo.linkRecurringOccurrence(plan.id, plan.nextIndex, chosen),
    );
  }

  Future<void> _mutate(
    Future<void> Function(ExpenseRepository repo) action,
  ) async {
    setState(() => _saving = true);
    final labels = context.l10n;
    try {
      await action(ref.read(expenseRepositoryProvider));
    } on TransactionRuleException catch (error) {
      if (mounted) _message(localizedTransactionRule(context, error));
    } on RecurringPlanException catch (error) {
      if (mounted) {
        _message(switch (error.error) {
          RecurringPlanError.invalid => labels.recurringInvalid,
          RecurringPlanError.stale => labels.recurringStale,
          RecurringPlanError.paused => labels.recurringPaused,
          RecurringPlanError.ineligible => labels.recurringIneligible,
          RecurringPlanError.alreadyLinked => labels.recurringAlreadyLinked,
        });
      }
    } catch (_) {
      if (mounted) _message(labels.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.plan,
    required this.occurrence,
    this.record,
  });
  final RecurringPlan plan;
  final RecurringOccurrence occurrence;
  final LedgerRecord? record;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final due = plan.draft.dueOn(occurrence.index)!;
    final txn = record;
    final status = txn == null
        ? labels.recurringUnavailableEntry
        : txn.hasReversal
        ? labels.recurringReversedEntry
        : !plan.draft.matches(txn)
        ? labels.recurringChangedEntry
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_displayDate(context, due)),
      subtitle: Text(
        [
          '${labels.recurringExpectedAmount}  ${formatMoney(occurrence.expectedMinor, plan.draft.currency)}',
          if (txn != null) ...[
            linkedTransactionTitle(context, txn),
            '${labels.recurringActualDate}  ${_displayDate(context, txn.occurredAt)}',
            '${labels.recurringActualAmount}  ${formatMoney(txn.amountMinor, txn.currencyCode)}',
          ],
          ?status,
        ].join('\n'),
      ),
    );
  }
}

typedef _Review = ({int amount, DateTime date, String note});

class _RecurringAmountDialog extends StatefulWidget {
  const _RecurringAmountDialog({required this.plan, required this.posting});
  final RecurringPlan plan;
  final bool posting;

  @override
  State<_RecurringAmountDialog> createState() => _RecurringAmountDialogState();
}

class _RecurringAmountDialogState extends State<_RecurringAmountDialog> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: moneyInputText(
      widget.plan.draft.expectedMinor,
      widget.plan.draft.currency,
    ),
  );
  late final _note = TextEditingController(text: widget.plan.draft.name);
  var _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final currency = widget.plan.draft.currency;
    return AlertDialog(
      title: Text(
        widget.posting
            ? labels.recurringPostTitle
            : labels.recurringChangeAmount,
      ),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.posting)
              Text(
                '${labels.recurringNextDue}  ${_displayDate(context, widget.plan.nextDueOn!)}',
              ),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.posting
                    ? labels.recurringActualAmount
                    : labels.recurringExpectedAmount,
                suffixText: currency,
              ),
              validator: (value) =>
                  recurringAmountError(context, value, currency),
            ),
            if (widget.posting) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(labels.recurringActualDate),
                subtitle: Text(_displayDate(context, _date)),
                onTap: _pickDate,
                trailing: const Icon(Icons.calendar_today_outlined),
              ),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: labels.noteOptional),
              ),
            ],
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
            Navigator.pop<_Review>(context, (
              amount: parseMoney(_amount.text, currency),
              date: _date,
              note: widget.posting ? _note.text : '',
            ));
          },
          child: Text(widget.posting ? labels.recurringPost : labels.save),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_date),
      firstDate: DateTime(firstPlanningYear),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (mounted && chosen != null) setState(() => _date = chosen);
  }
}

String _displayDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);
