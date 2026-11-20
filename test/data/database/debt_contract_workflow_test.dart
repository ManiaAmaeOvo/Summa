import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

const _cash = 'account-cash';
const _credit = 'account-huabei';
final _firstDue = DateTime.utc(2025, 3, 31);
final _due = DateTime.utc(2025, 4, 30);
final _paymentDate = DateTime(2025, 3, 2, 12);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository ledger;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ledger = DriftExpenseRepository(db);
  });
  tearDown(() => db.close());

  Future<DebtContract> contract() async =>
      (await ledger.watchDebtContracts().first).single;
  Future<List<LedgerRecord>> records() => ledger.watchTransactions().first;
  Future<int> balance(String id) async =>
      (await ledger.watchAccountBalances().first)
          .singleWhere((row) => row.id == id)
          .currentBalanceMinor;
  Future<DebtProgress> progress() async =>
      summarizeDebtContract(await contract(), await records());

  test('actual debt principal follows account postings and FIFO allocates partial repayments', () async {
    await ledger.setCurrentBalance(accountId: _credit, amountMinor: 10000);
    await ledger.setCurrentBalance(accountId: _cash, amountMinor: 20000);
    await ledger.addDebtContract(_draft(_credit, DebtDirection.debt));
    expect((await contract()).balanceMinor, 10000);
    expect(await records(), isEmpty);
    await expectLater(
      ledger.addDebtContract(_draft(_credit, DebtDirection.debt)),
      throwsA(_debtError(DebtContractError.accountInUse)),
    );

    final observedChange = ledger
        .watchDebtContracts()
        .firstWhere((items) => items.single.balanceMinor == 5500)
        .timeout(const Duration(seconds: 5));
    await ledger.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 4500,
      occurredAt: _paymentDate,
      accountId: _cash,
      targetAccountId: _credit,
      terms: const TransactionTerms(interestMinor: 250, feeMinor: 25),
      note: 'Partial',
    );
    final first = (await records()).single;
    expect((await observedChange).single.balanceMinor, await balance(_credit));
    expect(await balance(_cash), 15225);
    var allocation = await progress();
    expect(allocation.unlinkedPrincipalMinor, BigInt.from(4500));
    expect(allocation.installments.first.principalRemainingMinor, 4000);

    await ledger.linkDebtSettlement(_credit, first.id, DebtLinkKind.principal);
    allocation = await progress();
    expect(allocation.unlinkedPrincipalMinor, BigInt.zero);
    expect(allocation.linkedPrincipalMinor, BigInt.from(4500));
    expect(allocation.settlements.single.payment, (
      principalMinor: 4500,
      interestMinor: 250,
      feeMinor: 25,
    ));
    expect(allocation.settlements.single.allocations, [
      (dueOn: _firstDue, principalMinor: 4000, interestMinor: 250),
      (dueOn: _due, principalMinor: 500, interestMinor: 0),
    ]);
    expect(allocation.installments.first.interestRemainingMinor, 50);
    expect(allocation.installments.last.principalRemainingMinor, 5500);
    expect((await contract()).balanceMinor, 5500);
    await expectLater(
      ledger.linkDebtSettlement(_credit, first.id, DebtLinkKind.principal),
      throwsA(_debtError(DebtContractError.conflict)),
    );

    await ledger.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 5500,
      occurredAt: _paymentDate.add(const Duration(days: 1)),
      accountId: _cash,
      targetAccountId: _credit,
      status: LedgerPostingStatus.pending,
      terms: const TransactionTerms(interestMinor: 250),
      note: 'Full remainder',
    );
    final remainder = (await records()).singleWhere((row) => row.isPending);
    expect((await contract()).balanceMinor, 5500);
    await expectLater(
      ledger.linkDebtSettlement(_credit, remainder.id, DebtLinkKind.principal),
      throwsA(_debtError(DebtContractError.ineligible)),
    );
    await ledger.postTransaction(remainder.id);
    await ledger.linkDebtSettlement(
      _credit,
      remainder.id,
      DebtLinkKind.principal,
    );
    expect((await contract()).balanceMinor, await balance(_credit));
    expect((await contract()).balanceMinor, 0);
    expect(
      (await progress()).installments.every(
        (row) =>
            row.principalRemainingMinor == 0 && row.interestRemainingMinor == 0,
      ),
      isTrue,
    );

    await ledger.reverseTransaction(
      first.id,
      occurredAt: _paymentDate.add(const Duration(days: 2)),
    );
    expect((await contract()).balanceMinor, 4500);
    expect((await contract()).balanceMinor, await balance(_credit));
    allocation = await progress();
    expect(allocation.installments.last.principalRemainingMinor, 4500);
    expect(
      allocation.settlements
          .singleWhere((row) => row.link.entryId == first.id)
          .payment,
      isNull,
    );
    expect(
      await db.customSelect('''
      SELECT transaction_id FROM ledger_postings GROUP BY transaction_id, currency_code
      HAVING SUM(debit_minor) <> 0
    ''').get(),
      isEmpty,
    );
  });

  test('receivable collections reduce only principal; linked interest and unlink keep cash unchanged', () async {
    await ledger.addAccount(
      name: 'Receivable for travel',
      kind: AccountKind.receivable,
      currentBalanceMinor: 10000,
    );
    final account = (await ledger.watchAccounts().first)
        .singleWhere((row) => row.kind == AccountKind.receivable)
        .id;
    await ledger.addDebtContract(_draft(account, DebtDirection.receivable));
    await ledger.addTransaction(
      type: LedgerTransactionType.reimbursement,
      amountMinor: 4000,
      occurredAt: _paymentDate,
      accountId: account,
      targetAccountId: _cash,
      note: 'Returned',
    );
    await ledger.addTransaction(
      type: LedgerTransactionType.income,
      amountMinor: 500,
      occurredAt: _paymentDate,
      accountId: _cash,
      categoryId: 'income-parent-0-child-0',
      note: 'Interest paid',
    );
    final items = await records();
    final payment = items.singleWhere((row) => row.note == 'Returned');
    final interest = items.singleWhere((row) => row.note == 'Interest paid');
    await expectLater(
      ledger.linkDebtSettlement(account, interest.id, DebtLinkKind.principal),
      throwsA(_debtError(DebtContractError.ineligible)),
    );
    await ledger.linkDebtSettlement(
      account,
      payment.id,
      DebtLinkKind.principal,
    );
    await ledger.linkDebtSettlement(
      account,
      interest.id,
      DebtLinkKind.interest,
    );
    expect((await contract()).balanceMinor, 6000);
    expect((await contract()).balanceMinor, await balance(account));
    expect(await balance(_cash), 4500);
    expect(
      (await progress()).installments.map((row) => row.interestRemainingMinor),
      [0, 0],
    );
    final link = (await contract()).links.singleWhere(
      (row) => row.entryId == payment.id,
    );
    await ledger.unlinkDebtSettlement(link.id);
    expect((await progress()).installments.first.principalRemainingMinor, 4000);
    expect((await progress()).unlinkedPrincipalMinor, BigInt.from(4000));
    expect((await contract()).balanceMinor, 6000);
    expect(await balance(_cash), 4500);

    await ledger.linkDebtSettlement(
      account,
      payment.id,
      DebtLinkKind.principal,
    );
    expect(
      (await contract()).links.where(
        (row) => row.entryId == payment.id && !row.voided,
      ),
      hasLength(1),
    );
    await ledger.deleteTransaction(payment.id);
    expect((await contract()).balanceMinor, 10000);
    expect((await progress()).linkedPrincipalMinor, BigInt.zero);
  });

  test('V12 restores plans and audit; old backups preserve active local contracts when merged', () async {
    await ledger.setCurrentBalance(accountId: _credit, amountMinor: 10000);
    final draft = _draft(_credit, DebtDirection.debt);
    await ledger.addDebtContract(draft);
    await ledger.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 1000,
      occurredAt: _paymentDate,
      accountId: _credit,
      terms: const TransactionTerms(externalDebtPayment: true),
      note: 'Family payment',
    );
    final payment = (await records()).single;
    await ledger.linkDebtSettlement(
      _credit,
      payment.id,
      DebtLinkKind.principal,
    );
    final activeBackup = await ledger.createFullBackup();
    final link = (await contract()).links.single;
    await ledger.unlinkDebtSettlement(link.id);

    final payload =
        (jsonDecode(await ledger.createFullBackup()) as Map<String, dynamic>)
          ..['backup_version'] = 12
          ..['schema_version'] = 18
          ..remove('savings_goals');
    final backup = jsonEncode(payload);
    expect(ledger.inspectFullBackup(backup).debtContractCount, 1);
    final old = jsonEncode(
      {...payload, 'backup_version': 11, 'schema_version': 17}
        ..remove('debt_contracts'),
    );
    await ledger.restoreFullBackup(old, mode: BackupRestoreMode.merge);
    await ledger.restoreFullBackup(activeBackup, mode: BackupRestoreMode.merge);
    expect((await contract()).links.single.voided, isTrue);
    expect((await contract()).balanceMinor, 9000);
    await ledger.restoreFullBackup(old, mode: BackupRestoreMode.replace);
    expect(await ledger.watchDebtContracts().first, isEmpty);
    expect(await balance(_credit), 9000);
    await ledger.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    expect((await contract()).draft.installments, draft.installments);
    expect((await contract()).links.single.voided, isTrue);
    expect((await contract()).balanceMinor, await balance(_credit));

    payload['debt_contracts'][0]['links'][0]['entry_id'] = 'missing';
    await expectLater(
      ledger.restoreFullBackup(
        jsonEncode(payload),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect((await contract()).links.single.entryId, payment.id);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await ledger.resetLedgerData();
    expect(await ledger.watchDebtContracts().first, isEmpty);
    expect(await db.select(db.debtInstallments).get(), isEmpty);
    expect(await db.select(db.debtSettlements).get(), isEmpty);
  });
}

Matcher _debtError(DebtContractError error) => isA<DebtContractException>()
    .having((failure) => failure.error, 'error', error);

DebtContractDraft _draft(String account, DebtDirection direction) =>
    DebtContractDraft(
      accountId: account,
      name: 'Travel contract',
      counterparty: 'Example party',
      direction: direction,
      currency: 'CNY',
      originalPrincipalMinor: 10000,
      expectedInterestMinor: 500,
      dueOn: _due,
      installments: [
        (dueOn: _firstDue, principalMinor: 4000, interestMinor: 300),
        (dueOn: _due, principalMinor: 6000, interestMinor: 200),
      ],
    );
