import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/features/planning/debt_contract_editor.dart';
import 'package:summa/features/planning/ledger_link_picker.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

class DebtContractsScreen extends ConsumerWidget {
  const DebtContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.debtContracts)),
      body: SafeArea(
        child: ref
            .watch(debtContractsProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(labels.debtLoadFailed),
                    TextButton(
                      onPressed: () => ref.invalidate(debtContractsProvider),
                      child: Text(labels.retry),
                    ),
                  ],
                ),
              ),
              data: (contracts) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DebtContractEditor(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(labels.debtAddContract),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (contracts.isEmpty) Text(labels.debtEmpty),
                  for (final contract in contracts)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          contract.draft.direction == DebtDirection.debt
                              ? Icons.receipt_long_outlined
                              : Icons.account_balance_wallet_outlined,
                        ),
                        title: Text(contract.draft.name),
                        subtitle: Text(
                          [
                            contract.draft.counterparty,
                            _balanceLabel(context, contract),
                            _balanceStatus(context, contract),
                          ].whereType<String>().join('\n'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _DebtDetails(
                              accountId: contract.draft.accountId,
                            ),
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

String _balanceLabel(BuildContext context, DebtContract contract) =>
    '${context.l10n.debtOutstandingPrincipal}  ${formatMoney(contract.balanceMinor, contract.draft.currency)}';

String? _balanceStatus(BuildContext context, DebtContract contract) =>
    switch (contract.balanceMinor) {
      0 => context.l10n.debtCleared,
      < 0 => context.l10n.debtBalanceReview,
      _ => null,
    };

class _DebtDetails extends ConsumerStatefulWidget {
  const _DebtDetails({required this.accountId});
  final String accountId;

  @override
  ConsumerState<_DebtDetails> createState() => _DebtDetailsState();
}

class _DebtDetailsState extends ConsumerState<_DebtDetails> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final contracts = ref.watch(debtContractsProvider);
    final contract = contracts.value
        ?.where((row) => row.draft.accountId == widget.accountId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(contract?.draft.name ?? labels.debtContracts)),
      body: SafeArea(
        child: contract != null
            ? _body(contract, contracts.value!)
            : contracts.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(labels.debtLoadFailed)),
      ),
    );
  }

  Widget _body(DebtContract contract, List<DebtContract> contracts) {
    final labels = context.l10n;
    final draft = contract.draft;
    final records = ref.watch(transactionsProvider);
    final title = Theme.of(context).textTheme.titleMedium;
    final currency = draft.currency;
    final receiving = draft.direction == DebtDirection.receivable;
    final principalAction = receiving
        ? labels.debtLinkCollection
        : labels.debtLinkRepayment;
    final status = _balanceStatus(context, contract);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(draft.counterparty, style: title),
        Text(
          DefaultLedgerLabels.accountName(
            Localizations.localeOf(context),
            draft.accountId,
            contract.accountName,
          ),
        ),
        const SizedBox(height: 12),
        Text(_balanceLabel(context, contract), style: title),
        if (status != null) Text(status),
        Text(
          '${labels.debtOriginalPrincipal}  ${formatMoney(draft.originalPrincipalMinor, currency)}',
        ),
        Text(
          '${labels.debtExpectedInterest}  ${formatMoney(draft.expectedInterestMinor, currency)}',
        ),
        Text('${labels.debtDueDate}  ${debtDateLabel(context, draft.dueOn)}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _saving || !records.hasValue
                  ? null
                  : () => _pick(
                      contract,
                      contracts,
                      records.value!,
                      DebtLinkKind.principal,
                      principalAction,
                    ),
              child: Text(principalAction),
            ),
            if (receiving)
              OutlinedButton(
                onPressed: _saving || !records.hasValue
                    ? null
                    : () => _pick(
                        contract,
                        contracts,
                        records.value!,
                        DebtLinkKind.interest,
                        labels.debtLinkInterest,
                      ),
                child: Text(labels.debtLinkInterest),
              ),
          ],
        ),
        const Divider(height: 32),
        ...records.when(
          loading: () => [const LinearProgressIndicator()],
          error: (_, _) => [
            TextButton(
              onPressed: () => ref.invalidate(transactionsProvider),
              child: Text(labels.retry),
            ),
          ],
          data: (items) =>
              _progress(summarizeDebtContract(contract, items), currency),
        ),
      ],
    );
  }

  List<Widget> _progress(DebtProgress progress, String currency) {
    final labels = context.l10n;
    final title = Theme.of(context).textTheme.titleMedium;
    final today = planningDay(DateTime.now());
    return [
      if (progress.unlinkedPrincipalMinor > BigInt.zero)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${labels.debtUnlinkedPrincipal}  ${formatMoneyTotal(progress.unlinkedPrincipalMinor, currency)}',
          ),
        ),
      Text(labels.debtSchedule, style: title),
      for (final row in progress.installments)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(debtDateLabel(context, row.installment.dueOn)),
          subtitle: Text(
            [
              '${labels.debtPrincipal} ${formatMoney(row.installment.principalMinor, currency)} · ${labels.interestAmount} ${formatMoney(row.installment.interestMinor, currency)}',
              '${labels.debtRemainingPrincipal} ${formatMoney(row.principalRemainingMinor, currency)}',
              '${labels.debtRemainingInterest} ${formatMoney(row.interestRemainingMinor, currency)}',
              if ((row.principalRemainingMinor > 0 ||
                      row.interestRemainingMinor > 0) &&
                  row.installment.dueOn.isBefore(today))
                labels.debtOverdue,
            ].join('\n'),
          ),
        ),
      const Divider(height: 32),
      Text(labels.debtHistory, style: title),
      if (progress.settlements.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(labels.debtNoHistory),
        ),
      for (final item in progress.settlements)
        _SettlementTile(
          settlement: item,
          currency: currency,
          onUndo: _saving || item.link.voided
              ? null
              : () => _undo(item.link.id),
        ),
    ];
  }

  Future<void> _pick(
    DebtContract contract,
    List<DebtContract> contracts,
    List<LedgerRecord> records,
    DebtLinkKind kind,
    String title,
  ) async {
    final linked = {
      for (final item in contracts)
        for (final link in item.links)
          if (!link.voided) link.entryId,
    };
    final chosen = await pickLedgerLink(
      context,
      title: title,
      emptyLabel: context.l10n.debtNoPayments,
      candidates: records
          .where(
            (row) =>
                !linked.contains(row.id) &&
                debtPaymentForRecord(contract.draft, kind, row) != null,
          )
          .toList(),
    );
    if (!mounted || chosen == null) return;
    await _mutate(
      () => ref
          .read(expenseRepositoryProvider)
          .linkDebtSettlement(contract.draft.accountId, chosen, kind),
    );
  }

  Future<void> _undo(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final labels = context.l10n;
        return AlertDialog(
          title: Text(labels.debtUnlinkTitle),
          content: Text(labels.debtUnlinkMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(labels.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(labels.debtUnlink),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;
    await _mutate(
      () => ref.read(expenseRepositoryProvider).unlinkDebtSettlement(id),
    );
  }

  Future<void> _mutate(Future<void> Function() change) async {
    setState(() => _saving = true);
    final labels = context.l10n;
    try {
      await change();
    } on DebtContractException catch (error) {
      if (mounted) {
        _message(switch (error.error) {
          DebtContractError.conflict => labels.debtConflict,
          DebtContractError.ineligible => labels.debtIneligible,
          _ => labels.saveFailed,
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

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({
    required this.settlement,
    required this.currency,
    required this.onUndo,
  });

  final DebtSettlement settlement;
  final String currency;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final record = settlement.record;
    final payment = settlement.payment;
    final voided = settlement.link.voided;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        record == null
            ? labels.recurringUnavailableEntry
            : linkedTransactionTitle(context, record),
      ),
      subtitle: Text(
        [
          if (record != null) debtDateLabel(context, record.occurredAt),
          if (payment != null) ...[
            '${labels.debtPrincipal} ${formatMoney(payment.principalMinor, currency)} · ${labels.interestAmount} ${formatMoney(payment.interestMinor, currency)}',
            if (payment.feeMinor > 0)
              '${labels.feeAmount} ${formatMoney(payment.feeMinor, currency)}',
            for (final row in settlement.allocations)
              '${debtDateLabel(context, row.dueOn)} · ${labels.debtPrincipal} ${formatMoney(row.principalMinor, currency)} · ${labels.interestAmount} ${formatMoney(row.interestMinor, currency)}',
          ] else if (voided)
            labels.debtVoidedLink
          else
            labels.debtInvalidatedLink,
        ].join('\n'),
      ),
      trailing: voided
          ? null
          : IconButton(
              tooltip: labels.debtUnlink,
              onPressed: onUndo,
              icon: const Icon(Icons.link_off),
            ),
    );
  }
}
