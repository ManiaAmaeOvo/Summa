import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/reconciliation/reconciliation_candidates.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';

const cash = 'account-cash';
const credit = 'account-huabei';
const food = 'expense-parent-0-child-1';
final morning = DateTime(2026, 1, 10, 9);
final noon = DateTime(2026, 1, 10, 12);
final evening = DateTime(2026, 1, 10, 19);
final later = DateTime(2026, 1, 11, 9);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(db);
  });

  tearDown(() => db.close());

  Future<List<BalanceCheckpoint>> checkpoints([String id = cash]) =>
      repository.watchBalanceCheckpoints(id).first;

  Future<void> saveCheckpoint(
    DateTime at,
    int actual, [
    String accountId = cash,
  ]) => repository.saveBalanceCheckpoint(
    accountId: accountId,
    observedAt: at,
    actualMinor: actual,
    note: '  Statement  ',
  );

  Future<void> expense(
    int amount,
    DateTime at,
    String note, {
    String accountId = cash,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => repository.addTransaction(
    type: LedgerTransactionType.expense,
    amountMinor: amount,
    occurredAt: at,
    accountId: accountId,
    categoryId: food,
    status: status,
    note: note,
  );

  test(
    'historical checkpoint recalculates after edits, confirmation and deletion',
    () async {
      await repository.setCurrentBalance(accountId: cash, amountMinor: 10000);
      await expense(2000, noon, 'Errand');
      await expense(800, later, 'Future relative to checkpoint');
      await expense(
        500,
        evening,
        'Pending charge',
        status: LedgerPostingStatus.pending,
      );
      await saveCheckpoint(morning, 10000);
      await saveCheckpoint(evening, 7500);
      final initial = await checkpoints();
      expect(initial.last.isBalanced, isTrue);
      final first = initial.first;
      expect(first.bookMinor, 8000);
      expect(first.recordedBookMinor, 8000);
      expect(first.note, 'Statement');
      expect(first.differenceMinor, BigInt.from(-500));

      final records = await repository.watchTransactions().first;
      final candidates = reconciliationCandidates(
        records,
        checkpoint: first,
        isLiability: false,
        after: morning,
      );
      expect(candidates.map((row) => row.record.note), [
        'Pending charge',
        'Errand',
      ]);
      expect(candidates.first.matchesDifference, isTrue);

      final main = records.singleWhere((row) => row.note == 'Errand');
      await repository.updateExpense(
        id: main.id,
        amountMinor: 2500,
        occurredAt: noon,
        accountId: cash,
        categoryId: food,
        note: main.note,
      );
      expect((await checkpoints()).first.isBalanced, isTrue);
      await expectLater(
        repository.adjustBalanceCheckpoint(first.id, expectedBookMinor: 8000),
        throwsA(
          isA<ReconciliationException>().having(
            (error) => error.error,
            'error',
            ReconciliationError.changed,
          ),
        ),
      );
      final pending = records.singleWhere((row) => row.isPending);
      await repository.postTransaction(pending.id);
      final updated = (await checkpoints()).first;
      expect(updated.bookMinor, 7000);
      expect(updated.recordedBookMinor, 8000);
      expect(updated.differenceMinor, BigInt.from(500));
      await repository.deleteTransaction(pending.id);
      expect((await checkpoints()).first.isBalanced, isTrue);
    },
  );

  test('posted difference affects the liability at the observed time and can be voided', () async {
    await expense(1000, morning, 'Credit card purchase', accountId: credit);
    await expense(200, later, 'Later purchase', accountId: credit);
    await saveCheckpoint(noon, 1500, credit);
    final point = (await checkpoints(credit)).single;
    expect(point.bookMinor, 1000);
    await repository.adjustBalanceCheckpoint(point.id, expectedBookMinor: 1000);
    final active = (await checkpoints(credit)).single;
    expect(active.bookMinor, 1500);
    expect(active.isBalanced, isTrue);
    expect(active.recordedBookMinor, 1000);
    final records = await repository.watchTransactions().first;
    final adjustment = records.singleWhere(
      (row) => row.id == active.adjustmentId,
    );
    expect(adjustment.amountMinor, -500);
    expect(adjustment.occurredAt, noon);
    expect(adjustment.isReconciliationAdjustment, isTrue);
    expect(adjustment.canReverse, isFalse);
    final report = summarizeFinancialActivity(records, 'CNY');
    expect(report.grossSpending, BigInt.from(1200));
    expect(report.personalCashInflow, BigInt.zero);
    await expectLater(
      repository.reverseTransaction(adjustment.id, occurredAt: later),
      throwsA(
        isA<TransactionRuleException>().having(
          (error) => error.error,
          'error',
          TransactionRuleError.linkedCheckpoint,
        ),
      ),
    );
    await expectLater(
      repository.deleteTransaction(adjustment.id),
      throwsA(isA<TransactionRuleException>()),
    );
    await repository.voidBalanceCheckpoint(point.id);
    await repository.voidBalanceCheckpoint(point.id);
    final voided = (await checkpoints(credit)).single;
    expect(voided.isVoided, isTrue);
    expect(voided.isBalanced, isFalse);
    expect(voided.bookMinor, 1000);
    expect(voided.adjustmentId, active.adjustmentId);
    expect(
      (await repository.watchTransactions().first).any(
        (row) => row.id == adjustment.id,
      ),
      isFalse,
    );
    expect(
      (await db.select(db.ledgerEntries).get())
          .singleWhere((entry) => entry.id == adjustment.id)
          .isDeleted,
      isTrue,
    );
  });

  test('voiding a receivable adjustment rolls back if principal has been collected', () async {
    await repository.addAccount(
      name: 'Receivable',
      kind: AccountKind.receivable,
      currentBalanceMinor: 0,
    );
    final account = (await repository.watchAccounts().first).singleWhere(
      (row) => row.kind == AccountKind.receivable,
    );
    await saveCheckpoint(noon, 500, account.id);
    final point = (await checkpoints(account.id)).single;
    await repository.adjustBalanceCheckpoint(point.id, expectedBookMinor: 0);
    await repository.addTransaction(
      type: LedgerTransactionType.collection,
      amountMinor: 500,
      occurredAt: later,
      accountId: account.id,
      targetAccountId: cash,
      note: '',
    );
    await expectLater(
      repository.voidBalanceCheckpoint(point.id),
      throwsA(
        isA<TransactionRuleException>().having(
          (error) => error.error,
          'error',
          TransactionRuleError.receivableBalanceExceeded,
        ),
      ),
    );
    expect((await checkpoints(account.id)).single.isBalanced, isTrue);
    expect((await repository.watchTransactions().first), hasLength(2));
  });

  test('version 7 preserves checkpoints and rejects inconsistent adjustment atomically', () async {
    await repository.setCurrentBalance(accountId: cash, amountMinor: 1000);
    await saveCheckpoint(noon, 1250);
    final point = (await checkpoints()).single;
    await repository.adjustBalanceCheckpoint(point.id, expectedBookMinor: 1000);
    final backup = await repository.createFullBackup();
    expect(repository.inspectFullBackup(backup).checkpointCount, 1);
    await repository.resetToFactoryDefaults();
    expect(await checkpoints(), isEmpty);
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect((await checkpoints()).single.isBalanced, isTrue);
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.merge);
    expect(await checkpoints(), hasLength(1));

    final oldFormat = jsonDecode(backup) as Map<String, dynamic>;
    oldFormat['backup_version'] = 6;
    oldFormat.remove('balance_checkpoints');
    await repository.restoreFullBackup(
      jsonEncode(oldFormat),
      mode: BackupRestoreMode.merge,
    );
    expect((await checkpoints()).single.isBalanced, isTrue);

    (oldFormat['accounts'] as List).singleWhere(
      (row) => row['id'] == cash,
    )['kind'] = 'creditLine';
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(oldFormat),
        mode: BackupRestoreMode.merge,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await checkpoints()).single.isBalanced, isTrue);

    final damaged = jsonDecode(backup) as Map<String, dynamic>;
    (damaged['balance_checkpoints'] as List).single['adjusted_book_minor'] =
        1001;
    await expectLater(
      repository.restoreFullBackup(
        jsonEncode(damaged),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await checkpoints()).single.isBalanced, isTrue);
    await repository.voidBalanceCheckpoint(point.id);
    final voided = await repository.createFullBackup();
    await repository.restoreFullBackup(voided, mode: BackupRestoreMode.replace);
    expect((await checkpoints()).single.isVoided, isTrue);
    await expectLater(
      repository.restoreFullBackup(backup, mode: BackupRestoreMode.merge),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await checkpoints()).single.isVoided, isTrue);
  });
}
