import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_report.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/financial_report_export.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_source.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:xml/xml.dart';

final _start = DateTime(2026, 11, 1);
final _end = DateTime(2026, 12, 1);
const _cash = 'cash';
const _food = 'expense-parent-0-child-1';
const _wallet = 'yen-wallet';
const _note = '=SUM(1,2) | <sensitive>\nOther line';
const _channel = 'Private card';
const _party = 'Private merchant';

void main() {
  test('four formats export the same filtered split and protect sensitive fields by default', () {
    final split = _record(
      'split',
      1000,
      _start,
      LedgerTransactionType.expense,
      legs: [
        _leg(_cash, -600),
        _leg('entrusted', -400, kind: AccountKind.entrustedFunds),
      ],
      terms: const TransactionTerms(
        categories: [
          (categoryId: _food, amountMinor: 700),
          (categoryId: 'travel', amountMinor: 300),
        ],
      ),
      sources: const [
        TransactionSource(
          batchId: 'private-batch',
          batchName: 'private-file.csv',
          line: 12,
          cells: {
            'payment_channel': _channel,
            'merchant': _party,
            'external_id': 'private-order',
          },
        ),
      ],
    );
    final report = _report(
      [split, _record('unmatched', 900, _start, LedgerTransactionType.expense)],
      filter: const LedgerFilter(
        categoryId: _food,
        accountId: _cash,
        funding: LedgerFunding.personal,
        counterparty: _party,
        channel: _channel,
      ),
    );
    expect(report.position, isNull);
    expect(report.analysis.activity.grossSpending, BigInt.from(420));
    expect(report.transactions.map((record) => record.id), ['split']);

    const summary = FinancialReportExport(languageCode: 'en');
    final shortJson = _json(summary, report);
    expect(shortJson['transactions'], isNull);
    expect(shortJson['position'], isNull);
    expect(_metric(shortJson, 'gross_spending'), '420');

    const export = FinancialReportExport(
      includeTransactions: true,
      languageCode: 'en',
    );
    final json = _json(export, report);
    expect(json['format'], 'summa_financial_report');
    expect(json['scope']['start_date'], '2026-11-01');
    expect(json['scope']['end_date'], '2026-11-30');
    expect(json['scope']['matching_transactions'], 1);
    expect(json['scope']['counterparty_filter'], 'redacted');
    expect(json['scope']['category_id'], _food);
    final transaction = (json['transactions'] as List).single as Map;
    expect(transaction['original_amount_minor'], '1000');
    expect(transaction['gross_spending_minor'], '420');
    expect(transaction['cash_outflow_minor'], '420');
    expect(transaction['note'], isNull);
    expect(_metric(json, 'personal_cash_flow_net'), '-420');

    final csv = _text(export, report, FinancialReportFormat.csv);
    expect(
      export
          .encode(report, FinancialReportFormat.csv, exportedAt: _start)
          .take(3),
      [0xef, 0xbb, 0xbf],
    );
    expect(
      csv,
      contains('"summary","CNY","gross_spending","Total spending",420,'),
    );
    expect(csv, contains('"transactions","CNY"'));
    final markdown = _text(export, report, FinancialReportFormat.markdown);
    expect(
      markdown,
      contains('| gross_spending | Total spending | CNY | ¥4.20 |'),
    );
    expect(
      markdown,
      contains(
        '| personal_cash_flow_net | Net personal cash flow | CNY | -¥4.20 |',
      ),
    );
    final workbook = _workbook(export, report);
    final summarySheet = _sheet(workbook, 'Summary');
    expect(_cell(summarySheet, 'D3').innerText, '420');
    expect(_cell(summarySheet, 'D3').getAttribute('t'), 'n');
    final detail = _sheet(workbook, 'Transactions');
    expect(_cell(detail, 'H2').innerText, '1000');
    expect(_cell(detail, 'O2').innerText, '420');
    expect(
      detail.findAllElements('autoFilter').single.getAttribute('ref'),
      'A1:T2',
    );
    for (final text in [
      jsonEncode(json),
      csv,
      markdown,
      _xmlContents(workbook),
    ]) {
      expect(text, isNot(contains(_party)));
      expect(text, isNot(contains(_channel)));
      expect(text, isNot(contains('SUM(1,2)')));
    }

    const sensitive = FinancialReportExport(
      includeTransactions: true,
      includeSensitiveFields: true,
      languageCode: 'en',
    );
    final csvDetails = _text(sensitive, report, FinancialReportFormat.csv);
    expect(csvDetails, contains('"\'=SUM(1,2)'));
    expect(csvDetails, contains(_party));
    final markdownDetails = _text(
      sensitive,
      report,
      FinancialReportFormat.markdown,
    );
    expect(markdownDetails, contains(r'\| &lt;sensitive&gt; Other line'));
    final xlsxDetails = _sheet(_workbook(sensitive, report), 'Transactions');
    expect(_cell(xlsxDetails, 'U2').getAttribute('t'), 'inlineStr');
    expect(_cell(xlsxDetails, 'U2').innerText, _note);
    expect(xlsxDetails.findAllElements('f'), isEmpty);
    expect(
      jsonEncode(_json(sensitive, report)),
      isNot(contains('private-order')),
    );
  });

  test('cross-currency legs, posted cutoff, and balance changes reconcile', () {
    final transfer = _record(
      'fx',
      2500,
      _start,
      LedgerTransactionType.transfer,
      currency: 'CNY',
      legs: [
        _leg(_cash, -2500),
        _leg(_wallet, 512, currency: 'JPY'),
      ],
      settlement: const TransferSettlement(
        amountMinor: 512,
        currencyCode: 'JPY',
        quotedRate: '20.50',
      ),
    );
    final later = _record(
      'later',
      100,
      _end,
      LedgerTransactionType.income,
      currency: 'JPY',
      legs: [_leg(_wallet, 100, currency: 'JPY')],
    );
    final pending = _record(
      'pending',
      100,
      _start,
      LedgerTransactionType.expense,
      currency: 'JPY',
      legs: [_leg(_wallet, -100, currency: 'JPY')],
      pending: true,
    );
    final report = _report(
      [pending, transfer, later],
      currency: 'JPY',
      filter: const LedgerFilter(accountId: _wallet),
      balances: const [
        AccountBalance(
          id: _wallet,
          name: 'Tokyo wallet',
          kind: AccountKind.wallet,
          currencyCode: 'JPY',
          openingBalanceMinor: 50,
          currentBalanceMinor: 662,
        ),
      ],
    );
    expect(report.transactions.map((record) => record.id), ['fx']);
    expect(report.position!.opening.netWorthMinor, BigInt.from(50));
    expect(report.position!.closing.netWorthMinor, BigInt.from(562));
    const export = FinancialReportExport(
      includeTransactions: true,
      languageCode: 'en',
    );
    final json = _json(export, report);
    expect(json['scope']['account'], 'Tokyo wallet');
    expect(json['scope']['minor_digits'], 0);
    expect(_metric(json, 'income'), '0');
    expect(_metric(json, 'personal_cash_flow_net'), '512');
    final transaction = (json['transactions'] as List).single as Map;
    expect(transaction['original_currency_code'], 'CNY');
    expect(transaction['original_amount_minor'], '2500');
    expect(transaction['settlement_currency_code'], 'JPY');
    expect(transaction['settlement_amount_minor'], '512');
    expect(transaction['quoted_exchange_rate'], '20.50');

    final markdown = _text(export, report, FinancialReportFormat.markdown);
    expect(markdown, contains('| CNY | ¥25.00 | JPY | JPY 512 | 20.50 |'));
    final workbook = _workbook(export, report);
    expect(
      _cell(_sheet(workbook, 'Financial position'), 'D4').innerText,
      '562',
    );
  });

  test('large monetary totals retain every digit in XLSX and JSON', () {
    const amount = 9007199254740993;
    final record = _record(
      'large',
      amount,
      _start,
      LedgerTransactionType.income,
      legs: [_leg(_cash, amount)],
    );
    final report = _report([record]);
    const export = FinancialReportExport(languageCode: 'en');
    expect(_metric(_json(export, report), 'income'), '$amount');
    final sheet = _sheet(_workbook(export, report), 'Summary');
    expect(_cell(sheet, 'D2').getAttribute('t'), 'inlineStr');
    expect(_cell(sheet, 'D2').innerText, '$amount');
    final empty = _report([]);
    expect(_metric(_json(export, empty), 'income'), '0');
    expect(
      _sheet(
        _workbook(export, empty),
        'Expense categories',
      ).findAllElements('row'),
      hasLength(1),
    );
  });
}

