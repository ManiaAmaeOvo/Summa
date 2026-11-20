import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/statement_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';

const _account = 'migration-smoke-cash';
const _suggestedCategory = 'migration-smoke-child';
const _legacyExpense = 'migration-smoke-record';
const _csv =
    'type,amount,occurred_at,account,note\n'
    'expense,1.50,2026-11-20T00:40:00+08:00,Migration test cash,Demo Lunch\n';

void main() {
  test(
    'Phase 2 ledger continuity across review, reconciliation, restore and undo',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final ledger = DriftExpenseRepository(db);
      final file = parseStatementImport('rule-smoke.csv', utf8.encode(_csv));

      Future<int> cash() async => (await ledger.watchAccountBalances().first)
          .single
          .currentBalanceMinor;
      Future<int> spending() async => summarizeFinancialActivity(
        await ledger.watchTransactions().first,
        'CNY',
      ).grossSpending.toInt();
      final observedAt = DateTime.parse('2026-11-20T08:00:00+08:00');

      await ledger.restoreFullBackup(
        _legacyBackup,
        mode: BackupRestoreMode.replace,
      );
      expect(await cash(), 7655);
      expect(await spending(), 2345);
      await ledger.addCategory(
        type: LedgerTransactionType.expense,
        name: 'Reviewed lunch',
        parentId: 'migration-smoke-parent',
      );
      final reviewedCategory = (await ledger.watchExpenseCategories().first)
          .singleWhere((item) => item.name == 'Reviewed lunch')
          .id;
      await ledger.saveImportRule(
        field: ImportRuleField.description,
        keyword: 'Demo',
        categoryId: _suggestedCategory,
        priority: 100,
        enabled: true,
      );
      await ledger.saveBalanceCheckpoint(
        accountId: _account,
        observedAt: observedAt,
        actualMinor: 7505,
        note: 'Synthetic cash count',
      );
      var checkpoint =
          (await ledger.watchBalanceCheckpoints(_account).first).single;
      final checkpointId = checkpoint.id;
      expect(checkpoint.differenceMinor, BigInt.from(-150));

      final suggestion = (await ledger.previewCsvImport(file)).single;
      expect(suggestion.mapping.categoryId, _suggestedCategory);
      expect(suggestion.suggestion?.keyword, 'Demo');
      expect(await cash(), 7655);

      final batch = await ledger.commitCsvImport(file, [
        CsvSelection(1, (
          accountId: suggestion.mapping.accountId,
          targetId: null,
          categoryId: reviewedCategory,
        )),
      ]);
      expect((batch.added, batch.matched), (1, 0));
      final item = (await ledger.readCsvBatchItems(batch.batchId)).single;
      expect(item.raw['note'], 'Demo Lunch');
      final imported = (await ledger.watchTransactions().first).singleWhere(
        (record) => record.id == item.entryId,
      );
      expect(imported.categoryId, reviewedCategory);
      expect(await cash(), 7505);
      expect(await spending(), 2495);
      checkpoint =
          (await ledger.watchBalanceCheckpoints(_account).first).single;
      expect(checkpoint.isBalanced, isTrue);
      expect(checkpoint.id, checkpointId);
      expect(checkpoint.recordedBookMinor, 7655);
      expect(
        (await ledger.previewCsvImport(file)).single.state,
        CsvReviewState.duplicate,
      );

      final overlap = parseStatementImport(
        'overlap.csv',
        utf8.encode(
          'type,amount,occurred_at,account,note,source,external_id\n'
          'expense,1.50,2026-11-20T00:40:00+08:00,Migration test cash,Demo Lunch,synthetic,match-1\n',
        ),
      );
      final match = (await ledger.previewCsvImport(overlap)).single;
      expect(match.state, CsvReviewState.similar);
      expect(match.matches.single.id, item.entryId);
      final linked = await ledger.commitCsvImport(overlap, [
        CsvSelection(1, match.mapping, matchId: item.entryId),
      ]);
      expect((linked.added, linked.matched), (0, 1));
      expect(await cash(), 7505);

      final backup = await ledger.createFullBackup();
      expect(jsonDecode(backup)['backup_version'], 9);
      final preview = ledger.inspectFullBackup(backup);
      expect(preview.checkpointCount, 1);
      expect(preview.importBatchCount, 2);

      // Restore over the legacy ledger, then use the restored batch snapshots.
      await ledger.restoreFullBackup(
        _legacyBackup,
        mode: BackupRestoreMode.replace,
      );
      expect(await cash(), 7655);
      expect(await ledger.watchCsvBatches().first, isEmpty);
      expect(await ledger.watchImportRules().first, isEmpty);
      expect(await ledger.watchBalanceCheckpoints(_account).first, isEmpty);
      await ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
      expect(await cash(), 7505);
      expect(
        (await ledger.watchTransactions().first)
            .singleWhere((record) => record.id == item.entryId)
            .categoryId,
        reviewedCategory,
      );
      expect((await ledger.watchImportRules().first).single.keyword, 'Demo');
      expect(
        (await ledger.watchBalanceCheckpoints(_account).first)
            .single
            .isBalanced,
        isTrue,
      );
      expect(
        (await ledger.previewCsvImport(file)).single.state,
        CsvReviewState.duplicate,
      );
      await expectLater(
        ledger.undoCsvImport(batch.batchId),
        throwsA(
          isA<CsvBatchException>().having(
            (error) => error.error,
            'error',
            CsvBatchError.linked,
          ),
        ),
      );
      expect(await cash(), 7505);
      await ledger.undoCsvImport(linked.batchId);
      expect(await cash(), 7505);
      await ledger.undoCsvImport(batch.batchId);
      expect(await cash(), 7655);
      expect(await spending(), 2345);
      expect(
        (await ledger.watchTransactions().first).single.id,
        _legacyExpense,
      );
      expect(
        (await ledger.watchBalanceCheckpoints(_account).first)
            .single
            .differenceMinor,
        BigInt.from(-150),
      );
      expect(
        (await ledger.watchCsvBatches().first)
            .where((row) => row.undoneAt != null)
            .map((row) => row.id),
        unorderedEquals([batch.batchId, linked.batchId]),
      );
      expect(
        (await ledger.readCsvBatchItems(batch.batchId)).single.entryId,
        item.entryId,
      );
      expect(
        (await ledger.previewCsvImport(file)).single.suggestion?.categoryId,
        _suggestedCategory,
      );

      final undone = await ledger.createFullBackup();
      await expectLater(
        ledger.restoreFullBackup(backup, mode: BackupRestoreMode.merge),
        throwsA(isA<LedgerBackupException>()),
      );
      expect(await cash(), 7655);
      await ledger.restoreFullBackup(undone, mode: BackupRestoreMode.replace);
      expect(
        (await ledger.watchCsvBatches().first)
            .where((row) => row.undoneAt != null)
            .map((row) => row.id),
        unorderedEquals([batch.batchId, linked.batchId]),
      );
      expect(await cash(), 7655);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      expect(
        await db.customSelect('''
      SELECT transaction_id FROM ledger_postings
      GROUP BY transaction_id, currency_code HAVING SUM(debit_minor) <> 0
    ''').get(),
        isEmpty,
      );
    },
  );
}

