import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_pro/data/backup/local_backup_store.dart';
import 'package:ledger_pro/data/database/app_database.dart';
import 'package:ledger_pro/data/repositories/auto_backup_expense_repository.dart';
import 'package:ledger_pro/data/repositories/drift_expense_repository.dart';
import 'package:ledger_pro/domain/import_export/local_backup.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('summa-backup-test-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('keeps only one automatic snapshot in an app session', () async {
    final store = LocalBackupStore(rootProvider: () async => directory);
    final first = await store.beginAutomaticBackup('{"snapshot":1}');
    await store.commitAutomaticBackup(first);
    final second = await store.beginAutomaticBackup('{"snapshot":2}');

    expect(first, isNotNull);
    expect(second, isNull);
    expect(await store.listBackups(), hasLength(1));
  });

  test('failed mutation removes the tentative session snapshot', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final store = LocalBackupStore(rootProvider: () async => directory);
    final repository = AutoBackupExpenseRepository(
      DriftExpenseRepository(database),
      store,
    );
    final lunch = (await repository.watchExpenseCategories().first).singleWhere(
      (item) => item.name == '午餐',
    );

    await expectLater(
      repository.addTransaction(
        type: LedgerTransactionType.expense,
        amountMinor: 100,
        occurredAt: DateTime(2026, 9, 10),
        accountId: 'account-cash',
        categoryId: lunch.id,
        note: '余额不足',
      ),
      throwsA(anything),
    );
    expect(await store.listBackups(), isEmpty);

    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    final backups = await store.listBackups();
    expect(backups, hasLength(1));
    final payload = jsonDecode(await store.readBackup(backups.single));
    final accounts = payload['accounts'] as List<dynamic>;
    final cash = accounts.cast<Map<String, dynamic>>().singleWhere(
      (item) => item['id'] == 'account-cash',
    );
    expect(cash['opening_balance_minor'], 0);
  });

  test('automatic backups rotate at five across app sessions', () async {
    for (var index = 0; index < 6; index++) {
      final store = LocalBackupStore(rootProvider: () async => directory);
      final path = await store.beginAutomaticBackup('{"snapshot":$index}');
      await store.commitAutomaticBackup(path);
      await Future<void>.delayed(const Duration(milliseconds: 3));
    }

    final nodes = await LocalBackupStore(rootProvider: () async => directory)
        .listBackups();
    expect(
      nodes.where((item) => item.kind == LocalBackupKind.automatic),
      hasLength(5),
    );
  });

  test('manual backup can be renamed and deleted', () async {
    final store = LocalBackupStore(rootProvider: () async => directory);
    final original = await store.createManualBackup('{}', name: '出发前');
    final renamed = await store.renameBackup(original, '旅行结束');

    expect(renamed.name, '旅行结束');
    expect(await File(renamed.path).exists(), isTrue);
    await store.deleteBackup(renamed);
    expect(await store.listBackups(), isEmpty);
  });
}
