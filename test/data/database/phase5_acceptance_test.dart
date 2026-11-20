import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/analytics/financial_report.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/financial_report_export.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/statement_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:xml/xml.dart';

import '../../fixtures/legacy_smoke_backup.dart';

const _cash = 'migration-smoke-cash';
const _suggested = 'migration-smoke-child';
final _start = DateTime(2026, 11);
final _end = DateTime(2026, 12);

void main() {
  test('Phase 5 compound rule trial, reviewer override, four reports and legacy restore round trip', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ledger = DriftExpenseRepository(db);
    final sample = File('test/fixtures/phase5-rules-acceptance.csv');
    final file = parseStatementImport(
      'phase5-rules-acceptance.csv',
      await sample.readAsBytes(),
    );
    Future<void> restore(String backup) =>
        ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    Future<int> cashBalance() async =>
        (await ledger.watchAccountBalances().first).single.currentBalanceMinor;

    await restore(legacySmokeBackup);
    expect(await cashBalance(), 7655);
    await ledger.addCategory(
      type: LedgerTransactionType.expense,
      name: 'Reviewed lunch',
      parentId: 'migration-smoke-parent',
    );
    final reviewedCategory = (await ledger.watchExpenseCategories().first)
        .singleWhere((category) => category.name == 'Reviewed lunch')
        .id;
    const oldCondition = ImportRuleCondition(
      field: ImportRuleField.description,
      operator: ImportRuleOperator.contains,
      value: 'Demo',
    );
    await ledger.saveImportRule(
      conditions: [oldCondition],
      categoryId: _suggested,
      priority: 100,
      enabled: true,
    );
    final legacyRules = _backupContents(await ledger.createFullBackup())
      ..['backup_version'] = 13
      ..['schema_version'] = 19
      ..['created_at'] = '2026-11-20T12:00:00Z';
    final v13 = jsonEncode(legacyRules);

    const conditions = [
      ImportRuleCondition(
        field: ImportRuleField.description,
        operator: ImportRuleOperator.contains,
        value: 'Fresh meal',
      ),
      ImportRuleCondition(
        field: ImportRuleField.merchant,
        operator: ImportRuleOperator.contains,
        value: 'Harbor',
      ),
    ];
    final beforeTrial = _backupContents(await ledger.createFullBackup());
    final draft = ImportCategoryRule(
      id: '',
      conditions: conditions,
      categoryId: _suggested,
      priority: 10,
    );
    final trial = await ledger.previewImportRules(file, draft: draft);
    expect(trial.map((row) => row.suggestion?.categoryId), [_suggested, null]);
    expect(trial.first.suggestion!.matchedRules.single, same(draft));
    expect(_backupContents(await ledger.createFullBackup()), beforeTrial);

    await ledger.saveImportRule(
      conditions: conditions,
      categoryId: _suggested,
      priority: 10,
      enabled: true,
    );
    final review = await ledger.previewCsvImport(file);
    expect(review.first.suggestion?.priority, 10);
    expect(review.first.mapping.categoryId, _suggested);
    expect(review.last.state, CsvReviewState.unresolved);
    expect(await cashBalance(), 7655);

    final manual = (
      accountId: _cash,
      targetId: null,
      categoryId: reviewedCategory,
    );
    final selected = (await ledger.previewCsvImport(
      file,
      mappings: {1: manual},
    )).first;
    expect(selected.suggestion, isNull);
    final result = await ledger.commitCsvImport(file, [
      CsvSelection(1, selected.mapping),
    ]);
    expect((result.added, result.matched), (1, 0));
    expect(await cashBalance(), 7405);

    Future<FinancialReport> buildReport() async {
      final input = await ledger.watchLedgerHistoryInputs().first;
      return FinancialReport(
        records: input.transactions,
        balances: input.balances.where((account) => account.archivedAt == null),
        range: (start: _start, endExclusive: _end),
        currency: 'CNY',
        filter: LedgerFilter(
          accountId: _cash,
          categoryId: reviewedCategory,
          counterparty: 'Harbor Cafe',
        ),
        monthlyTimeline: false,
      );
    }

    final v14 = await ledger.createFullBackup();
    final exported = _verifyReports(await buildReport(), reviewedCategory);
    expect(
      _backupContents(await ledger.createFullBackup()),
      _backupContents(v14),
    );

    await restore(legacySmokeBackup);
    expect(await cashBalance(), 7655);
    expect(await ledger.watchCsvBatches().first, isEmpty);
    expect(await ledger.watchImportRules().first, isEmpty);
    await restore(v13);
    expect(await cashBalance(), 7655);
    final legacyRule = (await ledger.watchImportRules().first).single;
    expect(legacyRule.conditions.single.toJson(), oldCondition.toJson());
    expect(legacyRule.priority, 100);
    expect((await buildReport()).transactions, isEmpty);

    await restore(v14);
    expect(await cashBalance(), 7405);
    final restoredRules = await ledger.watchImportRules().first;
    expect(restoredRules.map((rule) => rule.priority), [10, 100]);
    expect(
      restoredRules.first.conditions.map((condition) => condition.toJson()),
      conditions.map((condition) => condition.toJson()),
    );
    expect(
      (await ledger.previewCsvImport(file)).first.state,
      CsvReviewState.duplicate,
    );
    expect(
      (await ledger.previewImportRules(file)).first.suggestion?.categoryId,
      _suggested,
    );
    expect(_verifyReports(await buildReport(), reviewedCategory), exported);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    expect(
      await db.customSelect('''
          SELECT transaction_id FROM ledger_postings
          GROUP BY transaction_id, currency_code HAVING SUM(debit_minor) <> 0
        ''').get(),
      isEmpty,
    );
  });
}