FinancialReport _report(
  List<LedgerRecord> records, {
  String currency = 'CNY',
  LedgerFilter filter = const LedgerFilter(),
  List<AccountBalance> balances = const [],
}) => FinancialReport(
  records: records,
  balances: balances,
  range: (start: _start, endExclusive: _end),
  currency: currency,
  filter: filter,
  monthlyTimeline: false,
);

LedgerRecord _record(
  String id,
  int amount,
  DateTime at,
  LedgerTransactionType type, {
  String currency = 'CNY',
  List<AccountPosting> legs = const [],
  TransactionTerms terms = const TransactionTerms(),
  List<TransactionSource> sources = const [],
  TransferSettlement? settlement,
  bool pending = false,
}) => LedgerRecord(
  id: id,
  type: type,
  amountMinor: amount,
  occurredAt: at,
  parentCategoryId: 'expense-parent-0',
  parentCategoryName: 'Food',
  categoryId: _food,
  categoryName: 'Lunch',
  accountId: _cash,
  accountName: 'Cash',
  accountKind: 'cash',
  targetAccountId: settlement == null ? null : _wallet,
  targetAccountName: settlement == null ? null : 'Tokyo wallet',
  targetAccountKind: settlement == null ? null : 'wallet',
  currencyCode: currency,
  settlement: settlement,
  accountPostings: legs,
  terms: terms,
  sources: sources,
  note: _note,
  status: pending ? LedgerPostingStatus.pending : LedgerPostingStatus.posted,
);

