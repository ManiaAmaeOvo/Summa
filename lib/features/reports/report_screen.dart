import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/import_export/ledger_export.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:share_plus/share_plus.dart';

enum _ReportPeriod { day, week, month, year }

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  _ReportPeriod _period = _ReportPeriod.month;
  DateTime _anchor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(transactionsProvider);
    final balances = ref.watch(accountBalancesProvider).asData?.value;
    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('报表读取失败')),
      data: (all) {
        if (balances == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final range = _rangeFor(_period, _anchor);
        final selected = all
            .where(
              (item) =>
                  !item.occurredAt.isBefore(range.start) &&
                  item.occurredAt.isBefore(range.end),
            )
            .toList(growable: false);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            SegmentedButton<_ReportPeriod>(
              segments: const [
                ButtonSegment(value: _ReportPeriod.day, label: Text('日')),
                ButtonSegment(value: _ReportPeriod.week, label: Text('周')),
                ButtonSegment(value: _ReportPeriod.month, label: Text('月')),
                ButtonSegment(value: _ReportPeriod.year, label: Text('年')),
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
                    _rangeLabel(_period, range),
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
            const SizedBox(height: 8),
            _SummaryGrid(records: selected),
            const SizedBox(height: 16),
            _TrendCard(records: selected, range: range, period: _period),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: '支出分类',
              emptyText: '此周期暂无支出分类数据',
              type: LedgerTransactionType.expense,
              records: selected,
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: '收入分类',
              emptyText: '此周期暂无收入分类数据',
              type: LedgerTransactionType.income,
              records: selected,
            ),
            const SizedBox(height: 16),
            _DebtTrendCard(
              allRecords: all,
              selectedRecords: selected,
              balances: balances,
              range: range,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ExportDialog(records: all),
              ),
              icon: const Icon(Icons.ios_share),
              label: const Text('导出账单'),
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
  const _SummaryGrid({required this.records});

  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    final expense = _sum(records, LedgerTransactionType.expense);
    final income = _sum(records, LedgerTransactionType.income);
    final borrowing = _sum(records, LedgerTransactionType.borrowing);
    final repayment = _sum(records, LedgerTransactionType.repayment);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        _Metric(label: '收入', value: income),
        _Metric(label: '支出', value: expense),
        _Metric(label: '收支结余', value: income - expense),
        _Metric(
          label: '借入 / 还款',
          text: '${formatCny(borrowing)} / ${formatCny(repayment)}',
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, this.value, this.text});
  final String label;
  final int? value;
  final String? text;

  @override
  Widget build(BuildContext context) => Card.filled(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text ?? formatCny(value!),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.records,
    required this.range,
    required this.period,
  });
  final List<LedgerRecord> records;
  final _DateRange range;
  final _ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final buckets = <DateTime, int>{};
    for (final record in records.where(
      (item) => item.type == LedgerTransactionType.expense,
    )) {
      final key = period == _ReportPeriod.year
          ? DateTime(record.occurredAt.year, record.occurredAt.month)
          : DateTime(
              record.occurredAt.year,
              record.occurredAt.month,
              record.occurredAt.day,
            );
      buckets[key] = (buckets[key] ?? 0) + record.amountMinor;
    }
    final points = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('支出趋势', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: points.isEmpty
                  ? const Center(child: Text('此周期暂无支出'))
                  : CustomPaint(
                      painter: _TrendPainter(
                        points.map((e) => e.value).toList(),
                        Theme.of(context).colorScheme.primary,
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
  _TrendPainter(this.values, this.color);
  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: .28), color.withValues(alpha: .02)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    final maxValue = math.max(1, values.reduce(math.max));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final y = size.height - 12 - (size.height - 24) * values[i] / maxValue;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({
    required this.title,
    required this.emptyText,
    required this.type,
    required this.records,
  });

  final String title;
  final String emptyText;
  final LedgerTransactionType type;
  final List<LedgerRecord> records;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final item in records.where((item) => item.type == type)) {
      totals[item.parentCategoryName] =
          (totals[item.parentCategoryName] ?? 0) + item.amountMinor;
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = rows.fold<int>(0, (sum, row) => sum + row.value);
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
            if (rows.isEmpty)
              SizedBox(height: 120, child: Center(child: Text(emptyText)))
            else ...[
              Center(
                child: SizedBox.square(
                  dimension: 176,
                  child: CustomPaint(
                    painter: _PiePainter(
                      values: rows.map((row) => row.value).toList(),
                      colors: colors,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < rows.length; index++) ...[
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
                    Expanded(child: Text(rows[index].key)),
                    Text(
                      '${(rows[index].value * 100 / total).toStringAsFixed(1)}%  '
                      '${formatCny(rows[index].value)}',
                    ),
                  ],
                ),
                if (index != rows.length - 1) const SizedBox(height: 8),
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

  final List<int> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    var start = -math.pi / 2;
    final rect = Offset.zero & size;
    for (var index = 0; index < values.length; index++) {
      final sweep = math.pi * 2 * values[index] / total;
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
  });

  final List<LedgerRecord> allRecords;
  final List<LedgerRecord> selectedRecords;
  final List<AccountBalance> balances;
  final _DateRange range;

  @override
  Widget build(BuildContext context) {
    final liabilityIds = balances
        .where((item) => item.group == AccountGroup.liability)
        .map((item) => item.id)
        .toSet();
    final current = balances
        .where((item) => item.group == AccountGroup.liability)
        .fold<int>(0, (sum, item) => sum + item.currentBalanceMinor);
    final now = DateTime.now();
    var opening = current;
    if (!range.start.isAfter(now)) {
      for (final record in allRecords) {
        if (!record.occurredAt.isBefore(range.start) &&
            !record.occurredAt.isAfter(now)) {
          opening -= _liabilityDelta(record, liabilityIds);
        }
      }
    }
    final ordered = [...selectedRecords]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final values = <int>[opening];
    var running = opening;
    for (final record in ordered) {
      running += _liabilityDelta(record, liabilityIds);
      values.add(running);
    }
    final hasLiabilityData =
        liabilityIds.isNotEmpty ||
        ordered.any((item) => _liabilityDelta(item, liabilityIds) != 0);
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
                    '负债走势',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('期末 ${formatCny(running)}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: !hasLiabilityData
                  ? const Center(child: Text('暂无负债账户或负债变动'))
                  : CustomPaint(
                      painter: _TrendPainter(
                        values,
                        Theme.of(context).colorScheme.error,
                      ),
                    ),
            ),
            if (hasLiabilityData)
              Text(
                '期初 ${formatCny(opening)}  ·  当前总负债 ${formatCny(current)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

int _liabilityDelta(LedgerRecord record, Set<String> liabilityIds) {
  final primaryIsLiability =
      liabilityIds.contains(record.accountId) ||
      record.accountKind == AccountKind.creditLine.name;
  final targetIsLiability =
      liabilityIds.contains(record.targetAccountId) ||
      record.targetAccountKind == AccountKind.creditLine.name;
  return switch (record.type) {
    LedgerTransactionType.expense when primaryIsLiability => record.amountMinor,
    LedgerTransactionType.income when primaryIsLiability => -record.amountMinor,
    LedgerTransactionType.borrowing when primaryIsLiability =>
      record.amountMinor,
    LedgerTransactionType.repayment when targetIsLiability =>
      -record.amountMinor,
    _ => 0,
  };
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
    title: const Text('导出账单'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<_ExportRange>(
          initialValue: _range,
          decoration: const InputDecoration(labelText: '时间范围'),
          items: const [
            DropdownMenuItem(value: _ExportRange.week, child: Text('本周')),
            DropdownMenuItem(value: _ExportRange.month, child: Text('本月')),
            DropdownMenuItem(value: _ExportRange.year, child: Text('本年')),
            DropdownMenuItem(value: _ExportRange.all, child: Text('全部')),
            DropdownMenuItem(value: _ExportRange.custom, child: Text('自定义时间段')),
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
          decoration: const InputDecoration(labelText: '文件格式'),
          items: const [
            DropdownMenuItem(
              value: LedgerExportFormat.json,
              child: Text('JSON（完整、可重新导入）'),
            ),
            DropdownMenuItem(
              value: LedgerExportFormat.csv,
              child: Text('CSV（表格分析）'),
            ),
            DropdownMenuItem(
              value: LedgerExportFormat.markdown,
              child: Text('Markdown（阅读）'),
            ),
          ],
          onChanged: (value) => setState(() => _format = value!),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _saving ? null : _export,
        child: Text(_saving ? '准备中…' : '导出'),
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
    final content = exportLedgerRecords(selected, _format);
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
        subject: 'Summa 账单导出',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (mounted) Navigator.pop(context);
  }
}

int _sum(List<LedgerRecord> records, LedgerTransactionType type) => records
    .where((item) => item.type == type)
    .fold(0, (sum, item) => sum + item.amountMinor);

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

String _rangeLabel(_ReportPeriod period, _DateRange range) => switch (period) {
  _ReportPeriod.day => DateFormat('yyyy年MM月dd日').format(range.start),
  _ReportPeriod.week =>
    '${DateFormat('MM月dd日').format(range.start)} – ${DateFormat('MM月dd日').format(range.end.subtract(const Duration(days: 1)))}',
  _ReportPeriod.month => DateFormat('yyyy年MM月').format(range.start),
  _ReportPeriod.year => DateFormat('yyyy年').format(range.start),
};
