import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/import_export/ledger_export.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

void main() {
  const accounts = [
    LedgerAccount(id: 'cash', name: '现金', kind: AccountKind.cash),
    LedgerAccount(id: 'wechat', name: '微信', kind: AccountKind.wallet),
    LedgerAccount(
      id: 'account-family-card',
      name: '亲情卡',
      kind: AccountKind.entrustedFunds,
    ),
    LedgerAccount(id: 'debt', name: '朋友欠款', kind: AccountKind.creditLine),
  ];
  const expenseCategories = [
    LedgerCategory(id: 'food', name: '饮食'),
    LedgerCategory(id: 'lunch', name: '午餐', parentId: 'food'),
  ];
  const incomeCategories = [
    LedgerCategory(id: 'support', name: '家庭支持'),
    LedgerCategory(id: 'allowance', name: '生活费', parentId: 'support'),
  ];

  test('parses fenced batch JSON and resolves names to stable ids', () {
    const source = '''```json
{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "饮食/午餐",
      "account": "微信",
      "note": "午餐"
    },
    {
      "type": "borrowing",
      "amount": "1000.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "朋友欠款",
      "target_account": "现金"
    }
  ]
}
```''';

    final drafts = parseLedgerImport(
      source,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    expect(drafts, hasLength(2));
    expect(drafts.first.amountMinor, 2850);
    expect(drafts.first.categoryId, 'lunch');
    expect(drafts.last.type, LedgerTransactionType.borrowing);
    expect(drafts.last.accountId, 'debt');
    expect(drafts.last.targetAccountId, 'cash');
  });

  test('rejects unknown categories before preview', () {
    const source = '''{
      "type":"expense",
      "amount":"10.00",
      "occurred_at":"2026-09-09T12:00:00+08:00",
      "category":"饮食/不存在",
      "account":"现金"
    }''';
    expect(
      () => parseLedgerImport(
        source,
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      ),
      throwsA(isA<LedgerImportException>()),
    );
  });

  test('unknown accounts become reusable account creation drafts', () {
    const source = '''{
      "schema_version": 1,
      "transactions": [
        {
          "type":"income",
          "amount":"100.00",
          "occurred_at":"2026-09-09T12:00:00+08:00",
          "category":"家庭支持/生活费",
          "account":"新银行卡",
          "account_kind":"bank"
        },
        {
          "type":"expense",
          "amount":"20.00",
          "occurred_at":"2026-09-09T13:00:00+08:00",
          "category":"饮食/午餐",
          "account":"新银行卡"
        }
      ]
    }''';

    final drafts = parseLedgerImport(
      source,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    expect(drafts.first.accountKind, AccountKind.bank);
    expect(drafts.every((item) => item.accountIsNew), isTrue);
    expect(drafts.first.accountId, drafts.last.accountId);
  });

  test('unknown borrowing accounts infer liability and wallet roles', () {
    const source = '''{
      "type":"borrowing",
      "amount":"500.00",
      "occurred_at":"2026-09-09T12:00:00+08:00",
      "account":"新负债",
      "target_account":"新钱包"
    }''';
    final draft = parseLedgerImport(
      source,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    ).single;

    expect(draft.accountKind, AccountKind.creditLine);
    expect(draft.targetAccountKind, AccountKind.wallet);
    expect(draft.accountIsNew, isTrue);
    expect(draft.targetAccountIsNew, isTrue);
  });

  test('accepts English aliases for untouched Chinese defaults', () {
    const defaultAccounts = [
      LedgerAccount(
        id: 'account-alipay',
        name: '支付宝',
        kind: AccountKind.wallet,
      ),
    ];
    const defaultExpenseCategories = [
      LedgerCategory(id: 'expense-parent-0', name: '饮食'),
      LedgerCategory(
        id: 'expense-parent-0-child-1',
        name: '午餐',
        parentId: 'expense-parent-0',
      ),
    ];
    const source = '''{
      "type":"expense",
      "amount":"28.50",
      "occurred_at":"2026-09-09T12:00:00+08:00",
      "category":"Food/Lunch",
      "account":"Alipay"
    }''';

    final draft = parseLedgerImport(
      source,
      accounts: defaultAccounts,
      expenseCategories: defaultExpenseCategories,
      incomeCategories: const [],
      languageCode: 'en',
    ).single;

    expect(draft.accountId, 'account-alipay');
    expect(draft.accountIsNew, isFalse);
    expect(draft.categoryId, 'expense-parent-0-child-1');
  });

  test('returns English validation feedback in English mode', () {
    const source = '''{
      "type":"expense",
      "amount":"invalid",
      "occurred_at":"2026-09-09T12:00:00+08:00",
      "category":"饮食/午餐",
      "account":"现金"
    }''';

    expect(
      () => parseLedgerImport(
        source,
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        languageCode: 'en',
      ),
      throwsA(
        isA<LedgerImportException>().having(
          (error) => error.message,
          'message',
          contains('Item 1 has an invalid amount'),
        ),
      ),
    );
  });

  test('parses a transfer between two personal accounts', () {
    const source = '''{
      "type":"transfer",
      "amount":"88.00",
      "occurred_at":"2026-09-09T12:00:00+08:00",
      "account":"现金",
      "target_account":"微信"
    }''';
    final draft = parseLedgerImport(
      source,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    ).single;
    expect(draft.type, LedgerTransactionType.transfer);
    expect(draft.accountId, 'cash');
    expect(draft.targetAccountId, 'wechat');
  });

  test(
    'allows entrusted funds as a repayment source and transfer endpoint',
    () {
      const source = '''{
      "schema_version": 1,
      "transactions": [
        {
          "type":"repayment",
          "amount":"50.00",
          "occurred_at":"2026-09-09T12:00:00+08:00",
          "account":"亲情卡",
          "target_account":"朋友欠款"
        },
        {
          "type":"transfer",
          "amount":"20.00",
          "occurred_at":"2026-09-09T13:00:00+08:00",
          "account":"亲情卡",
          "target_account":"微信"
        },
        {
          "type":"transfer",
          "amount":"10.00",
          "occurred_at":"2026-09-09T14:00:00+08:00",
          "account":"微信",
          "target_account":"亲情卡"
        }
      ]
    }''';
      final drafts = parseLedgerImport(
        source,
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );

      expect(drafts.map((item) => item.type), [
        LedgerTransactionType.repayment,
        LedgerTransactionType.transfer,
        LedgerTransactionType.transfer,
      ]);
      expect(drafts.first.accountKind, AccountKind.entrustedFunds);
      expect(drafts[1].targetAccountId, 'wechat');
      expect(drafts[2].accountId, 'wechat');
      expect(drafts[2].targetAccountId, 'account-family-card');
    },
  );

  test('JSON export is losslessly accepted by the import parser', () {
    final record = LedgerRecord(
      id: 'record',
      type: LedgerTransactionType.income,
      amountMinor: 12345,
      occurredAt: DateTime.parse('2026-09-09T12:00:00+08:00'),
      parentCategoryId: 'support',
      parentCategoryName: '家庭支持',
      categoryId: 'allowance',
      categoryName: '生活费',
      accountId: 'wechat',
      accountName: '微信',
      accountKind: AccountKind.wallet.name,
      note: '测试',
    );
    final exported = exportLedgerRecords([record], LedgerExportFormat.json);
    expect(exported, contains('"account_kind": "wallet"'));

    final imported = parseLedgerImport(
      exported,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    expect(imported.single.amountMinor, 12345);
    expect(imported.single.type, LedgerTransactionType.income);
    expect(imported.single.categoryPath, '家庭支持/生活费');
  });

  test('CSV export quotes commas and starts with an Excel BOM', () {
    final record = LedgerRecord(
      id: 'record',
      type: LedgerTransactionType.expense,
      amountMinor: 100,
      occurredAt: DateTime(2026, 9, 9),
      parentCategoryId: 'food',
      parentCategoryName: '饮食',
      categoryId: 'lunch',
      categoryName: '午餐',
      accountId: 'cash',
      accountName: '现金',
      accountKind: AccountKind.cash.name,
      note: '饭,饮料',
    );
    final csv = exportLedgerRecords([record], LedgerExportFormat.csv);
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('"饭,饮料"'));
  });

  test(
    'English export localizes untouched defaults and remains importable',
    () {
      final record = LedgerRecord(
        id: 'record',
        type: LedgerTransactionType.expense,
        amountMinor: 2850,
        occurredAt: DateTime.parse('2026-09-09T12:00:00+08:00'),
        parentCategoryId: 'expense-parent-0',
        parentCategoryName: '饮食',
        categoryId: 'expense-parent-0-child-1',
        categoryName: '午餐',
        accountId: 'account-alipay',
        accountName: '支付宝',
        accountKind: AccountKind.wallet.name,
        note: 'Lunch',
      );

      final markdown = exportLedgerRecords(
        [record],
        LedgerExportFormat.markdown,
        languageCode: 'en',
      );
      final csv = exportLedgerRecords(
        [record],
        LedgerExportFormat.csv,
        languageCode: 'en',
      );
      final json = exportLedgerRecords(
        [record],
        LedgerExportFormat.json,
        languageCode: 'en',
      );

      expect(markdown, contains('# Summa Transaction Export'));
      expect(markdown, contains('Food/Lunch'));
      expect(markdown, contains('Alipay'));
      expect(csv, contains('"type","amount","occurred_at"'));

      final imported = parseLedgerImport(
        json,
        accounts: const [
          LedgerAccount(
            id: 'account-alipay',
            name: '支付宝',
            kind: AccountKind.wallet,
          ),
        ],
        expenseCategories: const [
          LedgerCategory(id: 'expense-parent-0', name: '饮食'),
          LedgerCategory(
            id: 'expense-parent-0-child-1',
            name: '午餐',
            parentId: 'expense-parent-0',
          ),
        ],
        incomeCategories: const [],
        languageCode: 'en',
      );
      expect(imported.single.accountId, 'account-alipay');
      expect(imported.single.categoryId, 'expense-parent-0-child-1');
    },
  );

  test('copied template includes current categories and stays importable', () {
    final template = ledgerImportTemplateFor(
      'zh',
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    expect(template, contains('给 LLM 的简单指令'));
    expect(template, contains('当前支出分类（一级：二级）'));
    expect(template, contains('- 饮食: 午餐'));
    expect(template, contains('分类名称自身不能包含“/”'));
    expect(template, contains('```json'));

    final imported = parseLedgerImport(
      template,
      accounts: accounts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );
    expect(imported, hasLength(2));
    expect(imported.first.categoryId, 'lunch');
  });
}
