import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });

  tearDown(() => database.close());

  Future<ValuationSettings> settings() =>
      repository.watchValuationSettings().first;

  Future<void> setRate(String from, String to, String value) => repository
      .saveValuationRate(sourceCurrency: from, baseCurrency: to, rate: value);

  Future<NetWorthValuation> value() async => estimateNetWorth(
    await repository.watchAccountBalances().first,
    await settings(),
  );

  test(
    'historical settlement cannot satisfy a missing valuation rate',
    () async {
      await repository.setCurrentBalance(
        accountId: 'account-cash',
        amountMinor: 100000,
      );
      await repository.addAccount(
        name: 'USD wallet',
        kind: AccountKind.wallet,
        currentBalanceMinor: 0,
        currencyCode: 'USD',
      );
      final usd = (await repository.watchAccounts().first).singleWhere(
        (row) => row.currencyCode == 'USD',
      );
      await repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 72500,
        occurredAt: DateTime(2026, 11, 19),
        accountId: 'account-cash',
        targetAccountId: usd.id,
        settlement: const TransferSettlement(
          amountMinor: 10000,
          currencyCode: 'USD',
          quotedRate: '0.138',
        ),
        note: 'Historical settlement',
      );
      final before = (await repository.watchTransactions().first).single;
      expect((await value()).missingCurrencies, ['USD']);
      expect((await value()).totalMinor, isNull);

      await setRate('USD', 'CNY', '7.10');
      expect((await value()).totalMinor, BigInt.from(98500));
      await repository.setValuationBaseCurrency('USD');
      expect((await value()).missingCurrencies, ['CNY']);
      await setRate('CNY', 'USD', '0.14');
      expect((await value()).totalMinor, BigInt.from(13850));

      final after = (await repository.watchTransactions().first).single;
      expect(after.id, before.id);
      expect(after.amountMinor, 72500);
      expect(after.settlement?.amountMinor, 10000);
      expect(after.settlement?.quotedRate, '0.138');
      final balances = await repository.watchAccountBalances().first;
      expect(
        balances.singleWhere((row) => row.id == usd.id).currentBalanceMinor,
        10000,
      );
    },
  );

  test(
    'v5 and legacy v4 restore valuation, and v1–v3 retain local valuation',
    () async {
      await repository.setValuationBaseCurrency('JPY');
      await setRate('CNY', 'JPY', '20.50000');
      await setRate('USD', 'CNY', '7.123456789012345678');
      final original = await settings();
      final backup = await repository.createFullBackup();
      final payload = jsonDecode(backup) as Map<String, dynamic>;
      expect(payload['backup_version'], 5);
      expect(payload['schema_version'], 11);

      await repository.resetToFactoryDefaults();
      expect((await settings()).rates, isEmpty);
      expect((await settings()).baseCurrency, 'CNY');
      await repository.restoreFullBackup(
        backup,
        mode: BackupRestoreMode.replace,
      );
      final restored = await settings();
      expect(restored.baseCurrency, 'JPY');
      expect(
        restored.rates.map(
          (rate) => (
            rate.baseCurrency,
            rate.sourceCurrency,
            rate.rate,
            rate.updatedAt,
          ),
        ),
        original.rates.map(
          (rate) => (
            rate.baseCurrency,
            rate.sourceCurrency,
            rate.rate,
            rate.updatedAt,
          ),
        ),
      );

      payload['backup_version'] = 4;
      payload['schema_version'] = 10;
      await repository.resetToFactoryDefaults();
      await repository.restoreFullBackup(
        jsonEncode(payload),
        mode: BackupRestoreMode.replace,
      );
      expect((await settings()).baseCurrency, 'JPY');
      expect((await settings()).rates, hasLength(2));

      payload.remove('valuation');
      await repository.setValuationBaseCurrency('EUR');
      for (final version in [1, 2, 3]) {
        payload['backup_version'] = version;
        payload['schema_version'] = version + 6;
        await repository.restoreFullBackup(
          jsonEncode(payload),
          mode: BackupRestoreMode.replace,
        );
        final current = await settings();
        expect(current.baseCurrency, 'EUR');
        expect(current.rates.map((item) => item.rate), [
          '7.123456789012345678',
          '20.50000',
        ]);
      }
    },
  );

  test(
    'merge preserves the chosen base and takes the newer rate for each pair',
    () async {
      await repository.setValuationBaseCurrency('EUR');
      await setRate('USD', 'EUR', '0.9');
      await setRate('JPY', 'EUR', '0.006');
      final backup = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      final valuation = backup['valuation'] as Map<String, dynamic>;
      valuation['base_currency'] = 'USD';
      final rows = (valuation['rates'] as List).cast<Map<String, dynamic>>();
      final older = rows.singleWhere((row) => row['source_currency'] == 'USD');
      final newer = rows.singleWhere((row) => row['source_currency'] == 'JPY');
      older['updated_at'] = DateTime.utc(2000).toIso8601String();
      older['rate'] = '0.7';
      newer['updated_at'] = DateTime.utc(2100).toIso8601String();
      newer['rate'] = '0.0065';
      rows.add({
        'source_currency': 'CNY',
        'base_currency': 'USD',
        'rate': '0.14',
        'updated_at': DateTime.utc(2000).toIso8601String(),
      });
      await repository.restoreFullBackup(
        jsonEncode(backup),
        mode: BackupRestoreMode.merge,
      );
      final merged = await settings();
      expect(merged.baseCurrency, 'EUR');
      expect(
        {
          for (final rate in merged.rates)
            (rate.sourceCurrency, rate.baseCurrency): rate.rate,
        },
        {
          ('USD', 'EUR'): '0.9',
          ('JPY', 'EUR'): '0.0065',
          ('CNY', 'USD'): '0.14',
        },
      );
    },
  );

  test('invalid rate input and invalid backup replacements leave the ledger intact', () async {
    await repository.setValuationBaseCurrency('JPY');
    await setRate('USD', 'JPY', '150');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    for (final (from, to, rate) in [
      ('USD', 'JPY', '0'),
      ('USD', 'JPY', '-1'),
      ('USD', 'JPY', '1e2'),
      ('JPY', 'JPY', '1'),
      ('OLD', 'JPY', '1'),
    ]) {
      await expectLater(setRate(from, to, rate), throwsArgumentError);
    }
    final backup =
        jsonDecode(await repository.createFullBackup()) as Map<String, dynamic>;
    final valuation = backup['valuation'] as Map<String, dynamic>;
    final rates = valuation['rates'] as List;
    rates.add(rates.first);
    final cash = (backup['accounts'] as List).firstWhere(
      (item) => item['id'] == 'account-cash',
    );
    cash['opening_balance_minor'] = 1;
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(backup),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    final current = await settings();
    expect(current.baseCurrency, 'JPY');
    expect(current.rates.single.rate, '150');
    expect(
      (await repository.watchAccountBalances().first)
          .singleWhere((row) => row.id == 'account-cash')
          .currentBalanceMinor,
      1000,
    );
  });

  test(
    'removing a valuation rate does not remove the pair for another base',
    () async {
      await repository.setValuationBaseCurrency('JPY');
      await setRate('USD', 'JPY', '149.25');
      await setRate('USD', 'CNY', '7.3');
      await repository.removeValuationRate(
        sourceCurrency: 'USD',
        baseCurrency: 'JPY',
      );
      await repository.resetLedgerData();
      final current = await settings();
      expect(current.baseCurrency, 'JPY');
      expect(current.rates.single.baseCurrency, 'CNY');
      expect(current.rates.single.rate, '7.3');
    },
  );
}
