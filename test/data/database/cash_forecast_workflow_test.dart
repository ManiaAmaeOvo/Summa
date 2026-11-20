import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/cash_forecast.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const _cash = 'account-cash';
const _credit = 'account-huabei';
const _food = 'expense-parent-0-child-1';
const _salary = 'income-parent-0-child-0';
final _start = DateTime.utc(2025, 3, 1);

void main() {
  test('forecasts each currency separately and distinguishes future posted entries', () {
    final transfer = _record('FX', DateTime(2025, 3, 3, 12), [
      _posting(_cash, 600),
      _posting('yen', -900, currency: 'JPY'),
    ]);
    final outsideRange = _record('Later cash', DateTime(2025, 4, 2, 12), [
      _posting(_cash, 2000),
    ]);
    final pending = _record('Draft', DateTime(2025, 3, 4, 12), [
      _posting(_cash, -10000),
    ], pending: true);
    final inputs = CashForecastInputs(
      balances: [
        _balance(_cash, 4500),
        _balance('yen', 4100, currency: 'JPY'),
        _balance('entrusted', 50000, kind: AccountKind.entrustedFunds),
        _balance(_credit, 10000, kind: AccountKind.creditLine),
      ],
      transactions: [transfer, outsideRange, pending],
      recurringPlans: [
        _plan(
          'Renewal',
          RecurringPlanKind.subscription,
          DateTime.utc(2025, 1, 31),
          300,
        ),
        _plan(
          'Regular',
          RecurringPlanKind.expense,
          DateTime.utc(2025, 2, 1),
          400,
          confirmed: true,
        ),
        _plan(
          'Income',
          RecurringPlanKind.income,
          DateTime.utc(2025, 2, 23),
          1100,
          cadence: RecurringCadence.weekly,
        ),
        _plan('Paused', RecurringPlanKind.expense, _start, 900, paused: true),
        _plan(
          'Credit funded',
          RecurringPlanKind.subscription,
          _start,
          900,
          account: _credit,
        ),
      ],
      contracts: const [],
    );
    final cny = forecastCash(
      inputs,
      currency: 'CNY',
      today: _start,
      horizonDays: 7,
    );
    expect(cny.openingMinor, BigInt.from(1900));
    expect(cny.days.first.closingMinor, BigInt.from(900));
    final firstDay = cny.days.first.events;
    final overdueRenewal = firstDay.singleWhere(
      (event) => event.name == 'Renewal',
    );
    expect(overdueRenewal.overdueCycles, 2);
    expect(overdueRenewal.changeMinor, BigInt.from(-600));
    expect(
      firstDay.singleWhere((event) => event.name == 'Income').included,
      isFalse,
    );
    expect(cny.days[2].events.single.source, CashForecastSource.futurePosted);
    expect(cny.days[2].events.single.record?.id, 'FX');
    expect(cny.closingMinor, BigInt.from(2600));
    expect(cny.firstShortfall, isNull);
    final allEvents = cny.days
        .expand((day) => day.events)
        .map((event) => event.name);
    expect(allEvents, isNot(contains('Draft')));
    expect(allEvents, isNot(contains('Paused')));

    final jpy = forecastCash(
      inputs,
      currency: 'JPY',
      today: _start,
      horizonDays: 7,
    );
    expect(jpy.openingMinor, BigInt.from(5000));
    expect(jpy.days[2].events.single.changeMinor, BigInt.from(-900));
    expect(jpy.closingMinor, BigInt.from(4100));
    final extended = forecastCash(
      inputs,
      currency: 'CNY',
      today: _start,
      horizonDays: 90,
    );
    final march31 = extended.days.singleWhere(
      (day) => day.date == DateTime.utc(2025, 3, 31),
    );
    expect(
      march31.events
          .singleWhere((event) => event.name == 'Renewal')
          .overdueCycles,
      0,
    );
    expect(
      extended.days
          .expand((day) => day.events)
          .any(
            (event) =>
                event.name == 'Later cash' &&
                event.source == CashForecastSource.futurePosted,
          ),
      isTrue,
    );
  });

  test('projects loan and receivable installments from a coherent ledger snapshot and restores a full backup', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final ledger = DriftExpenseRepository(db);
    final prior = DateTime(2025, 2, 20, 12);
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 6000);
    await ledger.setCurrentBalance(accountId: _credit, amountMinor: 10000);
    await ledger.addAccount(
      name: 'Trip receivable',
      kind: AccountKind.receivable,
      currentBalanceMinor: 7000,
    );
    final receivable = (await ledger.watchAccounts().first).singleWhere(
      (row) => row.kind == AccountKind.receivable,
    );
    await ledger.addDebtContract(
      _contract(_credit, 'Loan', DebtDirection.debt, [
        (
          dueOn: DateTime.utc(2025, 3, 2),
          principalMinor: 5000,
          interestMinor: 500,
        ),
        (
          dueOn: DateTime.utc(2025, 3, 4),
          principalMinor: 5000,
          interestMinor: 200,
        ),
      ]),
    );
    await ledger.addDebtContract(
      _contract(receivable.id, 'Trip', DebtDirection.receivable, [
        (
          dueOn: DateTime.utc(2025, 2, 28),
          principalMinor: 3000,
          interestMinor: 100,
        ),
        (
          dueOn: DateTime.utc(2025, 3, 6),
          principalMinor: 4000,
          interestMinor: 300,
        ),
      ]),
    );
    await ledger.addRecurringPlan(
      _plan(
        'Renewal',
        RecurringPlanKind.subscription,
        DateTime.utc(2025, 2, 1),
        400,
      ).draft,
    );
    final plan = (await ledger.watchRecurringPlans().first).single;
    await ledger.confirmRecurringOccurrence(
      plan.id,
      0,
      amountMinor: 400,
      occurredAt: prior,
      note: 'Confirmed',
    );
    Future<void> repay(int principal, int interest, String note) =>
        ledger.addTransaction(
          type: LedgerTransactionType.repayment,
          amountMinor: principal,
          occurredAt: prior,
          accountId: _cash,
          targetAccountId: _credit,
          terms: TransactionTerms(interestMinor: interest),
          note: note,
        );
    await repay(1000, 100, 'Linked repayment');
    final debtEntry = (await ledger.watchTransactions().first).singleWhere(
      (row) => row.note == 'Linked repayment',
    );
    await ledger.linkDebtSettlement(
      _credit,
      debtEntry.id,
      DebtLinkKind.principal,
    );
    await repay(2000, 300, 'Unlinked repayment');
    await ledger.addTransaction(
      type: LedgerTransactionType.collection,
      amountMinor: 2000,
      occurredAt: prior,
      accountId: receivable.id,
      targetAccountId: _cash,
      note: 'Unlinked receipt',
    );
    Future<void> income(int amount, DateTime date, String note) =>
        ledger.addTransaction(
          type: LedgerTransactionType.income,
          amountMinor: amount,
          occurredAt: date,
          accountId: _cash,
          categoryId: _salary,
          note: note,
        );
    await income(200, prior, 'Linked interest');
    final interest = (await ledger.watchTransactions().first).singleWhere(
      (row) => row.note == 'Linked interest',
    );
    await ledger.linkDebtSettlement(
      receivable.id,
      interest.id,
      DebtLinkKind.interest,
    );
    final update = ledger.watchCashForecastInputs().firstWhere(
      (data) =>
          data.transactions.any((item) => item.note == 'Future booked income'),
    );
    await income(5000, DateTime(2025, 3, 7, 12), 'Future booked income');
    final inputs = await update.timeout(const Duration(seconds: 5));
    final cash = inputs.balances.singleWhere((item) => item.id == _cash);
    expect(cash.currentBalanceMinor, 9400);
    final before = await ledger.createFullBackup();
    final projection = forecastCash(
      inputs,
      currency: 'CNY',
      today: _start,
      horizonDays: 7,
    );
    expect(projection.openingMinor, BigInt.from(4400));
    expect(projection.days.map((day) => day.closingMinor.toInt()), [
      4000,
      1900,
      1900,
      -3300,
      -3300,
      900,
      5900,
    ]);
    expect(projection.firstShortfall?.date, DateTime.utc(2025, 3, 4));
    expect(projection.peakShortfallMinor, BigInt.from(3300));
    final late = projection.days.first.events.singleWhere(
      (event) => event.source == CashForecastSource.receivableCollection,
    );
    expect(late.changeMinor, BigInt.from(1000));
    expect(late.included, isFalse);
    expect(projection.unscheduledPrincipal, isEmpty);
    // Forecasting creates no transactions, associations or backup fields.
    final originalJson = (jsonDecode(before) as Map<String, dynamic>)
      ..remove('created_at');
    final afterwards =
        (jsonDecode(await ledger.createFullBackup()) as Map<String, dynamic>)
          ..remove('created_at');
    expect(originalJson['backup_version'], 14);
    expect(afterwards, originalJson);
    await ledger.restoreFullBackup(before, mode: BackupRestoreMode.replace);
    final restored = forecastCash(
      await ledger.watchCashForecastInputs().first,
      currency: 'CNY',
      today: _start,
      horizonDays: 7,
    );
    expect(
      restored.days.map((day) => day.closingMinor),
      projection.days.map((day) => day.closingMinor),
    );

    // A ledger correction that increases principal is surfaced until scheduled.
    await ledger.setCurrentBalance(accountId: _credit, amountMinor: 7200);
    final larger = forecastCash(
      await ledger.watchCashForecastInputs().first,
      currency: 'CNY',
      today: _start,
      horizonDays: 7,
    );
    expect(larger.unscheduledPrincipal.single.amountMinor, BigInt.from(200));
    expect(larger.closingMinor, projection.closingMinor);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

AccountBalance _balance(
  String id,
  int current, {
  String currency = 'CNY',
  AccountKind kind = AccountKind.cash,
}) => AccountBalance(
  id: id,
  name: id,
  kind: kind,
  openingBalanceMinor: current,
  currentBalanceMinor: current,
  currencyCode: currency,
);

AccountPosting _posting(String id, int amount, {String currency = 'CNY'}) =>
    AccountPosting(
      accountId: id,
      accountName: id,
      accountKind: AccountKind.cash.name,
      debitMinor: amount,
      needsReview: false,
      currencyCode: currency,
    );

LedgerRecord _record(
  String id,
  DateTime date,
  List<AccountPosting> postings, {
  bool pending = false,
}) => LedgerRecord(
  id: id,
  type: LedgerTransactionType.transfer,
  amountMinor: 600,
  occurredAt: date,
  parentCategoryId: 'flow',
  parentCategoryName: 'Flow',
  categoryId: 'flow-transfer',
  categoryName: 'Transfer',
  accountId: _cash,
  accountName: 'Cash',
  accountKind: AccountKind.cash.name,
  note: id,
  status: pending ? LedgerPostingStatus.pending : LedgerPostingStatus.posted,
  accountPostings: postings,
);

RecurringPlan _plan(
  String name,
  RecurringPlanKind kind,
  DateTime first,
  int amount, {
  bool paused = false,
  bool confirmed = false,
  String account = _cash,
  RecurringCadence cadence = RecurringCadence.monthly,
}) => RecurringPlan(
  id: name,
  paused: paused,
  draft: RecurringPlanDraft(
    name: name,
    kind: kind,
    cadence: cadence,
    firstDueOn: first,
    currency: 'CNY',
    expectedMinor: amount,
    accountId: account,
    categoryId: kind == RecurringPlanKind.income ? _salary : _food,
  ),
  occurrences: [
    if (confirmed) (index: 0, entryId: 'confirmed', expectedMinor: amount),
  ],
);

DebtContractDraft _contract(
  String account,
  String name,
  DebtDirection direction,
  List<DebtInstallment> rows,
) => DebtContractDraft(
  accountId: account,
  name: name,
  counterparty: 'Example',
  direction: direction,
  currency: 'CNY',
  originalPrincipalMinor: rows.fold(0, (sum, row) => sum + row.principalMinor),
  expectedInterestMinor: rows.fold(0, (sum, row) => sum + row.interestMinor),
  dueOn: rows.last.dueOn,
  installments: rows,
);
