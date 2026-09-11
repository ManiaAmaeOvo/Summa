import 'dart:convert';

import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/defaults/default_ledger_names.dart';

class LedgerImportException implements Exception {
  const LedgerImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LedgerImportDraft {
  const LedgerImportDraft({
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.accountId,
    required this.accountName,
    required this.accountKind,
    this.accountIsNew = false,
    this.targetAccountId,
    this.targetAccountName,
    this.targetAccountKind,
    this.targetAccountIsNew = false,
    this.categoryId,
    this.categoryPath,
    required this.note,
  });

  final LedgerTransactionType type;
  final int amountMinor;
  final DateTime occurredAt;
  final String accountId;
  final String accountName;
  final AccountKind accountKind;
  final bool accountIsNew;
  final String? targetAccountId;
  final String? targetAccountName;
  final AccountKind? targetAccountKind;
  final bool targetAccountIsNew;
  final String? categoryId;
  final String? categoryPath;
  final String note;

  LedgerImportDraft copyWith({
    int? amountMinor,
    DateTime? occurredAt,
    String? accountId,
    String? accountName,
    AccountKind? accountKind,
    bool? accountIsNew,
    String? targetAccountId,
    String? targetAccountName,
    AccountKind? targetAccountKind,
    bool? targetAccountIsNew,
    String? categoryId,
    String? categoryPath,
    String? note,
  }) => LedgerImportDraft(
    type: type,
    amountMinor: amountMinor ?? this.amountMinor,
    occurredAt: occurredAt ?? this.occurredAt,
    accountId: accountId ?? this.accountId,
    accountName: accountName ?? this.accountName,
    accountKind: accountKind ?? this.accountKind,
    accountIsNew: accountIsNew ?? this.accountIsNew,
    targetAccountId: targetAccountId ?? this.targetAccountId,
    targetAccountName: targetAccountName ?? this.targetAccountName,
    targetAccountKind: targetAccountKind ?? this.targetAccountKind,
    targetAccountIsNew: targetAccountIsNew ?? this.targetAccountIsNew,
    categoryId: categoryId ?? this.categoryId,
    categoryPath: categoryPath ?? this.categoryPath,
    note: note ?? this.note,
  );
}

List<LedgerImportDraft> parseLedgerImport(
  String source, {
  required List<LedgerAccount> accounts,
  required List<LedgerCategory> expenseCategories,
  required List<LedgerCategory> incomeCategories,
  String languageCode = 'zh',
}) {
  final text = _stripFence(source, languageCode);
  dynamic root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (error) {
    throw LedgerImportException(
      _localized(
        languageCode,
        'JSON 格式错误：${error.message}',
        'Invalid JSON: ${error.message}',
      ),
    );
  }
  late List<dynamic> rows;
  if (root is List) {
    rows = root;
  } else if (root is Map<String, dynamic> && root['transactions'] is List) {
    if (root['schema_version'] != 1) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '仅支持 schema_version: 1',
          'Only schema_version: 1 is supported',
        ),
      );
    }
    rows = root['transactions'] as List<dynamic>;
  } else if (root is Map<String, dynamic> && root.containsKey('type')) {
    rows = [root];
  } else {
    throw LedgerImportException(
      _localized(
        languageCode,
        '代码块必须是账单对象、数组或 transactions 包装对象',
        'The input must be a transaction object, an array, or a transactions wrapper object',
      ),
    );
  }
  if (rows.isEmpty) {
    throw LedgerImportException(
      _localized(languageCode, '没有可导入的账单', 'No transactions to import'),
    );
  }
  if (rows.length > 500) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '单次最多导入 500 条账单',
        'A single import is limited to 500 transactions',
      ),
    );
  }

  final availableAccounts = [...accounts];
  return [
    for (var index = 0; index < rows.length; index++)
      _parseRow(
        rows[index],
        index,
        availableAccounts,
        expenseCategories,
        incomeCategories,
        languageCode,
      ),
  ];
}

