import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const _cash = 'account-cash';
const _bank = 'account-bank';
const _card = 'account-family-card';
const _food = 'expense-parent-0-child-1';
const _transport = 'expense-parent-1-child-0';
final _start = DateTime.utc(2026, 1, 31);
final _february = DateTime.utc(2026, 2, 28);
final _march = DateTime.utc(2026, 3, 31);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<List<LedgerRecord>> records() => ledger.watchTransactions().first;
  Future<List<SpendingPlan>> plans() => ledger.watchSpendingPlans().first;
  Future<Map<String, int>> balances() async => {
    for (final item in await ledger.watchAccountBalances().first)
      item.id: item.currentBalanceMinor,
  };

  test(
    'budget scopes use posted settlement, receipts and split allocations',
    () async {
      for (final id in [_cash, _bank, _card]) {
        await ledger.setCurrentBalance(accountId: id, amountMinor: 5000);
      }
      await ledger.addAccount(
        name: 'Travel partner',
        kind: AccountKind.receivable,
        currentBalanceMinor: 0,
      );
      final receivable = (await ledger.watchAccounts().first)
          .singleWhere((row) => row.name == 'Travel partner')
          .id;
      await ledger.addSpendingPlan(_draft('Total', SpendingScope.total));
      await ledger.addSpendingPlan(_draft('Personal', SpendingScope.personal));
      await ledger.addSpendingPlan(
        _draft('Family', SpendingScope.familyDirect),
      );
      await ledger.addSpendingPlan(
        _draft('Cash', SpendingScope.account, account: _cash),
      );
      await ledger.addSpendingPlan(
        _draft('Bank', SpendingScope.account, account: _bank),
      );
      await ledger.addSpendingPlan(
        _draft('Food', SpendingScope.category, category: _food),
      );
      await ledger.addSpendingPlan(
        _draft('Travel', SpendingScope.category, category: 'expense-parent-1'),
      );
      await ledger.addSpendingPlan(
        _draft('External', SpendingScope.allowance, account: _card),
      );
      await ledger.addSpendingPlan(
        _draft('Yen', SpendingScope.total, currency: 'JPY'),
      );

      final today = DateTime(2026, 2, 10, 12);
      Future<Map<String, int>> used() async {
        final transactions = await records();
        return {
          for (final plan in await plans())
            plan.draft.name: summarizeSpendingPlan(
              plan,
              transactions,
              periodIndex: 0,
              today: today,
            ).usedMinor.toInt(),
        };
      }

      await ledger.addTransaction(
        type: LedgerTransactionType.expense,
        amountMinor: 1200,
        occurredAt: DateTime(2026, 2, 1, 12),
        accountId: _cash,
        categoryId: _food,
        payments: const [
          AccountPayment(_cash, 800),
          AccountPayment(_bank, 400),
        ],
        terms: TransactionTerms(
          originalPrice: const TransferSettlement(
            amountMinor: 250,
            currencyCode: 'JPY',
          ),
          advance: AccountPayment(receivable, 400),
          categories: const [
            (categoryId: _food, amountMinor: 300),
            (categoryId: _transport, amountMinor: 500),
          ],
        ),
        status: LedgerPostingStatus.pending,
        note: 'Split AA purchase',
      );
      final purchase = (await records()).singleWhere(
        (entry) => entry.note == 'Split AA purchase',
      );
      expect((await used()).values, everyElement(0));
      await ledger.postTransaction(purchase.id);
      expect(await used(), {
        'Total': 800,
        'Personal': 800,
        'Family': 0,
        'Cash': 533,
        'Bank': 267,
        'Food': 300,
        'Travel': 500,
        'External': 0,
        'Yen': 0,
      });
      await ledger.saveRefund(
        originalId: purchase.id,
        accountId: _cash,
        amountMinor: 350,
        occurredAt: DateTime(2026, 2, 2, 12),
        note: 'Partial refund',
      );
      await ledger.addExpense(
        amountMinor: 175,
        occurredAt: DateTime(2026, 2, 3, 12),
        categoryId: _food,
        accountId: _card,
        note: 'Family card purchase',
      );
      await ledger.saveFamilyExpense(
        amountMinor: 225,
        currencyCode: 'CNY',
        occurredAt: DateTime(2026, 2, 3, 12),
        categoryId: _food,
        note: 'Family paid directly',
      );
      await ledger.addExpense(
        amountMinor: 100,
        occurredAt: DateTime(2026, 2, 11, 12),
        categoryId: _food,
        accountId: _cash,
        note: 'Future date',
      );
      expect(await used(), {
        'Total': 850,
        'Personal': 450,
        'Family': 225,
        'Cash': 183,
        'Bank': 267,
        'Food': 400,
        'Travel': 450,
        'External': 175,
        'Yen': 0,
      });
      final card = (await records()).singleWhere(
        (row) => row.note == 'Family card purchase',
      );
      await ledger.reverseTransaction(
        card.id,
        occurredAt: DateTime(2026, 2, 4, 12),
      );
      expect((await used())['External'], 0);
      expect((await used())['Total'], 675);
    },
  );

  test('monthly clamping, rollover, limit revisions and fixed forecast follow calendar days', () async {
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 5000);
    await ledger.addSpendingPlan(
      _draft('Carry', SpendingScope.total, rollover: true),
    );
    await ledger.addSpendingPlan(
      _draft('Fixed', SpendingScope.total, ends: DateTime.utc(2026, 2, 10)),
    );
    final carry = (await plans()).singleWhere(
      (row) => row.draft.name == 'Carry',
    );
    final fixed = (await plans()).singleWhere(
      (row) => row.draft.name == 'Fixed',
    );
    expect(carry.draft.periodStart(1), _february);
    expect(carry.draft.periodStart(2), _march);
    expect(carry.draft.periodIndex(DateTime.utc(2026, 2, 27)), 0);
    expect(carry.draft.periodIndex(_february), 1);
    expect(fixed.draft.periodIndex(DateTime.utc(2026, 2, 10)), 0);
    expect(fixed.draft.periodIndex(DateTime.utc(2026, 2, 11)), isNull);
    await ledger.addExpense(
      amountMinor: 400,
      occurredAt: DateTime(2026, 2, 2, 12),
      categoryId: _food,
      accountId: _cash,
      note: 'First cycle',
    );
    await ledger.addExpense(
      amountMinor: 2500,
      occurredAt: DateTime(2026, 2, 28, 12),
      categoryId: _food,
      accountId: _cash,
      note: 'Second cycle',
    );
    await ledger.setSpendingPlanLimit(carry.id, (
      periodStart: _february,
      limitMinor: 1250,
      ongoing: false,
    ));
    await ledger.setSpendingPlanLimit(carry.id, (
      periodStart: _february,
      limitMinor: 1400,
      ongoing: true,
    ));
    await expectLater(
      ledger.setSpendingPlanLimit(carry.id, (
        periodStart: DateTime.utc(2026, 2, 27),
        limitMinor: 1400,
        ongoing: true,
      )),
      throwsA(isA<SpendingPlanException>()),
    );
    final revised = (await plans()).singleWhere((row) => row.id == carry.id);
    expect(revised.limits.map((item) => item.limit.limitMinor), [1250, 1400]);
    final entries = await records();
    final feb = summarizeSpendingPlan(
      revised,
      entries,
      periodIndex: 1,
      today: _march,
    );
    expect(feb.baseMinor, BigInt.from(1400));
    expect(feb.carriedMinor, BigInt.from(600));
    expect(feb.usedMinor, BigInt.from(2500));
    expect(feb.remainingMinor, BigInt.from(-500));
    expect(feb.projectedMinor, isNull);
    final mar = summarizeSpendingPlan(
      revised,
      entries,
      periodIndex: 2,
      today: _march,
    );
    expect(mar.baseMinor, BigInt.from(1400));
    expect(mar.carriedMinor, BigInt.zero);
    final fixedSummary = summarizeSpendingPlan(
      fixed,
      entries,
      periodIndex: 0,
      today: DateTime.utc(2026, 2, 4),
    );
    expect(fixedSummary.endExclusive, DateTime.utc(2026, 2, 11));
    expect(fixedSummary.projectedMinor, BigInt.from(880));
  });

  test('allowance stays outside ledger assets and survives backup, older merge and reset', () async {
    final before = await balances();
    final legacy =
        (jsonDecode(await ledger.createFullBackup()) as Map<String, dynamic>)
          ..['backup_version'] = 9
          ..remove('spending_plans');
    final draft = _draft(
      'Approved amount',
      SpendingScope.allowance,
      account: _card,
    );
    await ledger.addSpendingPlan(draft);
    await ledger.addSpendingPlan(_draft('Monthly total', SpendingScope.total));
    await expectLater(
      ledger.addSpendingPlan(draft),
      throwsA(isA<SpendingPlanException>()),
    );
    await expectLater(
      ledger.addSpendingPlan(
        _draft('Wrong account', SpendingScope.allowance, account: _cash),
      ),
      throwsA(isA<SpendingPlanException>()),
    );
    final initial = (await plans()).singleWhere(
      (row) => row.draft.scope == SpendingScope.allowance,
    );
    await ledger.setSpendingPlanLimit(initial.id, (
      periodStart: _february,
      limitMinor: 1900,
      ongoing: true,
    ));
    final oldRevision = await ledger.createFullBackup();
    await ledger.setSpendingPlanLimit(initial.id, (
      periodStart: _february,
      limitMinor: 2350,
      ongoing: false,
    ));
    expect(await records(), isEmpty);
    expect(await balances(), before);
    final personalCash = summarizeFinancialActivity(await records(), 'CNY');
    expect(personalCash.personalCashInflow, BigInt.zero);
    expect(personalCash.personalCashOutflow, BigInt.zero);

    final backup = await ledger.createFullBackup();
    expect(ledger.inspectFullBackup(backup).spendingPlanCount, 2);
    await ledger.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.merge,
    );
    await ledger.restoreFullBackup(oldRevision, mode: BackupRestoreMode.merge);
    final merged = (await plans()).singleWhere((row) => row.id == initial.id);
    expect(merged.limits.map((row) => row.limit.limitMinor), [1900, 2350]);
    await ledger.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.replace,
    );
    expect(await plans(), isEmpty);
    await ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    final restored = (await plans()).singleWhere((row) => row.id == initial.id);
    final feb = summarizeSpendingPlan(
      restored,
      await records(),
      periodIndex: 1,
      today: _march,
    );
    final mar = summarizeSpendingPlan(
      restored,
      await records(),
      periodIndex: 2,
      today: _march,
    );
    expect(feb.remainingMinor, BigInt.from(2350));
    expect(mar.remainingMinor, BigInt.from(1900));
    expect(feb.projectedMinor, isNull);
    expect(await balances(), before);

    final invalid = jsonDecode(backup) as Map<String, dynamic>;
    final allowance =
        (invalid['spending_plans'] as List<dynamic>).first
            as Map<String, dynamic>;
    (allowance['limits'] as List<dynamic>).last['period_start'] = '2026-02-27';
    await expectLater(
      ledger.restoreFullBackup(
        jsonEncode(invalid),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(
      (await plans()).singleWhere((row) => row.id == initial.id).limits,
      hasLength(2),
    );
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await ledger.resetLedgerData();
    expect((await plans()).single.draft.name, 'Monthly total');
    await ledger.resetToFactoryDefaults();
    expect(await plans(), isEmpty);
    expect(await db.select(db.spendingPlanLimits).get(), isEmpty);
  });
}

SpendingPlanDraft _draft(
  String name,
  SpendingScope scope, {
  String currency = 'CNY',
  String? account,
  String? category,
  bool rollover = false,
  DateTime? ends,
}) => SpendingPlanDraft(
  name: name,
  currency: currency,
  scope: scope,
  limitMinor: 1000,
  startsOn: _start,
  endsOn: ends,
  rollover: rollover,
  accountId: account,
  categoryId: category,
);
