import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';

const cash = 'account-cash';
const credit = 'account-huabei';
const food = 'expense-parent-0-child-1';
const timestamp = '2026-01-20T12:30:00+08:00';
const header =
    'type,amount,occurred_at,account,category,note,currency_code,target_account,source,external_id';
final time = DateTime.parse(timestamp);

CsvImportFile csv(List<String> rows, {String name = 'statement.csv'}) =>
    parseCsvImport(name, utf8.encode([header, ...rows].join('\n')));
String expense(
  String amount,
  String note, {
  String id = '',
  String at = timestamp,
}) => 'expense,$amount,$at,Cash,Food/Lunch,$note,CNY,,bank-a,$id';
CsvSelection select(CsvReviewRow item, {String? matchId, bool asNew = false}) =>
    CsvSelection(
      item.row.number,
      item.mapping,
      matchId: matchId,
      reviewedMatchIds: asNew
          ? item.matches.map((match) => match.id).toSet()
          : null,
    );

Matcher error(CsvBatchError kind) =>
    isA<CsvBatchException>().having((error) => error.error, 'error', kind);

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftExpenseRepository(db);
    await repo.setCurrentBalance(accountId: cash, amountMinor: 20000);
  });
  tearDown(() => db.close());

  Future<int> balance(String id) async =>
      (await repo.watchAccountBalances().first)
          .singleWhere((row) => row.id == id)
          .currentBalanceMinor;

  test('file replay and overlapping source IDs are idempotent and keep identical real rows', () async {
    final first = csv([
      expense('12', 'One', id: 'a'),
      expense('12', 'Two', id: 'b'),
      expense('2', 'Identical'),
      expense('2', 'Identical'),
    ]);
    final preview = await repo.previewCsvImport(first);
    expect(preview.map((row) => row.state), everyElement(CsvReviewState.ready));
    final batch = await repo.commitCsvImport(
      first,
      preview.map(select).toList(),
    );
    expect(batch.added, 4);
    expect(await balance(cash), 17200);

    final replay = csv([
      expense('12', 'One', id: 'a'),
      expense('12', 'Two', id: 'b'),
      expense('2', 'Identical'),
      expense('2', 'Identical'),
    ], name: 'renamed.csv');
    expect(
      (await repo.previewCsvImport(replay)).map((row) => row.state),
      everyElement(CsvReviewState.duplicate),
    );
    await expectLater(
      repo.commitCsvImport(replay, [select(preview.first)]),
      throwsA(error(CsvBatchError.reviewChanged)),
    );
    expect(await repo.watchCsvBatches().first, hasLength(1));

    final overlap = csv([
      expense('12', 'Two', id: 'b'),
      expense('14', 'Corrected One', id: 'a'),
      expense('12', 'Unrelated', id: 'c', at: '2026-01-21T12:30:00+08:00'),
    ]);
    final next = await repo.previewCsvImport(overlap);
    expect(next.map((row) => row.state), [
      CsvReviewState.duplicate,
      CsvReviewState.conflict,
      CsvReviewState.ready,
    ]);
    final second = await repo.commitCsvImport(overlap, [select(next.last)]);
    expect(second.added, 1);
    await repo.undoCsvImport(batch.batchId);
    expect(await balance(cash), 18800);
    expect(
      (await repo.previewCsvImport(replay)).map((row) => row.state),
      everyElement(CsvReviewState.ready),
    );
  });

  test('concurrent confirmation claims a row once and leaves skipped rows eligible', () async {
    final file = csv([
      expense('10', 'First', id: 'one'),
      expense('5', 'Second', id: 'two'),
    ]);
    final reviewed = await repo.previewCsvImport(file);
    Future<Object> confirm() async {
      try {
        return await repo.commitCsvImport(file, [select(reviewed.first)]);
      } on CsvBatchException catch (error) {
        return error;
      }
    }

    final results = await Future.wait([confirm(), confirm()]);
    expect(results.whereType<CsvImportResult>(), hasLength(1));
    expect(
      results.whereType<CsvBatchException>().single.error,
      CsvBatchError.reviewChanged,
    );
    final remaining = await repo.previewCsvImport(file);
    expect(remaining.map((row) => row.state), [
      CsvReviewState.duplicate,
      CsvReviewState.ready,
    ]);
    await repo.commitCsvImport(file, [select(remaining.last)]);
    expect(await balance(cash), 18500);
    expect(await repo.watchTransactions().first, hasLength(2));
  });

  test('in-file repeated external IDs and conflicts are distinct from identical payments', () async {
    final repeated = csv([
      expense('12', 'One', id: 'one'),
      expense('12', 'One', id: 'one'),
      expense('4', 'A', id: 'conflict'),
      expense('5', 'B', id: 'conflict'),
    ]);
    final rows = await repo.previewCsvImport(repeated);
    expect(rows.map((row) => row.state), [
      CsvReviewState.ready,
      CsvReviewState.duplicate,
      CsvReviewState.conflict,
      CsvReviewState.conflict,
    ]);
    expect(
      (await repo.commitCsvImport(repeated, [select(rows.first)])).added,
      1,
    );
  });

  test('manually maps a foreign-currency account and links an existing movement without re-posting it', () async {
    await repo.addAccount(
      name: 'Japan wallet',
      kind: AccountKind.wallet,
      currentBalanceMinor: 1000,
      currencyCode: 'JPY',
    );
    final yen = (await repo.watchAccounts().first).singleWhere(
      (account) => account.currencyCode == 'JPY',
    );
    await repo.addExpense(
      amountMinor: 300,
      occurredAt: time.add(const Duration(seconds: 25)),
      categoryId: food,
      accountId: yen.id,
      note: 'Manual lunch',
    );
    final file = csv([
      'expense,300,$timestamp,Unmapped,,Lunch,JPY,,merchant,lunch',
    ]);
    final unassigned = (await repo.previewCsvImport(file)).single;
    expect(unassigned.state, CsvReviewState.unresolved);
    final mapping = (accountId: yen.id, targetId: null, categoryId: null);
    final mapped = (await repo.previewCsvImport(
      file,
      mappings: {1: mapping},
    )).single;
    expect(mapped.state, CsvReviewState.similar);
    expect(mapped.matches.single.note, 'Manual lunch');
    await expectLater(
      repo.commitCsvImport(file, [select(mapped)]),
      throwsA(error(CsvBatchError.reviewChanged)),
    );
    final result = await repo.commitCsvImport(file, [
      select(mapped, matchId: mapped.matches.single.id),
    ]);
    expect((result.added, result.matched), (0, 1));
    expect(await balance(yen.id), 700);
    expect(
      (await repo.readCsvBatchItems(result.batchId)).single.raw['account'],
      'Unmapped',
    );
    await repo.undoCsvImport(result.batchId);
    expect(await balance(yen.id), 700);
    expect(await repo.watchTransactions().first, hasLength(1));
  });

  test('active source links update live, filter activity, and survive full backup restore', () async {
    final file = parseCsvImport(
      'wallet.csv',
      utf8.encode(
        '$header,payment_channel,merchant\n'
        '${expense('12', 'Matched lunch', id: 'trace-123')},Wallet,Example Bakery',
      ),
    );
    await repo.addExpense(
      amountMinor: 1200,
      occurredAt: time,
      categoryId: food,
      accountId: cash,
      note: 'Matched lunch',
    );
    final row = (await repo.previewCsvImport(file)).single;
    final updates = StreamIterator(repo.watchTransactions());
    final filter = const LedgerFilter(
      channel: 'Wallet',
      counterparty: 'Example Bakery',
    );
    try {
      expect(await updates.moveNext(), isTrue);
      expect(updates.current.single.sources, isEmpty);
      final next = updates.moveNext();
      final result = await repo.commitCsvImport(file, [
        select(row, matchId: row.matches.single.id),
      ]);
      expect(result.matched, 1);
      expect(await next, isTrue);
      final source = updates.current.single.sources.single;
      expect(source.batchId, result.batchId);
      expect(source.line, 2);
      expect(source.provider, 'bank-a');
      expect(source.cells['external_id'], 'trace-123');
      expect(filter.matches(updates.current.single), isTrue);
      expect(
        analyzeLedger(updates.current, 'CNY', filter).activity.grossSpending,
        BigInt.from(1200),
      );
      final backup = await repo.createFullBackup();
      final undone = updates.moveNext();
      await repo.undoCsvImport(result.batchId);
      expect(await undone, isTrue);
      expect(updates.current.single.sources, isEmpty);
      expect(filter.matches(updates.current.single), isFalse);
      expect(await balance(cash), 18800);
      await repo.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
      final restored = await repo.watchLedgerHistoryInputs().first;
      expect(
        restored.transactions.single.sources.single.batchName,
        'wallet.csv',
      );
      expect(filter.matches(restored.transactions.single), isTrue);
      expect(await balance(cash), 18800);
    } finally {
      await updates.cancel();
    }
  });

  test('overlap without IDs requires review and permits explicitly separate postings', () async {
    final prior = csv([expense('12', 'Lunch')]);
    final first = (await repo.previewCsvImport(prior)).single;
    final original = await repo.commitCsvImport(prior, [select(first)]);
    final overlap = csv([
      expense('12', 'Lunch'),
      expense('5', 'Another day', at: '2026-01-21'),
    ]);
    final rows = await repo.previewCsvImport(overlap);
    expect(rows.map((row) => row.state), [
      CsvReviewState.similar,
      CsvReviewState.ready,
    ]);
    expect(rows.first.matches.single.sameSourceRow, isTrue);
    final match = await repo.commitCsvImport(overlap, [
      select(rows.first, matchId: rows.first.matches.single.id),
    ]);
    await expectLater(
      repo.undoCsvImport(original.batchId),
      throwsA(error(CsvBatchError.linked)),
    );
    await repo.undoCsvImport(match.batchId);
    final approved = await repo.commitCsvImport(overlap, [
      select(rows.first, asNew: true),
      select(rows.last),
    ]);
    expect(approved.added, 2);
    expect(await balance(cash), 17100);
  });

  test(
    'a posting error aborts the whole batch and releases all keys',
    () async {
      final file = csv([
        expense('10', 'Fits', id: 'a'),
        expense('500', 'Too big', id: 'b'),
      ]);
      final rows = await repo.previewCsvImport(file);
      await expectLater(
        repo.commitCsvImport(file, rows.map(select).toList()),
        throwsA(
          isA<CsvPostingException>().having((error) => error.line, 'line', 3),
        ),
      );
      expect(await repo.watchTransactions().first, isEmpty);
      expect(await repo.watchCsvBatches().first, isEmpty);
      expect(await balance(cash), 20000);
      expect(
        (await repo.previewCsvImport(file)).map((row) => row.state),
        everyElement(CsvReviewState.ready),
      );
    },
  );

  test(
    'undo refuses an edited row or linked refund and preserves the whole batch',
    () async {
      final file = csv([expense('10', 'A'), expense('20', 'B')]);
      final preview = await repo.previewCsvImport(file);
      final batch = await repo.commitCsvImport(
        file,
        preview.map(select).toList(),
      );
      final records = await repo.watchTransactions().first;
      final a = records.singleWhere((row) => row.note == 'A');
      final b = records.singleWhere((row) => row.note == 'B');
      await repo.saveRefund(
        originalId: a.id,
        accountId: cash,
        amountMinor: 200,
        occurredAt: time.add(const Duration(days: 1)),
        note: 'Refund',
      );
      await expectLater(
        repo.undoCsvImport(batch.batchId),
        throwsA(error(CsvBatchError.linked)),
      );
      final refund = (await repo.watchTransactions().first).singleWhere(
        (row) => row.isRefund,
      );
      await repo.deleteTransaction(refund.id);
      await repo.updateExpense(
        id: b.id,
        amountMinor: 2100,
        occurredAt: b.occurredAt,
        categoryId: b.categoryId,
        accountId: b.accountId,
        note: 'Edited',
      );
      await expectLater(
        repo.undoCsvImport(batch.batchId),
        throwsA(error(CsvBatchError.modified)),
      );
      expect(await repo.watchTransactions().first, hasLength(2));
      expect((await repo.watchCsvBatches().first).single.undoneAt, isNull);
    },
  );

  test('undo protects later repayments of imported credit purchases', () async {
    final file = csv([
      'expense,30,$timestamp,Huabei,Food/Lunch,Credit,CNY,,bank-a,1',
    ]);
    final reviewed = (await repo.previewCsvImport(file)).single;
    final batch = await repo.commitCsvImport(file, [select(reviewed)]);
    await repo.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 3000,
      occurredAt: time.add(const Duration(days: 1)),
      accountId: cash,
      targetAccountId: credit,
      note: 'Later repayment',
    );
    await expectLater(
      repo.undoCsvImport(batch.batchId),
      throwsA(error(CsvBatchError.linked)),
    );
    expect(await balance(credit), 0);
    expect(await repo.watchTransactions().first, hasLength(2));
  });

  test('undo refuses to remove a deposit used by later spending', () async {
    final file = csv([
      'income,80,$timestamp,Cash,Earned Income/Salary,Deposit,CNY,,bank-a,deposit',
    ]);
    final batch = await repo.commitCsvImport(file, [
      select((await repo.previewCsvImport(file)).single),
    ]);
    await repo.addExpense(
      amountMinor: 25000,
      occurredAt: time.add(const Duration(days: 1)),
      categoryId: food,
      accountId: cash,
      note: 'Later payment',
    );
    await expectLater(
      repo.undoCsvImport(batch.batchId),
      throwsA(error(CsvBatchError.linked)),
    );
    expect(await balance(cash), 3000);
    expect(await repo.watchTransactions().first, hasLength(2));
  });

  test('Version 8 round-trips audit, protects against resurrection, and merges old backups', () async {
    final legacy =
        jsonDecode(await repo.createFullBackup()) as Map<String, dynamic>;
    legacy['backup_version'] = 7;
    legacy.remove('csv_import');
    final file = csv([expense('12', 'One', id: 'one')]);
    final batch = await repo.commitCsvImport(file, [
      select((await repo.previewCsvImport(file)).single),
    ]);
    await repo.restoreFullBackup(
      jsonEncode(legacy),
      mode: BackupRestoreMode.merge,
    );
    final backup = await repo.createFullBackup();
    expect(repo.inspectFullBackup(backup).importBatchCount, 1);
    await repo.resetToFactoryDefaults();
    await repo.restoreFullBackup(backup, mode: BackupRestoreMode.replace);
    await repo.restoreFullBackup(backup, mode: BackupRestoreMode.merge);
    expect(
      (await repo.previewCsvImport(file)).single.state,
      CsvReviewState.duplicate,
    );
    expect(await repo.watchCsvBatches().first, hasLength(1));
    await repo.undoCsvImport(batch.batchId);
    expect(await balance(cash), 20000);
    final undone = await repo.createFullBackup();
    await repo.restoreFullBackup(undone, mode: BackupRestoreMode.replace);
    expect((await repo.watchCsvBatches().first).single.undoneAt, isNotNull);
    expect(
      (await repo.previewCsvImport(file)).single.state,
      CsvReviewState.ready,
    );

    final resurrection = jsonDecode(backup) as Map<String, dynamic>;
    resurrection['backup_version'] = 7;
    resurrection.remove('csv_import');
    await expectLater(
      repo.restoreFullBackup(
        jsonEncode(resurrection),
        mode: BackupRestoreMode.merge,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    final malformed = jsonDecode(backup) as Map<String, dynamic>;
    (malformed['csv_import']['rows'] as List).single['entry_id'] = 'missing';
    await expectLater(
      repo.restoreFullBackup(
        jsonEncode(malformed),
        mode: BackupRestoreMode.replace,
      ),
      throwsA(isA<LedgerBackupException>()),
    );
    expect(await repo.watchTransactions().first, isEmpty);
    expect((await repo.watchCsvBatches().first).single.undoneAt, isNotNull);
  });
}
