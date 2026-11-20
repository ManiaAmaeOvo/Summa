import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:summa/app/app.dart';
import 'package:summa/app/locale_controller.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/text_scale_controller.dart';
import 'package:summa/app/theme/ledger_scroll_behavior.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';
import 'package:summa/features/transaction_editor/add_expense_sheet.dart';
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('流动净资产'));
    await tester.pumpAndSettle();

    expect(find.text('账户余额'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard and report totals only use the selected currency', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LedgerRecord expense(String currency, int amount) => LedgerRecord(
      id: currency,
      type: LedgerTransactionType.expense,
      amountMinor: amount,
      currencyCode: currency,
      occurredAt: DateTime.now(),
      parentCategoryId: 'food',
      parentCategoryName: '饮食',
      categoryId: 'lunch',
      categoryName: '午餐',
      accountId: currency,
      accountName: '$currency cash',
      accountKind: AccountKind.cash.name,
      note: '',
    );

    await tester.pumpWidget(
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value([expense('CNY', 200), expense('USD', 400)]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([
              const AccountBalance(
                id: 'CNY',
                name: 'CNY cash',
                kind: AccountKind.cash,
                openingBalanceMinor: 1000,
                currentBalanceMinor: 1000,
              ),
              const AccountBalance(
                id: 'USD',
                name: 'USD cash',
                kind: AccountKind.cash,
                currencyCode: 'USD',
                openingBalanceMinor: 3000,
                currentBalanceMinor: 3000,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Future<void> selectUsd() async {
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD').last);
      await tester.pumpAndSettle();
    }

    expect(find.text('¥10.00'), findsOneWidget);
    expect(find.text('USD 30.00'), findsNothing);
    await selectUsd();
    expect(find.text('USD 30.00'), findsOneWidget);
    expect(find.text('USD 4.00'), findsWidgets);
    expect(find.text('¥10.00'), findsNothing);

    await tester.tap(find.text('报表'));
    await tester.pumpAndSettle();
    expect(find.text('¥2.00'), findsWidgets);
    expect(find.text('USD 4.00'), findsNothing);
    await selectUsd();
    expect(find.text('USD 4.00'), findsWidgets);
    expect(find.text('¥2.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an FX transfer edit keeps both amounts and the quote direction',
    (tester) async {
      tester.view.physicalSize = const Size(450, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final transfer = LedgerRecord(
        id: 'fx',
        type: LedgerTransactionType.transfer,
        amountMinor: 2500,
        occurredAt: DateTime.now(),
        parentCategoryId: 'flow-transfer-parent',
        parentCategoryName: '转账',
        categoryId: 'flow-transfer',
        categoryName: '账户间转账',
        accountId: 'cash',
        accountName: '现金',
        accountKind: AccountKind.cash.name,
        targetAccountId: 'jpy',
        targetAccountName: '东京钱包',
        targetAccountKind: AccountKind.wallet.name,
        settlement: const TransferSettlement(
          amountMinor: 512,
          currencyCode: 'JPY',
          quotedRate: '20.5',
        ),
        note: '',
      );
      await tester.pumpWidget(
        _testApp(
          overrides: [
            transactionsProvider.overrideWith(
              (ref) => Stream.value([transfer]),
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
                  id: 'jpy',
                  name: '东京钱包',
                  kind: AccountKind.wallet,
                  currencyCode: 'JPY',
                ),
              ]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('转账'));
      await tester.pumpAndSettle();

      expect(find.text('25.00'), findsOneWidget);
      expect(find.text('512'), findsOneWidget);
      expect(find.text('20.5'), findsOneWidget);
      expect(find.text('1 CNY 兑换的 JPY 金额'), findsOneWidget);
      expect(find.text('实际汇率：1 CNY = 20.48 JPY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shows missing valuation currency and updates the estimate after a rate arrives',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final valuation = StreamController<ValuationSettings>();
      addTearDown(valuation.close);
      valuation.add(const ValuationSettings());
      await tester.pumpWidget(
        _testApp(
          valuation: valuation.stream,
          overrides: [
            transactionsProvider.overrideWith(
              (ref) => Stream.value(<LedgerRecord>[]),
            ),
            accountBalancesProvider.overrideWith(
              (ref) => Stream.value([
                const AccountBalance(
                  id: 'cash',
                  name: 'Cash',
                  kind: AccountKind.cash,
                  openingBalanceMinor: 1000,
                  currentBalanceMinor: 1000,
                ),
                const AccountBalance(
                  id: 'usd',
                  name: 'USD wallet',
                  kind: AccountKind.wallet,
                  currencyCode: 'USD',
                  openingBalanceMinor: 100,
                  currentBalanceMinor: 100,
                ),
              ]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('账户'));
      await tester.pumpAndSettle();

      final amount = find.byKey(const ValueKey('estimated-net-worth-amount'));
      expect(find.text('缺少估值汇率：USD'), findsOneWidget);
      expect(amount, findsNothing);
      await tester.tap(find.text('估值设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('valuation-rate-USD')));
      await tester.pumpAndSettle();
      expect(find.text('1 USD 兑换的 CNY 金额'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      valuation.add(
        ValuationSettings(
          rates: [
            ValuationRate(
              sourceCurrency: 'USD',
              baseCurrency: 'CNY',
              rate: '7.2',
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('缺少估值汇率：USD'), findsNothing);
      expect(tester.widget<Text>(amount).data, '¥17.20');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('changes and persists language from Settings', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value(<AccountBalance>[]),
          ),
        ],
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
        ],
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
      _testApp(
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
    await tester.drag(
      find.ancestor(of: find.text('分类管理'), matching: find.byType(ListView)),
      const Offset(0, 200),
    );
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
      _testApp(
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
      _testApp(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(<LedgerRecord>[]),
          ),
          accountBalancesProvider.overrideWith(
            (ref) => Stream.value([cashBalance]),
          ),
        ],
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
      _testApp(
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
      _testApp(
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
              const LedgerAccount(
                id: 'family-card',
                name: '亲情卡',
                kind: AccountKind.entrustedFunds,
              ),
              const LedgerAccount(
                id: 'wechat',
                name: '微信',
                kind: AccountKind.wallet,
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

    await tester.ensureVisible(find.text('还款'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('还款'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repayment-source')));
    await tester.pumpAndSettle();
    expect(find.text('亲情卡'), findsWidgets);
    await tester.tap(find.text('亲情卡').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('转账'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转账'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transfer-source')));
    await tester.pumpAndSettle();
    expect(find.text('亲情卡'), findsWidgets);
    await tester.tap(find.text('亲情卡').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transfer-target-family-card')));
    await tester.pumpAndSettle();
    expect(find.text('微信'), findsOneWidget);
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
      _testApp(
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

Widget _testApp({
  required List<Override> overrides,
  Stream<ValuationSettings>? valuation,
}) => ProviderScope(
  overrides: [
    valuationSettingsProvider.overrideWith(
      (ref) => valuation ?? Stream.value(const ValuationSettings()),
    ),
    ...overrides,
  ],
  child: const SummaApp(),
);

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
    List<AccountPayment>? payments,
    TransferSettlement? settlement,
    TransactionTerms terms = const TransactionTerms(),
    LedgerPostingStatus status = LedgerPostingStatus.posted,
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
