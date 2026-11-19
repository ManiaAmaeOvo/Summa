import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/reconciliation/reconciliation_candidates.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/features/transaction_editor/add_expense_sheet.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:summa/l10n/transaction_rule_labels.dart';

class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key, required this.account});

  final AccountBalance account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = balanceCheckpointsProvider(account.id);
    final history = ref.watch(provider);
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.reconciliation)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(onRetry: () => ref.invalidate(provider)),
        data: (items) {
          final latestMatch = items
              .where((item) => item.isBalanced)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                DefaultLedgerLabels.balance(context, account),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                latestMatch == null
                    ? labels.noSuccessfulReconciliation
                    : labels.lastSuccessfulReconciliation(
                        _date(context, latestMatch.observedAt),
                      ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty) Text(labels.noCheckpoints),
              for (final item in items)
                Card(
                  child: ListTile(
                    title: Text(_date(context, item.observedAt)),
                    subtitle: Text(
                      '${labels.observedBalance} ${formatMoney(item.actualMinor, item.currencyCode)}'
                      ' · ${_status(context, item)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _CheckpointDetails(account: account, id: item.id),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _CheckpointForm(account: account),
        ),
        icon: const Icon(Icons.add),
        label: Text(labels.recordCheckpoint),
      ),
    );
  }
}

class _CheckpointForm extends ConsumerStatefulWidget {
  const _CheckpointForm({required this.account});
  final AccountBalance account;

  @override
  ConsumerState<_CheckpointForm> createState() => _CheckpointFormState();
}

class _CheckpointFormState extends ConsumerState<_CheckpointForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _observedAt = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _observedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_observedAt),
    );
    if (time == null || !mounted) return;
    setState(
      () => _observedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    final currency = widget.account.currencyCode;
    final int amount;
    try {
      amount = parseMoney(_amount.text, currency, allowZero: true);
    } on MoneyInputException catch (error) {
      setState(
        () => _error = localizedMoneyInputError(
          context,
          error,
          currency: currency,
        ),
      );
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(expenseRepositoryProvider)
          .saveBalanceCheckpoint(
            accountId: widget.account.id,
            observedAt: _observedAt,
            actualMinor: amount,
            note: _note.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _errorMessage(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return AlertDialog(
      title: Text(labels.recordCheckpoint),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(labels.checkpointTime),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickDate,
              icon: const Icon(Icons.schedule),
              label: Text(_date(context, _observedAt)),
            ),
            TextField(
              key: const ValueKey('checkpoint-observed-balance'),
              controller: _amount,
              keyboardType: TextInputType.numberWithOptions(
                decimal: currencyMinorDigits[widget.account.currencyCode] != 0,
              ),
              decoration: InputDecoration(
                labelText: labels.observedBalance,
                suffixText: widget.account.currencyCode,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(labelText: labels.noteOptional),
            ),
            if (_error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? labels.saving : labels.save),
        ),
      ],
    );
  }
}

class _CheckpointDetails extends ConsumerStatefulWidget {
  const _CheckpointDetails({required this.account, required this.id});

  final AccountBalance account;
  final String id;

  @override
  ConsumerState<_CheckpointDetails> createState() => _CheckpointDetailsState();
}

