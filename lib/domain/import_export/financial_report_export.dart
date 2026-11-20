import 'dart:convert';
import 'dart:typed_data';

import 'package:summa/core/money/money.dart';
import 'package:summa/domain/analytics/financial_report.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/defaults/default_ledger_names.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_source.dart';

import 'report_workbook.dart';

enum FinancialReportFormat {
  json('json', 'application/json'),
  csv('csv', 'text/csv'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  markdown('md', 'text/markdown');

  const FinancialReportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

class FinancialReportExport {
  const FinancialReportExport({
    this.includeTransactions = false,
    this.includeSensitiveFields = false,
    this.languageCode = 'zh',
  });

  final bool includeTransactions;
  final bool includeSensitiveFields;
  final String languageCode;

  Uint8List encode(
    FinancialReport report,
    FinancialReportFormat format, {
    required DateTime exportedAt,
  }) {
    final scope = _scope(report);
    final tables = [
      _summary(report),
      _table(
        'scope',
        'Scope',
        '报告范围',
        ['field', 'value'],
        [
          for (final entry in scope.entries)
            {'field': entry.key, 'value': entry.value},
        ],
      ),
      _categories(report, expense: true),
      _categories(report, expense: false),
      _accountFlows(report),
      _table(
        'spending_timeline',
        'Spending timeline',
        '支出趋势',
        ['date', 'amount_minor'],
        [
          for (final row in report.spendingTimeline)
            {
              'date': encodePlanningDay(row.date),
              'amount_minor': row.amountMinor,
            },
        ],
      ),
      if (report.position case final position?) ...[
        _position(position),
        _table(
          'account_balances',
          'Account balances',
          '账户余额',
          [
            'account_id',
            'account',
            'account_group',
            'opening_minor',
            'closing_minor',
            'change_minor',
          ],
          [
            for (final row in position.balances)
              {
                'account_id': row.account.id,
                'account': _accountName(row.account.id, row.account.name),
                'account_group': row.account.group.name,
                'opening_minor': row.openingMinor,
                'closing_minor': row.closingMinor,
                'change_minor': row.closingMinor - row.openingMinor,
              },
          ],
        ),
        if (position.hasLiabilities)
          _table(
            'liability_timeline',
            'Liability timeline',
            '负债走势',
            ['at_utc', 'amount_minor'],
            [
              for (final row in position.liabilityTrend)
                {'at_utc': _instant(row.date), 'amount_minor': row.amountMinor},
            ],
          ),
      ],
      if (includeTransactions) _transactions(report),
    ];

    return switch (format) {
      FinancialReportFormat.json => utf8.encode(
        JsonEncoder.withIndent(
          '  ',
          (value) => (value as BigInt).toString(),
        ).convert({
          'format': 'summa_financial_report',
          'report_version': 1,
          'exported_at_utc': _instant(exportedAt),
          'scope': scope,
          for (final table in tables)
            if (table.id != 'scope') table.id: table.rows,
        }),
      ),
      FinancialReportFormat.csv => utf8.encode(_csv(tables, report.currency)),
      FinancialReportFormat.xlsx => encodeReportWorkbook([
        for (final table in tables)
          (
            name: table.title,
            columns: table.columns,
            rows: table.rows.map(
              (row) => table.columns.map((column) => row[column]),
            ),
          ),
      ]),
      FinancialReportFormat.markdown => utf8.encode(
        _markdown(tables, report.currency, exportedAt),
      ),
    };
  }

  _Row _scope(FinancialReport report) {
    final filter = report.filter;
    return {
      'start_date': encodePlanningDay(report.range.start.toLocal()),
      'end_date': encodePlanningDay(
        report.range.endExclusive.toLocal().subtract(
          const Duration(microseconds: 1),
        ),
      ),
      'start_at_utc': _instant(report.range.start),
      'end_exclusive_at_utc': _instant(report.range.endExclusive),
      'currency_code': report.currency,
      'minor_digits': currencyMinorDigits[report.currency] ?? 2,
      'posting_status': LedgerPostingStatus.posted.name,
      'spending_timeline_grain': report.monthlyTimeline ? 'month' : 'day',
      'matching_transactions': report.transactions.length,
      'category_id': ?filter.categoryId,
      if (report.categoryName case final name?)
        'category': _categoryName(filter.categoryId!, name),
      'account_id': ?filter.accountId,
      if (report.accountName case final name?)
        'account': _accountName(filter.accountId!, name),
      if (filter.funding case final funding?) 'funding': funding.name,
      if (filter.channel != null)
        'channel_filter': includeSensitiveFields ? filter.channel! : 'redacted',
      if (filter.counterparty != null)
        'counterparty_filter': includeSensitiveFields
            ? filter.counterparty!
            : 'redacted',
      'include_transactions': includeTransactions,
      'include_sensitive_fields': includeSensitiveFields,
      'balances_included': report.position != null,
    };
  }

  _Table _summary(FinancialReport report) {
    final analysis = report.analysis;
    final activity = analysis.activity;
    final metrics = [
      ('income', 'Income', '收入', analysis.incomeMinor),
      ('gross_spending', 'Total spending', '总消费', activity.grossSpending),
      (
        'personal_spending',
        'Personally borne',
        '本人承担',
        activity.personalSpending,
      ),
      (
        'family_direct_spending',
        'Family direct payments',
        '家庭直接承担',
        activity.familyDirectSpending,
      ),
      (
        'entrusted_spending',
        'Entrusted funds spending',
        '受托资金支付',
        activity.entrustedSpending,
      ),
      (
        'third_party_payable_spending',
        'Third-party payable spending',
        '他人垫付且待偿',
        activity.thirdPartyPayableSpending,
      ),
      (
        'unclassified_spending',
        'Spending to classify',
        '待确认归属',
        activity.unclassifiedSpending,
      ),
      (
        'family_support_received',
        'Family support received',
        '家庭资金转入',
        activity.familySupportReceived,
      ),
      (
        'personal_cash_inflow',
        'Personal cash inflow',
        '个人现金流入',
        activity.personalCashInflow,
      ),
      (
        'personal_cash_outflow',
        'Personal cash outflow',
        '个人现金流出',
        activity.personalCashOutflow,
      ),
      (
        'personal_cash_flow_net',
        'Net personal cash flow',
        '个人净现金流',
        activity.personalCashInflow - activity.personalCashOutflow,
      ),
      ('borrowing', 'Borrowing', '借入本金', analysis.borrowingMinor),
      ('repayment', 'Repayment', '偿还本金', analysis.repaymentMinor),
    ];
    return _table(
      'summary',
      'Summary',
      '财务摘要',
      ['metric', 'label', 'currency_code', 'amount_minor'],
      [
        for (final (id, english, chinese, amount) in metrics)
          {
            'metric': id,
            'label': _label(english, chinese),
            'currency_code': report.currency,
            'amount_minor': amount,
          },
      ],
    );
  }

  _Table _categories(FinancialReport report, {required bool expense}) => _table(
    expense ? 'expense_categories' : 'income_categories',
    expense ? 'Expense categories' : 'Income categories',
    expense ? '支出分类' : '收入分类',
    ['category_id', 'category', 'amount_minor'],
    [
      for (final row
          in expense
              ? report.analysis.expenseCategories
              : report.analysis.incomeCategories)
        {
          'category_id': row.id,
          'category': _categoryName(row.id, row.name),
          'amount_minor': row.amountMinor,
        },
    ],
  );

  _Table _accountFlows(FinancialReport report) => _table(
    'account_cash_flows',
    'Account cash flows',
    '账户现金变动',
    ['account_id', 'account', 'cash_inflow_minor', 'cash_outflow_minor'],
    [
      for (final row in report.analysis.accountFlows)
        {
          'account_id': row.id,
          'account': _accountName(row.id, row.name),
          'cash_inflow_minor': row.inflowMinor,
          'cash_outflow_minor': row.outflowMinor,
        },
    ],
  );

  _Table _position(ReportPosition report) {
    final opening = report.opening;
    final closing = report.closing;
    return _table(
      'position',
      'Financial position',
      '资产负债',
      ['metric', 'label', 'opening_minor', 'closing_minor', 'change_minor'],
      [
        for (final (id, english, chinese, start, end) in [
          ('assets', 'Assets', '资产', opening.assetsMinor, closing.assetsMinor),
          (
            'liabilities',
            'Liabilities',
            '负债',
            opening.liabilitiesMinor,
            closing.liabilitiesMinor,
          ),
          (
            'net_worth',
            'Net worth',
            '净资产',
            opening.netWorthMinor,
            closing.netWorthMinor,
          ),
        ])
          {
            'metric': id,
            'label': _label(english, chinese),
            'opening_minor': start,
            'closing_minor': end,
            'change_minor': end - start,
          },
      ],
    );
  }

  _Table _transactions(FinancialReport report) => _table(
    'transactions',
    'Transactions',
    '匹配流水',
    [
      'transaction_id',
      'at_utc',
      'type',
      'account',
      'target_account',
      'category',
      'original_currency_code',
      'original_amount_minor',
      'settlement_currency_code',
      'settlement_amount_minor',
      'quoted_exchange_rate',
      'refund_of_id',
      'reversal_of_id',
      'income_minor',
      'gross_spending_minor',
      'personal_spending_minor',
      'cash_inflow_minor',
      'cash_outflow_minor',
      'borrowing_minor',
      'repayment_minor',
      if (includeSensitiveFields) ...[
        'note',
        'payment_channel',
        'counterparty',
      ],
    ],
    [for (final record in report.transactions) _transaction(report, record)],
  );

  _Row _transaction(FinancialReport report, LedgerRecord record) {
    final attributed = analyzeLedger([record], report.currency, report.filter);
    final activity = attributed.activity;
    final Iterable<TransactionSource> sources = includeSensitiveFields
        ? record.sources.where(
            (source) =>
                (report.filter.channel == null ||
                    report.filter.channel == source.channel) &&
                (report.filter.counterparty == null ||
                    report.filter.counterparty == source.counterparty),
          )
        : const [];
    final channels = {for (final source in sources) ?source.channel};
    final parties = {for (final source in sources) ?source.counterparty};
    return {
      'transaction_id': record.id,
      'at_utc': _instant(record.occurredAt),
      'type': record.isRefund ? 'refund' : record.type.name,
      'account': _accountName(record.accountId, record.accountName),
      if (record.targetAccountId case final id?)
        'target_account': _accountName(id, record.targetAccountName ?? id),
      'category': _categoryName(record.categoryId, record.categoryName),
      'original_currency_code': record.currencyCode,
      'original_amount_minor': BigInt.from(record.amountMinor),
      if (record.settlement case final settlement?) ...{
        'settlement_currency_code': settlement.currencyCode,
        'settlement_amount_minor': BigInt.from(settlement.amountMinor),
        'quoted_exchange_rate': ?settlement.quotedRate,
      },
      'refund_of_id': ?record.refundOfId,
      'reversal_of_id': ?record.terms.reversalOfId,
      'income_minor': attributed.incomeMinor,
      'gross_spending_minor': activity.grossSpending,
      'personal_spending_minor': activity.personalSpending,
      'cash_inflow_minor': activity.personalCashInflow,
      'cash_outflow_minor': activity.personalCashOutflow,
      'borrowing_minor': attributed.borrowingMinor,
      'repayment_minor': attributed.repaymentMinor,
      if (includeSensitiveFields) ...{
        'note': record.note,
        if (channels.isNotEmpty) 'payment_channel': channels.join(' · '),
        if (parties.isNotEmpty) 'counterparty': parties.join(' · '),
      },
    };
  }

  _Table _table(
    String id,
    String english,
    String chinese,
    List<String> columns,
    List<_Row> rows,
  ) => (id: id, title: _label(english, chinese), columns: columns, rows: rows);

  String _accountName(String id, String name) =>
      DefaultLedgerNames.accountName(languageCode, id, name);

  String _categoryName(String id, String name) =>
      DefaultLedgerNames.categoryName(languageCode, id, name);

  String _label(String english, String chinese) =>
      languageCode == 'zh' ? chinese : english;

  String _markdown(List<_Table> tables, String currency, DateTime exportedAt) {
    final result = StringBuffer()
      ..writeln(_label('# Summa financial report', '# Summa 财务报告'))
      ..writeln()
      ..writeln(_instant(exportedAt));
    for (final table in tables) {
      result
        ..writeln()
        ..writeln('## ${table.title}')
        ..writeln()
        ..writeln('| ${table.columns.map(_columnLabel).join(' | ')} |')
        ..writeln(
          '| ${List.filled(table.columns.length, '---').join(' | ')} |',
        );
      for (final row in table.rows) {
        final cells = table.columns.map((column) {
          final value = row[column];
          if (value is BigInt) {
            final code = switch (column) {
              'original_amount_minor' =>
                row['original_currency_code'] as String,
              'settlement_amount_minor' =>
                row['settlement_currency_code'] as String,
              _ => currency,
            };
            return formatMoneyTotal(value, code);
          }
          return _md(value?.toString() ?? '');
        });
        result.writeln('| ${cells.join(' | ')} |');
      }
    }
    return result.toString();
  }

  String _columnLabel(String key) {
    final label = key.endsWith('_minor')
        ? key.substring(0, key.length - '_minor'.length)
        : key;
    return label.replaceAll('_', ' ');
  }
}

typedef _Row = Map<String, Object>;
typedef _Table = ({
  String id,
  String title,
  List<String> columns,
  List<_Row> rows,
});

String _instant(DateTime date) => date.toUtc().toIso8601String();

String _csv(List<_Table> tables, String currency) {
  final columns = {
    'section',
    'currency_code',
    for (final table in tables) ...table.columns,
  };
  final result = StringBuffer('\uFEFF')
    ..write(columns.map(_csvCell).join(','))
    ..write('\r\n');
  for (final table in tables) {
    for (final row in table.rows) {
      result
        ..write(
          columns
              .map(
                (key) => _csvCell(switch (key) {
                  'section' => table.id,
                  'currency_code' => currency,
                  _ => row[key],
                }),
              )
              .join(','),
        )
        ..write('\r\n');
    }
  }
  return result.toString();
}

final _formulaStart = RegExp(r'^\s*[=+\-@]|^[\t\r\n]');

String _csvCell(Object? value) {
  if (value == null) return '';
  if (value is! String) return value.toString();
  final text = _formulaStart.hasMatch(value) ? "'$value" : value;
  return '"${text.replaceAll('"', '""')}"';
}

String _md(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll(r'\', r'\\')
    .replaceAll('|', r'\|')
    .replaceAll('[', r'\[')
    .replaceAll(']', r'\]')
    .replaceAll('`', r'\`')
    .replaceAll(RegExp(r'[\r\n]+'), ' ');