AccountPosting _leg(
  String account,
  int change, {
  String currency = 'CNY',
  AccountKind kind = AccountKind.cash,
}) => AccountPosting(
  accountId: account,
  accountName: account,
  accountKind: kind.name,
  debitMinor: change,
  needsReview: false,
  currencyCode: currency,
);

Map<String, dynamic> _json(
  FinancialReportExport export,
  FinancialReport report,
) =>
    jsonDecode(_text(export, report, FinancialReportFormat.json))
        as Map<String, dynamic>;

Object? _metric(Map<String, dynamic> json, String key) =>
    (json['summary'] as List).singleWhere(
      (row) => row['metric'] == key,
    )['amount_minor'];

String _text(
  FinancialReportExport export,
  FinancialReport report,
  FinancialReportFormat format,
) => String.fromCharCodes(
  const Utf8Decoder()
      .convert(export.encode(report, format, exportedAt: _start))
      .runes,
);

Archive _workbook(FinancialReportExport export, FinancialReport report) =>
    ZipDecoder().decodeBytes(
      export.encode(report, FinancialReportFormat.xlsx, exportedAt: _start),
      verify: true,
    );

String _xmlContents(Archive archive) => archive.files
    .where((file) => file.name.endsWith('.xml'))
    .map((file) => utf8.decode(file.content))
    .join();

XmlDocument _sheet(Archive archive, String name) {
  final workbook = XmlDocument.parse(
    utf8.decode(archive.findFile('xl/workbook.xml')!.content),
  );
  final sheet = workbook
      .findAllElements('sheet')
      .singleWhere((sheet) => sheet.getAttribute('name') == name);
  final id = sheet.getAttribute('sheetId');
  return XmlDocument.parse(
    utf8.decode(archive.findFile('xl/worksheets/sheet$id.xml')!.content),
  );
}

XmlElement _cell(XmlDocument sheet, String address) => sheet
    .findAllElements('c')
    .singleWhere((cell) => cell.getAttribute('r') == address);