class _CheckpointDetailsState extends ConsumerState<_CheckpointDetails> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final provider = balanceCheckpointsProvider(widget.account.id);
    final history = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.checkpointDetails)),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(onRetry: () => ref.invalidate(provider)),
        data: (items) {
          final item = items.where((item) => item.id == widget.id).firstOrNull;
          if (item == null) {
            return Center(child: Text(context.l10n.checkpointUnavailable));
          }
          final lastMatch = items
              .where(
                (prior) =>
                    prior.isBalanced &&
                    prior.observedAt.isBefore(item.observedAt),
              )
              .firstOrNull;
          return _body(context, item, lastMatch);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    BalanceCheckpoint item,
    BalanceCheckpoint? lastMatch,
  ) {
    final labels = context.l10n;
    final currency = item.currencyCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          _date(context, item.observedAt),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(_status(context, item)),
        const SizedBox(height: 12),
        _AmountLine(
          label: labels.observedBalance,
          amount: formatMoney(item.actualMinor, currency),
        ),
        _AmountLine(
          label: labels.bookBalanceAtCheckpoint,
          amount: formatMoney(item.bookMinor, currency),
        ),
        _AmountLine(
          label: labels.checkpointDifference,
          amount: formatMoneyTotal(item.differenceMinor, currency),
        ),
        if (item.bookChanged)
          _AmountLine(
            label: labels.recordedBookBalance,
            amount: formatMoney(item.recordedBookMinor, currency),
          ),
        if (item.adjustmentId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(labels.linkedAdjustmentRecorded),
          ),
        if (item.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(item.note),
          ),
        if (!item.isVoided) ...[
          const SizedBox(height: 20),
          if (item.adjustmentId == null && !item.isBalanced)
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _confirm(
                      title: labels.applyCheckpointAdjustment,
                      message: labels.confirmCheckpointAdjustment,
                      action: () => ref
                          .read(expenseRepositoryProvider)
                          .adjustBalanceCheckpoint(
                            item.id,
                            expectedBookMinor: item.bookMinor,
                          ),
                    ),
              child: Text(labels.applyCheckpointAdjustment),
            ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _confirm(
                    title: labels.voidCheckpoint,
                    message: item.adjustmentId == null
                        ? labels.confirmVoidCheckpoint
                        : labels.confirmVoidAdjustedCheckpoint,
                    action: () => ref
                        .read(expenseRepositoryProvider)
                        .voidBalanceCheckpoint(item.id),
                  ),
            child: Text(labels.voidCheckpoint),
          ),
        ],
        if (!item.isVoided && !item.isBalanced) ...[
          const SizedBox(height: 16),
          Text(
            labels.reconciliationCandidates,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            lastMatch == null
                ? labels.checkpointRangeThrough(_date(context, item.observedAt))
                : labels.checkpointRange(
                    _date(context, lastMatch.observedAt),
                    _date(context, item.observedAt),
                  ),
          ),
          _CandidateList(
            checkpoint: item,
            lastMatch: lastMatch,
            isLiability: widget.account.kind.isLiability,
          ),
        ],
      ],
    );
  }

  Future<void> _confirm({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(dialog.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(title),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(context, error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CandidateList extends ConsumerWidget {
  const _CandidateList({
    required this.checkpoint,
    required this.lastMatch,
    required this.isLiability,
  });
  final BalanceCheckpoint checkpoint;
  final BalanceCheckpoint? lastMatch;
  final bool isLiability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    return ref
        .watch(transactionsProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              _LoadError(onRetry: () => ref.invalidate(transactionsProvider)),
          data: (records) {
            final rows = reconciliationCandidates(
              records,
              checkpoint: checkpoint,
              isLiability: isLiability,
              after: lastMatch?.observedAt,
            );
            if (rows.isEmpty) return Text(labels.noReconciliationCandidates);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in rows.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_recordTitle(context, item.record)),
                    subtitle: Text(
                      [
                        _date(context, item.record.occurredAt),
                        if (item.record.isPending) labels.pendingPosting,
                        if (item.similar) labels.similarCheckpointMovement,
                        if (item.matchesDifference)
                          labels.checkpointMatchingAmount,
                        if (item.record.needsReview) labels.fundingReviewBadge,
                        if (item.record.note.isNotEmpty) item.record.note,
                      ].join(' · '),
                    ),
                    trailing: Text(
                      formatMoneyTotal(item.effect, checkpoint.currencyCode),
                    ),
                    onTap: _isEditable(item.record)
                        ? () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) =>
                                TransactionEditorSheet(record: item.record),
                          )
                        : null,
                  ),
                if (rows.length > 12) Text(labels.checkpointCandidateLimit),
              ],
            );
          },
        );
  }

  bool _isEditable(LedgerRecord record) =>
      !record.isRefund &&
      !record.isReversal &&
      !record.hasReversal &&
      record.type != LedgerTransactionType.adjustment;
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(child: Text(amount, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
  );
}

String _date(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hms()
        .format(date.toLocal());

String _status(BuildContext context, BalanceCheckpoint item) {
  if (item.isVoided) return context.l10n.voidedCheckpoint;
  return item.isBalanced
      ? context.l10n.checkpointBalanced
      : context.l10n.checkpointUnbalanced;
}

String _errorMessage(BuildContext context, Object error) => switch (error) {
  ReconciliationException(error: ReconciliationError.changed) =>
    context.l10n.checkpointChanged,
  ReconciliationException(error: ReconciliationError.unavailable) =>
    context.l10n.checkpointUnavailable,
  TransactionRuleException() => localizedTransactionRule(context, error),
  _ => context.l10n.saveFailed,
};

String _recordTitle(BuildContext context, LedgerRecord record) =>
    switch (record.type) {
      LedgerTransactionType.expense when record.isRefund => context.l10n.refund,
      LedgerTransactionType.expense ||
      LedgerTransactionType.income => DefaultLedgerLabels.categoryName(
        Localizations.localeOf(context),
        record.categoryId,
        record.categoryName,
      ),
      LedgerTransactionType.transfer => context.l10n.transfer,
      LedgerTransactionType.borrowing => context.l10n.borrowing,
      LedgerTransactionType.repayment => context.l10n.repayment,
      LedgerTransactionType.lending => context.l10n.lending,
      LedgerTransactionType.advance => context.l10n.advance,
      LedgerTransactionType.collection => context.l10n.collection,
      LedgerTransactionType.reimbursement => context.l10n.reimbursement,
      LedgerTransactionType.adjustment => context.l10n.balanceAdjustment,
    };
