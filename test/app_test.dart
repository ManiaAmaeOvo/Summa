import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/app/app.dart';
import 'package:ledger_pro/app/locale_controller.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/app/text_scale_controller.dart';
import 'package:ledger_pro/app/theme/ledger_scroll_behavior.dart';
import 'package:ledger_pro/data/database/app_database.dart';
import 'package:ledger_pro/data/repositories/drift_expense_repository.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';
import 'package:ledger_pro/features/transaction_editor/add_expense_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTesting();
    LocaleController.instance.value = AppLanguage.simplifiedChinese;
    TextScaleController.instance.resetForTesting();
  });

  tearDown(() {
    LocaleController.instance.resetForTesting();
    TextScaleController.instance.resetForTesting();
  });

  final cashBalance = AccountBalance(
    id: 'cash',
    name: '现金',
    kind: AccountKind.cash,
    openingBalanceMinor: 0,
    currentBalanceMinor: 0,
  );

  testWidgets('shows the Summa foundation screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Summa'), findsOneWidget);
    expect(find.text('还没有账单'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('本月支出'), findsOneWidget);
    expect(find.text('流动净资产'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.scrollBehavior, isA<LedgerScrollBehavior>());
  });

  testWidgets('switches the complete shell to English', (tester) async {
    LocaleController.instance.value = AppLanguage.english;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Expense this month'), findsOneWidget);
    expect(find.text('Liquid net worth'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens Accounts from the liquid net worth card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('流动净资产'));
    await tester.pumpAndSettle();

    expect(find.text('账户余额'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes and persists language from Settings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('语言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(LocaleController.instance.value, AppLanguage.english);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'english');
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes and persists the app font size', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('字体大小'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('特大'));
    await tester.pumpAndSettle();

    expect(TextScaleController.instance.value, AppTextSize.extraLarge);
    expect(
      TextScaleController.instance.apply(TextScaler.noScaling).scale(10),
      13,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(TextScaleController.preferenceKey),
      'extraLarge',
    );
    expect(find.text('设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('balance dialog closes without lifecycle errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('现金'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('现金'));
    await tester.pumpAndSettle();

    expect(find.text('校准现金当前余额'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('校准现金当前余额'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens settings and category management', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerCategory(id: 'food', name: '饮食'),
              const LedgerCategory(id: 'other', name: '其他', parentId: 'food'),
            ]),
          ),
          incomeCategoriesProvider.overrideWith(
            (ref) => Stream.value(<LedgerCategory>[]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('数据与备份'), findsOneWidget);
    expect(find.text('使用说明'), findsOneWidget);
    expect(find.text('关于 Summa'), findsOneWidget);
    await tester.ensureVisible(find.text('使用说明'));
    await tester.tap(find.text('使用说明'));
    await tester.pumpAndSettle();
    expect(find.text('记账与交易类型'), findsOneWidget);
    await tester.tap(find.text('记账与交易类型'));
    await tester.pumpAndSettle();
    expect(find.textContaining('借入会同时增加负债'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('分类管理'));
    await tester.pumpAndSettle();
    expect(find.text('分类管理'), findsOneWidget);
    expect(find.text('饮食'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports show expense, income, and liability charts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final expense = LedgerRecord(
      id: 'report-expense',
      type: LedgerTransactionType.expense,
      amountMinor: 12345,
      occurredAt: DateTime.now(),
      parentCategoryId: 'expense-parent-0',
      parentCategoryName: '饮食',
      categoryId: 'expense-parent-0-child-1',
      categoryName: '午餐',
      accountId: 'account-cash',
      accountName: '现金',
      accountKind: AccountKind.cash.name,
      note: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith((ref) => Stream.value([expense])),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([
              cashBalance,
              const AccountBalance(
                id: 'account-huabei',
                name: '花呗',
                kind: AccountKind.creditLine,
                openingBalanceMinor: 0,
                currentBalanceMinor: 0,
              ),
            ]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('报表'));
    await tester.pumpAndSettle();

    expect(find.text('支出分类'), findsOneWidget);
    expect(find.text('收入分类'), findsOneWidget);
    expect(find.text('此周期暂无收入分类数据'), findsOneWidget);
    expect(find.text('负债走势'), findsOneWidget);
    expect(find.text('暂无负债账户或负债变动'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account dialog closes without lifecycle errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('账户'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('添加账户'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('添加账户'));
    await tester.pumpAndSettle();

    expect(find.text('核算类型'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('核算类型'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens an existing expense with editable values', (tester) async {
    final expense = LedgerRecord(
      id: 'expense-1',
      type: LedgerTransactionType.expense,
      amountMinor: 2850,
      occurredAt: DateTime(2026, 9, 9, 12, 30),
      parentCategoryId: 'food',
      parentCategoryName: '饮食',
      categoryId: 'lunch',
      categoryName: '午餐',
      accountId: 'cash',
      accountName: '现金',
      accountKind: AccountKind.cash.name,
      note: '工作日午餐',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith((ref) => Stream.value([expense])),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
          accountsProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerAccount(
                id: 'cash',
                name: '现金',
                kind: AccountKind.cash,
              ),
            ]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerCategory(id: 'food', name: '饮食'),
              const LedgerCategory(id: 'lunch', name: '午餐', parentId: 'food'),
            ]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('饮食 · 午餐'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('饮食 · 午餐'));
    await tester.pumpAndSettle();

    expect(find.text('编辑记录'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '28.50'), findsOneWidget);
    expect(find.text('工作日午餐'), findsOneWidget);
  });

  testWidgets('shows four transaction modes on a phone-width screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const food = LedgerCategory(id: 'food', name: '饮食');
    const lunch = LedgerCategory(id: 'lunch', name: '午餐', parentId: 'food');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
          accountsProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerAccount(
                id: 'cash',
                name: '现金',
                kind: AccountKind.cash,
              ),
              const LedgerAccount(
                id: 'debt',
                name: '朋友欠款',
                kind: AccountKind.creditLine,
              ),
            ]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => Stream.value([food, lunch]),
          ),
          incomeCategoriesProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerCategory(id: 'support', name: '家庭支持'),
              const LedgerCategory(
                id: 'allowance',
                name: '生活费',
                parentId: 'support',
              ),
            ]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();

    expect(find.text('支出'), findsOneWidget);
    expect(find.text('收入'), findsOneWidget);
    expect(find.text('转账'), findsOneWidget);
    expect(find.text('借入'), findsOneWidget);
    expect(find.text('还款'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('借入'));
    await tester.pumpAndSettle();
    expect(find.text('负债账户'), findsOneWidget);
    expect(find.text('资金存入账户'), findsOneWidget);
    expect(find.text('快捷添加负债账户'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows insufficient balance inside the open editor', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    });
    final repository = _RejectingExpenseRepository(database);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repository),
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([
              const AccountBalance(
                id: 'account-cash',
                name: '现金',
                kind: AccountKind.cash,
                openingBalanceMinor: 100,
                currentBalanceMinor: 100,
              ),
            ]),
          ),
          accountsProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerAccount(
                id: 'account-cash',
                name: '现金',
                kind: AccountKind.cash,
              ),
            ]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => Stream.value([
              const LedgerCategory(id: 'food', name: '饮食'),
              const LedgerCategory(id: 'lunch', name: '午餐', parentId: 'food'),
            ]),
          ),
        ],
        child: const SummaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('记一笔'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '2.00');
    await tester.scrollUntilVisible(
      find.text('保存记录'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('保存记录'));
    await tester.pumpAndSettle();

    expect(find.text('记一笔'), findsWidgets);
    expect(find.text('现金余额不足，当前可用 ¥1.00'), findsOneWidget);
    expect(find.byType(TransactionEditorSheet), findsOneWidget);
  });
}

class _RejectingExpenseRepository extends DriftExpenseRepository {
  _RejectingExpenseRepository(super.database);

  @override
  Future<void> addTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  }) {
    return Future.error(
      const TransactionRuleException(
        TransactionRuleError.insufficientBalance,
        accountId: 'account-cash',
        accountName: '现金',
        amountMinor: 100,
      ),
    );
  }
}