const _legacyBackup = '''
{
  "format": "ledgerpro_full_backup",
  "backup_version": 1,
  "created_at": "2026-11-18T12:00:00.000",
  "accounts": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "id": "migration-smoke-cash",
      "name": "Migration test cash",
      "kind": "cash",
      "currency_code": "CNY",
      "opening_balance_minor": 10000,
      "sort_order": 0,
      "is_archived": false
    }
  ],
  "categories": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "sort_order": 0,
      "is_archived": false,
      "transaction_type": "expense",
      "id": "migration-smoke-parent",
      "name": "Migration test",
      "parent_id": null
    },
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "sort_order": 0,
      "is_archived": false,
      "transaction_type": "expense",
      "id": "migration-smoke-child",
      "name": "Migration test expense",
      "parent_id": "migration-smoke-parent"
    }
  ],
  "entries": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "id": "migration-smoke-record",
      "transaction_type": "expense",
      "amount_minor": 2345,
      "currency_code": "CNY",
      "occurred_at": "2026-11-18T12:00:00.000",
      "timezone_offset_minutes": 0,
      "category_id": "migration-smoke-child",
      "account_id": "migration-smoke-cash",
      "target_account_id": null,
      "note": "Migration smoke test",
      "is_deleted": false
    }
  ]
}
''';
