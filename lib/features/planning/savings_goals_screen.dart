import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/features/planning/savings_goal_editor.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.savingsGoals)),
      body: SafeArea(
        child: ref
            .watch(savingsAllocationsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(labels.savingsLoadFailed),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(savingsAllocationsProvider),
                      child: Text(labels.retry),
                    ),
                  ],
                ),
              ),
              data: (accounts) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavingsGoalEditor(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(labels.savingsAddGoal),
                    ),
                  ),
                  if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(labels.savingsEmpty),
                    ),
                  for (final account in accounts) ...[
                    const SizedBox(height: 12),
                    _AccountAmounts(account: account),
                    for (final goal in account.goals)
                      ListTile(
                        title: Text(goal.draft.name),
                        subtitle: _GoalAmounts(goal: goal),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _SavingsDetails(
                              accountId: account.accountId,
                              goalId: goal.id,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}

class _SavingsDetails extends ConsumerStatefulWidget {
  const _SavingsDetails({required this.accountId, required this.goalId});

  final String accountId;
  final String goalId;

  @override
  ConsumerState<_SavingsDetails> createState() => _SavingsDetailsState();
}

class _SavingsDetailsState extends ConsumerState<_SavingsDetails> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final accounts = ref.watch(savingsAllocationsProvider);
    final account = accounts.value
        ?.where((row) => row.accountId == widget.accountId)
        .firstOrNull;
    final goal = account?.goals
        .where((row) => row.id == widget.goalId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(goal?.draft.name ?? labels.savingsGoals),
        actions: [
          if (goal != null)
            IconButton(
              tooltip: labels.savingsEditGoal,
              onPressed: _saving
                  ? null
                  : () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavingsGoalEditor(goal: goal),
                      ),
                    ),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: account != null && goal != null
            ? _body(account, goal)
            : accounts.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(labels.savingsLoadFailed)),
      ),
    );
  }

  Widget _body(SavingsAccountAllocation account, SavingsGoal goal) {
    final labels = context.l10n;
    final currency = account.currency;
    final dateLabels = MaterialLocalizations.of(context);
    final targetOn = goal.draft.targetOn;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AccountAmounts(account: account),
        const SizedBox(height: 16),
        _GoalAmounts(goal: goal),
        Text(
          '${labels.savingsPriority}  ${savingsPriorityLabel(context, goal.draft.priority)}',
        ),
        if (targetOn != null)
          Text(
            '${labels.savingsTargetOn}  ${dateLabels.formatShortDate(targetOn)}',
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed:
                  _saving ||
                      account.archived ||
                      account.unallocatedMinor == BigInt.zero
                  ? null
                  : () => _change(account, goal, releasing: false),
              child: Text(labels.savingsReserve),
            ),
            OutlinedButton(
              onPressed: _saving || goal.allocatedMinor == BigInt.zero
                  ? null
                  : () => _change(account, goal, releasing: true),
              child: Text(labels.savingsRelease),
            ),
          ],
        ),
        const Divider(height: 32),
        Text(
          labels.savingsHistory,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (goal.activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(labels.savingsNoHistory),
          ),
        for (final event in goal.activity.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              event.changeMinor < 0
                  ? labels.savingsRelease
                  : labels.savingsReserve,
            ),
            subtitle: Text(
              [
                dateLabels.formatShortDate(event.recordedAt.toLocal()),
                if (event.note.isNotEmpty) event.note,
              ].join(' · '),
            ),
            trailing: Text(formatMoney(event.changeMinor, currency)),
          ),
      ],
    );
  }

  Future<void> _change(
    SavingsAccountAllocation account,
    SavingsGoal goal, {
    required bool releasing,
  }) async {
    final result = await showDialog<_AllocationInput>(
      context: context,
      builder: (_) => _AllocationDialog(
        currency: account.currency,
        available: releasing ? goal.allocatedMinor : account.unallocatedMinor,
        releasing: releasing,
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _saving = true);
    final labels = context.l10n;
    try {
      await ref
          .read(expenseRepositoryProvider)
          .changeSavingsAllocation(
            goal.id,
            releasing ? -result.amount : result.amount,
            note: result.note,
          );
    } on SavingsGoalException catch (error) {
      if (mounted) {
        _message(switch (error.error) {
          SavingsGoalError.notEnoughUnallocated =>
            labels.savingsNotEnoughUnallocated,
          SavingsGoalError.notEnoughReserved => labels.savingsNotEnoughReserved,
          _ => labels.savingsInvalid,
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

class _AccountAmounts extends StatelessWidget {
  const _AccountAmounts({required this.account});

  final SavingsAccountAllocation account;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final theme = Theme.of(context);
    final currency = account.currency;
    final name = DefaultLedgerLabels.accountName(
      Localizations.localeOf(context),
      account.accountId,
      account.accountName,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name · $currency', style: theme.textTheme.titleMedium),
            Text(
              '${labels.balance}  ${formatMoney(account.balanceMinor, currency)}',
            ),
            Text(
              '${labels.savingsReserved}  ${formatMoneyTotal(account.reservedMinor, currency)}',
            ),
            Text(
              '${labels.savingsUnallocated}  ${formatMoneyTotal(account.unallocatedMinor, currency)}',
            ),
            if (account.shortfallMinor > BigInt.zero)
              Text(
                '${labels.savingsShortfall}  ${formatMoneyTotal(account.shortfallMinor, currency)}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (account.archived) Text(labels.savingsAccountArchived),
          ],
        ),
      ),
    );
  }
}

class _GoalAmounts extends StatelessWidget {
  const _GoalAmounts({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final currency = goal.draft.currency;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labels.savingsAllocated}  ${formatMoneyTotal(goal.allocatedMinor, currency)}',
        ),
        Text(
          '${labels.savingsTarget}  ${formatMoney(goal.draft.targetMinor, currency)}',
        ),
        if (goal.reached) Text(labels.savingsReached),
      ],
    );
  }
}

typedef _AllocationInput = ({int amount, String note});

class _AllocationDialog extends StatefulWidget {
  const _AllocationDialog({
    required this.currency,
    required this.available,
    required this.releasing,
  });
  final String currency;
  final BigInt available;
  final bool releasing;

  @override
  State<_AllocationDialog> createState() => _AllocationDialogState();
}

class _AllocationDialogState extends State<_AllocationDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final action = widget.releasing
        ? labels.savingsRelease
        : labels.savingsReserve;
    final available = widget.releasing
        ? labels.savingsAllocated
        : labels.savingsUnallocated;
    return AlertDialog(
      scrollable: true,
      title: Text(action),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$available  ${formatMoneyTotal(widget.available, widget.currency)}',
            ),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: labels.amount,
                suffixText: widget.currency,
              ),
              validator: (value) {
                final message = savingsAmountError(
                  context,
                  value,
                  widget.currency,
                );
                if (message != null) return message;
                final amount = parseMoney(value!, widget.currency);
                if (BigInt.from(amount) <= widget.available) return null;
                return widget.releasing
                    ? labels.savingsNotEnoughReserved
                    : labels.savingsNotEnoughUnallocated;
              },
            ),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: labels.noteOptional),
            ),
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
            Navigator.pop<_AllocationInput>(context, (
              amount: parseMoney(_amount.text, widget.currency),
              note: _note.text,
            ));
          },
          child: Text(labels.save),
        ),
      ],
    );
  }
}
