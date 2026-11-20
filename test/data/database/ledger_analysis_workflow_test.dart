import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const _cash = 'account-cash';
const _bank = 'account-bank';
const _card = 'account-family-card';
const _food = 'expense-parent-0-child-1';
const _travel = 'expense-parent-1-child-0';
final _purchaseDay = DateTime(2025, 3, 10, 12);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<List<LedgerRecord>> records() => ledger.watchTransactions().first;
  Future<String> account(
    String name,
    AccountKind kind, {
    String currency = 'CNY',
  }) async {
    await ledger.addAccount(
      name: name,
      kind: kind,
      currentBalanceMinor: 0,
      currencyCode: currency,
    );
    return (await ledger.watchAccounts().first)
        .singleWhere((row) => row.name == name)
        .id;
  }

  test('combined date, category, account and funding use the matching share and retain original records', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 10000);
    await ledger.setCurrentBalance(accountId: _card, amountMinor: 5000);
    await ledger.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 10000,
      occurredAt: _purchaseDay,
      accountId: _cash,
      categoryId: _food,
      note: 'Split',
      payments: const [
        AccountPayment(_cash, 7000),
        AccountPayment(_card, 3000),
      ],
      terms: const TransactionTerms(
        categories: [
          (categoryId: _food, amountMinor: 6001),
          (categoryId: _travel, amountMinor: 3999),
        ],
      ),
    );
    final original = (await records()).single;
    await ledger.saveRefund(
      originalId: original.id,
      accountId: _cash,
      amountMinor: 1000,
      occurredAt: _purchaseDay.add(const Duration(days: 1)),
      note: 'Refund',
    );
    await ledger.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 2000,
      occurredAt: _purchaseDay,
      accountId: _cash,
      categoryId: _food,
      status: LedgerPostingStatus.pending,
      note: 'Pending',
    );
    final all = await records();
    final plain = analyzeLedger(all, 'CNY', const LedgerFilter());
    expect(plain.activity, summarizeFinancialActivity(all, 'CNY'));
    expect(plain.activity.grossSpending, BigInt.from(9000));
    expect(plain.activity.personalSpending, BigInt.from(6000));
    expect(plain.activity.entrustedSpending, BigInt.from(3000));
    expect(plain.activity.personalCashOutflow, BigInt.from(7000));
    expect(plain.activity.personalCashInflow, BigInt.from(1000));

    final bothDays = (
      start: DateTime(2025, 3, 10),
      endExclusive: DateTime(2025, 3, 12),
    );
    final combined = LedgerFilter(
      range: bothDays,
      currency: 'CNY',
      categoryId: 'expense-parent-0',
      accountId: _cash,
      funding: LedgerFunding.personal,
    );
    expect(
      all.where(combined.matches).map((row) => row.note),
      unorderedEquals(['Split', 'Refund', 'Pending']),
    );
    expect(all.singleWhere((row) => row.id == original.id).amountMinor, 10000);
    final filtered = analyzeLedger(all, 'CNY', combined);
    expect(filtered.activity.grossSpending, BigInt.from(3200));
    expect(filtered.activity.personalCashOutflow, BigInt.from(4200));
    expect(filtered.activity.personalCashInflow, BigInt.from(1000));
    expect(filtered.expenseCategories.single.amountMinor, BigInt.from(3200));
    expect(
      filtered.spending.fold(
        BigInt.zero,
        (sum, point) => sum + point.amountMinor,
      ),
      BigInt.from(3200),
    );
    expect(filtered.accountFlows.single.id, _cash);
    final familyCardFood = analyzeLedger(
      all,
      'CNY',
      const LedgerFilter(categoryId: _food, accountId: _card),
    );
    expect(familyCardFood.activity.grossSpending, BigInt.from(1801));
    expect(familyCardFood.activity.personalCashOutflow, BigInt.zero);
    const mismatch = LedgerFilter(
      accountId: _cash,
      categoryId: _travel,
      funding: LedgerFunding.entrusted,
    );
    expect(all.where(mismatch.matches), isEmpty);

    final refundDay = analyzeLedger(
      all,
      'CNY',
      LedgerFilter(
        range: (
          start: DateTime(2025, 3, 11),
          endExclusive: DateTime(2025, 3, 12),
        ),
        categoryId: _food,
        accountId: _cash,
      ),
    );
    expect(refundDay.activity.grossSpending, BigInt.from(-1000));
    expect(refundDay.activity.personalCashInflow, BigInt.from(1000));

    final backedUp = await ledger.createFullBackup();
    final data = _backupContent(backedUp);
    expect(data['backup_version'], 14);
    await ledger.restoreFullBackup(backedUp, mode: BackupRestoreMode.replace);
    expect(
      analyzeLedger(await records(), 'CNY', combined).activity,
      filtered.activity,
    );
    expect(_backupContent(await ledger.createFullBackup()), data);
  });

  test(
    'FX account cash flows preserve both currency legs and keep fees separate',
    () async {
      final jpy = await account(
        'Japan wallet',
        AccountKind.wallet,
        currency: 'JPY',
      );
      await ledger.setCurrentBalance(accountId: _cash, amountMinor: 10000);
      await ledger.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 2500,
        occurredAt: _purchaseDay,
        accountId: _cash,
        targetAccountId: jpy,
        note: 'FX',
        settlement: const TransferSettlement(
          amountMinor: 512,
          currencyCode: 'JPY',
        ),
        terms: const TransactionTerms(feeMinor: 100),
      );
      final all = await records();
      final global = analyzeLedger(all, 'CNY', const LedgerFilter());
      expect(global.activity.personalCashOutflow, BigInt.from(100));
      expect(global.accountFlows.single.outflowMinor, BigInt.from(2600));
      expect(
        analyzeLedger(
          all,
          'JPY',
          const LedgerFilter(),
        ).activity.personalCashInflow,
        BigInt.zero,
      );
      final destination = LedgerFilter(accountId: jpy, currency: 'JPY');
      expect(destination.matches(all.single), isTrue);
      final inYen = analyzeLedger(all, 'JPY', destination);
      expect(inYen.activity.personalCashInflow, BigInt.from(512));
      expect(inYen.incomeMinor, BigInt.zero);
      expect(inYen.activity.grossSpending, BigInt.zero);
      expect(
        LedgerFilter(accountId: jpy, currency: 'CNY').matches(all.single),
        isFalse,
      );

      final fee = analyzeLedger(
        all,
        'CNY',
        const LedgerFilter(
          accountId: _cash,
          categoryId: financialFeeCategoryId,
        ),
      );
      expect(fee.activity.grossSpending, BigInt.from(100));
      expect(fee.activity.personalCashOutflow, BigInt.from(100));
      final principal = analyzeLedger(
        all,
        'CNY',
        const LedgerFilter(accountId: _cash, categoryId: 'flow-transfer'),
      );
      expect(principal.activity.grossSpending, BigInt.zero);
      expect(principal.activity.personalCashOutflow, BigInt.from(2500));
      final balances = {
        for (final row in await ledger.watchAccountBalances().first)
          row.id: row.currentBalanceMinor,
      };
      expect(10000 - balances[_cash]!, 2600);
      expect(balances[jpy], 512);
    },
  );

  test('AA principal belongs to cash flow, and reversing a posted share offsets its original side', () async {
    final receivable = await account('Travel share', AccountKind.receivable);
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 5000);
    await ledger.setCurrentBalance(accountId: _bank, amountMinor: 5000);
    await ledger.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 1200,
      occurredAt: _purchaseDay,
      accountId: _cash,
      categoryId: _food,
      note: 'AA',
      payments: const [AccountPayment(_cash, 800), AccountPayment(_bank, 400)],
      terms: TransactionTerms(advance: AccountPayment(receivable, 400)),
    );
    final original = (await records()).single;
    const cashScope = LedgerFilter(accountId: _cash);
    final accountFlow = analyzeLedger(await records(), 'CNY', cashScope);
    expect(accountFlow.activity.grossSpending, BigInt.from(533));
    expect(accountFlow.activity.personalCashOutflow, BigInt.from(800));
    final food = analyzeLedger(
      await records(),
      'CNY',
      const LedgerFilter(accountId: _cash, categoryId: _food),
    );
    expect(food.activity.personalCashOutflow, BigInt.from(533));
    final other = analyzeLedger(
      await records(),
      'CNY',
      const LedgerFilter(accountId: _bank),
    );
    expect(other.activity.grossSpending, BigInt.from(267));
    expect(other.activity.personalCashOutflow, BigInt.from(400));
    final owing = LedgerFilter(accountId: receivable);
    expect(owing.matches(original), isTrue);
    expect(
      analyzeLedger(await records(), 'CNY', owing).activity.personalCashOutflow,
      BigInt.zero,
    );

    await ledger.reverseTransaction(
      original.id,
      occurredAt: _purchaseDay.add(const Duration(days: 1)),
    );
    final reversed = analyzeLedger(await records(), 'CNY', cashScope);
    expect(reversed.activity.grossSpending, BigInt.zero);
    expect(reversed.activity.personalCashInflow, BigInt.zero);
    expect(reversed.activity.personalCashOutflow, BigInt.zero);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

Map<String, dynamic> _backupContent(String source) {
  final data = (jsonDecode(source) as Map<String, dynamic>)
    ..remove('created_at');
  for (final key in ['accounts', 'categories', 'entries']) {
    (data[key] as List<dynamic>).sort(
      (a, b) => (a['id'] as String).compareTo(b['id'] as String),
    );
  }
  return data;
}