LedgerImportDraft _parseRow(
  dynamic value,
  int index,
  List<LedgerAccount> accounts,
  List<LedgerCategory> expenseCategories,
  List<LedgerCategory> incomeCategories,
  String languageCode,
) {
  final number = index + 1;
  if (value is! Map<String, dynamic>) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条不是 JSON 对象',
        'Item $number is not a JSON object',
      ),
    );
  }
  final rawType = value['type'];
  final rawAmount = value['amount'];
  final rawTime = value['occurred_at'];
  final rawAccount = value['account'];
  if (rawType is! String ||
      rawAmount is! String ||
      rawTime is! String ||
      rawAccount is! String) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条缺少字符串字段 type、amount、occurred_at 或 account',
        'Item $number is missing a string field: type, amount, occurred_at, or account',
      ),
    );
  }
  final type = LedgerTransactionType.values
      .where((item) => item.name == rawType)
      .firstOrNull;
  if (type == null) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条 type 必须是 expense、income、transfer、borrowing 或 repayment',
        'Item $number type must be expense, income, transfer, borrowing, or repayment',
      ),
    );
  }
  int amountMinor;
  try {
    amountMinor = parseCnyMinorUnits(rawAmount);
  } on MoneyInputException catch (error) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条金额错误：${error.message}',
        'Item $number has an invalid amount: ${_moneyErrorEnglish(error)}',
      ),
    );
  }
  final occurredAt = DateTime.tryParse(rawTime);
  if (occurredAt == null) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条 occurred_at 不是 ISO 8601 时间',
        'Item $number occurred_at is not an ISO 8601 timestamp',
      ),
    );
  }
  var account = accounts
      .where((item) => DefaultLedgerNames.accountMatches(item, rawAccount))
      .firstOrNull;
  final accountIsNew = account == null;
  account ??= _newAccount(
    rawAccount,
    value['account_kind'],
    _inferredKind(type, isTarget: false),
    number,
    languageCode,
  );
  if (accountIsNew) accounts.add(account);

  LedgerAccount? target;
  final rawTarget = value['target_account'];
  if (rawTarget != null) {
    if (rawTarget is! String) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条 target_account 必须是字符串',
          'Item $number target_account must be a string',
        ),
      );
    }
    target = accounts
        .where((item) => DefaultLedgerNames.accountMatches(item, rawTarget))
        .firstOrNull;
    final isNew = target == null;
    target ??= _newAccount(
      rawTarget,
      value['target_account_kind'],
      _inferredKind(type, isTarget: true),
      number,
      languageCode,
    );
    if (isNew) accounts.add(target);
  }

  String? categoryId;
  String? categoryPath;
  if (type == LedgerTransactionType.expense ||
      type == LedgerTransactionType.income) {
    final rawCategory = value['category'];
    if (rawCategory is! String) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条缺少 category',
          'Item $number is missing category',
        ),
      );
    }
    final categories = type == LedgerTransactionType.expense
        ? expenseCategories
        : incomeCategories;
    final parts = rawCategory.split('/');
    if (parts.length != 2) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条 category 应为“主分类/子分类”',
          'Item $number category must use “Primary/Secondary”',
        ),
      );
    }
    final parent = categories
        .where(
          (item) =>
              item.isParent &&
              DefaultLedgerNames.categoryMatches(item, parts.first),
        )
        .firstOrNull;
    final child = parent == null
        ? null
        : categories
              .where(
                (item) =>
                    item.parentId == parent.id &&
                    DefaultLedgerNames.categoryMatches(item, parts.last),
              )
              .firstOrNull;
    if (child == null) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条找不到分类“$rawCategory”',
          'Item $number category “$rawCategory” was not found',
        ),
      );
    }
    categoryId = child.id;
    categoryPath = rawCategory;
  }
  _validateAccountRoles(number, type, account, target, languageCode);
  final note = value['note'] ?? '';
  if (note is! String || note.length > 200) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条 note 必须是最多 200 字的字符串',
        'Item $number note must be a string of no more than 200 characters',
      ),
    );
  }
  return LedgerImportDraft(
    type: type,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    accountId: account.id,
    accountName: account.name,
    accountKind: account.kind,
    accountIsNew: account.id.startsWith('__new__:'),
    targetAccountId: target?.id,
    targetAccountName: target?.name,
    targetAccountKind: target?.kind,
    targetAccountIsNew: target?.id.startsWith('__new__:') ?? false,
    categoryId: categoryId,
    categoryPath: categoryPath,
    note: note,
  );
}

