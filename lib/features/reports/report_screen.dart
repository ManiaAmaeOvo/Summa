import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/ledger_export.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/features/analysis/ledger_filter_control.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

enum _ReportPeriod { day, week, month, year }

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    this.initialFilter = const LedgerFilter(),
    this.initialCurrency,
  });

  final LedgerFilter initialFilter;
  final String? initialCurrency;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  _ReportPeriod _period = _ReportPeriod.month;
  DateTime _anchor = DateTime.now();
  late String? _currency = widget.initialCurrency;
  late LedgerFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(transactionsProvider);
    final balances = ref.watch(accountBalancesProvider).asData?.value;
    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(context.l10n.reportReadFailed)),
      data: (all) {
        if (balances == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final custom = _filter.range;
        final range = custom == null
            ? _rangeFor(_period, _anchor)
            : _DateRange(custom.start, custom.endExclusive);
        final filter = LedgerFilter(
          range: (start: range.start, endExclusive: range.end),
          accountId: _filter.accountId,
          categoryId: _filter.categoryId,
          funding: _filter.funding,
        );
        final posted = all
            .where((item) => !item.isPending)
            .toList(growable: false);
        final currencies = currencyOptions([
          ...balances.map((account) => account.currencyCode),
          for (final record in posted) ...ledgerRecordCurrencies(record),
        ]);
        final currency = currencies.contains(_currency)
            ? _currency!
            : currencies.first;
        final periodRecords = posted
            .where(
              (item) =>
                  !item.occurredAt.isBefore(range.start) &&
                  item.occurredAt.isBefore(range.end),
            )
            .toList(growable: false);
        final analysis = analyzeLedger(posted, currency, filter);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (currencies.length > 1) ...[
              CurrencySelector(
                currencies: currencies,
                value: currency,
                label: context.l10n.summaryCurrency,
                onChanged: (code) => setState(() => _currency = code),
              ),
              const SizedBox(height: 12),
            ],
            LedgerFilterControl(
              filter: _filter,
              records: posted,
              balances: balances,
              forReport: true,
              onChanged: (value) => setState(() => _filter = value),
            ),
            if (custom == null) ...[
              SegmentedButton<_ReportPeriod>(
                segments: [
                  ButtonSegment(
                    value: _ReportPeriod.day,
                    label: Text(context.l10n.periodDay),
                  ),
                  ButtonSegment(
                    value: _ReportPeriod.week,
                    label: Text(context.l10n.periodWeek),
                  ),
                  ButtonSegment(
                    value: _ReportPeriod.month,
                    label: Text(context.l10n.periodMonth),
                  ),
                  ButtonSegment(
                    value: _ReportPeriod.year,
                    label: Text(context.l10n.periodYear),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (value) => setState(() {
                  _period = value.single;
                  _anchor = DateTime.now();
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _anchor = _shift(-1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      _rangeLabel(context, _period, range),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _anchor = _shift(1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _SummaryGrid(analysis: analysis, currency: currency),
            const SizedBox(height: 16),
            _FundingSummary(currency: currency, activity: analysis.activity),
            if (analysis.accountFlows.isNotEmpty)
              _AccountFlowCard(
                flows: analysis.accountFlows,
                currency: currency,
              ),
            if (_filter.hasDimensions)
              ExpansionTile(
                title: Text(context.l10n.ledgerFiltersActive),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(context.l10n.ledgerFilterAllocationHint)],
              ),
            const SizedBox(height: 16),
            _TrendCard(
              points: analysis.spending,
              period: _period,
              currency: currency,
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: context.l10n.expenseCategories,
              emptyText: context.l10n.noExpenseCategoryData,
              rows: analysis.expenseCategories,
              currency: currency,
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: context.l10n.incomeCategories,
              emptyText: context.l10n.noIncomeCategoryData,
              rows: analysis.incomeCategories,
              currency: currency,
            ),
            if (_filter.categoryId == null && _filter.funding == null) ...[
              const SizedBox(height: 16),
              _DebtTrendCard(
                allRecords: posted,
                selectedRecords: periodRecords,
                balances: balances
                    .where(
                      (item) =>
                          item.currencyCode == currency &&
                          (_filter.accountId == null ||
                              _filter.accountId == item.id),
                    )
                    .toList(),
                currency: currency,
                range: range,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ExportDialog(records: all),
              ),
              icon: const Icon(Icons.ios_share),
              label: Text(context.l10n.exportTransactions),
            ),
          ],
        );
      },
    );
  }

  DateTime _shift(int amount) => switch (_period) {
    _ReportPeriod.day => _anchor.add(Duration(days: amount)),
    _ReportPeriod.week => _anchor.add(Duration(days: 7 * amount)),
    _ReportPeriod.month => DateTime(_anchor.year, _anchor.month + amount, 1),
    _ReportPeriod.year => DateTime(_anchor.year + amount, 1, 1),
  };
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.analysis, required this.currency});

  final LedgerAnalysis analysis;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final activity = analysis.activity;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 104,
      children: [
        _Metric(
          label: context.l10n.income,
          text: formatMoneyTotal(analysis.incomeMinor, currency),
        ),
        _Metric(
          label: context.l10n.grossSpending,
          text: formatMoneyTotal(activity.grossSpending, currency),
        ),
        _Metric(
          label: context.l10n.personalCashFlowNet,
          text: formatMoneyTotal(
            activity.personalCashInflow - activity.personalCashOutflow,
            currency,
          ),
        ),
        _Metric(
          label: context.l10n.borrowingRepayment,
          text:
              '${formatMoneyTotal(analysis.borrowingMinor, currency)} / ${formatMoneyTotal(analysis.repaymentMinor, currency)}',
        ),
      ],
    );
  }
}

