import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/ledger_export.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';

const _cash = 'account-cash';
const _bank = 'account-bank';
const _lunch = 'expense-parent-0-child-1';
final _date = DateTime(2026, 11, 18, 9);

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });

  tearDown(() => database.close());

  Future<String> addAccount(String currency, {int balance = 0}) async {
    await repository.addAccount(
      name: '$currency Account',
      kind: AccountKind.bank,
      currentBalanceMinor: balance,
      currencyCode: currency,
    );
    final account = (await repository.watchAccounts().first).singleWhere(
      (row) => row.name == '$currency Account',
    );
    expect(account.currencyCode, currency);
    return account.id;
  }

  Future<Map<String, (String, int)>> balances() async => {
    for (final account in await repository.watchAccountBalances().first)
      account.id: (account.currencyCode, account.currentBalanceMinor),
  };

  test('foreign transfer balances each currency after restoring a sparse legacy backup', () async {
    final legacy =
        jsonDecode(await repository.createFullBackup()) as Map<String, dynamic>;
    legacy['backup_version'] = 1;
    legacy['schema_version'] = 6;
    (legacy['categories'] as List).removeWhere(
      (row) => row['transaction_type'] == 'transfer',
    );
    await repository.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.replace,
    );
    await repository.setCurrentBalance(accountId: _cash, amountMinor: 100000);
    final usd = await addAccount('USD');
    const settlement = TransferSettlement(
      amountMinor: 10000,
      currencyCode: 'USD',
      quotedRate: '0.138500',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.transfer,
      amountMinor: 72234,
      occurredAt: _date,
      accountId: _cash,
      targetAccountId: usd,
      settlement: settlement,
      note: 'Bank exchange',
    );
    final record = (await repository.watchTransactions().first).single;
    expect((record.currencyCode, record.amountMinor), ('CNY', 72234));
    expect(record.settlement?.quotedRate, '0.138500');
    expect(record.settlement?.amountMinor, 10000);
    expect(record.actualExpenseMinor, 0);
    expect(
      await balances(),
      allOf(
        containsPair(_cash, ('CNY', 27766)),
        containsPair(usd, ('USD', 10000)),
      ),
    );

    final legs = await database.select(database.ledgerPostings).get();
    expect(
      legs.map((leg) => (leg.role, leg.currencyCode, leg.debitMinor)),
      unorderedEquals([
        ('account', 'CNY', -72234),
        ('account', 'USD', 10000),
        ('exchange', 'CNY', 72234),
        ('exchange', 'USD', -10000),
      ]),
    );

    await repository.updateTransaction(
      id: record.id,
      type: LedgerTransactionType.transfer,
      amountMinor: record.amountMinor,
      occurredAt: _date,
      accountId: _cash,
      targetAccountId: usd,
      note: 'Corrected memo',
    );
    final edited = (await repository.watchTransactions().first).single;
    expect(edited.settlement?.quotedRate, '0.138500');
    expect(edited.note, 'Corrected memo');
    await repository.deleteTransaction(record.id);
    expect(
      await balances(),
      allOf(
        containsPair(_cash, ('CNY', 100000)),
        containsPair(usd, ('USD', 0)),
      ),
    );
  });

  test('pending FX never assumes a rate and confirmation checks source currency funds', () async {
    final usd = await addAccount('USD');
    final jpy = await addAccount('JPY');
    Future<void> add(TransferSettlement? settlement) =>
        repository.addTransaction(
          type: LedgerTransactionType.transfer,
          amountMinor: 1050,
          occurredAt: _date,
          accountId: usd,
          targetAccountId: jpy,
          settlement: settlement,
          status: LedgerPostingStatus.pending,
          note: '',
        );
    for (final invalid in [
      null,
      const TransferSettlement(amountMinor: 0, currencyCode: 'JPY'),
      const TransferSettlement(amountMinor: 1500, currencyCode: 'EUR'),
      const TransferSettlement(
        amountMinor: 1500,
        currencyCode: 'JPY',
        quotedRate: '0',
      ),
    ]) {
      await expectLater(
        add(invalid),
        _rule(TransactionRuleError.invalidTransferSettlement),
      );
    }
    expect(await repository.watchTransactions().first, isEmpty);
    await add(const TransferSettlement(amountMinor: 1575, currencyCode: 'JPY'));
    final draft = (await repository.watchTransactions().first).single;
    expect(draft.isPending, isTrue);
    expect(draft.settlement?.quotedRate, isNull);
    expect(
      await balances(),
      allOf(containsPair(usd, ('USD', 0)), containsPair(jpy, ('JPY', 0))),
    );
    await expectLater(
      repository.postTransaction(draft.id),
      throwsA(
        isA<TransactionRuleException>()
            .having(
              (err) => err.error,
              'reason',
              TransactionRuleError.insufficientBalance,
            )
            .having((err) => err.currencyCode, 'currency', 'USD'),
      ),
    );
    await repository.setCurrentBalance(accountId: usd, amountMinor: 3000);
    await repository.postTransaction(draft.id);
    expect(
      await balances(),
      allOf(containsPair(usd, ('USD', 1950)), containsPair(jpy, ('JPY', 1575))),
    );
  });

  test(
    'foreign expenses and refunds retain currency, and old imports stay CNY',
    () async {
      final jpy = await addAccount('JPY', balance: 1000);
      await repository.addExpense(
        amountMinor: 330,
        occurredAt: _date,
        categoryId: _lunch,
        accountId: jpy,
        note: 'Lunch',
      );
      final purchase = (await repository.watchTransactions().first).single;
      await repository.saveRefund(
        originalId: purchase.id,
        accountId: jpy,
        amountMinor: 120,
        occurredAt: _date,
        note: 'Refund',
      );
      final records = await repository.watchTransactions().first;
      expect(records.every((record) => record.currencyCode == 'JPY'), isTrue);
      expect(
        records.fold(0, (total, record) => total + record.actualExpenseMinor),
        210,
      );
      expect(await balances(), containsPair(jpy, ('JPY', 790)));

      await expectLater(
        repository.importTransactions([
          LedgerImportDraft(
            type: LedgerTransactionType.expense,
            amountMinor: 100,
            occurredAt: _date,
            accountId: jpy,
            accountName: 'JPY Account',
            accountKind: AccountKind.bank,
            categoryId: _lunch,
            note: 'CNY legacy import',
          ),
        ]),
        _rule(TransactionRuleError.currencyMismatch),
      );
      expect(await repository.watchTransactions().first, hasLength(2));
    },
  );

  test(
    'v3 and v4 backups round-trip FX exactly and reject damaged settlement',
    () async {
      final jpy = await addAccount('JPY');
      await repository.setCurrentBalance(accountId: _cash, amountMinor: 50000);
      await repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 10425,
        occurredAt: _date,
        accountId: _cash,
        targetAccountId: jpy,
        settlement: const TransferSettlement(
          amountMinor: 2100,
          currencyCode: 'JPY',
          quotedRate: '20.12500001',
        ),
        note: '',
      );
      final backup = await repository.createFullBackup();
      final before = (await repository.watchTransactions().first).single;
      await repository.resetToFactoryDefaults();
      final old = jsonDecode(backup) as Map<String, dynamic>;
      old['backup_version'] = 3;
      old['schema_version'] = 9;
      old.remove('valuation');
      await repository.restoreFullBackup(
        jsonEncode(old),
        mode: BackupRestoreMode.replace,
      );
      await repository.restoreFullBackup(backup, mode: BackupRestoreMode.merge);
      final after = (await repository.watchTransactions().first).single;
      expect(after.id, before.id);
      expect(after.settlement?.quotedRate, '20.12500001');
      expect(after.settlement?.amountMinor, 2100);
      expect(await balances(), containsPair(jpy, ('JPY', 2100)));

      final json = jsonDecode(
        exportLedgerRecords([after], LedgerExportFormat.json),
      ) as Map;
      expect(json['schema_version'], 2);
      final exported = (json['transactions'] as List).single;
      expect(
        exported,
        allOf(
          containsPair('amount', '104.25'),
          containsPair('currency_code', 'CNY'),
          containsPair('settlement_amount', '2100'),
          containsPair('settlement_currency_code', 'JPY'),
          containsPair('quoted_exchange_rate', '20.12500001'),
        ),
      );
      final damaged = jsonDecode(backup) as Map<String, dynamic>;
      final entry = (damaged['entries'] as List).single as Map<String, dynamic>;
      entry['settlement_amount_minor'] = 2101;
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(damaged),
          mode: BackupRestoreMode.replace,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      expect(await balances(), containsPair(jpy, ('JPY', 2100)));
    },
  );

  test(
    'merging an older backup cannot overwrite an FX transfer with the same ID',
    () async {
      final usd = await addAccount('USD');
      await repository.setCurrentBalance(accountId: _cash, amountMinor: 10000);
      await repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 7215,
        occurredAt: _date,
        accountId: _cash,
        targetAccountId: _bank,
        note: '',
      );
      final original = (await repository.watchTransactions().first).single;
      final old = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      old['backup_version'] = 2;
      old['schema_version'] = 8;

      await repository.updateTransaction(
        id: original.id,
        type: LedgerTransactionType.transfer,
        amountMinor: 7215,
        occurredAt: _date,
        accountId: _cash,
        targetAccountId: usd,
        settlement: const TransferSettlement(
          amountMinor: 1000,
          currencyCode: 'USD',
        ),
        note: '',
      );
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(old),
          mode: BackupRestoreMode.merge,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      expect(
        await balances(),
        allOf(
          containsPair(_bank, ('CNY', 0)),
          containsPair(usd, ('USD', 1000)),
        ),
      );
    },
  );
}

Matcher _rule(TransactionRuleError rule) => throwsA(
  isA<TransactionRuleException>().having((err) => err.error, 'reason', rule),
);
