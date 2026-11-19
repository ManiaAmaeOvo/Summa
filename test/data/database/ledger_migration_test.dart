import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';

void main() {
  test(
    'schema 6 upgrades on disk and preserves active and deleted transactions',
    () async {
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      late Map<String, dynamic> payload;
      try {
        final repository = DriftExpenseRepository(source);
        final day = DateTime(2026, 9, 9);
        await repository.setCurrentBalance(
          accountId: 'account-bank',
          amountMinor: 800,
        );
        await repository.addTransaction(
          type: LedgerTransactionType.transfer,
          amountMinor: 150,
          occurredAt: day,
          accountId: 'account-bank',
          targetAccountId: 'account-cash',
          note: 'Transfer',
        );
        await repository.addExpense(
          amountMinor: 50,
          occurredAt: day,
          categoryId: 'expense-parent-0-child-0',
          accountId: 'account-bank',
          note: 'Deleted expense',
        );
        final records = await repository.watchTransactions().first;
        await repository.deleteTransaction(
          records.singleWhere((record) => record.note == 'Deleted expense').id,
        );
        payload = jsonDecode(
          await repository.createFullBackup(),
        ) as Map<String, dynamic>;
      } finally {
        await source.close();
      }

      final directory = await Directory.systemTemp.createTemp('summa-v6-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/ledger_pro.sqlite');
      final before = _Schema6Database(NativeDatabase(file));
      late List<EntryRow> originalRows;
      try {
        payload['format'] = 'ledgerpro_full_backup';
        payload.remove('schema_version');
        await DriftExpenseRepository(before).restoreFullBackup(
          jsonEncode(payload),
          mode: BackupRestoreMode.replace,
        );
        originalRows = await before.select(before.ledgerEntries).get();
        expect(originalRows, hasLength(2));
      } finally {
        await before.close();
      }

      for (var opening = 0; opening < 2; opening++) {
        final after = AppDatabase.forTesting(NativeDatabase(file));
        try {
          final upgraded = DriftExpenseRepository(after);
          final balances = await upgraded.watchAccountBalances().first;
          expect(
            {
              for (final account in balances)
                account.id: account.currentBalanceMinor,
            },
            allOf(
              containsPair('account-bank', 650),
              containsPair('account-cash', 150),
            ),
          );
          expect(
            await after.select(after.ledgerEntries).get(),
            unorderedEquals(originalRows),
          );
          final postings = await after
              .customSelect('SELECT * FROM ledger_postings')
              .get();
          expect(postings, hasLength(2));
          final schema = await after
              .customSelect('PRAGMA user_version')
              .getSingle();
          expect(schema.read<int>('user_version'), 7);
        } finally {
          await after.close();
        }
      }
    },
  );
}

class _Schema6Database extends AppDatabase {
  _Schema6Database(super.executor) : super.forTesting();

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: super.migration.beforeOpen,
  );
}
