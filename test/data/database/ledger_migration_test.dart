import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';

void main() {
  for (final version in [6, 7, 8, 9, 10]) {
    test('migrates schema $version to persisted postings and reopens safely', () async {
      final directory = await Directory.systemTemp.createTemp(
        'summa-v$version-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/ledger_pro.sqlite');
      final before = _LegacyDatabase(NativeDatabase(file), version);
      try {
        // Force creation and close the file before the new schema opens it.
        final schema = await before
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(schema.read<int>('user_version'), version);
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
            version >= 8
                ? {'bank': 800, 'cash': 0}
                : {'bank': 650, 'cash': 150},
          );
          final entries = await after.select(after.ledgerEntries).get();
          expect(entries, hasLength(2));
          final active = entries.singleWhere((row) => !row.isDeleted);
          final deleted = entries.singleWhere((row) => row.isDeleted);
          expect(active.id, 'bank-to-cash');
          expect(active.targetAccountId, 'cash');
          expect(active.note, 'Transfer');
          expect(active.timezoneOffsetMinutes, 480);
          expect(active.status, version >= 8 ? 'pending' : 'posted');
          expect(active.settlementAmountMinor, version >= 9 ? 2000 : null);
          expect(active.quotedExchangeRate, version >= 9 ? '13.33' : null);
          expect(deleted.id, 'hidden');
          expect(deleted.amountMinor, 50);
          final postings = await after.select(after.ledgerPostings).get();
          expect(postings, hasLength(version >= 9 ? 6 : 4));
          expect(
            postings
                .where((leg) => leg.transactionId == active.id)
                .map((leg) => leg.debitMinor),
            unorderedEquals(
              version >= 9 ? [-150, 2000, 150, -2000] : [-150, 150],
            ),
          );
          final table = await after
              .customSelect(
                "SELECT type FROM sqlite_master WHERE name = 'ledger_postings'",
              )
              .getSingle();
          expect(table.read<String>('type'), 'table');
          final schema = await after
              .customSelect('PRAGMA user_version')
              .getSingle();
          expect(schema.read<int>('user_version'), 11);
          final valuation = await upgraded.watchValuationSettings().first;
          expect(valuation.baseCurrency, version >= 10 ? 'EUR' : 'CNY');
          expect(
            valuation.rates.map((rate) => rate.rate),
            version >= 10 ? ['0.13'] : isEmpty,
          );
        } finally {
          await after.close();
        }
      }
    });
  }
}

class _LegacyDatabase extends AppDatabase {
  _LegacyDatabase(super.executor, this.schemaVersion) : super.forTesting();

