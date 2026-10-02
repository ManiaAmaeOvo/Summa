import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_pro/data/database/app_database.dart';
import 'package:ledger_pro/data/repositories/drift_expense_repository.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';

void main() {
  late AppDatabase database;
  late DriftExpenseRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftExpenseRepository(database);
  });

  tearDown(() => database.close());

  test('seeds ordered accounts and two-level expense categories', () async {
    final accounts = await repository.watchAccounts().first;
    final categories = await repository.watchExpenseCategories().first;
    final incomeCategories = await repository.watchIncomeCategories().first;

    expect(accounts.map((account) => account.name), [
      '现金',
      '银行卡',
      '支付宝',
      '微信',
      '花呗',
      '白条',
      '抖音月付',
      '美团月付',
      '亲情卡',
    ]);
    expect(categories.where((category) => category.isParent).length, 5);
    expect(categories.where((category) => !category.isParent).length, 22);
    expect(incomeCategories.where((category) => category.isParent).length, 4);
    expect(incomeCategories.where((category) => !category.isParent).length, 13);
  });

  test('persists an expense and resolves category and account', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    final occurredAt = DateTime(2026, 9, 9, 12, 30);
    await repository.setCurrentBalance(
      accountId: 'account-alipay',
      amountMinor: 3000,
    );

    await repository.addExpense(
      amountMinor: 2850,
      occurredAt: occurredAt,
      categoryId: lunch.id,
      accountId: 'account-alipay',
      note: '工作日午餐',
    );
    final expenses = await repository.watchTransactions().first;

    expect(expenses, hasLength(1));
    expect(expenses.single.amountMinor, 2850);
    expect(expenses.single.parentCategoryName, '饮食');
    expect(expenses.single.categoryName, '午餐');
    expect(expenses.single.accountName, '支付宝');
    expect(expenses.single.note, '工作日午餐');
    expect(expenses.single.occurredAt, occurredAt);
  });

  test('calculates asset, entrusted fund, and liability balances', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');

    await repository.setCurrentBalance(
      accountId: 'account-alipay',
      amountMinor: 20000,
    );
    await repository.setCurrentBalance(
      accountId: 'account-family-card',
      amountMinor: 10000,
    );
    await repository.addExpense(
      amountMinor: 2850,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: lunch.id,
      accountId: 'account-alipay',
      note: '',
    );
    await repository.addExpense(
      amountMinor: 5000,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: lunch.id,
      accountId: 'account-huabei',
      note: '',
    );

    final balances = await repository.watchAccountBalances().first;
    expect(
      balances
          .singleWhere((account) => account.name == '支付宝')
          .currentBalanceMinor,
      17150,
    );
    expect(
      balances
          .singleWhere((account) => account.name == '亲情卡')
          .currentBalanceMinor,
      10000,
    );
    expect(
      balances
          .singleWhere((account) => account.name == '花呗')
          .currentBalanceMinor,
      5000,
    );
  });

  test('uses entrusted funds for repayment and transfers without changing account identity or history', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-family-card',
      amountMinor: 5000,
    );
    await repository.setCurrentBalance(
      accountId: 'account-huabei',
      amountMinor: 3000,
    );
    await repository.setCurrentBalance(
      accountId: 'account-wechat',
      amountMinor: 0,
    );

    await repository.addExpense(
      amountMinor: 500,
      occurredAt: DateTime(2026, 9, 8),
      categoryId: lunch.id,
      accountId: 'account-family-card',
      note: '更新前的历史支出',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 1000,
      occurredAt: DateTime(2026, 9, 9),
      accountId: 'account-family-card',
      targetAccountId: 'account-huabei',
      note: '亲情卡还款',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.transfer,
      amountMinor: 1200,
      occurredAt: DateTime(2026, 9, 10),
      accountId: 'account-family-card',
      targetAccountId: 'account-wechat',
      note: '亲情卡转入微信',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.transfer,
      amountMinor: 200,
      occurredAt: DateTime(2026, 9, 11),
      accountId: 'account-wechat',
      targetAccountId: 'account-family-card',
      note: '微信转回亲情卡',
    );

    final familyCard = (await repository.watchAccountBalances().first)
        .singleWhere((item) => item.id == 'account-family-card');
    final liability = (await repository.watchAccountBalances().first)
        .singleWhere((item) => item.id == 'account-huabei');
    final records = await repository.watchTransactions().first;
    expect(familyCard.kind, AccountKind.entrustedFunds);
    expect(familyCard.group, AccountGroup.entrustedFunds);
    expect(familyCard.currentBalanceMinor, 2500);
    expect(liability.currentBalanceMinor, 2000);
    expect(
      records.singleWhere((item) => item.note == '更新前的历史支出').accountId,
      'account-family-card',
    );
    expect(
      records.map((item) => item.type),
      containsAll([
        LedgerTransactionType.expense,
        LedgerTransactionType.repayment,
        LedgerTransactionType.transfer,
      ]),
    );
  });

  test(
    'calibrates the displayed current balance after prior expenses',
    () async {
      final categories = await repository.watchExpenseCategories().first;
      final lunch = categories.singleWhere((category) => category.name == '午餐');
      await repository.setCurrentBalance(
        accountId: 'account-alipay',
        amountMinor: 3000,
      );
      await repository.addExpense(
        amountMinor: 2850,
        occurredAt: DateTime(2026, 9, 9),
        categoryId: lunch.id,
        accountId: 'account-alipay',
        note: '',
      );

      await repository.setCurrentBalance(
        accountId: 'account-alipay',
        amountMinor: 20000,
      );
      final balances = await repository.watchAccountBalances().first;

      expect(
        balances
            .singleWhere((account) => account.name == '支付宝')
            .currentBalanceMinor,
        20000,
      );
    },
  );

  test('adds a custom liability with its current balance', () async {
    await repository.addAccount(
      name: '朋友欠款',
      kind: AccountKind.creditLine,
      currentBalanceMinor: 12000,
    );

    final balances = await repository.watchAccountBalances().first;
    final account = balances.singleWhere((account) => account.name == '朋友欠款');

    expect(account.group, AccountGroup.liability);
    expect(account.currentBalanceMinor, 12000);
  });

  test('rejects a duplicate account name', () async {
    expect(
      () => repository.addAccount(
        name: '支付宝',
        kind: AccountKind.wallet,
        currentBalanceMinor: 0,
      ),
      throwsStateError,
    );
  });

  test('updates an expense and recalculates both account balances', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-alipay',
      amountMinor: 1000,
    );
    await repository.addExpense(
      amountMinor: 1000,
      occurredAt: DateTime(2026, 9, 8),
      categoryId: lunch.id,
      accountId: 'account-alipay',
      note: '原备注',
    );
    final original = (await repository.watchTransactions().first).single;

    await repository.updateExpense(
      id: original.id,
      amountMinor: 2000,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: lunch.id,
      accountId: 'account-huabei',
      note: '修改后',
    );

    final updated = (await repository.watchTransactions().first).single;
    final balances = await repository.watchAccountBalances().first;
    expect(updated.amountMinor, 2000);
    expect(updated.accountName, '花呗');
    expect(updated.note, '修改后');
    expect(
      balances
          .singleWhere((account) => account.name == '支付宝')
          .currentBalanceMinor,
      1000,
    );
    expect(
      balances
          .singleWhere((account) => account.name == '花呗')
          .currentBalanceMinor,
      2000,
    );
  });

  test('soft deletes an expense and restores its account balance', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1500,
    );
    await repository.addExpense(
      amountMinor: 1500,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: lunch.id,
      accountId: 'account-cash',
      note: '',
    );
    final expense = (await repository.watchTransactions().first).single;

    await repository.deleteTransaction(expense.id);

    expect(await repository.watchTransactions().first, isEmpty);
    final balances = await repository.watchAccountBalances().first;
    expect(
      balances
          .singleWhere((account) => account.name == '现金')
          .currentBalanceMinor,
      1500,
    );
    final stored = await database.select(database.ledgerEntries).getSingle();
    expect(stored.isDeleted, isTrue);
  });

  test(
    'archives and restores a default account without resetting it',
    () async {
      final categories = await repository.watchExpenseCategories().first;
      final lunch = categories.singleWhere((category) => category.name == '午餐');
      await repository.setCurrentBalance(
        accountId: 'account-alipay',
        amountMinor: 1000,
      );
      await repository.addExpense(
        amountMinor: 1000,
        occurredAt: DateTime(2026, 9, 9),
        categoryId: lunch.id,
        accountId: 'account-alipay',
        note: '保留的历史账单',
      );
      await repository.setCurrentBalance(
        accountId: 'account-alipay',
        amountMinor: 20000,
      );
      await repository.archiveAccount('account-alipay');
      expect(
        (await repository.watchAccounts().first).map((account) => account.name),
        isNot(contains('支付宝')),
      );
      expect(
        (await repository.watchTransactions().first).single.accountName,
        '支付宝',
      );

      await repository.restoreDefaultAccounts();

      final account = (await repository.watchAccountBalances().first)
          .singleWhere((account) => account.name == '支付宝');
      expect(account.currentBalanceMinor, 20000);
    },
  );

  test('records income into assets and can reduce a liability', () async {
    final categories = await repository.watchIncomeCategories().first;
    final familySupport = categories.singleWhere(
      (category) => category.name == '生活费',
    );
    await repository.setCurrentBalance(
      accountId: 'account-huabei',
      amountMinor: 50000,
    );

    await repository.addTransaction(
      type: LedgerTransactionType.income,
      amountMinor: 100000,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: familySupport.id,
      accountId: 'account-wechat',
      note: '家庭生活费',
    );
    await repository.addTransaction(
      type: LedgerTransactionType.income,
      amountMinor: 10000,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: familySupport.id,
      accountId: 'account-huabei',
      note: '冲减欠款',
    );

    final balances = await repository.watchAccountBalances().first;
    expect(
      balances
          .singleWhere((account) => account.name == '微信')
          .currentBalanceMinor,
      100000,
    );
    expect(
      balances
          .singleWhere((account) => account.name == '花呗')
          .currentBalanceMinor,
      40000,
    );
  });

  test('borrowing and repayment keep liquid net assets unchanged', () async {
    await repository.addAccount(
      name: '朋友欠款',
      kind: AccountKind.creditLine,
      currentBalanceMinor: 0,
    );
    final friendDebt = (await repository.watchAccounts().first).singleWhere(
      (account) => account.name == '朋友欠款',
    );

    await repository.addTransaction(
      type: LedgerTransactionType.borrowing,
      amountMinor: 100000,
      occurredAt: DateTime(2026, 9, 9),
      accountId: friendDebt.id,
      targetAccountId: 'account-wechat',
      note: '向朋友借款',
    );
    var balances = await repository.watchAccountBalances().first;
    expect(
      balances
          .singleWhere((account) => account.name == '微信')
          .currentBalanceMinor,
      100000,
    );
    expect(
      balances
          .singleWhere((account) => account.name == '朋友欠款')
          .currentBalanceMinor,
      100000,
    );

    await repository.addTransaction(
      type: LedgerTransactionType.repayment,
      amountMinor: 30000,
      occurredAt: DateTime(2026, 9, 10),
      accountId: 'account-wechat',
      targetAccountId: friendDebt.id,
      note: '归还部分借款',
    );
    balances = await repository.watchAccountBalances().first;
    final wechat = balances.singleWhere((account) => account.name == '微信');
    final debt = balances.singleWhere((account) => account.name == '朋友欠款');
    expect(wechat.currentBalanceMinor, 70000);
    expect(debt.currentBalanceMinor, 70000);
    expect(wechat.currentBalanceMinor - debt.currentBalanceMinor, 0);

    final records = await repository.watchTransactions().first;
    expect(records.first.type, LedgerTransactionType.repayment);
    expect(records.last.type, LedgerTransactionType.borrowing);
    expect(records.last.targetAccountName, '微信');
  });

  test('rejects expenses that exceed an asset balance', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );

    expect(
      () => repository.addExpense(
        amountMinor: 1001,
        occurredAt: DateTime(2026, 9, 9),
        categoryId: lunch.id,
        accountId: 'account-cash',
        note: '',
      ),
      throwsA(isA<TransactionRuleException>()),
    );
    expect(await repository.watchTransactions().first, isEmpty);
  });

  test('rejects repayment above either cash or outstanding debt', () async {
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 10000,
    );
    await repository.setCurrentBalance(
      accountId: 'account-huabei',
      amountMinor: 5000,
    );

    expect(
      () => repository.addTransaction(
        type: LedgerTransactionType.repayment,
        amountMinor: 5001,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        targetAccountId: 'account-huabei',
        note: '',
      ),
      throwsA(isA<TransactionRuleException>()),
    );
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    expect(
      () => repository.addTransaction(
        type: LedgerTransactionType.repayment,
        amountMinor: 1001,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        targetAccountId: 'account-huabei',
        note: '',
      ),
      throwsA(isA<TransactionRuleException>()),
    );
    expect(await repository.watchTransactions().first, isEmpty);
  });

  test('editing validates against the balance before the old record', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    await repository.addExpense(
      amountMinor: 800,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: lunch.id,
      accountId: 'account-cash',
      note: '',
    );
    final record = (await repository.watchTransactions().first).single;

    await repository.updateExpense(
      id: record.id,
      amountMinor: 900,
      occurredAt: record.occurredAt,
      categoryId: record.categoryId,
      accountId: record.accountId,
      note: '',
    );
    expect(
      () => repository.updateExpense(
        id: record.id,
        amountMinor: 1001,
        occurredAt: record.occurredAt,
        categoryId: record.categoryId,
        accountId: record.accountId,
        note: '',
      ),
      throwsA(isA<TransactionRuleException>()),
    );
    final unchanged = (await repository.watchTransactions().first).single;
    expect(unchanged.amountMinor, 900);
  });

  test('batch import is atomic when a later record fails', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((category) => category.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    final drafts = [
      LedgerImportDraft(
        type: LedgerTransactionType.expense,
        amountMinor: 400,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        accountName: '现金',
        accountKind: AccountKind.cash,
        categoryId: lunch.id,
        categoryPath: '饮食/午餐',
        note: '',
      ),
      LedgerImportDraft(
        type: LedgerTransactionType.expense,
        amountMinor: 700,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        accountName: '现金',
        accountKind: AccountKind.cash,
        categoryId: lunch.id,
        categoryPath: '饮食/午餐',
        note: '',
      ),
    ];

    expect(
      () => repository.importTransactions(drafts),
      throwsA(isA<TransactionRuleException>()),
    );
    expect(await repository.watchTransactions().first, isEmpty);
  });

  test(
    'batch import creates a missing account with a safe opening balance',
    () async {
      final categories = await repository.watchExpenseCategories().first;
      final lunch = categories.singleWhere((category) => category.name == '午餐');
      await repository.importTransactions([
        LedgerImportDraft(
          type: LedgerTransactionType.expense,
          amountMinor: 5000,
          occurredAt: DateTime(2026, 9, 9),
          accountId: '__new__:新钱包',
          accountName: '新钱包',
          accountKind: AccountKind.wallet,
          accountIsNew: true,
          categoryId: lunch.id,
          categoryPath: '饮食/午餐',
          note: '',
        ),
      ]);

      final account = (await repository.watchAccountBalances().first)
          .singleWhere((item) => item.name == '新钱包');
      expect(account.kind, AccountKind.wallet);
      expect(account.openingBalanceMinor, 5000);
      expect(account.currentBalanceMinor, 0);
      expect(await repository.watchTransactions().first, hasLength(1));
    },
  );

  test('transfer moves money without changing total personal assets', () async {
    await repository.setCurrentBalance(
      accountId: 'account-alipay',
      amountMinor: 10000,
    );
    await repository.addTransaction(
      type: LedgerTransactionType.transfer,
      amountMinor: 3500,
      occurredAt: DateTime(2026, 9, 9),
      accountId: 'account-alipay',
      targetAccountId: 'account-wechat',
      note: '零钱转移',
    );

    final balances = await repository.watchAccountBalances().first;
    expect(
      balances
          .singleWhere((item) => item.id == 'account-alipay')
          .currentBalanceMinor,
      6500,
    );
    expect(
      balances
          .singleWhere((item) => item.id == 'account-wechat')
          .currentBalanceMinor,
      3500,
    );
    expect(
      balances
          .where((item) => item.group == AccountGroup.personalAsset)
          .fold<int>(0, (sum, item) => sum + item.currentBalanceMinor),
      10000,
    );
    expect(
      (await repository.watchTransactions().first).single.type,
      LedgerTransactionType.transfer,
    );
  });

  test('transfer rejects overdrafts and non-personal targets', () async {
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 100,
    );
    expect(
      () => repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 101,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        targetAccountId: 'account-wechat',
        note: '',
      ),
      throwsA(isA<TransactionRuleException>()),
    );
    expect(
      () => repository.addTransaction(
        type: LedgerTransactionType.transfer,
        amountMinor: 50,
        occurredAt: DateTime(2026, 9, 9),
        accountId: 'account-cash',
        targetAccountId: 'account-huabei',
        note: '',
      ),
      throwsArgumentError,
    );
  });

  test('archived custom category remains readable in history', () async {
    await repository.addCategory(
      type: LedgerTransactionType.expense,
      name: '学习',
    );
    var categories = await repository.watchExpenseCategories().first;
    final parent = categories.singleWhere((item) => item.name == '学习');
    expect(
      categories.where((item) => item.parentId == parent.id).map((e) => e.name),
      contains('其他'),
    );
    await repository.addCategory(
      type: LedgerTransactionType.expense,
      parentId: parent.id,
      name: '教材',
    );
    categories = await repository.watchExpenseCategories().first;
    final child = categories.singleWhere((item) => item.name == '教材');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    await repository.addExpense(
      amountMinor: 500,
      occurredAt: DateTime(2026, 9, 9),
      categoryId: child.id,
      accountId: 'account-cash',
      note: '',
    );
    await repository.archiveCategory(child.id);

    expect(
      (await repository.watchExpenseCategories().first).any(
        (item) => item.id == child.id,
      ),
      isFalse,
    );
    expect(
      (await repository.watchTransactions().first).single.categoryName,
      '教材',
    );
  });

  test('keeps Other last for both category levels', () async {
    await repository.addCategory(
      type: LedgerTransactionType.expense,
      name: '学习',
    );
    await repository.addCategory(
      type: LedgerTransactionType.income,
      name: '补助',
    );

    var expenses = await repository.watchExpenseCategories().first;
    var income = await repository.watchIncomeCategories().first;
    expect(expenses.where((item) => item.isParent).last.name, '其他');
    expect(income.where((item) => item.isParent).last.name, '其他收入');

    final food = expenses.singleWhere((item) => item.name == '饮食');
    await repository.addCategory(
      type: LedgerTransactionType.expense,
      parentId: food.id,
      name: '夜宵',
    );
    expenses = await repository.watchExpenseCategories().first;
    var foodChildren = expenses
        .where((item) => item.parentId == food.id)
        .toList();
    expect(foodChildren.last.name, '其他');
    expect(foodChildren[foodChildren.length - 2].name, '夜宵');

    final lateSnack = foodChildren.singleWhere((item) => item.name == '夜宵');
    await repository.moveCategory(lateSnack.id, moveUp: false);
    expenses = await repository.watchExpenseCategories().first;
    foodChildren = expenses.where((item) => item.parentId == food.id).toList();
    expect(foodChildren.last.name, '其他');
    expect(foodChildren[foodChildren.length - 2].name, '夜宵');
  });

  test('full backup previews and restores soft-deleted data', () async {
    final categories = await repository.watchExpenseCategories().first;
    final lunch = categories.singleWhere((item) => item.name == '午餐');
    await repository.setCurrentBalance(
      accountId: 'account-cash',
      amountMinor: 1000,
    );
    for (final item in const [('保留', 300), ('软删除', 200)]) {
      await repository.addExpense(
        amountMinor: item.$2,
        occurredAt: DateTime(2026, 9, 9),
        categoryId: lunch.id,
        accountId: 'account-cash',
        note: item.$1,
      );
    }
    var entries = await repository.watchTransactions().first;
    await repository.deleteTransaction(
      entries.singleWhere((item) => item.note == '软删除').id,
    );

    final backup = await repository.createFullBackup();
    expect(
      (jsonDecode(backup) as Map<String, dynamic>)['format'],
      'ledgerpro_full_backup',
      reason: 'The legacy marker keeps pre-Summa backups compatible.',
    );
    final preview = repository.inspectFullBackup(backup);
    expect(preview.entryCount, 2);
    expect(preview.deletedEntryCount, 1);

    entries = await repository.watchTransactions().first;
    await repository.deleteTransaction(entries.single.id);
    expect(await repository.watchTransactions().first, isEmpty);
    await repository.restoreFullBackup(backup, mode: BackupRestoreMode.replace);

    final restored = await repository.watchTransactions().first;
    expect(restored, hasLength(1));
    expect(restored.single.note, '保留');
    expect(
      repository
          .inspectFullBackup(await repository.createFullBackup())
          .deletedEntryCount,
      1,
    );
  });

  test(
    'invalid replacement backup rolls back without losing current data',
    () async {
      final categories = await repository.watchExpenseCategories().first;
      final lunch = categories.singleWhere((item) => item.name == '午餐');
      await repository.setCurrentBalance(
        accountId: 'account-cash',
        amountMinor: 1000,
      );
      await repository.addExpense(
        amountMinor: 100,
        occurredAt: DateTime(2026, 9, 9),
        categoryId: lunch.id,
        accountId: 'account-cash',
        note: '不能丢失',
      );
      final payload = jsonDecode(
        await repository.createFullBackup(),
      ) as Map<String, dynamic>;
      final entries = payload['entries'] as List<dynamic>;
      (entries.single as Map<String, dynamic>)['account_id'] =
          'missing-account';

      expect(
        () => repository.restoreFullBackup(
          jsonEncode(payload),
          mode: BackupRestoreMode.replace,
        ),
        throwsA(anything),
      );
      final stillPresent = await repository.watchTransactions().first;
      expect(stillPresent.single.note, '不能丢失');
    },
  );

  test(
    'ledger reset clears entries and accounts but preserves categories',
    () async {
      await repository.addCategory(
        type: LedgerTransactionType.expense,
        name: '测试分类',
      );
      await repository.addAccount(
        name: '测试钱包',
        kind: AccountKind.wallet,
        currentBalanceMinor: 500,
      );
      final categories = await repository.watchExpenseCategories().first;
      final lunch = categories.singleWhere((item) => item.name == '午餐');
      final wallet = (await repository.watchAccounts().first).singleWhere(
        (item) => item.name == '测试钱包',
      );
      await repository.addExpense(
        amountMinor: 100,
        occurredAt: DateTime(2026, 9, 10),
        categoryId: lunch.id,
        accountId: wallet.id,
        note: '待清空',
      );

      await repository.resetLedgerData();

      expect(await repository.watchTransactions().first, isEmpty);
      expect(
        (await repository.watchAccounts().first).map((item) => item.name),
        isNot(contains('测试钱包')),
      );
      expect(
        (await repository.watchAccountBalances().first).every(
          (item) => item.currentBalanceMinor == 0,
        ),
        isTrue,
      );
      expect(
        (await repository.watchExpenseCategories().first).map(
          (item) => item.name,
        ),
        contains('测试分类'),
      );
    },
  );

  test('factory reset restores default categories', () async {
    await repository.addCategory(
      type: LedgerTransactionType.expense,
      name: '测试分类',
    );

    await repository.resetToFactoryDefaults();

    expect(
      (await repository.watchExpenseCategories().first).map(
        (item) => item.name,
      ),
      isNot(contains('测试分类')),
    );
    expect(await repository.watchTransactions().first, isEmpty);
  });
}
