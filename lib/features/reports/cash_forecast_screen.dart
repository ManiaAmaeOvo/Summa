import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/analytics/cash_forecast.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/features/planning/ledger_link_picker.dart';
import 'package:summa/l10n/l10n.dart';

class CashForecastScreen extends ConsumerStatefulWidget {
  const CashForecastScreen({super.key});

  @override
  ConsumerState<CashForecastScreen> createState() => _CashForecastScreenState();
}

class _CashForecastScreenState extends ConsumerState<CashForecastScreen> {
  static const _horizons = [7, 30, 90];
  int _horizon = 30;
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final inputs = ref.watch(cashForecastInputsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(labels.cashForecast)),
      body: SafeArea(
        child: inputs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labels.cashForecastReadFailed),
                TextButton(
                  onPressed: () => ref.invalidate(cashForecastInputsProvider),
                  child: Text(labels.retry),
                ),
              ],
            ),
          ),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(CashForecastInputs input) {
    final labels = context.l10n;
    final options = currencyOptions(input.currencies);
    final currency = options.contains(_currency) ? _currency! : options.first;
    final forecast = forecastCash(
      input,
      currency: currency,
      today: DateTime.now(),
      horizonDays: _horizon,
    );
    final activeDays = forecast.days.where((day) => day.events.isNotEmpty);
    final title = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CurrencySelector(
          currencies: options,
          value: currency,
          label: labels.summaryCurrency,
          onChanged: options.length > 1
              ? (value) => setState(() => _currency = value)
              : null,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final days in _horizons)
              ChoiceChip(
                label: Text(labels.forecastRangeDays(days)),
                selected: _horizon == days,
                onSelected: (selected) {
                  if (selected) setState(() => _horizon = days);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ForecastSummary(forecast: forecast, currency: currency),
        const SizedBox(height: 8),
        _BalanceChart(forecast: forecast),
        ExpansionTile(
          title: Text(labels.forecastAssumptions),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text(labels.forecastAssumptionsText)],
        ),
        if (forecast.unscheduledPrincipal.isNotEmpty)
          ExpansionTile(
            title: Text(labels.forecastUnscheduledPrincipal),
            initiallyExpanded: true,
            children: [
              for (final item in forecast.unscheduledPrincipal)
                ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    item.direction == DebtDirection.debt
                        ? labels.forecastDebtRepayment
                        : labels.forecastReceivableCollection,
                  ),
                  trailing: Text(formatMoneyTotal(item.amountMinor, currency)),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text(labels.forecastCashMovements, style: title),
        if (activeDays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(labels.forecastNoMovements),
          ),
        for (final day in activeDays)
          _ForecastDayCard(day: day, currency: currency),
      ],
    );
  }
}

class _ForecastSummary extends StatelessWidget {
  const _ForecastSummary({required this.forecast, required this.currency});

  final CashForecast forecast;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final theme = Theme.of(context);
    final firstGap = forecast.firstShortfall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.forecastPostedBalance),
            Text(
              formatMoneyTotal(forecast.openingMinor, currency),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(labels.forecastClosingBalance),
            Text(
              formatMoneyTotal(forecast.closingMinor, currency),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (firstGap == null)
              Text(labels.forecastNoShortfall)
            else ...[
              Text(
                '${labels.forecastPeakShortfall}  ${formatMoneyTotal(forecast.peakShortfallMinor, currency)}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              Text(
                labels.forecastFirstShortfall(_date(context, firstGap.date)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  const _ForecastDayCard({required this.day, required this.currency});

  final CashForecastDay day;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_date(context, day.date), style: theme.textTheme.titleMedium),
            Text(
              '${labels.forecastDailyClosing}  ${formatMoneyTotal(day.closingMinor, currency)}',
              style: day.closingMinor.isNegative
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            for (final event in day.events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  event.record == null
                      ? event.name
                      : linkedTransactionTitle(context, event.record!),
                ),
                subtitle: Text(
                  [
                    cashForecastSourceLabel(context, event.source),
                    if (event.dueOn.isBefore(day.date))
                      labels.forecastOverdueSince(_date(context, event.dueOn)),
                    if (event.overdueCycles > 1)
                      labels.forecastOverdueCycles(event.overdueCycles),
                    if (!event.included) labels.forecastUncertainInflow,
                  ].join('\n'),
                ),
                trailing: Text(
                  '${event.changeMinor.isNegative ? '' : '+'}${formatMoneyTotal(event.changeMinor, currency)}',
                  style: event.included
                      ? null
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String cashForecastSourceLabel(
  BuildContext context,
  CashForecastSource source,
) {
  final labels = context.l10n;
  return switch (source) {
    CashForecastSource.recurringIncome => labels.forecastScheduled(
      labels.forecastRecurringIncome,
    ),
    CashForecastSource.recurringExpense => labels.forecastScheduled(
      labels.forecastRecurringExpense,
    ),
    CashForecastSource.subscription => labels.forecastScheduled(
      labels.forecastSubscription,
    ),
    CashForecastSource.debtRepayment => labels.forecastScheduled(
      labels.forecastDebtRepayment,
    ),
    CashForecastSource.receivableCollection => labels.forecastScheduled(
      labels.forecastReceivableCollection,
    ),
    CashForecastSource.futurePosted => labels.forecastFuturePosted,
  };
}

String _date(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);

class _BalanceChart extends StatelessWidget {
  const _BalanceChart({required this.forecast});

  final CashForecast forecast;

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.forecastBalanceOverTime;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomPaint(
                painter: _BalancePainter(
                  amounts: [
                    forecast.openingMinor,
                    for (final day in forecast.days) day.closingMinor,
                  ],
                  line: theme.colorScheme.primary,
                  zero: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_date(context, forecast.days.first.date)),
                Text(_date(context, forecast.days.last.date)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancePainter extends CustomPainter {
  const _BalancePainter({
    required this.amounts,
    required this.line,
    required this.zero,
  });

  final List<BigInt> amounts;
  final Color line;
  final Color zero;

  @override
  void paint(Canvas canvas, Size size) {
    var min = BigInt.zero;
    var max = BigInt.zero;
    for (final amount in amounts) {
      if (amount < min) min = amount;
      if (amount > max) max = amount;
    }
    final span = max == min ? 1.0 : (max - min).toDouble();
    final plot = Rect.fromLTWH(1, 2, size.width - 2, size.height - 4);
    double ordinate(BigInt amount) =>
        plot.bottom - plot.height * (amount - min).toDouble() / span;

    final zeroY = ordinate(BigInt.zero);
    canvas.drawLine(
      Offset(plot.left, zeroY),
      Offset(plot.right, zeroY),
      Paint()..color = zero,
    );
    final path = Path()..moveTo(plot.left, ordinate(amounts.first));
    for (var i = 1; i < amounts.length; i++) {
      final dx = plot.left + plot.width * i / (amounts.length - 1);
      path.lineTo(dx, ordinate(amounts[i - 1]));
      path.lineTo(dx, ordinate(amounts[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BalancePainter oldDelegate) =>
      !listEquals(amounts, oldDelegate.amounts) ||
      line != oldDelegate.line ||
      zero != oldDelegate.zero;
}
