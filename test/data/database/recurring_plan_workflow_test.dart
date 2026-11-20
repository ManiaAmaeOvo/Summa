import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';

const _cash = 'account-cash';
const _bank = 'account-bank';
const _category = 'expense-parent-0-child-1';
const _salary = 'income-parent-0-child-0';
final _first = DateTime.utc(2025, 1, 31);
final _actual = DateTime(2025, 2, 2, 12);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<List<LedgerRecord>> transactions() => ledger.watchTransactions().first;
  Future<List<RecurringPlan>> plans() => ledger.watchRecurringPlans().first;
  Future<RecurringPlan> named(String name) async =>
      (await plans()).singleWhere((plan) => plan.draft.name == name);
  Future<int> cash() async => (await ledger.watchAccountBalances().first)
      .singleWhere((account) => account.id == _cash)
      .currentBalanceMinor;

  test(
    'recurrence keeps the original month anchor and handles all cadences',
    () {
      final next = {
        RecurringCadence.daily: DateTime.utc(2025, 2, 1),
        RecurringCadence.weekly: DateTime.utc(2025, 2, 7),
        RecurringCadence.monthly: DateTime.utc(2025, 2, 28),
        RecurringCadence.quarterly: DateTime.utc(2025, 4, 30),
        RecurringCadence.yearly: DateTime.utc(2026, 1, 31),
        RecurringCadence.custom: DateTime.utc(2025, 2, 10),
      };
      for (final entry in next.entries) {
        final draft = _plan(
          'Test',
          cadence: entry.key,
          days: entry.key == RecurringCadence.custom ? 10 : null,
        );
        expect(draft.isValid, isTrue);
        expect(draft.dueOn(0), _first);
        expect(draft.dueOn(1), entry.value);
      }
      expect(_plan('Monthly').dueOn(2), DateTime.utc(2025, 3, 31));
      expect(
        _plan(
          'Custom',
          cadence: RecurringCadence.custom,
          days: 3650,
        ).dueOn(109000),
        isNull,
      );
    },
  );

  test('a paused plan waits for review, failed or concurrent confirmation posts at most once', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 3000);
    await ledger.addRecurringPlan(_plan('Subscription'));
    final id = (await named('Subscription')).id;
    expect(await cash(), 3000);
    expect(await transactions(), isEmpty);

    await ledger.setRecurringPlanPaused(id, true);
    expect((await named('Subscription')).nextDueOn, _first);
    Future<void> confirm(int amount, {DateTime? at}) =>
        ledger.confirmRecurringOccurrence(
          id,
          0,
          amountMinor: amount,
          occurredAt: at ?? _actual,
          note: 'Confirmed',
        );
    await expectLater(
      confirm(1200),
      throwsA(_planError(RecurringPlanError.paused)),
    );
    await ledger.setRecurringPlanPaused(id, false);
    await expectLater(confirm(3500), throwsA(isA<TransactionRuleException>()));
    await expectLater(
      confirm(1200, at: DateTime.now().add(const Duration(days: 1))),
      throwsA(_planError(RecurringPlanError.invalid)),
    );
    expect(await transactions(), isEmpty);
    expect((await named('Subscription')).nextIndex, 0);

    Future<Object?> attempt() async {
      try {
        await confirm(1200);
        return null;
      } on RecurringPlanException catch (error) {
        return error.error;
      }
    }

    expect(
      await Future.wait([attempt(), attempt()]),
      unorderedEquals([null, RecurringPlanError.stale]),
    );
    final record = (await transactions()).single;
    expect(record.amountMinor, 1200);
    expect(record.occurredAt, _actual);
    expect(record.isPending, isFalse);
    expect(await cash(), 1800);

    await ledger.setRecurringPlanExpectedAmount(id, 1500);
    final completed = await named('Subscription');
    expect(completed.draft.expectedMinor, 1500);
    expect(completed.occurrences.single, (
      index: 0,
      entryId: record.id,
      expectedMinor: 1000,
    ));
    expect(completed.nextDueOn, DateTime.utc(2025, 2, 28));
    expect(
      await db.customSelect('''
      SELECT transaction_id FROM ledger_postings GROUP BY transaction_id, currency_code
      HAVING SUM(debit_minor) <> 0
    ''').get(),
      isEmpty,
    );
  });

  test('linking consumes one cycle without posting and retains the link after removal', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 5000);
    await ledger.setCurrentBalance(accountId: _bank, amountMinor: 5000);
    await ledger.addRecurringPlan(
      _plan('Expense', kind: RecurringPlanKind.expense),
    );
    await ledger.addRecurringPlan(
      _plan('Salary', kind: RecurringPlanKind.income),
    );
    final expense = (await named('Expense')).id;
    final salary = (await named('Salary')).id;

    await ledger.addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: 1300,
      occurredAt: _actual,
      categoryId: _category,
      accountId: _bank,
      payments: const [AccountPayment(_bank, 900), AccountPayment(_cash, 400)],
      status: LedgerPostingStatus.pending,
      note: 'Actual split expense',
    );
    final entry = (await transactions()).single.id;
    await expectLater(
      ledger.linkRecurringOccurrence(expense, 0, entry),
      throwsA(_planError(RecurringPlanError.ineligible)),
    );
    await ledger.postTransaction(entry);
    await expectLater(
      ledger.linkRecurringOccurrence(salary, 0, entry),
      throwsA(_planError(RecurringPlanError.ineligible)),
    );
    final afterPosting = await cash();
    await ledger.linkRecurringOccurrence(expense, 0, entry);
    expect((await transactions()).single.id, entry);
    expect(await cash(), afterPosting);
    expect((await named('Expense')).nextIndex, 1);
    await expectLater(
      ledger.linkRecurringOccurrence(expense, 1, entry),
      throwsA(_planError(RecurringPlanError.alreadyLinked)),
    );

    await ledger.deleteTransaction(entry);
    expect(await transactions(), isEmpty);
    expect((await named('Expense')).occurrences.single.entryId, entry);
    expect((await named('Expense')).nextIndex, 1);
    await ledger.confirmRecurringOccurrence(
      salary,
      0,
      amountMinor: 2000,
      occurredAt: _actual,
      note: 'Received',
    );
    expect((await transactions()).single.type, LedgerTransactionType.income);
    expect(await cash(), 7000);
  });

  test('V11 preserves plans, settings and associations, and V10 restores its budgets', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 5000);
    await ledger.addSpendingPlan(
      SpendingPlanDraft(
        name: 'Old budget',
        currency: 'CNY',
        scope: SpendingScope.total,
        limitMinor: 5000,
        startsOn: _first,
      ),
    );
    await ledger.addRecurringPlan(_plan('Subscription'));
    final plan = await named('Subscription');
    await ledger.confirmRecurringOccurrence(
      plan.id,
      0,
      amountMinor: 1100,
      occurredAt: _actual,
      note: 'Actual payment',
    );
    final entryId = (await transactions()).single.id;
    final beforePause = await ledger.createFullBackup();
    await ledger.setRecurringPlanPaused(plan.id, true);
    await ledger.setRecurringPlanExpectedAmount(plan.id, 1500);

    final current =
        (jsonDecode(await ledger.createFullBackup()) as Map<String, dynamic>)
          ..['backup_version'] = 11
          ..['schema_version'] = 17
          ..remove('debt_contracts');
    final source = jsonEncode(current);
    expect(current['backup_version'], 11);
    expect(ledger.inspectFullBackup(source).recurringPlanCount, 1);
    final older = {...current, 'backup_version': 10, 'schema_version': 16}
      ..remove('recurring_plans');
    final v10 = jsonEncode(older);

    await ledger.restoreFullBackup(v10, mode: BackupRestoreMode.merge);
    await ledger.restoreFullBackup(beforePause, mode: BackupRestoreMode.merge);
    expect((await named('Subscription')).paused, isTrue);
    expect((await named('Subscription')).draft.expectedMinor, 1500);
    await ledger.restoreFullBackup(v10, mode: BackupRestoreMode.replace);
    expect(await plans(), isEmpty);
    expect(
      (await ledger.watchSpendingPlans().first).single.draft.name,
      'Old budget',
    );
    expect((await transactions()).single.id, entryId);

    await ledger.restoreFullBackup(source, mode: BackupRestoreMode.replace);
    final restored = await named('Subscription');
    expect(restored.paused, isTrue);
    expect(restored.draft.expectedMinor, 1500);
    expect(restored.occurrences.single.entryId, entryId);
    expect(restored.nextDueOn, DateTime.utc(2025, 2, 28));

    current['recurring_plans'][0]['occurrences'][0]['entry_id'] =
        'missing-entry';
    await expectLater(
      ledger.restoreFullBackup(
        jsonEncode(current),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await named('Subscription')).occurrences.single.entryId, entryId);
    expect(await cash(), 3900);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await ledger.resetLedgerData();
    expect(await transactions(), isEmpty);
    expect(await plans(), isEmpty);
    expect(await db.select(db.recurringOccurrences).get(), isEmpty);
    expect(await ledger.watchSpendingPlans().first, hasLength(1));
  });
}

Matcher _planError(RecurringPlanError error) => isA<RecurringPlanException>()
    .having((failure) => failure.error, 'error', error);

RecurringPlanDraft _plan(
  String name, {
  RecurringPlanKind kind = RecurringPlanKind.subscription,
  RecurringCadence cadence = RecurringCadence.monthly,
  int? days,
}) => RecurringPlanDraft(
  name: name,
  kind: kind,
  cadence: cadence,
  firstDueOn: _first,
  currency: 'CNY',
  expectedMinor: 1000,
  accountId: _cash,
  categoryId: kind == RecurringPlanKind.income ? _salary : _category,
  customDays: days,
);
