import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/features/planning/spending_plan_editor.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';

class SpendingPlansScreen extends ConsumerWidget {
  const SpendingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plans = ref.watch(spendingPlansProvider);
    final records = ref.watch(transactionsProvider);
    final today = ref.watch(localPlanningDateProvider);
    void add({required bool allowance}) => Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SpendingPlanEditor(allowance: allowance),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spendingPlans)),
      body: SafeArea(
        child: plans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _LoadError(),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => add(allowance: false),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addBudget),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => add(allowance: true),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addAllowance),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty) Text(l10n.spendingPlansEmpty),
              for (final plan in items)
                Card(
                  child: ListTile(
                    leading: Icon(
                      plan.draft.scope.isAllowance
                          ? Icons.card_giftcard_outlined
                          : Icons.pie_chart_outline,
                    ),
                    title: Text(plan.draft.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ScopeText(plan: plan),
                        if (plan.archived)
                          Text(l10n.spendingPlanArchived)
                        else if (records.value case final transactions?)
                          _PlanTotals(
                            currency: plan.draft.currency,
                            period: summarizeSpendingPlan(
                              plan,
                              transactions,
                              periodIndex: _currentIndex(plan, today),
                              today: today,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpendingPlanDetails(id: plan.id),
                      ),
                    ),
                  ),
                ),
              if (items.isNotEmpty && records.hasError) const _LoadError(),
            ],
          ),
        ),
      ),
    );
  }
}

int _currentIndex(SpendingPlan plan, DateTime now) =>
    plan.draft.periodIndex(planningDay(now)) ?? 0;

class SpendingPlanDetails extends ConsumerStatefulWidget {
  const SpendingPlanDetails({super.key, required this.id});

  final String id;

  @override
  ConsumerState<SpendingPlanDetails> createState() => _PlanDetailsState();
}

