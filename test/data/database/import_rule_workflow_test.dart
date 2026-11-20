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
    conditions: [
      ImportRuleCondition(
        field: field,
        operator: ImportRuleOperator.contains,
        value: keyword,
      ),
    ],
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
    expect(
      review.suggestion?.matchedRules.first.conditions.single.value,
      'SAMPLE',
    );
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

  test('AND and OR use amount currency, keep priority, and share trial and review results', () async {
    await rule(transport, 30);
    await repo.saveImportRule(
      conditions: const [
        ImportRuleCondition(
          field: ImportRuleField.merchant,
          operator: ImportRuleOperator.startsWith,
          value: 'sample',
        ),
        ImportRuleCondition(
          field: ImportRuleField.description,
          operator: ImportRuleOperator.equals,
          value: 'Fresh meal',
        ),
        ImportRuleCondition(
          field: ImportRuleField.amount,
          operator: ImportRuleOperator.atLeast,
          value: '2.00',
          currency: 'CNY',
        ),
      ],
      categoryId: lunch,
      priority: 5,
      enabled: true,
    );
    await repo.saveImportRule(
      conditions: const [
        ImportRuleCondition(
          field: ImportRuleField.source,
          operator: ImportRuleOperator.equals,
          value: 'demo',
        ),
        ImportRuleCondition(
          field: ImportRuleField.paymentChannel,
          operator: ImportRuleOperator.equals,
          value: 'wallet',
        ),
      ],
      mode: ImportRuleMode.any,
      categoryId: transport,
      priority: 10,
      enabled: true,
    );
    final sample = parseCsvImport(
      'advanced.csv',
      utf8.encode(
        'type,amount,occurred_at,account,category,merchant,description,note,currency_code,source,payment_channel\n'
        'expense,2,2026-11-20,Cash,,Sample Coffee,Fresh meal,Other note,CNY,unknown,wallet\n'
        'expense,1.99,2026-11-21,Cash,,Sample Coffee,Fresh meal,Other note,CNY,unknown,\n'
        'expense,2,2026-11-22,Cash,,Sample Coffee,Fresh meal,Other note,JPY,unknown,\n'
        'expense,2,2026-11-23,Cash,,Another Store,Book,Office,CNY,demo,\n'
        'expense,2,2026-11-24,Cash,,Another Store,Book,Office,CNY,unknown,\n'
        'expense,2,2026-11-25,Cash,Transport/Bus & Metro,Sample Coffee,Fresh meal,Other note,CNY,unknown,wallet\n',
      ),
    );
    final trial = await repo.previewImportRules(sample);
    final review = await repo.previewCsvImport(sample);
    expect(trial.map((item) => item.suggestion?.categoryId), [
      lunch,
      transport,
      transport,
      transport,
      null,
      lunch,
    ]);
    expect(trial.first.suggestion!.matchedRules.map((rule) => rule.priority), [
      5,
      10,
      30,
    ]);
    expect(trial.last.explicitCategoryId, transport);
    expect(review.map((item) => item.mapping.categoryId), [
      lunch,
      transport,
      transport,
      transport,
      null,
      transport,
    ]);
    expect(review.last.suggestion, isNull);
    expect(await repo.watchTransactions().first, isEmpty);

    final manual = (accountId: cash, targetId: null, categoryId: transport);
    final assigned = (await repo.previewCsvImport(
      sample,
      mappings: {1: manual},
    )).first;
    expect(assigned.suggestion, isNull);
    await repo.commitCsvImport(sample, [CsvSelection(1, assigned.mapping)]);
    expect((await repo.watchTransactions().first).single.categoryId, transport);
    expect(
      (await repo.previewCsvImport(sample)).first.state,
      CsvReviewState.duplicate,
    );

    final top = (await repo.watchImportRules().first).first;
    final savedBefore = _contents(await repo.createFullBackup());
    final draft = ImportCategoryRule(
      id: top.id,
      conditions: top.conditions,
      categoryId: transport,
      priority: 5,
    );
    final simulated = (await repo.previewImportRules(
      sample,
      draft: draft,
    )).first;
    expect(simulated.suggestion!.categoryId, transport);
    expect(simulated.suggestion!.matchedRules.first, same(draft));
    expect(_contents(await repo.createFullBackup()), savedBefore);
  });

  test('V13 single conditions and V14 compound conditions restore without changing priority', () async {
    await rule(transport, 25);
    final legacy = _contents(await repo.createFullBackup())
      ..['backup_version'] = 13;
    // Preserve the top-level timestamp required by the restore protocol.
    legacy['created_at'] = '2026-11-20T12:00:00Z';
    await repo.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.replace,
    );
    final simple = (await repo.watchImportRules().first).single;
    expect(simple.conditions.single.operator, ImportRuleOperator.contains);
    expect(simple.conditions.single.value, 'SAMPLE');

    await repo.saveImportRule(
      conditions: const [
        ImportRuleCondition(
          field: ImportRuleField.amount,
          operator: ImportRuleOperator.atMost,
          value: '2.00',
          currency: 'CNY',
        ),
        ImportRuleCondition(
          field: ImportRuleField.merchant,
          operator: ImportRuleOperator.equals,
          value: 'Other',
        ),
      ],
      mode: ImportRuleMode.any,
      categoryId: lunch,
      priority: 4,
      enabled: true,
    );
    final backup = await repo.createFullBackup();
    await repo.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    await repo.restoreFullBackup(backup, mode: BackupRestoreMode.merge);
    await repo.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.merge,
    );
    expect(_contents(await repo.createFullBackup()), _contents(backup));
    expect(
      (await repo.previewCsvImport(file())).single.mapping.categoryId,
      lunch,
    );

    final invalid = jsonDecode(backup) as Map<String, dynamic>;
    final advanced = (invalid['import_category_rules'] as List).first as Map;
    (advanced['conditions'] as List).first['currency'] = 'INVALID';
    await expectLater(
      repo.restoreFullBackup(
        jsonEncode(invalid),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(_contents(await repo.createFullBackup()), _contents(backup));
  });

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

Map<String, dynamic> _contents(String backup) {
  final contents = (jsonDecode(backup) as Map<String, dynamic>)
    ..remove('created_at');
  for (final key in [
    'accounts',
    'categories',
    'entries',
    'import_category_rules',
  ]) {
    (contents[key] as List).sort(
      (a, b) => (a['id'] as String).compareTo(b['id'] as String),
    );
  }
  return contents;
}
