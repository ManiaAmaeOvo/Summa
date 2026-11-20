import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';

const lunch = 'expense-parent-0-child-1';
const transport = 'expense-parent-1-child-0';
const salary = 'income-parent-0-child-0';
const cash = 'account-cash';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftExpenseRepository(db);
    await repo.setCurrentBalance(accountId: cash, amountMinor: 10000);
  });
  tearDown(() => db.close());

  Future<void> rule(
    String category,
    int priority, {
    bool enabled = true,
    ImportRuleField field = ImportRuleField.merchant,
    String keyword = 'SAMPLE',
  }) => repo.saveImportRule(
    field: field,
    keyword: keyword,
    categoryId: category,
    priority: priority,
    enabled: enabled,
  );

  CsvImportFile file({String category = '', String type = 'expense'}) =>
      parseCsvImport(
        'rule.csv',
        utf8.encode(
          'type,amount,occurred_at,account,category,merchant,note\n'
          '$type,2,2026-11-20,Cash,$category,Sample Coffee,late lunch\n',
        ),
      );

  test('rules rank and filter by type; reviewer can override and explicit source category wins', () async {
    await rule(transport, 25);
    await rule(lunch, 10);
    await rule(salary, 0);
    await rule(transport, 0, enabled: false);
    final source = file();
    final review = (await repo.previewCsvImport(source)).single;
    expect(review.suggestion?.categoryId, lunch);
    expect(review.suggestion?.keyword, 'SAMPLE');
    expect(review.mapping.categoryId, lunch);
    expect(await repo.watchTransactions().first, isEmpty);

    final income = (await repo.previewCsvImport(file(type: 'income'))).single;
    expect(income.mapping.categoryId, salary);
    final explicit = (await repo.previewCsvImport(
      file(category: 'Transport/Bus & Metro'),
    )).single;
    expect(explicit.mapping.categoryId, transport);
    expect(explicit.suggestion, isNull);

    final manual = (accountId: cash, targetId: null, categoryId: transport);
    final overridden = (await repo.previewCsvImport(
      source,
      mappings: {1: manual},
    )).single;
    expect(overridden.mapping, manual);
    expect(overridden.suggestion, isNull);
    await repo.commitCsvImport(source, [CsvSelection(1, manual)]);
    expect((await repo.watchTransactions().first).single.categoryId, transport);
  });

  test(
    'ties require review, disabled and archived targets cannot be suggested',
    () async {
      await rule(lunch, 10);
      await rule(
        transport,
        10,
        field: ImportRuleField.description,
        keyword: 'LUNCH',
      );
      var reviewed = (await repo.previewCsvImport(file())).single;
      expect(reviewed.suggestion, isNotNull);
      expect(reviewed.suggestion?.categoryId, isNull);
      expect(reviewed.state, CsvReviewState.unresolved);
      await repo.archiveCategory(transport);
      reviewed = (await repo.previewCsvImport(file())).single;
      expect(reviewed.mapping.categoryId, lunch);
      await repo.archiveCategory(lunch);
      reviewed = (await repo.previewCsvImport(file())).single;
      expect(reviewed.suggestion, isNull);
      expect(reviewed.state, CsvReviewState.unresolved);
    },
  );

  test('rule backup round-trips and old merge preserves rules; invalid restore is atomic', () async {
    final legacy =
        jsonDecode(await repo.createFullBackup()) as Map<String, dynamic>;
    legacy['backup_version'] = 8;
    legacy.remove('import_category_rules');
    await rule(lunch, 10);
    await repo.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.merge,
    );
    final saved = await repo.createFullBackup();
    final oldId = (await repo.watchImportRules().first).single.id;
    await repo.resetToFactoryDefaults();
    expect(await repo.watchImportRules().first, isEmpty);
    await repo.restoreFullBackup(saved, mode: BackupRestoreMode.replace);
    expect((await repo.watchImportRules().first).single.id, oldId);
    final corrupted = jsonDecode(saved) as Map;
    (corrupted['import_category_rules'] as List).single['category_id'] =
        'unavailable';
    await expectLater(
      repo.restoreFullBackup(
        jsonEncode(corrupted),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await repo.watchImportRules().first).single.id, oldId);
    await repo.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.replace,
    );
    expect(await repo.watchImportRules().first, isEmpty);
  });
}
