import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/ledger_export.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const cash = 'account-cash';
const bank = 'account-bank';
const credit = 'account-huabei';
const food = 'expense-parent-0-child-1';
const transport = 'expense-parent-1-child-0';
final date = DateTime(2026, 1, 20, 12);

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });
  tearDown(() => database.close());

  Future<List<LedgerRecord>> records() => repository.watchTransactions().first;

  Future<Map<String, int>> balances() async => {
    for (final account in await repository.watchAccountBalances().first)
      account.id: account.currentBalanceMinor,
  };

  Future<void> assertBalanced() async {
    final invalid = await database.customSelect('''
      SELECT transaction_id, currency_code FROM ledger_postings
      GROUP BY transaction_id, currency_code HAVING SUM(debit_minor) <> 0
    ''').get();
    expect(invalid, isEmpty);
  }

  Future<String> addAccount(
    String name,
    AccountKind kind,
    String currency,
  ) async {
    await repository.addAccount(
      name: name,
      kind: kind,
      currentBalanceMinor: 0,
      currencyCode: currency,
    );
    return (await repository.watchAccounts().first)
        .singleWhere((row) => row.name == name)
        .id;
  }

  Future<void> addPurchase(TransactionTerms terms, {bool pending = false}) =>
      repository.addTransaction(
        type: LedgerTransactionType.expense,
        amountMinor: 1200,
        occurredAt: date,
        accountId: cash,
        categoryId: food,
        payments: const [AccountPayment(cash, 800), AccountPayment(bank, 400)],
        terms: terms,
        status: pending
            ? LedgerPostingStatus.pending
            : LedgerPostingStatus.posted,
        note: 'Split purchase',
      );

  test('settled foreign bill, AA, partial refunds, and reimbursement balance together', () async {
    await repository.setCurrentBalance(accountId: cash, amountMinor: 5000);
    await repository.setCurrentBalance(accountId: bank, amountMinor: 1000);
    final receivable = await addAccount(
      'Travel partner',
      AccountKind.receivable,
      'CNY',
    );
    await addPurchase(
      TransactionTerms(
        originalPrice: const TransferSettlement(
          amountMinor: 250,
          currencyCode: 'JPY',
          quotedRate: '0.048',
        ),
        advance: AccountPayment(receivable, 400),
        categories: const [
          (categoryId: food, amountMinor: 300),
          (categoryId: transport, amountMinor: 500),
        ],
      ),
      pending: true,
    );
    final pending = (await records()).single;
    expect(pending.spendingMinor, 0);
    expect((await balances())[receivable], 0);
    await repository.postTransaction(pending.id);
    await repository.postTransaction(pending.id);
    final purchase = (await records()).single;
    expect(purchase.currencyCode, 'CNY');
    expect(purchase.terms.originalPrice?.currencyCode, 'JPY');
    expect(purchase.terms.originalPrice?.amountMinor, 250);
    expect(purchase.terms.originalPrice?.quotedRate, '0.048');
    expect(purchase.allocationLabels[transport]?.parentId, 'expense-parent-1');
    final exported = jsonDecode(
      exportLedgerRecords([purchase], LedgerExportFormat.json),
    ) as Map;
    final bill = (exported['transactions'] as List).single as Map;
    expect(bill['amount'], '12.00');
    expect(bill['financial_details']['original_price']['amount_minor'], 250);
    expect(bill['payments'].map((payment) => payment['amount']), [
      '8.00',
      '4.00',
    ]);
    expect(purchase.spendingMinor, 800);
    expect((await balances())[receivable], 400);

    await repository.saveRefund(
      originalId: purchase.id,
      accountId: cash,
      amountMinor: 350,
      occurredAt: date.add(const Duration(hours: 1)),
      note: 'Partial refund',
    );
    await expectLater(
      repository.saveRefund(
        originalId: purchase.id,
        accountId: cash,
        amountMinor: 451,
        occurredAt: date.add(const Duration(hours: 1)),
        note: '',
      ),
      throwsA(
        isA<TransactionRuleException>().having(
          (error) => error.error,
          'error',
          TransactionRuleError.refundLimitExceeded,
        ),
      ),
    );
    final refund = (await records()).singleWhere((row) => row.isRefund);
    expect(refund.spendingCategories, [
      (categoryId: food, amountMinor: -300),
      (categoryId: transport, amountMinor: -50),
    ]);

    await repository.addTransaction(
      type: LedgerTransactionType.reimbursement,
      amountMinor: 150,
      occurredAt: date.add(const Duration(hours: 2)),
      accountId: receivable,
      targetAccountId: cash,
      note: '',
    );
    expect(await balances(), containsPair(receivable, 250));
    expect(await balances(), containsPair(cash, 4700));
    expect(await balances(), containsPair(bank, 600));
    final report = summarizeFinancialActivity(await records(), 'CNY');
    expect(report.grossSpending, BigInt.from(450));
    expect(report.personalSpending, BigInt.from(450));
    expect(report.personalCashOutflow, BigInt.from(1200));
    expect(report.personalCashInflow, BigInt.from(500));
    expect(
      summarizeFinancialActivity(await records(), 'JPY').grossSpending,
      BigInt.zero,
    );
    await assertBalanced();

    final backup = await repository.createFullBackup();
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect(
      (await records())
          .singleWhere((row) => row.id == pending.id)
          .terms
          .originalPrice
          ?.amountMinor,
      250,
    );
    expect(await balances(), containsPair(receivable, 250));
    await assertBalanced();
  });

  test('fee, interest, external debt payment, adjustment and FX reversal use distinct postings', () async {
    await repository.setCurrentBalance(accountId: cash, amountMinor: 5000);
    await repository.setCurrentBalance(accountId: credit, amountMinor: 1000);
    final yen = await addAccount('Yen wallet', AccountKind.wallet, 'JPY');
    await repository.addTransaction(
      type: LedgerTransactionType.transfer,
      amountMinor: 1000,
      occurredAt: date,
      accountId: cash,
      targetAccountId: yen,
      settlement: const TransferSettlement(
        amountMinor: 200,
        currencyCode: 'JPY',
      ),
      terms: const TransactionTerms(feeMinor: 50),
      note: 'FX transfer',
    );
    final transfer = (await records()).single;
    expect(await balances(), containsPair(cash, 3950));
    expect(await balances(), containsPair(yen, 200));

    await repository.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 200,
      occurredAt: date,
      accountId: cash,
      targetAccountId: credit,
      terms: const TransactionTerms(feeMinor: 10, interestMinor: 40),
      note: 'My payment',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 300,
      occurredAt: date,
      accountId: credit,
      terms: const TransactionTerms(externalDebtPayment: true),
      note: 'Family paid',
    );
    expect(await balances(), containsPair(credit, 500));
    expect(await balances(), containsPair(cash, 3700));
    final before = summarizeFinancialActivity(await records(), 'CNY');
    expect(before.grossSpending, BigInt.from(100));
    expect(before.personalCashOutflow, BigInt.from(300));
    expect(
      summarizeFinancialActivity(await records(), 'JPY').personalCashInflow,
      BigInt.zero,
    );
    final payment = (await records()).singleWhere(
      (row) => row.note == 'My payment',
    );
    expect(payment.spendingCategories, [
      (categoryId: financialFeeCategoryId, amountMinor: 10),
      (categoryId: financialInterestCategoryId, amountMinor: 40),
    ]);

    final reversalDate = date.add(const Duration(days: 1));
    await repository.reverseTransaction(transfer.id, occurredAt: reversalDate);
    await repository.reverseTransaction(transfer.id, occurredAt: reversalDate);
    expect((await records()).where((row) => row.isReversal), hasLength(1));
    await expectLater(
      repository.deleteTransaction(transfer.id),
      throwsA(isA<TransactionRuleException>()),
    );
    expect(await balances(), containsPair(cash, 4750));
    expect(await balances(), containsPair(yen, 0));

    await repository.recordBalanceAdjustment(
      accountId: cash,
      amountMinor: 4600,
      note: 'Counted cash',
    );
    await repository.recordBalanceAdjustment(
      accountId: credit,
      amountMinor: 550,
      note: 'Bank statement',
    );
    final adjusted = await records();
    expect(
      adjusted.where((row) => row.type == LedgerTransactionType.adjustment),
      hasLength(2),
    );
    expect(await balances(), containsPair(credit, 550));
    expect(await balances(), containsPair(cash, 4600));
    final cashRow = (await repository.watchAccountBalances().first).singleWhere(
      (row) => row.id == cash,
    );
    expect(cashRow.openingBalanceMinor, 5000);
    final after = summarizeFinancialActivity(adjusted, 'CNY');
    expect(after.grossSpending, BigInt.from(50));
    expect(after.personalCashOutflow, BigInt.from(250));
    expect(after.personalCashInflow, BigInt.zero);
    await assertBalanced();

    final backup = await repository.createFullBackup();
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect(await balances(), containsPair(cash, 4600));
    expect(
      (await records()).singleWhere((row) => row.id == transfer.id).hasReversal,
      isTrue,
    );

    final payload = jsonDecode(backup) as Map<String, dynamic>;
    final reversal = (payload['entries'] as List).singleWhere(
      (row) => row['financial_details']?['reversal_of_id'] != null,
    );
    reversal['financial_details']['reversal_of_id'] = 'missing-original';
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(payload),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(await balances(), containsPair(cash, 4600));
    await assertBalanced();
  });

  test(
    'a full AA refund cancels both spending and outstanding principal',
    () async {
      await repository.setCurrentBalance(accountId: cash, amountMinor: 5000);
      await repository.setCurrentBalance(accountId: bank, amountMinor: 1000);
      final receivable = await addAccount(
        'Unreimbursed bill',
        AccountKind.receivable,
        'CNY',
      );
      await addPurchase(
        TransactionTerms(advance: AccountPayment(receivable, 400)),
      );
      final purchase = (await records()).single;
      final refundDate = date.add(const Duration(days: 1));
      await repository.saveRefund(
        originalId: purchase.id,
        accountId: cash,
        amountMinor: 800,
        occurredAt: refundDate,
        note: 'My share fully refunded',
      );
      await repository.saveRefund(
        originalId: purchase.id,
        accountId: bank,
        amountMinor: 400,
        occurredAt: refundDate,
        note: 'Other share refunded',
        status: LedgerPostingStatus.pending,
      );
      final pending = (await records()).singleWhere(
        (record) => record.isPending,
      );
      expect(await balances(), containsPair(receivable, 400));
      await repository.postTransaction(pending.id);
      expect(await balances(), containsPair(receivable, 0));
      final combined = summarizeFinancialActivity(await records(), 'CNY');
      expect(combined.grossSpending, BigInt.zero);
      expect(combined.personalSpending, BigInt.zero);
      expect(combined.personalCashInflow, BigInt.from(1200));
      expect(combined.personalCashOutflow, BigInt.from(1200));
      await assertBalanced();
      final backup = await repository.createFullBackup();
      await repository.restoreFullBackup(
        backup,
        mode: BackupRestoreMode.replace,
      );
      expect(await balances(), containsPair(receivable, 0));
    },
  );

  test(
    'prepaid top-up and later use count consumption and cash only once',
    () async {
      await repository.setCurrentBalance(accountId: cash, amountMinor: 1000);
      final savings = await addAccount('Savings', AccountKind.savings, 'CNY');
      final prepaid = await addAccount(
        'Store credit',
        AccountKind.prepaid,
        'CNY',
      );
      await repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 200,
        occurredAt: date,
        accountId: cash,
        targetAccountId: savings,
        note: '',
      );
      await repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 300,
        occurredAt: date,
        accountId: cash,
        targetAccountId: prepaid,
        note: '',
      );
      await repository.addExpense(
        amountMinor: 150,
        occurredAt: date,
        accountId: prepaid,
        categoryId: food,
        note: '',
      );
      final report = summarizeFinancialActivity(await records(), 'CNY');
      expect(report.grossSpending, BigInt.from(150));
      expect(report.personalSpending, BigInt.from(150));
      expect(report.personalCashOutflow, BigInt.from(300));
      expect(await balances(), containsPair(savings, 200));
      expect(await balances(), containsPair(prepaid, 150));
      final stored = await repository.watchAccountBalances().first;
      expect(
        stored.singleWhere((row) => row.id == savings).group,
        AccountGroup.personalAsset,
      );
      expect(
        stored.singleWhere((row) => row.id == prepaid).group,
        AccountGroup.prepaid,
      );
      await assertBalanced();
    },
  );

  test(
    'rejects invalid detail atomically and protects it from a legacy merge',
    () async {
      await repository.setCurrentBalance(accountId: cash, amountMinor: 2000);
      await repository.setCurrentBalance(accountId: bank, amountMinor: 1000);
      await expectLater(
        addPurchase(
          const TransactionTerms(
            categories: [
              (categoryId: food, amountMinor: 300),
              (categoryId: transport, amountMinor: 100),
            ],
          ),
        ),
        throwsA(isA<TransactionRuleException>()),
      );
      expect(await records(), isEmpty);
      await addPurchase(
        const TransactionTerms(
          categories: [
            (categoryId: food, amountMinor: 300),
            (categoryId: transport, amountMinor: 900),
          ],
        ),
      );
      final payload = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      payload['backup_version'] = 5;
      ((payload['entries'] as List).single as Map).remove('financial_details');
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(payload),
          mode: BackupRestoreMode.merge,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      expect((await records()).single.terms.categories, hasLength(2));
      await assertBalanced();
    },
  );
}
