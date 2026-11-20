import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const _cash = 'account-cash';
const _credit = 'account-huabei';
const _card = 'account-family-card';
const _food = 'expense-parent-0-child-1';
final _starts = DateTime.utc(2025, 3, 1);
final _date = DateTime(2025, 3, 8, 12);

void main() {
  test('Phase 3 joint acceptance keeps plans, principal, budgets and real funds reconciled', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ledger = DriftExpenseRepository(db);
    Future<List<LedgerRecord>> transactions() =>
        ledger.watchTransactions().first;
    Future<SavingsAccountAllocation> savings() async =>
        (await ledger.watchSavingsAllocations().first).single;
    Future<DebtContract> contract() async =>
        (await ledger.watchDebtContracts().first).single;
    Future<Map<String, int>> budgets() async {
      final records = await transactions();
      return {
        for (final plan in await ledger.watchSpendingPlans().first)
          plan.draft.name: summarizeSpendingPlan(
            plan,
            records,
            periodIndex: 0,
            today: _date,
          ).usedMinor.toInt(),
      };
    }

    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 10000);
    await ledger.setCurrentBalance(accountId: _credit, amountMinor: 3000);
    await ledger.setCurrentBalance(accountId: _card, amountMinor: 2000);
    await ledger.addSpendingPlan(
      SpendingPlanDraft(
        name: 'Total',
        currency: 'CNY',
        scope: SpendingScope.total,
        limitMinor: 3000,
        startsOn: _starts,
      ),
    );
    await ledger.addSpendingPlan(
      SpendingPlanDraft(
        name: 'Family Card',
        currency: 'CNY',
        scope: SpendingScope.allowance,
        accountId: _card,
        limitMinor: 2000,
        startsOn: _starts,
      ),
    );
    await ledger.addRecurringPlan(
      RecurringPlanDraft(
        name: 'Subscription',
        kind: RecurringPlanKind.subscription,
        cadence: RecurringCadence.monthly,
        firstDueOn: _starts,
        currency: 'CNY',
        expectedMinor: 400,
        accountId: _cash,
        categoryId: _food,
      ),
    );
    final due = DateTime.utc(2025, 3, 31);
    await ledger.addDebtContract(
      DebtContractDraft(
        accountId: _credit,
        name: 'Loan',
        counterparty: 'Example creditor',
        direction: DebtDirection.debt,
        currency: 'CNY',
        originalPrincipalMinor: 3000,
        expectedInterestMinor: 100,
        dueOn: due,
        installments: [(dueOn: due, principalMinor: 3000, interestMinor: 100)],
      ),
    );
    final preGoals =
        jsonDecode(await ledger.createFullBackup()) as Map<String, dynamic>;
    final older = jsonEncode(
      {...preGoals, 'backup_version': 12, 'schema_version': 18}
        ..remove('savings_goals'),
    );
    for (final name in ['Emergency', 'Travel']) {
      await ledger.addSavingsGoal(
        SavingsGoalDraft(
          name: name,
          accountId: _cash,
          currency: 'CNY',
          targetMinor: 6000,
          priority: SavingsPriority.normal,
        ),
      );
    }
    final goals = (await savings()).goals;
    final emergency = goals
        .singleWhere((row) => row.draft.name == 'Emergency')
        .id;
    final travel = goals.singleWhere((row) => row.draft.name == 'Travel').id;
    await ledger.changeSavingsAllocation(emergency, 5000, note: '');
    await ledger.changeSavingsAllocation(travel, 2500, note: '');
    expect((await savings()).balanceMinor, 10000);
    expect((await savings()).unallocatedMinor, BigInt.from(2500));
    expect(await transactions(), isEmpty);
    expect(await budgets(), {'Total': 0, 'Family Card': 0});

    final plan = (await ledger.watchRecurringPlans().first).single;
    await ledger.confirmRecurringOccurrence(
      plan.id,
      plan.nextIndex,
      amountMinor: 400,
      occurredAt: _date,
      note: 'Posted subscription',
    );
    await ledger.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 1000,
      occurredAt: _date,
      accountId: _cash,
      targetAccountId: _credit,
      terms: const TransactionTerms(interestMinor: 100),
      note: 'Partial payment',
    );
    await ledger.addExpense(
      amountMinor: 300,
      occurredAt: _date,
      categoryId: _food,
      accountId: _card,
      note: 'Entrusted expense',
    );
    final repayment = (await transactions()).singleWhere(
      (row) => row.note == 'Partial payment',
    );
    await ledger.linkDebtSettlement(
      _credit,
      repayment.id,
      DebtLinkKind.principal,
    );
    expect((await contract()).balanceMinor, 2000);
    expect(
      summarizeDebtContract(
        await contract(),
        await transactions(),
      ).linkedPrincipalMinor,
      BigInt.from(1000),
    );
    expect(await budgets(), {'Total': 800, 'Family Card': 300});
    expect((await savings()).balanceMinor, 8500);
    expect((await savings()).unallocatedMinor, BigInt.from(1000));

    await ledger.addExpense(
      amountMinor: 1200,
      occurredAt: _date,
      categoryId: _food,
      accountId: _cash,
      note: 'Additional actual expense',
    );
    expect((await savings()).balanceMinor, 7300);
    expect((await savings()).shortfallMinor, BigInt.from(200));
    await ledger.changeSavingsAllocation(
      travel,
      -300,
      note: 'Release after spending',
    );
    expect((await savings()).shortfallMinor, BigInt.zero);
    expect((await savings()).unallocatedMinor, BigInt.from(100));
    final totals = summarizeFinancialActivity(await transactions(), 'CNY');
    expect(totals.grossSpending, BigInt.from(2000));
    expect(totals.personalCashOutflow, BigInt.from(2700));
    expect(await transactions(), hasLength(4));

    final backup = await ledger.createFullBackup();
    final preview = ledger.inspectFullBackup(backup);
    expect(preview.spendingPlanCount, 2);
    expect(preview.recurringPlanCount, 1);
    expect(preview.debtContractCount, 1);
    expect(preview.savingsGoalCount, 2);
    await ledger.restoreFullBackup(older, mode: BackupRestoreMode.replace);
    expect(await ledger.watchSavingsAllocations().first, isEmpty);
    expect((await contract()).balanceMinor, 3000);
    expect((await ledger.watchRecurringPlans().first).single.nextIndex, 0);
    await ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect((await savings()).unallocatedMinor, BigInt.from(100));
    expect((await savings()).reservedMinor, BigInt.from(7200));
    expect((await contract()).links.single.entryId, repayment.id);
    expect((await ledger.watchRecurringPlans().first).single.nextIndex, 1);
    expect(await budgets(), {'Total': 2000, 'Family Card': 300});
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    expect(
      await db.customSelect('''
      SELECT transaction_id FROM ledger_postings GROUP BY transaction_id, currency_code
      HAVING SUM(debit_minor) <> 0
    ''').get(),
      isEmpty,
    );
  });
}
