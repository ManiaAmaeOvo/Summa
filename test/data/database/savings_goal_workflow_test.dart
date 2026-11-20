import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/transactions/expense_record.dart';

const _cash = 'account-cash';
const _food = 'expense-parent-0-child-1';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<SavingsAccountAllocation> account() async =>
      (await ledger.watchSavingsAllocations().first).single;

  test('two goals reserve real cash only once and later spending exposes the shortfall', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 10000);
    await ledger.addSavingsGoal(
      _goal('Emergency', priority: SavingsPriority.high),
    );
    await ledger.addSavingsGoal(_goal('Travel'));
    await expectLater(
      ledger.addSavingsGoal(_goal('Granted', account: 'account-family-card')),
      throwsA(_error(SavingsGoalError.invalid)),
    );
    final initial = await account();
    expect(initial.goals.map((goal) => goal.draft.name), [
      'Emergency',
      'Travel',
    ]);

    Future<SavingsGoalError?> tryReserve(SavingsGoal goal) async {
      try {
        await ledger.changeSavingsAllocation(
          goal.id,
          6000,
          note: 'First reservation',
        );
        return null;
      } on SavingsGoalException catch (error) {
        return error.error;
      }
    }

    expect(
      await Future.wait(initial.goals.map(tryReserve)),
      unorderedEquals([null, SavingsGoalError.notEnoughUnallocated]),
    );
    final reserved = await account();
    final funded = reserved.goals.singleWhere(
      (goal) => goal.activity.isNotEmpty,
    );
    expect(funded.reached, isTrue);
    expect(reserved.balanceMinor, 10000);
    expect(reserved.reservedMinor, BigInt.from(6000));
    expect(reserved.unallocatedMinor, BigInt.from(4000));
    expect(await ledger.watchTransactions().first, isEmpty);
    await expectLater(
      ledger.changeSavingsAllocation(funded.id, -6001, note: ''),
      throwsA(_error(SavingsGoalError.notEnoughReserved)),
    );

    await ledger.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 5000,
      occurredAt: DateTime(2025, 3, 15),
      accountId: _cash,
      categoryId: _food,
      status: LedgerPostingStatus.pending,
      note: 'Actual spending',
    );
    final staged = (await ledger.watchTransactions().first).single;
    expect((await account()).shortfallMinor, BigInt.zero);
    final shortage = ledger
        .watchSavingsAllocations()
        .firstWhere((items) => items.single.shortfallMinor > BigInt.zero)
        .timeout(const Duration(seconds: 5));
    await ledger.postTransaction(staged.id);
    final overspent = (await shortage).single;
    expect(overspent.balanceMinor, 5000);
    expect(overspent.reservedMinor, BigInt.from(6000));
    expect(overspent.unallocatedMinor, BigInt.zero);
    expect(overspent.shortfallMinor, BigInt.from(1000));
    await expectLater(
      ledger.changeSavingsAllocation(funded.id, 1, note: ''),
      throwsA(_error(SavingsGoalError.notEnoughUnallocated)),
    );

    await ledger.changeSavingsAllocation(
      funded.id,
      -1500,
      note: 'Release for ledger spending',
    );
    final resolved = await account();
    expect(resolved.balanceMinor, 5000);
    expect(resolved.reservedMinor, BigInt.from(4500));
    expect(resolved.unallocatedMinor, BigInt.from(500));
    expect(resolved.shortfallMinor, BigInt.zero);
    await ledger.updateSavingsGoal(
      funded.id,
      _goal('Updated goal', target: 7500),
    );
    await ledger.archiveAccount(_cash);
    await expectLater(
      ledger.changeSavingsAllocation(funded.id, 300, note: ''),
      throwsA(_error(SavingsGoalError.unavailable)),
    );
    await ledger.changeSavingsAllocation(
      funded.id,
      -500,
      note: 'Release from archived account',
    );
    final archived = await account();
    expect(archived.archived, isTrue);
    expect(
      archived.goals.singleWhere((goal) => goal.id == funded.id).draft.name,
      'Updated goal',
    );
    expect(archived.reservedMinor, BigInt.from(4000));
    expect(await ledger.watchTransactions().first, hasLength(1));
  });

  test('V13 restores legitimate shortfalls and rejects merging two competing reservations', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 10000);
    await ledger.addSavingsGoal(_goal('Travel'));
    final id = (await account()).goals.single.id;
    final base = await ledger.createFullBackup();
    await ledger.changeSavingsAllocation(id, 6000, note: 'First branch');
    final first = await ledger.createFullBackup();
    await ledger.restoreFullBackup(base, mode: BackupRestoreMode.replace);
    await ledger.changeSavingsAllocation(id, 6000, note: 'Second branch');
    await expectLater(
      ledger.restoreFullBackup(first, mode: BackupRestoreMode.merge),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(
      (await account()).goals.single.activity.single.note,
      'Second branch',
    );
    expect((await account()).unallocatedMinor, BigInt.from(4000));
    await ledger.addExpense(
      amountMinor: 5000,
      occurredAt: DateTime(2025, 3, 15),
      categoryId: _food,
      accountId: _cash,
      note: 'Later expense',
    );
    final backup = await ledger.createFullBackup();
    final json = jsonDecode(backup) as Map<String, dynamic>;
    expect(json['schema_version'], 19);
    expect(json['backup_version'], 13);
    expect(ledger.inspectFullBackup(backup).savingsGoalCount, 1);
    final v12 = jsonEncode(
      {...json, 'backup_version': 12, 'schema_version': 18}
        ..remove('savings_goals'),
    );
    await ledger.restoreFullBackup(v12, mode: BackupRestoreMode.merge);
    expect((await account()).shortfallMinor, BigInt.from(1000));
    await ledger.restoreFullBackup(v12, mode: BackupRestoreMode.replace);
    expect(await ledger.watchSavingsAllocations().first, isEmpty);
    await ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect((await account()).shortfallMinor, BigInt.from(1000));
    expect(
      (await account()).goals.single.draft.targetOn,
      DateTime.utc(2025, 12, 31),
    );
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

SavingsGoalDraft _goal(
  String name, {
  String account = _cash,
  int target = 6000,
  SavingsPriority priority = SavingsPriority.normal,
}) => SavingsGoalDraft(
  name: name,
  accountId: account,
  currency: 'CNY',
  targetMinor: target,
  priority: priority,
  targetOn: DateTime.utc(2025, 12, 31),
);

Matcher _error(SavingsGoalError error) =>
    isA<SavingsGoalException>().having((value) => value.error, 'error', error);