Map<String, dynamic> _backupContents(String data) =>
    (jsonDecode(data) as Map<String, dynamic>)..remove('created_at');

Map<String, dynamic> _verifyReports(
  FinancialReport report,
  String reviewedCategory,
) {
  expect(report.transactions.single.categoryId, reviewedCategory);
  expect(report.analysis.activity.grossSpending, BigInt.from(250));
  expect(report.analysis.activity.personalCashOutflow, BigInt.from(250));

  const exporter = FinancialReportExport(
    includeTransactions: true,
    languageCode: 'en',
  );
  String text(FinancialReportFormat format) =>
      utf8.decode(exporter.encode(report, format, exportedAt: _end));

  final json =
      jsonDecode(text(FinancialReportFormat.json)) as Map<String, dynamic>;
  final scope = json['scope'] as Map<String, dynamic>;
  expect(scope['matching_transactions'], 1);
  expect(scope['category_id'], reviewedCategory);
  expect(scope['counterparty_filter'], 'redacted');
  final transaction = (json['transactions'] as List).single as Map;
  expect(transaction['category'], 'Reviewed lunch');
  expect(transaction['original_amount_minor'], '250');
  expect(transaction['gross_spending_minor'], '250');
  expect(transaction.containsKey('note'), isFalse);
  final summary = {
    for (final row in (json['summary'] as List).cast<Map<String, dynamic>>())
      row['metric'] as String: row['amount_minor'] as String,
  };
  expect(summary, hasLength(13));
  expect(summary['gross_spending'], '250');
  expect(summary['personal_cash_flow_net'], '-250');

  final rows = readCsvRecords(text(FinancialReportFormat.csv))
      .map((row) => row.cells)
      .toList();
  final header = rows.first;
  final section = header.indexOf('section');
  final metric = header.indexOf('metric');
  final amount = header.indexOf('amount_minor');
  expect({
    for (final row in rows.skip(1))
      if (row[section] == 'summary') row[metric]: row[amount],
  }, summary);

  final zip = ZipDecoder().decodeBytes(
    exporter.encode(report, FinancialReportFormat.xlsx, exportedAt: _end),
    verify: true,
  );
  final sheet = XmlDocument.parse(
    utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content),
  );
  expect({
    for (final row in sheet.findAllElements('row').skip(1))
      row.childElements.first.innerText: row.childElements.last.innerText,
  }, summary);

  final markdown = text(FinancialReportFormat.markdown).split('\n');
  for (final entry in summary.entries) {
    final row = markdown.singleWhere(
      (line) => line.startsWith('| ${entry.key} |'),
    );
    expect(
      row,
      endsWith('| ${formatMoneyTotal(BigInt.parse(entry.value), 'CNY')} |'),
    );
  }
  return json;
}
