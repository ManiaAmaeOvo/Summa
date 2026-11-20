import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/analytics/ledger_history.dart';
import 'package:summa/features/dashboard/transaction_browser.dart';
import 'package:summa/l10n/l10n.dart';

class HistoricalAnalysisScreen extends ConsumerStatefulWidget {
  const HistoricalAnalysisScreen({
    super.key,
    this.initialCurrency,
    this.initialFilter = const LedgerFilter(),
  });

  final String? initialCurrency;
  final LedgerFilter initialFilter;

  @override
  ConsumerState<HistoricalAnalysisScreen> createState() =>
      _HistoricalAnalysisScreenState();
}

class _HistoricalAnalysisScreenState
    extends ConsumerState<HistoricalAnalysisScreen> {
  late String? _currency = widget.initialCurrency;
  var _interval = LedgerHistoryInterval.month;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.historicalAnalysis)),
      body: ref
          .watch(ledgerHistoryInputsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(ledgerHistoryInputsProvider),
                child: Text('${labels.reportReadFailed} ${labels.retry}'),
              ),
            ),
            data: _content,
          ),
    );
  }

  Widget _content(LedgerHistoryInputs input) {
    final labels = context.l10n;
    final options = currencyOptions([
      ...input.balances.map((item) => item.currencyCode),
      for (final record in input.transactions)
        ...ledgerRecordCurrencies(record),
    ]);
    final currency = options.contains(_currency) ? _currency! : options.first;
    final filter = widget.initialFilter;
    final today = DateTime.now();
    final points = analyzeLedgerHistory(
      input,
      today: today,
      currency: currency,
      interval: _interval,
      filter: filter,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (options.length > 1) ...[
          CurrencySelector(
            currencies: options,
            value: currency,
            label: labels.summaryCurrency,
            onChanged: (value) => setState(() => _currency = value),
          ),
          const SizedBox(height: 8),
        ],
        SegmentedButton<LedgerHistoryInterval>(
          segments: [
            ButtonSegment(
              value: LedgerHistoryInterval.month,
              label: Text(labels.periodMonth),
            ),
            ButtonSegment(
              value: LedgerHistoryInterval.year,
              label: Text(labels.periodYear),
            ),
          ],
          selected: {_interval},
          onSelectionChanged: (values) =>
              setState(() => _interval = values.single),
        ),
        if (filter.isActive)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(labels.historyFilterHint),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            labels.historyMethod,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (var i = points.length - 1; i > 0; i--)
          _PeriodCard(
            key: ValueKey(points[i].range.start),
            point: points[i],
            previous: points[i - 1],
            interval: _interval,
            inProgress: i == points.length - 1,
            currency: currency,
            onOpen: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => LedgerDrilldownScreen(
                  filter: filter.scoped(
                    range: points[i].range,
                    currency: currency,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    super.key,
    required this.point,
    required this.previous,
    required this.interval,
    required this.inProgress,
    required this.currency,
    required this.onOpen,
  });

  final LedgerHistoryPoint point;
  final LedgerHistoryPoint previous;
  final LedgerHistoryInterval interval;
  final bool inProgress;
  final String currency;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = interval == LedgerHistoryInterval.month
        ? DateFormat.yMMM(locale)
        : DateFormat.y(locale);
    final material = MaterialLocalizations.of(context);
    final activity = point.analysis.activity;
    final prior = previous.analysis.activity;
    final cash = activity.personalCashInflow - activity.personalCashOutflow;
    final priorCash = prior.personalCashInflow - prior.personalCashOutflow;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: inProgress,
        title: Text(date.format(point.range.start)),
        subtitle: Text(
          '${labels.historyNetWorth} · ${formatMoneyTotal(point.netWorthMinor, currency)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inProgress)
            Text(
              labels.historyThroughDate(
                material.formatShortDate(
                  point.range.endExclusive.subtract(
                    const Duration(milliseconds: 1),
                  ),
                ),
              ),
            ),
          for (final (label, value, old) in [
            (
              labels.historyNetWorth,
              point.netWorthMinor,
              previous.netWorthMinor,
            ),
            (
              labels.income,
              point.analysis.incomeMinor,
              previous.analysis.incomeMinor,
            ),
            (labels.grossSpending, activity.grossSpending, prior.grossSpending),
            (
              labels.personalSpending,
              activity.personalSpending,
              prior.personalSpending,
            ),
            (labels.personalCashFlowNet, cash, priorCash),
          ])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoneyTotal(value, currency),
                          textAlign: TextAlign.end,
                        ),
                        Text(
                          labels.historyPreviousDifference(
                            _signed(value - old),
                          ),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(labels.reportTransactions),
          ),
        ],
      ),
    );
  }

  String _signed(BigInt value) =>
      '${value > BigInt.zero ? '+' : ''}${formatMoneyTotal(value, currency)}';
}