LedgerAccount _newAccount(
  String name,
  dynamic rawKind,
  AccountKind inferred,
  int number,
  String languageCode,
) {
  var kind = inferred;
  if (rawKind != null) {
    if (rawKind is! String) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条账户类型必须是字符串',
          'Item $number account kind must be a string',
        ),
      );
    }
    final parsed = AccountKind.values
        .where((item) => item.name == rawKind)
        .firstOrNull;
    if (parsed == null) {
      throw LedgerImportException(
        _localized(
          languageCode,
          '第 $number 条账户类型必须是 cash、bank、wallet、creditLine 或 entrustedFunds',
          'Item $number account kind must be cash, bank, wallet, creditLine, or entrustedFunds',
        ),
      );
    }
    kind = parsed;
  }
  return LedgerAccount(id: '__new__:$name', name: name, kind: kind);
}

AccountKind _inferredKind(
  LedgerTransactionType type, {
  required bool isTarget,
}) {
  if ((type == LedgerTransactionType.borrowing && !isTarget) ||
      (type == LedgerTransactionType.repayment && isTarget)) {
    return AccountKind.creditLine;
  }
  return AccountKind.wallet;
}

void _validateAccountRoles(
  int number,
  LedgerTransactionType type,
  LedgerAccount account,
  LedgerAccount? target,
  String languageCode,
) {
  if (type == LedgerTransactionType.borrowing &&
      (account.group != AccountGroup.liability ||
          target?.group != AccountGroup.personalAsset)) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条借入必须从负债账户流向个人余额账户',
        'Item $number borrowing must flow from a liability to a personal asset account',
      ),
    );
  }
  if (type == LedgerTransactionType.repayment &&
      (account.group != AccountGroup.personalAsset ||
          target?.group != AccountGroup.liability)) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条还款必须从个人余额账户流向负债账户',
        'Item $number repayment must flow from a personal asset to a liability account',
      ),
    );
  }
  if (type == LedgerTransactionType.transfer &&
      (account.id == target?.id ||
          account.group != AccountGroup.personalAsset ||
          target?.group != AccountGroup.personalAsset)) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条转账必须在两个不同的个人余额账户之间',
        'Item $number transfer must be between two different personal asset accounts',
      ),
    );
  }
  if ((type == LedgerTransactionType.expense ||
          type == LedgerTransactionType.income) &&
      target != null) {
    throw LedgerImportException(
      _localized(
        languageCode,
        '第 $number 条支出或收入不能包含 target_account',
        'Item $number expense or income must not contain target_account',
      ),
    );
  }
}

String _stripFence(String input, String languageCode) {
  var text = input.trim();
  final openingFence = text.indexOf('```');
  if (openingFence >= 0) {
    final firstLine = text.indexOf('\n', openingFence);
    final closingFence = firstLine < 0 ? -1 : text.indexOf('```', firstLine);
    if (firstLine < 0 || closingFence <= firstLine) {
      throw LedgerImportException(
        _localized(languageCode, '代码块围栏不完整', 'The code fence is incomplete'),
      );
    }
    text = text.substring(firstLine + 1, closingFence).trim();
  }
  return text;
}