class _FundingSummary extends StatelessWidget {
  const _FundingSummary({required this.currency, required this.activity});

  final String currency;
  final FinancialActivity activity;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final lines = [
      (labels.personalSpending, activity.personalSpending),
      (labels.familyDirectFunding, activity.familyDirectSpending),
      (labels.entrustedSpending, activity.entrustedSpending),
      if (activity.thirdPartyPayableSpending != BigInt.zero)
        (labels.thirdPartyPayableSpending, activity.thirdPartyPayableSpending),
      if (activity.unclassifiedSpending != BigInt.zero)
        (labels.unclassifiedSpending, activity.unclassifiedSpending),
      if (activity.familySupportReceived != BigInt.zero)
        (labels.familySupportReceived, activity.familySupportReceived),
      (labels.personalCashInflow, activity.personalCashInflow),
      (labels.personalCashOutflow, activity.personalCashOutflow),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              labels.fundingAndCashFlow,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final (label, amount) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    const SizedBox(width: 8),
                    Text(formatMoneyTotal(amount, currency)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountFlowCard extends StatelessWidget {
  const _AccountFlowCard({required this.flows, required this.currency});

  final List<AnalysisAccountFlow> flows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final locale = Localizations.localeOf(context);
    return Card(
      child: ExpansionTile(
        title: Text(labels.ledgerFilterAccountCashFlow),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labels.ledgerFilterAccountCashFlowHint),
          for (final row in flows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                DefaultLedgerLabels.accountName(locale, row.id, row.name),
              ),
              subtitle: Text(
                [
                  '${labels.personalCashInflow}  ${formatMoneyTotal(row.inflowMinor, currency)}',
                  '${labels.personalCashOutflow}  ${formatMoneyTotal(row.outflowMinor, currency)}',
                ].join('\n'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Card.filled(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.points,
    required this.currency,
    required this.period,
  });

  final List<AnalysisSpendingPoint> points;
  final _ReportPeriod period;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final buckets = <DateTime, BigInt>{};
    for (final item in points) {
      final date = item.date;
      final key = period == _ReportPeriod.year
          ? DateTime(date.year, date.month)
          : DateTime(date.year, date.month, date.day);
      buckets.update(
        key,
        (sum) => sum + item.amountMinor,
        ifAbsent: () => item.amountMinor,
      );
    }
    final timeline = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.expenseTrend,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: timeline.isEmpty
                  ? Center(child: Text(context.l10n.noExpensesThisPeriod))
                  : CustomPaint(
                      painter: _TrendPainter(
                        currency: currency,
                        values: timeline
                            .map((e) => e.value.toDouble())
                            .toList(),
                        xLabels: _axisDateLabels(
                          timeline.map((e) => e.key).toList(),
                          context,
                          useMonths: period == _ReportPeriod.year,
                        ),
                        lineColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                        labelColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        textDirection: Directionality.of(context),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.currency,
    required this.xLabels,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.textDirection,
  });

  final List<num> values;
  final String currency;
  final List<String> xLabels;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const leftAxisWidth = 52.0;
    const bottomAxisHeight = 26.0;
    const topPadding = 8.0;
    const rightPadding = 8.0;
    final plot = Rect.fromLTRB(
      leftAxisWidth,
      topPadding,
      size.width - rightPadding,
      size.height - bottomAxisHeight,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: .28),
          lineColor.withValues(alpha: .02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(plot);
    var minValue = 0.0;
    var maxValue = 0.0;
    for (final value in values) {
      minValue = math.min(minValue, value.toDouble());
      maxValue = math.max(maxValue, value.toDouble());
    }
    if (maxValue == minValue) maxValue = 1;
    final span = maxValue - minValue;
    final zeroY = plot.bottom + plot.height * minValue / span;

    for (var tick = 0; tick < 3; tick++) {
      final fraction = tick / 2;
      final y = plot.top + plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final value = maxValue - span * fraction;
      _paintAxisLabel(
        canvas,
        _compactAxisAmount(value, currency),
        Offset(plot.left - 6, y),
        alignRight: true,
        centerVertically: true,
      );
    }
    canvas.drawLine(plot.topLeft, plot.bottomLeft, gridPaint);

    final path = Path();
    final offsets = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? plot.center.dx
          : plot.left + plot.width * i / (values.length - 1);
      final y = plot.bottom - plot.height * (values[i] - minValue) / span;
      offsets.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (offsets.length > 1) {
      final area = Path.from(path)
        ..lineTo(offsets.last.dx, zeroY)
        ..lineTo(offsets.first.dx, zeroY)
        ..close();
      canvas.drawPath(area, fill);
      canvas.drawPath(path, linePaint);
    } else {
      canvas.drawCircle(offsets.single, 3.5, Paint()..color = lineColor);
    }

    for (var i = 0; i < xLabels.length; i++) {
      if (xLabels[i].isEmpty) continue;
      final x = xLabels.length == 1
          ? plot.center.dx
          : plot.left + plot.width * i / (xLabels.length - 1);
      _paintAxisLabel(
        canvas,
        xLabels[i],
        Offset(x, plot.bottom + 6),
        centerHorizontally: true,
      );
    }
  }

  void _paintAxisLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool centerHorizontally = false,
    bool centerVertically = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    var dx = anchor.dx;
    var dy = anchor.dy;
    if (alignRight) dx -= painter.width;
    if (centerHorizontally) dx -= painter.width / 2;
    if (centerVertically) dy -= painter.height / 2;
    final maxWidth = canvas.getLocalClipBounds().width;
    dx = dx.clamp(0.0, math.max(0.0, maxWidth - painter.width)).toDouble();
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.currency != currency ||
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.xLabels, xLabels) ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.textDirection != textDirection;
}

List<String> _axisDateLabels(
  List<DateTime> dates,
  BuildContext context, {
  required bool useMonths,
}) {
  if (dates.isEmpty) return const [];
  final locale = Localizations.localeOf(context).toLanguageTag();
  final format = useMonths ? DateFormat.MMM(locale) : DateFormat.Md(locale);
  final visibleIndices = <int>{0, dates.length ~/ 2, dates.length - 1};
  return [
    for (var index = 0; index < dates.length; index++)
      visibleIndices.contains(index) ? format.format(dates[index]) : '',
  ];
}

String _compactAxisAmount(num minor, String currency) {
  final digits = currencyMinorDigits[currency] ?? 0;
  final amount = minor / math.pow(10, digits);
  final compact = NumberFormat.compact(locale: 'en').format(amount);
  return currency == defaultCurrency ? '¥$compact' : compact;
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({
    required this.title,
    required this.emptyText,
    required this.rows,
    required this.currency,
  });

  final String title;
  final String emptyText;
  final List<AnalysisBreakdown> rows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]
      ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    final total = sorted.fold(BigInt.zero, (sum, row) => sum + row.amountMinor);
    final showPie =
        total > BigInt.zero &&
        sorted.every((row) => !row.amountMinor.isNegative);
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.error,
      Colors.teal,
      Colors.amber.shade700,
      Colors.indigo,
      Colors.pink,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              SizedBox(height: 120, child: Center(child: Text(emptyText)))
            else ...[
              if (showPie) ...[
                Center(
                  child: SizedBox.square(
                    dimension: 176,
                    child: CustomPaint(
                      painter: _PiePainter(
                        values: sorted.map((row) => row.amountMinor).toList(),
                        colors: colors,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              for (var index = 0; index < sorted.length; index++) ...[
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DefaultLedgerLabels.categoryName(
                          Localizations.localeOf(context),
                          sorted[index].id,
                          sorted[index].name,
                        ),
                      ),
                    ),
                    Text(
                      '${showPie ? '${(sorted[index].amountMinor.toDouble() * 100 / total.toDouble()).toStringAsFixed(1)}%  ' : ''}'
                      '${formatMoneyTotal(sorted[index].amountMinor, currency)}',
                    ),
                  ],
                ),
                if (index != sorted.length - 1) const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({required this.values, required this.colors});

  final List<BigInt> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(BigInt.zero, (sum, value) => sum + value);
    var start = -math.pi / 2;
    final rect = Offset.zero & size;
    for (var index = 0; index < values.length; index++) {
      final sweep = math.pi * 2 * values[index].toDouble() / total.toDouble();
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        true,
        Paint()..color = colors[index % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

class _DebtTrendCard extends StatelessWidget {
  const _DebtTrendCard({
    required this.allRecords,
    required this.selectedRecords,
    required this.balances,
    required this.range,
    required this.currency,
  });

  final List<LedgerRecord> allRecords;
  final List<LedgerRecord> selectedRecords;
  final List<AccountBalance> balances;
  final _DateRange range;

  final String currency;

  @override
  Widget build(BuildContext context) {
    final liabilityIds = balances
        .where((item) => item.group == AccountGroup.liability)
        .map((item) => item.id)
        .toSet();
    final current = balances
        .where((item) => item.group == AccountGroup.liability)
        .fold<int>(0, (sum, item) => sum + item.currentBalanceMinor);
    final opening = allRecords
        .where((record) => !record.occurredAt.isBefore(range.start))
        .fold(
          current,
          (balance, record) =>
              balance - _liabilityDelta(record, liabilityIds, currency),
        );
    final ordered =
        selectedRecords
            .where((item) => _liabilityDelta(item, liabilityIds, currency) != 0)
            .toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final values = <int>[opening];
    final dates = <DateTime>[range.start];
    var running = opening;
    for (final record in ordered) {
      running += _liabilityDelta(record, liabilityIds, currency);
      values.add(running);
      dates.add(record.occurredAt);
    }
    final closingDate = range.end.subtract(const Duration(milliseconds: 1));
    if (dates.last != closingDate) {
      values.add(running);
      dates.add(closingDate);
    }
    final hasLiabilityData =
        liabilityIds.isNotEmpty ||
        ordered.any(
          (item) => _liabilityDelta(item, liabilityIds, currency) != 0,
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.liabilityTrend,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  context.l10n.closingAmount(formatMoney(running, currency)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: !hasLiabilityData
                  ? Center(child: Text(context.l10n.noLiabilityData))
                  : CustomPaint(
                      painter: _TrendPainter(
                        currency: currency,
                        values: values,
                        xLabels: _axisDateLabels(
                          dates,
                          context,
                          useMonths:
                              range.end.difference(range.start).inDays > 200,
                        ),
                        lineColor: Theme.of(context).colorScheme.error,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                        labelColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        textDirection: Directionality.of(context),
                      ),
                    ),
            ),
            if (hasLiabilityData)
              Text(
                context.l10n.liabilityRangeSummary(
                  formatMoney(opening, currency),
                  formatMoney(current, currency),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

int _liabilityDelta(
  LedgerRecord record,
  Set<String> liabilityIds,
  String currency,
) => record.accountPostings
    .where(
      (posting) =>
          posting.currencyCode == currency &&
          liabilityIds.contains(posting.accountId),
    )
    .fold(0, (balance, posting) => balance - posting.debitMinor);

enum _ExportRange { week, month, year, all, custom }

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.records});
  final List<LedgerRecord> records;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  LedgerExportFormat _format = LedgerExportFormat.json;
  _ExportRange _range = _ExportRange.month;
  DateTimeRange? _custom;
  var _saving = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.exportTransactions),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<_ExportRange>(
          initialValue: _range,
          decoration: InputDecoration(labelText: context.l10n.timeRange),
          items: [
            DropdownMenuItem(
              value: _ExportRange.week,
              child: Text(context.l10n.thisWeek),
            ),
            DropdownMenuItem(
              value: _ExportRange.month,
              child: Text(context.l10n.thisMonth),
            ),
            DropdownMenuItem(
              value: _ExportRange.year,
              child: Text(context.l10n.thisYear),
            ),
            DropdownMenuItem(
              value: _ExportRange.all,
              child: Text(context.l10n.allTime),
            ),
            DropdownMenuItem(
              value: _ExportRange.custom,
              child: Text(context.l10n.customRange),
            ),
          ],
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _range = value);
            if (value == _ExportRange.custom) {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _custom = picked);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LedgerExportFormat>(
          initialValue: _format,
          decoration: InputDecoration(labelText: context.l10n.fileFormat),
          items: [
            DropdownMenuItem(
              value: LedgerExportFormat.json,
              child: Text(context.l10n.jsonFormatDescription),
            ),
            DropdownMenuItem(
              value: LedgerExportFormat.csv,
              child: Text(context.l10n.csvFormatDescription),
            ),
            DropdownMenuItem(
              value: LedgerExportFormat.markdown,
              child: Text(context.l10n.markdownFormatDescription),
            ),
          ],
          onChanged: (value) => setState(() => _format = value!),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: _saving ? null : _export,
        child: Text(_saving ? context.l10n.preparing : context.l10n.export),
      ),
    ],
  );

  Future<void> _export() async {
    if (_range == _ExportRange.custom && _custom == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final range = switch (_range) {
      _ExportRange.week => _rangeFor(_ReportPeriod.week, now),
      _ExportRange.month => _rangeFor(_ReportPeriod.month, now),
      _ExportRange.year => _rangeFor(_ReportPeriod.year, now),
      _ExportRange.all => null,
      _ExportRange.custom => _DateRange(
        _custom!.start,
        _custom!.end.add(const Duration(days: 1)),
      ),
    };
    final selected = range == null
        ? widget.records
        : widget.records
              .where(
                (item) =>
                    !item.occurredAt.isBefore(range.start) &&
                    item.occurredAt.isBefore(range.end),
              )
              .toList();
    final content = exportLedgerRecords(
      selected,
      _format,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final extension = switch (_format) {
      LedgerExportFormat.json => 'json',
      LedgerExportFormat.csv => 'csv',
      LedgerExportFormat.markdown => 'md',
    };
    final mime = switch (_format) {
      LedgerExportFormat.json => 'application/json',
      LedgerExportFormat.csv => 'text/csv',
      LedgerExportFormat.markdown => 'text/markdown',
    };
    final name = 'summa-${DateFormat('yyyyMMdd-HHmm').format(now)}.$extension';
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(content), mimeType: mime)],
        fileNameOverrides: [name],
        subject: context.l10n.transactionExportSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

_DateRange _rangeFor(_ReportPeriod period, DateTime anchor) {
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  return switch (period) {
    _ReportPeriod.day => _DateRange(day, day.add(const Duration(days: 1))),
    _ReportPeriod.week => _DateRange(
      day.subtract(Duration(days: anchor.weekday - 1)),
      day
          .subtract(Duration(days: anchor.weekday - 1))
          .add(const Duration(days: 7)),
    ),
    _ReportPeriod.month => _DateRange(
      DateTime(anchor.year, anchor.month),
      DateTime(anchor.year, anchor.month + 1),
    ),
    _ReportPeriod.year => _DateRange(
      DateTime(anchor.year),
      DateTime(anchor.year + 1),
    ),
  };
}

String _rangeLabel(
  BuildContext context,
  _ReportPeriod period,
  _DateRange range,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return switch (period) {
    _ReportPeriod.day => DateFormat.yMMMMd(locale).format(range.start),
    _ReportPeriod.week =>
      '${DateFormat.MMMd(locale).format(range.start)} – '
          '${DateFormat.MMMd(locale).format(range.end.subtract(const Duration(days: 1)))}',
    _ReportPeriod.month => DateFormat.yMMMM(locale).format(range.start),
    _ReportPeriod.year => DateFormat.y(locale).format(range.start),
  };
}