class _PlanDetailsState extends ConsumerState<SpendingPlanDetails> {
  int? _position;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plans = ref.watch(spendingPlansProvider);
    final records = ref.watch(transactionsProvider);
    final plan = plans.value?.where((item) => item.id == widget.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan?.draft.name ?? l10n.spendingPlans),
        actions: [
          if (plan != null)
            IconButton(
              tooltip: plan.archived
                  ? l10n.spendingPlanReactivate
                  : l10n.archive,
              icon: Icon(
                plan.archived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              onPressed: _saving ? null : () => _setArchived(!plan.archived),
            ),
        ],
      ),
      body: SafeArea(
        child: plan == null
            ? plans.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const _LoadError()
            : records.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _LoadError(),
                data: (items) => _details(context, plan, items),
              ),
      ),
    );
  }

  Widget _details(
    BuildContext context,
    SpendingPlan plan,
    List<LedgerRecord> items,
  ) {
    final l10n = context.l10n;
    final today = ref.watch(localPlanningDateProvider);
    final latest = _currentIndex(plan, today);
    final index = (_position ?? latest).clamp(0, latest);
    final period = summarizeSpendingPlan(
      plan,
      items,
      periodIndex: index,
      today: today,
    );
    final currency = plan.draft.currency;
    final dateLabels = MaterialLocalizations.of(context);
    final money = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ScopeText(plan: plan),
        if (plan.draft.scope == SpendingScope.resettableAllowance)
          Text(l10n.accountPeriodicAllowanceExplanation),
        if (plan.archived) Text(l10n.spendingPlanArchived),
        Row(
          children: [
            IconButton(
              tooltip: l10n.spendingPlanPrevious,
              icon: const Icon(Icons.chevron_left),
              onPressed: index == 0
                  ? null
                  : () => setState(() => _position = index - 1),
            ),
            Expanded(
              child: Text(
                '${dateLabels.formatShortDate(period.start)} – ${dateLabels.formatShortDate(period.endExclusive.subtract(const Duration(days: 1)))}',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: l10n.spendingPlanNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: index == latest
                  ? null
                  : () => setState(() => _position = index + 1),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.spendingPlanLimit}  ${formatMoneyTotal(period.baseMinor, currency)}',
                  style: money,
                ),
                if (plan.draft.rollover)
                  Text(
                    '${l10n.spendingPlanCarried}  ${formatMoneyTotal(period.carriedMinor, currency)}',
                  ),
                _PlanTotals(currency: currency, period: period),
                if (period.projectedMinor case final projected?)
                  Text(
                    '${l10n.spendingPlanProjected}  ${formatMoneyTotal(projected, currency)}',
                  ),
                if (!plan.archived)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _changeLimit(plan, period),
                    child: Text(l10n.spendingPlanChangeLimit),
                  ),
              ],
            ),
          ),
        ),
        if (plan.limits.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.spendingPlanLimitHistory),
            children: [
              for (final revision in plan.limits.reversed)
                ListTile(
                  title: Text(
                    dateLabels.formatShortDate(revision.limit.periodStart),
                  ),
                  subtitle: Text(
                    [
                      revision.limit.ongoing
                          ? l10n.spendingPlanFromPeriod
                          : l10n.spendingPlanSinglePeriod,
                      dateLabels.formatShortDate(revision.savedAt.toLocal()),
                    ].join(' · '),
                  ),
                  trailing: Text(
                    formatMoney(revision.limit.limitMinor, currency),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text(l10n.transactions, style: money),
        if (period.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.spendingPlanNoActivity),
          ),
        for (final item in period.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item.record.note.trim().isEmpty
                  ? DefaultLedgerLabels.categoryName(
                      Localizations.localeOf(context),
                      item.record.categoryId,
                      item.record.categoryName,
                    )
                  : item.record.note,
            ),
            subtitle: Text(dateLabels.formatShortDate(item.record.occurredAt)),
            trailing: Text(formatMoneyTotal(item.amountMinor, currency)),
          ),
      ],
    );
  }

  Future<void> _changeLimit(SpendingPlan plan, SpendingPeriod period) async {
    final limit = await showDialog<SpendingPlanLimit>(
      context: context,
      builder: (_) => _LimitDialog(plan: plan, period: period),
    );
    if (!mounted || limit == null) return;
    await _mutate(
      () => ref
          .read(expenseRepositoryProvider)
          .setSpendingPlanLimit(widget.id, limit),
    );
  }

  Future<void> _setArchived(bool archived) => _mutate(
    () => ref
        .read(expenseRepositoryProvider)
        .setSpendingPlanArchived(widget.id, archived),
  );

  Future<void> _mutate(Future<void> Function() change) async {
    setState(() => _saving = true);
    final l10n = context.l10n;
    try {
      await change();
    } on SpendingPlanException {
      if (mounted) _error(l10n.spendingPlanInvalid);
    } catch (_) {
      if (mounted) _error(l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _ScopeText extends ConsumerWidget {
  const _ScopeText({required this.plan});

  final SpendingPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = plan.draft;
    final scope = spendingScopeLabel(context, draft.scope);
    String? name;
    if (draft.accountId case final id?) {
      final account = ref
          .watch(accountsProvider)
          .value
          ?.where((item) => item.id == id)
          .firstOrNull;
      if (account != null) name = DefaultLedgerLabels.account(context, account);
    }
    if (draft.categoryId case final id?) {
      final category = ref
          .watch(expenseCategoriesProvider)
          .value
          ?.where((item) => item.id == id)
          .firstOrNull;
      if (category != null) {
        name = DefaultLedgerLabels.category(context, category);
      }
    }
    return Text([scope, ?name, draft.currency].join(' · '));
  }
}

class _PlanTotals extends StatelessWidget {
  const _PlanTotals({required this.currency, required this.period});

  final String currency;
  final SpendingPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.spendingPlanUsed}  ${formatMoneyTotal(period.usedMinor, currency)}',
        ),
        Text(
          '${l10n.spendingPlanRemaining}  ${formatMoneyTotal(period.remainingMinor, currency)}',
        ),
        if (period.remainingMinor.isNegative)
          Text(
            l10n.spendingPlanOverLimit,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({required this.plan, required this.period});

  final SpendingPlan plan;
  final SpendingPeriod period;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: moneyInputText(
      widget.period.baseMinor.toInt(),
      widget.plan.draft.currency,
    ),
  );
  bool _ongoing = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = widget.plan.draft.currency;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.spendingPlanChangeLimit),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.spendingPlanLimit,
                suffixText: currency,
              ),
              validator: (value) {
                try {
                  parseMoney(value ?? '', currency, allowZero: true);
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
            if (widget.plan.draft.endsOn == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.spendingPlanOngoing),
                value: _ongoing,
                onChanged: (value) => setState(() => _ongoing = value!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop<SpendingPlanLimit>(context, (
              periodStart: widget.period.start,
              limitMinor: parseMoney(_amount.text, currency, allowZero: true),
              ongoing: _ongoing,
            ));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.spendingPlansLoadFailed),
        TextButton(
          onPressed: () {
            ref.invalidate(spendingPlansProvider);
            ref.invalidate(transactionsProvider);
          },
          child: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}
