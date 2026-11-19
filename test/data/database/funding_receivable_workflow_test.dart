import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

const cash = 'account-cash';
const bank = 'account-bank';
const credit = 'account-huabei';
const entrusted = 'account-family-card';
const category = 'expense-parent-0-child-1';
final date = DateTime(2026, 11, 19, 10);

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });
  tearDown(() => database.close());

  Future<String> account(String name, AccountKind kind) async {
    await repository.addAccount(name: name, kind: kind, currentBalanceMinor: 0);
    return (await repository.watchAccounts().first)
        .singleWhere((item) => item.name == name)
        .id;
  }

  Future<void> flow(
    LedgerTransactionType type,
    String source,
    String target,
    int amount, {
    DateTime? time,
    String note = '',
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => repository.addTransaction(
    type: type,
    amountMinor: amount,
    accountId: source,
    targetAccountId: target,
    occurredAt: time ?? date,
    note: note,
    status: status,
  );

  Future<Map<String, int>> balances() async => {
    for (final balance in await repository.watchAccountBalances().first)
      balance.id: balance.currentBalanceMinor,
  };

  test('funding and receivable flows reconcile spending, cash and net worth together', () async {
    final receivable = await account('Sam receivables', AccountKind.receivable);
    final payable = await account(
      'Friend paid for me',
      AccountKind.thirdPartyPayable,
    );
    await repository.setCurrentBalance(accountId: cash, amountMinor: 10000);
    await repository.setCurrentBalance(accountId: entrusted, amountMinor: 1000);

    await repository.addTransaction(
      type: LedgerTransactionType.income,
      amountMinor: 1000,
      accountId: cash,
      occurredAt: date,
      categoryId: 'income-parent-1-child-0',
      note: 'Family deposit',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 500,
      accountId: cash,
      occurredAt: date,
      categoryId: category,
      note: 'Mixed personal payment',
      payments: const [AccountPayment(cash, 300), AccountPayment(credit, 200)],
    );
    await repository.addExpense(
      amountMinor: 800,
      accountId: payable,
      occurredAt: date,
      categoryId: category,
      note: 'Personal expense paid by friend',
    );
    await repository.saveFamilyExpense(
      amountMinor: 2000,
      currencyCode: 'CNY',
      occurredAt: date,
      categoryId: category,
      note: 'Family paid directly',
    );
    await repository.saveFamilyExpense(
      amountMinor: 999,
      currencyCode: 'CNY',
      occurredAt: date,
      categoryId: category,
      note: 'Pending external expense',
      status: LedgerPostingStatus.pending,
    );
    await repository.addExpense(
      amountMinor: 600,
      accountId: entrusted,
      occurredAt: date,
      categoryId: category,
      note: 'Entrusted funds',
    );

    final original = await repository.watchTransactions().first;
    final familyPurchase = original.singleWhere(
      (record) => record.note == 'Family paid directly',
    );
    await repository.saveRefund(
      originalId: familyPurchase.id,
      accountId: familyPurchase.accountId,
      amountMinor: 500,
      occurredAt: date,
      note: 'Family refund',
    );
    final personallyPaid = original.singleWhere(
      (record) => record.note == 'Mixed personal payment',
    );
    await repository.saveRefund(
      originalId: personallyPaid.id,
      accountId: cash,
      amountMinor: 100,
      occurredAt: date,
      note: 'Cash refund',
    );

    await flow(LedgerTransactionType.lending, cash, receivable, 1500);
    await flow(LedgerTransactionType.advance, cash, receivable, 600);
    await flow(LedgerTransactionType.collection, receivable, cash, 1000);
    await flow(LedgerTransactionType.reimbursement, receivable, cash, 400);
    await flow(LedgerTransactionType.repayment, cash, payable, 400);
    await flow(LedgerTransactionType.transfer, cash, bank, 300);

    final records = await repository.watchTransactions().first;
    final activity = summarizeFinancialActivity(records, 'CNY');
    expect(activity.grossSpending, BigInt.from(3300));
    expect(activity.personalSpending, BigInt.from(1200));
    expect(activity.thirdPartyPayableSpending, BigInt.from(800));
    expect(activity.familyDirectSpending, BigInt.from(1500));
    expect(activity.entrustedSpending, BigInt.from(600));
    expect(activity.unclassifiedSpending, BigInt.zero);
    expect(activity.familySupportReceived, BigInt.from(1000));
    expect(activity.personalCashInflow, BigInt.from(2500));
    expect(activity.personalCashOutflow, BigInt.from(2800));

    final current = await balances();
    expect(current, containsPair(receivable, 700));
    expect(current, containsPair(payable, 400));
    expect(current[cash]! + current[bank]!, 9700);
    expect(current.containsKey(familyPurchase.accountId), isFalse);
    expect(
      (await repository.watchAccounts().first).any(
        (account) => account.kind == AccountKind.familyDirect,
      ),
      isFalse,
    );
    final total = estimateNetWorth(
      await repository.watchAccountBalances().first,
      const ValuationSettings(),
    );
    expect(total.totalMinor, BigInt.from(9800));

    final unbalanced = await database.customSelect('''
      SELECT transaction_id, currency_code FROM ledger_postings
      GROUP BY transaction_id, currency_code HAVING SUM(debit_minor) <> 0
    ''').get();
    expect(unbalanced, isEmpty);
  });

  test('receivables guard confirmation, edits and deletions against historical overcollection', () async {
    final receivable = await account('Sam receivables', AccountKind.receivable);
    await repository.setCurrentBalance(accountId: cash, amountMinor: 10000);
    await flow(
      LedgerTransactionType.advance,
      cash,
      receivable,
      1000,
      note: 'Advance',
    );
    final purchase = (await repository.watchTransactions().first).single;
    await flow(
      LedgerTransactionType.reimbursement,
      receivable,
      cash,
      1000,
      time: date.subtract(const Duration(days: 1)),
      note: 'Backdated reimbursement',
      status: LedgerPostingStatus.pending,
    );
    final draft = (await repository.watchTransactions().first).singleWhere(
      (row) => row.isPending,
    );
    expect(await balances(), containsPair(receivable, 1000));
    await expectLater(repository.postTransaction(draft.id), _receivableError);
    expect(
      (await repository.watchTransactions().first)
          .singleWhere((row) => row.id == draft.id)
          .isPending,
      isTrue,
    );

    await repository.updateTransaction(
      id: draft.id,
      type: LedgerTransactionType.reimbursement,
      amountMinor: 1000,
      accountId: receivable,
      targetAccountId: cash,
      occurredAt: date.add(const Duration(days: 1)),
      note: 'Reimbursement received',
    );
    await Future.wait([
      repository.postTransaction(draft.id),
      repository.postTransaction(draft.id),
    ]);
    expect(await balances(), containsPair(receivable, 0));

    await expectLater(
      repository.deleteTransaction(purchase.id),
      _receivableError,
    );
    await expectLater(
      repository.updateTransaction(
        id: purchase.id,
        type: LedgerTransactionType.advance,
        amountMinor: 999,
        accountId: cash,
        targetAccountId: receivable,
        occurredAt: date,
        note: '',
      ),
      _receivableError,
    );
    await expectLater(
      flow(
        LedgerTransactionType.collection,
        receivable,
        cash,
        1,
        time: date.add(const Duration(days: 2)),
      ),
      _receivableError,
    );
    expect(
      (await repository.watchTransactions().first).map(
        (row) => row.amountMinor,
      ),
      [1000, 1000],
    );
    expect(await balances(), containsPair(cash, 10000));
  });

  test('v5 round-trips funding and receivables, and overcollected backup rolls back', () async {
    final receivable = await account('Loan to Sam', AccountKind.receivable);
    await repository.setCurrentBalance(accountId: cash, amountMinor: 10000);
    await flow(LedgerTransactionType.lending, cash, receivable, 1000);
    await flow(
      LedgerTransactionType.collection,
      receivable,
      cash,
      200,
      time: date.add(const Duration(days: 1)),
    );
    await repository.saveFamilyExpense(
      amountMinor: 500,
      currencyCode: 'CNY',
      occurredAt: date,
      categoryId: category,
      note: 'Family purchase',
    );
    final v5 =
        jsonDecode(await repository.createFullBackup()) as Map<String, dynamic>;
    v5['backup_version'] = 5;
    v5['schema_version'] = 11;
    final backup = jsonEncode(v5);
    final before = (await repository.watchTransactions().first)
        .map((row) => row.id)
        .toList();
    await repository.resetToFactoryDefaults();
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    final records = await repository.watchTransactions().first;
    expect(records.map((row) => row.id), before);
    expect(await balances(), containsPair(receivable, 800));
    expect(
      summarizeFinancialActivity(records, 'CNY').familyDirectSpending,
      BigInt.from(500),
    );

    final damaged = jsonDecode(backup) as Map<String, dynamic>;
    final collection = (damaged['entries'] as List).singleWhere(
      (row) => row['transaction_type'] == 'collection',
    );
    collection['amount_minor'] = 1200;
    (collection['postings'] as List)[0]['debit_minor'] = -1200;
    (collection['postings'] as List)[1]['debit_minor'] = 1200;
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(damaged),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(await balances(), containsPair(receivable, 800));
    expect(
      (await repository.watchTransactions().first).map((row) => row.id),
      before,
    );
  });

  test(
    'legacy merge protects a purchase now recorded as family-funded',
    () async {
      await repository.setCurrentBalance(accountId: cash, amountMinor: 1000);
      await repository.addExpense(
        amountMinor: 200,
        accountId: cash,
        occurredAt: date,
        categoryId: category,
        note: 'Before',
      );
      final original = (await repository.watchTransactions().first).single;
      final old = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      old['backup_version'] = 4;
      old['schema_version'] = 10;
      await repository.saveFamilyExpense(
        id: original.id,
        amountMinor: 200,
        currencyCode: 'CNY',
        occurredAt: date,
        categoryId: category,
        note: 'Family paid',
      );
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(old),
          mode: BackupRestoreMode.merge,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      expect(await balances(), containsPair(cash, 1000));
      expect(
        (await repository.watchTransactions().first).single.isFamilyDirect,
        isTrue,
      );
    },
  );
}

final _receivableError = throwsA(
  isA<TransactionRuleException>().having(
    (error) => error.error,
    'rule',
    TransactionRuleError.receivableBalanceExceeded,
  ),
);