  @override
  final int schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createTable(ledgerAccounts);
      await migrator.createTable(ledgerCategories);
      await customStatement('''
        CREATE TABLE ledger_entries (
          id TEXT NOT NULL PRIMARY KEY,
          transaction_type TEXT NOT NULL,
          amount_minor INTEGER NOT NULL,
          currency_code TEXT NOT NULL DEFAULT 'CNY',
          occurred_at INTEGER NOT NULL,
          timezone_offset_minutes INTEGER NOT NULL,
          category_id TEXT NOT NULL REFERENCES ledger_categories (id),
          account_id TEXT NOT NULL REFERENCES ledger_accounts (id),
          target_account_id TEXT REFERENCES ledger_accounts (id),
          note TEXT NOT NULL DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))
        )
      ''');
      if (schemaVersion == 7) {
        await customStatement('''
          CREATE INDEX ledger_entries_active_account ON ledger_entries (account_id)
          WHERE is_deleted = 0
        ''');
        await customStatement('''
          CREATE INDEX ledger_entries_active_target ON ledger_entries (target_account_id)
          WHERE is_deleted = 0
        ''');
        // The frozen fixture uses transfer and expense rows only.
        await customStatement('''
          CREATE VIEW ledger_account_postings AS
          SELECT id AS transaction_id, account_id, -amount_minor AS debit_minor
          FROM ledger_entries WHERE is_deleted = 0
          UNION ALL
          SELECT id, target_account_id, amount_minor
          FROM ledger_entries WHERE is_deleted = 0 AND target_account_id IS NOT NULL
        ''');
        await customStatement('''
          CREATE VIEW ledger_postings AS SELECT * FROM ledger_account_postings
        ''');
      }
      await customStatement('''
        INSERT INTO ledger_accounts (id, name, kind, opening_balance_minor, created_at, updated_at)
        VALUES ('bank', 'Bank', 'bank', 800, 1000, 1000),
               ('cash', 'Cash', 'cash', 0, 1000, 1000)
      ''');
      await customStatement('''
        INSERT INTO ledger_categories (id, name, transaction_type, parent_id, created_at, updated_at)
        VALUES ('flow-transfer-parent', 'Transfers', 'transfer', NULL, 1000, 1000),
               ('flow-transfer', 'Transfer', 'transfer', 'flow-transfer-parent', 1000, 1000),
               ('expense-parent', 'Food', 'expense', NULL, 1000, 1000),
               ('expense-child', 'Lunch', 'expense', 'expense-parent', 1000, 1000)
      ''');
      await customStatement('''
        INSERT INTO ledger_entries (
          id, transaction_type, amount_minor, occurred_at, timezone_offset_minutes,
          category_id, account_id, target_account_id, note, created_at, updated_at, is_deleted
        )
        VALUES ('bank-to-cash', 'transfer', 150, 2000, 480,
                'flow-transfer', 'bank', 'cash', 'Transfer', 2000, 2000, 0),
               ('hidden', 'expense', 50, 2000, 480,
                'expense-child', 'bank', NULL, 'Deleted', 2000, 2001, 1)
      ''');
      if (schemaVersion >= 8) {
        await migrator.addColumn(ledgerEntries, ledgerEntries.status);
        await migrator.addColumn(ledgerEntries, ledgerEntries.refundOfId);
        await migrator.createTable(ledgerPostings);
        await customStatement(
          "UPDATE ledger_entries SET status = 'pending' WHERE id = 'bank-to-cash'",
        );
        await customStatement('''
          INSERT INTO ledger_postings (
            transaction_id, position, account_id, currency_code, debit_minor, role
          )
          VALUES ('bank-to-cash', 0, 'bank', 'CNY', -150, 'account'),
                 ('bank-to-cash', 1, 'cash', 'CNY', 150, 'account'),
                 ('hidden', 0, 'bank', 'CNY', -50, 'account'),
                 ('hidden', 1, NULL, 'CNY', 50, 'expense')
        ''');
      }
      if (schemaVersion >= 9) {
        await migrator.addColumn(
          ledgerEntries,
          ledgerEntries.settlementAmountMinor,
        );
        await migrator.addColumn(
          ledgerEntries,
          ledgerEntries.settlementCurrencyCode,
        );
        await migrator.addColumn(
          ledgerEntries,
          ledgerEntries.quotedExchangeRate,
        );
        await customStatement(
          "UPDATE ledger_accounts SET currency_code = 'JPY' WHERE id = 'cash'",
        );
        await customStatement('''
          UPDATE ledger_entries
          SET settlement_amount_minor = 2000, settlement_currency_code = 'JPY',
              quoted_exchange_rate = '13.33'
          WHERE id = 'bank-to-cash'
        ''');
        await customStatement('''
          UPDATE ledger_postings SET currency_code = 'JPY', debit_minor = 2000
          WHERE transaction_id = 'bank-to-cash' AND position = 1
        ''');
        await customStatement('''
          INSERT INTO ledger_postings (transaction_id, position, currency_code, debit_minor, role)
          VALUES ('bank-to-cash', 2, 'CNY', 150, 'exchange'),
                 ('bank-to-cash', 3, 'JPY', -2000, 'exchange')
        ''');
      }
      if (schemaVersion >= 10) {
        await migrator.createTable(valuationPreferences);
        await migrator.createTable(valuationRates);
        await customStatement(
          "INSERT INTO valuation_preferences (id, base_currency) VALUES (1, 'EUR')",
        );
        await customStatement('''
          INSERT INTO valuation_rates (base_currency, source_currency, rate, updated_at)
          VALUES ('EUR', 'CNY', '0.13', 2000)
        ''');
      }
    },
  );
}