String ledgerImportTemplateFor(
  String languageCode, {
  List<LedgerCategory> expenseCategories = const [],
  List<LedgerCategory> incomeCategories = const [],
}) {
  final isChinese = languageCode == 'zh';
  final expenseLines = _categoryPromptLines(expenseCategories, languageCode);
  final incomeLines = _categoryPromptLines(incomeCategories, languageCode);
  final instructions = isChinese
      ? '''<!-- 给 LLM 的简单指令：
请把账单文字、截图 OCR 结果或自然语言整理成下方 schema_version: 1 的 JSON。
category 必须严格使用“一级分类/二级分类”格式；分类名称自身不能包含“/”，“/”只用于分隔两级。不要生成当前列表以外的分类。

当前支出分类（一级：二级）：
${expenseLines.isEmpty ? '- 暂无' : expenseLines.join('\n')}

当前收入分类（一级：二级）：
${incomeLines.isEmpty ? '- 暂无' : incomeLines.join('\n')}

amount 使用最多两位小数的字符串，occurred_at 使用带时区的 ISO 8601 时间。type 仅可为 expense、income、transfer、borrowing 或 repayment。只返回有效 JSON，不要附加解释。
-->'''
      : '''<!-- Simple prompt for an LLM:
Convert transaction text, OCR output, or natural language into the schema_version: 1 JSON shown below.
category must strictly use the “Primary/Secondary” format. A category name itself must not contain “/”; the slash is only the separator between the two levels. Do not invent categories outside the current lists.

Current expense categories (primary: secondary):
${expenseLines.isEmpty ? '- None' : expenseLines.join('\n')}

Current income categories (primary: secondary):
${incomeLines.isEmpty ? '- None' : incomeLines.join('\n')}

Use a string with no more than two decimal places for amount and a timezone-aware ISO 8601 timestamp for occurred_at. type must be expense, income, transfer, borrowing, or repayment. Return valid JSON only, without additional explanation.
-->''';
  final json = isChinese ? _ledgerImportTemplateZh : _ledgerImportTemplateEn;
  return '$instructions\n```json\n$json\n```';
}

List<String> _categoryPromptLines(
  List<LedgerCategory> categories,
  String languageCode,
) {
  final parents = categories.where((item) => item.isParent);
  return [
    for (final parent in parents)
      '- ${DefaultLedgerNames.categoryName(languageCode, parent.id, parent.name)}: '
          '${categories.where((item) => item.parentId == parent.id).map((child) => DefaultLedgerNames.categoryName(languageCode, child.id, child.name)).join(', ')}',
  ];
}

const _ledgerImportTemplateZh = '''{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "饮食/午餐",
      "account": "支付宝",
      "account_kind": "wallet",
      "note": "午餐"
    },
    {
      "type": "borrowing",
      "amount": "1000.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "朋友欠款",
      "account_kind": "creditLine",
      "target_account": "微信",
      "target_account_kind": "wallet",
      "note": "向朋友借款"
    }
  ]
}''';

const _ledgerImportTemplateEn = '''{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "Food/Lunch",
      "account": "Alipay",
      "account_kind": "wallet",
      "note": "Lunch"
    },
    {
      "type": "borrowing",
      "amount": "1000.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "Loan from a friend",
      "account_kind": "creditLine",
      "target_account": "WeChat Pay",
      "target_account_kind": "wallet",
      "note": "Short-term loan"
    }
  ]
}''';

String _localized(String languageCode, String zh, String en) =>
    languageCode == 'zh' ? zh : en;

String _moneyErrorEnglish(MoneyInputException error) => switch (error.error) {
  MoneyInputError.invalidFormat =>
    'enter a valid amount with up to two decimal places',
  MoneyInputError.negative => 'amount must not be negative',
  MoneyInputError.notPositive => 'amount must be greater than zero',
};

@Deprecated(
  'Use ledgerImportTemplateFor so examples follow the selected language.',
)
const ledgerImportTemplate = _ledgerImportTemplateZh;
