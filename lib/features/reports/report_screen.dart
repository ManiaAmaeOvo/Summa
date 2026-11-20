import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/app/widgets/ledger_surfaces.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/analytics/financial_report.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/ledger_export.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/features/analysis/ledger_filter_control.dart';
import 'package:summa/features/dashboard/transaction_browser.dart';
import 'package:summa/features/reports/financial_report_export_dialog.dart';
import 'package:summa/features/reports/historical_analysis_screen.dart';
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
  late String? _currency =
      widget.initialCurrency ?? widget.initialFilter.currency;
  late LedgerFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final inputs = ref.watch(ledgerHistoryInputsProvider);
    return inputs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(ledgerHistoryInputsProvider),
          child: Text(
            '${context.l10n.reportReadFailed} · ${context.l10n.retry}',
          ),
        ),
      ),
      data: (input) {
        final all = input.transactions;
        final balances = input.balances
            .where((account) => account.archivedAt == null)
            .toList(growable: false);
        final custom = _filter.range;
        final range = custom == null
            ? _rangeFor(_period, _anchor)
            : _DateRange(custom.start, custom.endExclusive);
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
        final report = FinancialReport(
          records: posted,
          balances: balances,
          range: (start: range.start, endExclusive: range.end),
          currency: currency,
          filter: _filter,
          monthlyTimeline: custom == null && _period == _ReportPeriod.year,
        );
        final filter = report.filter;
        final analysis = report.analysis;
        void openTransactions(LedgerFilter selected) => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => LedgerDrilldownScreen(filter: selected),
          ),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (custom == null) ...[
                      LedgerChoiceBar<_ReportPeriod>(
                        options: {
                          _ReportPeriod.day: context.l10n.periodDay,
                          _ReportPeriod.week: context.l10n.periodWeek,
                          _ReportPeriod.month: context.l10n.periodMonth,
                          _ReportPeriod.year: context.l10n.periodYear,
                        },
                        selected: _period,
                        onChanged: (value) => setState(() {
                          _period = value;
                          _anchor = DateTime.now();
                        }),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: context.l10n.previousReportPeriod,
                            onPressed: () =>
                                setState(() => _anchor = _shift(-1)),
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
                            tooltip: context.l10n.nextReportPeriod,
                            onPressed: () =>
                                setState(() => _anchor = _shift(1)),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                    if (currencies.length > 1)
                      CurrencySelector(
                        currencies: currencies,
                        value: currency,
                        label: context.l10n.summaryCurrency,
                        onChanged: (code) => setState(() => _currency = code),
                      ),
                    LedgerFilterControl(
                      filter: _filter,
                      records: posted,
                      balances: balances,
                      forReport: true,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => FinancialReportExportDialog(report: report),
                ),
                icon: const Icon(Icons.file_download_outlined),
                label: Text(context.l10n.exportFinancialReport),
              ),
            ),
            const SizedBox(height: 8),
            _SummaryGrid(analysis: analysis, currency: currency),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => openTransactions(filter),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(context.l10n.reportTransactions),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoricalAnalysisScreen(
                        initialCurrency: currency,
                        initialFilter: _filter,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                  label: Text(context.l10n.historicalAnalysis),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FundingSummary(currency: currency, activity: analysis.activity),
            if (analysis.accountFlows.isNotEmpty) ...[
              const SizedBox(height: 10),
              _AccountFlowCard(
                flows: analysis.accountFlows,
                currency: currency,
                onOpen: (id) => openTransactions(filter.scoped(accountId: id)),
              ),
            ],
            if (_filter.hasDimensions)
              ExpansionTile(
                title: Text(context.l10n.ledgerFiltersActive),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(context.l10n.ledgerFilterAllocationHint)],
              ),
            const SizedBox(height: 16),
            _TrendCard(
              timeline: report.spendingTimeline,
              monthly: report.monthlyTimeline,
              currency: currency,
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: context.l10n.expenseCategories,
              emptyText: context.l10n.noExpenseCategoryData,
              rows: analysis.expenseCategories,
              currency: currency,
              onOpen: (id) => openTransactions(filter.scoped(categoryId: id)),
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: context.l10n.incomeCategories,
              emptyText: context.l10n.noIncomeCategoryData,
              rows: analysis.incomeCategories,
              currency: currency,
              onOpen: (id) => openTransactions(filter.scoped(categoryId: id)),
            ),
            if (report.position case final position?) ...[
              const SizedBox(height: 16),
              _PositionCard(position: position, currency: currency),
              const SizedBox(height: 10),
              _DebtTrendCard(
                position: position,
                useMonths: range.end.difference(range.start).inDays > 200,
                currency: currency,
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
    _ReportPeriod.day => _calendarOffset(_anchor, amount),
    _ReportPeriod.week => _calendarOffset(_anchor, 7 * amount),
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
    return LedgerMetricGrid(
      children: [
        LedgerMetricCard(
          label: context.l10n.income,
          value: formatMoneyTotal(analysis.incomeMinor, currency),
        ),
        LedgerMetricCard(
          label: context.l10n.grossSpending,
          value: formatMoneyTotal(activity.grossSpending, currency),
        ),
        LedgerMetricCard(
          label: context.l10n.personalCashFlowNet,
          value: formatMoneyTotal(
            activity.personalCashInflow - activity.personalCashOutflow,
            currency,
          ),
        ),
        LedgerMetricCard(
          label: context.l10n.borrowingRepayment,
          value:
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
                child: LedgerValueRow(
                  label: label,
                  value: formatMoneyTotal(amount, currency),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountFlowCard extends StatelessWidget {
  const _AccountFlowCard({
    required this.flows,
    required this.currency,
    required this.onOpen,
  });

  final List<AnalysisAccountFlow> flows;
  final String currency;
  final ValueChanged<String> onOpen;

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
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(row.id),
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

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.timeline,
    required this.currency,
    required this.monthly,
  });

  final List<AnalysisSpendingPoint> timeline;
  final bool monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
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
                            .map((e) => e.amountMinor.toDouble())
                            .toList(),
                        xLabels: _axisDateLabels(
                          timeline.map((e) => e.date).toList(),
                          context,
                          useMonths: monthly,
                        ),
                        lineColor: Theme.of(context).colorScheme.primary,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                        labelColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
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
    required this.textScaler,
  });

  final List<num> values;
  final String currency;
  final List<String> xLabels;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final leftAxisWidth = math.min(
      size.width * .35,
      45 * textScaler.scale(10) / 10,
    );
    final bottomAxisHeight = textScaler.scale(13) + 10;
    final topPadding = textScaler.scale(11) / 2 + 3;
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
      textScaler: textScaler,
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
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.currency != currency ||
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.xLabels, xLabels) ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.textScaler != textScaler;
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
    required this.onOpen,
  });

  final String title;
  final String emptyText;
  final List<AnalysisBreakdown> rows;
  final String currency;
  final ValueChanged<String> onOpen;

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
              for (final (index, row) in sorted.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => onOpen(row.id),
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: colors[index % colors.length],
                  ),
                  title: Text(
                    DefaultLedgerLabels.categoryName(
                      Localizations.localeOf(context),
                      row.id,
                      row.name,
                    ),
                  ),
                  subtitle: Text(
                    '${showPie ? '${(row.amountMinor.toDouble() * 100 / total.toDouble()).toStringAsFixed(1)}%  ' : ''}'
                    '${formatMoneyTotal(row.amountMinor, currency)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
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

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position, required this.currency});

  final ReportPosition position;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final opening = position.opening;
    final closing = position.closing;
    return Card(
      child: ExpansionTile(
        title: Text(labels.reportFinancialPosition),
        subtitle: Text(
          labels.closingAmount(
            formatMoneyTotal(closing.netWorthMinor, currency),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final (label, start, end) in [
            (labels.reportAssets, opening.assetsMinor, closing.assetsMinor),
            (
              labels.reportLiabilities,
              opening.liabilitiesMinor,
              closing.liabilitiesMinor,
            ),
            (
              labels.reportNetWorth,
              opening.netWorthMinor,
              closing.netWorthMinor,
            ),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              subtitle: Text(
                labels.reportOpeningToClosing(
                  formatMoneyTotal(start, currency),
                  formatMoneyTotal(end, currency),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebtTrendCard extends StatelessWidget {
  const _DebtTrendCard({
    required this.position,
    required this.currency,
    required this.useMonths,
  });

  final ReportPosition position;
  final String currency;
  final bool useMonths;

  @override
  Widget build(BuildContext context) {
    final points = position.liabilityTrend;
    final hasLiabilityData = position.hasLiabilities;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerValueRow(
              label: context.l10n.liabilityTrend,
              value: context.l10n.closingAmount(
                formatMoneyTotal(position.closing.liabilitiesMinor, currency),
              ),
              labelStyle: Theme.of(context).textTheme.titleMedium,
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
                        values: points
                            .map((point) => point.amountMinor.toDouble())
                            .toList(),
                        xLabels: _axisDateLabels(
                          points.map((point) => point.date).toList(),
                          context,
                          useMonths: useMonths,
                        ),
                        lineColor: Theme.of(context).colorScheme.error,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                        labelColor: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      ),
                    ),
            ),
            if (hasLiabilityData)
              Text(
                context.l10n.liabilityRangeSummary(
                  formatMoneyTotal(position.opening.liabilitiesMinor, currency),
                  formatMoneyTotal(position.currentLiabilitiesMinor, currency),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

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
        _calendarOffset(_custom!.end, 1),
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
    _ReportPeriod.day => _DateRange(day, _calendarOffset(day, 1)),
    _ReportPeriod.week => _DateRange(
      _calendarOffset(day, 1 - anchor.weekday),
      _calendarOffset(day, 8 - anchor.weekday),
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

DateTime _calendarOffset(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

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
          '${DateFormat.MMMd(locale).format(range.end.subtract(const Duration(microseconds: 1)))}',
    _ReportPeriod.month => DateFormat.yMMMM(locale).format(range.start),
    _ReportPeriod.year => DateFormat.y(locale).format(range.start),
  };
}
