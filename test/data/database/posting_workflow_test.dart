import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/ledger_export.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';

const _cash = 'account-cash';
const _bank = 'account-bank';
const _credit = 'account-huabei';
const _category = 'expense-parent-0-child-1';
final _purchaseDate = DateTime(2026, 11, 1, 13);
final _refundDate = DateTime(2026, 11, 3, 9);

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });

  tearDown(() => database.close());

  Future<Map<String, int>> balances() async => {
    for (final account in await repository.watchAccountBalances().first)
      account.id: account.currentBalanceMinor,
  };

  Future<void> addPurchase({
    List<AccountPayment> payments = const [
      AccountPayment(_cash, 2000),
      AccountPayment(_credit, 1000),
    ],
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => repository.addTransaction(
    type: LedgerTransactionType.expense,
    amountMinor: 3000,
    occurredAt: _purchaseDate,
    accountId: _cash,
    categoryId: _category,
    note: 'Purchase',
    payments: payments,
    status: status,
  );

  test(
    'a split is atomic, balance-checked per account, and editable',
    () async {
      await repository.setCurrentBalance(accountId: _cash, amountMinor: 3000);
      await repository.setCurrentBalance(accountId: _bank, amountMinor: 600);

      for (final invalid in const [
        [AccountPayment(_cash, 2000), AccountPayment(_cash, 1000)],
        [AccountPayment(_cash, 2000), AccountPayment(_credit, 999)],
        [AccountPayment(_cash, 3000), AccountPayment(_credit, 0)],
      ]) {
        await expectLater(
          addPurchase(payments: invalid),
          _rule(TransactionRuleError.invalidPaymentSplit),
        );
      }
      await expectLater(
        addPurchase(
          payments: const [
            AccountPayment(_cash, 2000),
            AccountPayment(_bank, 1000),
          ],
        ),
        _rule(TransactionRuleError.insufficientBalance),
      );
      expect(await database.select(database.ledgerPostings).get(), isEmpty);

      await addPurchase();
      final purchase = (await repository.watchTransactions().first).single;
      final legs = await database.select(database.ledgerPostings).get();
      expect(
        legs.map((leg) => leg.debitMinor),
        unorderedEquals([-2000, -1000, 3000]),
      );
      expect(purchase.accountPostings.map((leg) => leg.accountId), [
        _cash,
        _credit,
      ]);
      expect(
        await balances(),
        allOf(containsPair(_cash, 1000), containsPair(_credit, 1000)),
      );

      await repository.updateTransaction(
        id: purchase.id,
        type: LedgerTransactionType.expense,
        amountMinor: 3300,
        occurredAt: _purchaseDate,
        accountId: _cash,
        categoryId: _category,
        payments: const [
          AccountPayment(_cash, 2800),
          AccountPayment(_credit, 500),
        ],
        note: 'Updated',
      );
      expect(
        await balances(),
        allOf(containsPair(_cash, 200), containsPair(_credit, 500)),
      );
      final edited = (await repository.watchTransactions().first).single;
      expect(edited.id, purchase.id);
      expect(edited.actualExpenseMinor, 3300);

      await repository.deleteTransaction(purchase.id);
      expect(await repository.watchTransactions().first, isEmpty);
      expect(
        await balances(),
        allOf(containsPair(_cash, 3000), containsPair(_credit, 0)),
      );
      expect(
        await database.select(database.ledgerPostings).get(),
        hasLength(3),
      );
    },
  );

  test(
    'pending splits persist legs and post once only after balance validation',
    () async {
      await addPurchase(status: LedgerPostingStatus.pending);
      final pending = (await repository.watchTransactions().first).single;
      expect(pending.isPending, isTrue);
      expect(pending.actualExpenseMinor, 0);
      expect(
        await database.select(database.ledgerPostings).get(),
        hasLength(3),
      );
      expect(
        await balances(),
        allOf(containsPair(_cash, 0), containsPair(_credit, 0)),
      );
      await expectLater(
        repository.postTransaction(pending.id),
        _rule(TransactionRuleError.insufficientBalance),
      );
      expect(
        (await repository.watchTransactions().first).single.isPending,
        isTrue,
      );

      await repository.setCurrentBalance(accountId: _cash, amountMinor: 2500);
      await Future.wait([
        repository.postTransaction(pending.id),
        repository.postTransaction(pending.id),
      ]);
      final posted = (await repository.watchTransactions().first).single;
      expect(posted.isPending, isFalse);
      expect(posted.actualExpenseMinor, 3000);
      expect(
        await balances(),
        allOf(containsPair(_cash, 500), containsPair(_credit, 1000)),
      );
      expect(
        await database.select(database.ledgerPostings).get(),
        hasLength(3),
      );
    },
  );

  test('cash and credit refunds reverse only the paid portions and exclude pending effects', () async {
    await repository.setCurrentBalance(accountId: _cash, amountMinor: 3000);
    await addPurchase();
    final purchase = (await repository.watchTransactions().first).single;

    Future<void> refund(
      String account,
      int amount, {
      LedgerPostingStatus status = LedgerPostingStatus.posted,
      DateTime? occurredAt,
    }) => repository.saveRefund(
      originalId: purchase.id,
      accountId: account,
      amountMinor: amount,
      occurredAt: occurredAt ?? _refundDate,
      status: status,
      note: 'Refund',
    );

    await expectLater(refund(_bank, 100), throwsArgumentError);
    await expectLater(
      refund(_cash, 100, occurredAt: DateTime(2026)),
      throwsArgumentError,
    );
    await refund(_cash, 400);
    await refund(_credit, 300);
    await refund(_credit, 500, status: LedgerPostingStatus.pending);
    await expectLater(
      refund(_credit, 201),
      _rule(TransactionRuleError.refundLimitExceeded),
    );
    await expectLater(
      repository.deleteTransaction(purchase.id),
      _rule(TransactionRuleError.linkedRefunds),
    );
    await expectLater(
      repository.updateExpense(
        id: purchase.id,
        amountMinor: 3000,
        occurredAt: _purchaseDate,
        categoryId: _category,
        accountId: _cash,
        note: 'Rewrite',
      ),
      _rule(TransactionRuleError.linkedRefunds),
    );
    var records = await repository.watchTransactions().first;
    expect(records, hasLength(4));
    expect(
      records
          .where((row) => row.isRefund)
          .every((row) => row.refundOfId == purchase.id),
      isTrue,
    );
    expect(
      records.fold(0, (total, row) => total + row.actualExpenseMinor),
      2300,
    );
    expect(
      await balances(),
      allOf(containsPair(_cash, 1400), containsPair(_credit, 700)),
    );

    final draft = records.singleWhere((row) => row.isPending);
    await repository.postTransaction(draft.id);
    records = await repository.watchTransactions().first;
    expect(
      records.fold(0, (total, row) => total + row.actualExpenseMinor),
      1800,
    );
    expect(await balances(), containsPair(_credit, 200));
    final refundPostings = await database.select(database.ledgerPostings).get();
    expect(
      refundPostings
          .where((leg) => leg.transactionId == draft.id)
          .map((leg) => leg.debitMinor),
      unorderedEquals([500, -500]),
    );

    await repository.deleteTransaction(draft.id);
    await refund(_credit, 700);
    expect(await balances(), containsPair(_credit, 0));
  });

  test('v2 backups restore postings, pending state and refund links and reject unbalanced data', () async {
    await repository.setCurrentBalance(accountId: _cash, amountMinor: 3000);
    await addPurchase();
    final purchase = (await repository.watchTransactions().first).single;
    await repository.saveRefund(
      originalId: purchase.id,
      accountId: _cash,
      amountMinor: 250,
      occurredAt: _refundDate,
      note: 'Partial refund',
    );
    await addPurchase(status: LedgerPostingStatus.pending);

    final source = await repository.createFullBackup();
    final before = await repository.watchTransactions().first;
    await repository.resetToFactoryDefaults();
    await repository.restoreFullBackup(source, mode: BackupRestoreMode.replace);
    await repository.restoreFullBackup(source, mode: BackupRestoreMode.merge);
    final after = await repository.watchTransactions().first;
    expect(after.map((record) => record.id), before.map((record) => record.id));
    expect(
      after.singleWhere((record) => record.isRefund).refundOfId,
      purchase.id,
    );
    expect(
      after.singleWhere((record) => record.isPending).accountPostings,
      hasLength(2),
    );
    expect(
      await balances(),
      allOf(containsPair(_cash, 1250), containsPair(_credit, 1000)),
    );
    final reportExport =
        jsonDecode(exportLedgerRecords(after, LedgerExportFormat.json)) as Map;
    expect(reportExport['schema_version'], 2);
    expect(
      reportExport['transactions'],
      contains(
        allOf(
          containsPair('type', 'refund'),
          containsPair('refund_of_id', purchase.id),
        ),
      ),
    );
    expect(
      reportExport['transactions'],
      contains(
        allOf(
          containsPair('status', 'pending'),
          containsPair('payments', hasLength(2)),
        ),
      ),
    );

    final damaged = jsonDecode(source) as Map<String, dynamic>;
    final entries = (damaged['entries'] as List).cast<Map<String, dynamic>>();
    final legs =
        entries.singleWhere((row) => row['id'] == purchase.id)['postings']
            as List;
    (legs.first as Map<String, dynamic>)['debit_minor'] = -2001;
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(damaged),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(
      (await repository.watchTransactions().first).map((row) => row.id),
      before.map((row) => row.id),
    );
    expect(await balances(), containsPair(_cash, 1250));
  });

  test(
    'merging v1 cannot overwrite an existing transaction with richer postings',
    () async {
      await repository.setCurrentBalance(accountId: _cash, amountMinor: 3000);
      await addPurchase();
      final payload = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      payload['backup_version'] = 1;
      final entry = (payload['entries'] as List).single as Map<String, dynamic>;
      entry.remove('status');
      entry.remove('refund_of_id');
      entry.remove('postings');
      entry['amount_minor'] = 200;
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(payload),
          mode: BackupRestoreMode.merge,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      final purchase = (await repository.watchTransactions().first).single;
      expect(purchase.amountMinor, 3000);
      expect(purchase.accountPostings, hasLength(2));
      expect(await balances(), containsPair(_cash, 1000));
    },
  );

  test(
    'an old backup cannot overwrite the original purchase linked to a refund',
    () async {
      await repository.setCurrentBalance(accountId: _cash, amountMinor: 1000);
      await repository.addExpense(
        amountMinor: 500,
        occurredAt: _purchaseDate,
        categoryId: _category,
        accountId: _cash,
        note: 'Purchase',
      );
      final purchase = (await repository.watchTransactions().first).single;
      final old = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      old['backup_version'] = 1;
      final entry = (old['entries'] as List).single as Map<String, dynamic>;
      entry.remove('status');
      entry.remove('refund_of_id');
      entry.remove('postings');
      entry['amount_minor'] = 600;

      await repository.saveRefund(
        originalId: purchase.id,
        accountId: _cash,
        amountMinor: 125,
        occurredAt: _refundDate,
        note: 'Refund',
      );
      await expectLater(
        repository.restoreFullBackup(
          jsonEncode(old),
          mode: BackupRestoreMode.merge,
        ),
        throwsA(isA<LedgerBackupException>()),
      );
      expect(await balances(), containsPair(_cash, 625));
    },
  );
}

Matcher _rule(TransactionRuleError error) => throwsA(
  isA<TransactionRuleException>().having((e) => e.error, 'reason', error),
);
