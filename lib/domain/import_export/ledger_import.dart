import 'dart:convert';

import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

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
}) {
  final text = _stripFence(source);
  dynamic root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (error) {
    throw LedgerImportException('JSON 格式错误：${error.message}');
  }
  late List<dynamic> rows;
  if (root is List) {
    rows = root;
  } else if (root is Map<String, dynamic> && root['transactions'] is List) {
    if (root['schema_version'] != 1) {
      throw const LedgerImportException('仅支持 schema_version: 1');
    }
    rows = root['transactions'] as List<dynamic>;
  } else if (root is Map<String, dynamic> && root.containsKey('type')) {
    rows = [root];
  } else {
    throw const LedgerImportException('代码块必须是账单对象、数组或 transactions 包装对象');
  }
  if (rows.isEmpty) throw const LedgerImportException('没有可导入的账单');
  if (rows.length > 500) throw const LedgerImportException('单次最多导入 500 条账单');

  final availableAccounts = [...accounts];
  return [
    for (var index = 0; index < rows.length; index++)
      _parseRow(
        rows[index],
        index,
        availableAccounts,
        expenseCategories,
        incomeCategories,
      ),
  ];
}

LedgerImportDraft _parseRow(
  dynamic value,
  int index,
  List<LedgerAccount> accounts,
  List<LedgerCategory> expenseCategories,
  List<LedgerCategory> incomeCategories,
) {
  final number = index + 1;
  if (value is! Map<String, dynamic>) {
    throw LedgerImportException('第 $number 条不是 JSON 对象');
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
      '第 $number 条缺少字符串字段 type、amount、occurred_at 或 account',
    );
  }
  final type = LedgerTransactionType.values
      .where((item) => item.name == rawType)
      .firstOrNull;
  if (type == null) {
    throw LedgerImportException(
      '第 $number 条 type 必须是 expense、income、transfer、borrowing 或 repayment',
    );
  }
  int amountMinor;
  try {
    amountMinor = parseCnyMinorUnits(rawAmount);
  } on MoneyInputException catch (error) {
    throw LedgerImportException('第 $number 条金额错误：${error.message}');
  }
  final occurredAt = DateTime.tryParse(rawTime);
  if (occurredAt == null) {
    throw LedgerImportException('第 $number 条 occurred_at 不是 ISO 8601 时间');
  }
  var account = accounts.where((item) => item.name == rawAccount).firstOrNull;
  final accountIsNew = account == null;
  account ??= _newAccount(
    rawAccount,
    value['account_kind'],
    _inferredKind(type, isTarget: false),
    number,
  );
  if (accountIsNew) accounts.add(account);

  LedgerAccount? target;
  final rawTarget = value['target_account'];
  if (rawTarget != null) {
    if (rawTarget is! String) {
      throw LedgerImportException('第 $number 条 target_account 必须是字符串');
    }
    target = accounts.where((item) => item.name == rawTarget).firstOrNull;
    final isNew = target == null;
    target ??= _newAccount(
      rawTarget,
      value['target_account_kind'],
      _inferredKind(type, isTarget: true),
      number,
    );
    if (isNew) accounts.add(target);
  }

  String? categoryId;
  String? categoryPath;
  if (type == LedgerTransactionType.expense ||
      type == LedgerTransactionType.income) {
    final rawCategory = value['category'];
    if (rawCategory is! String) {
      throw LedgerImportException('第 $number 条缺少 category');
    }
    final categories = type == LedgerTransactionType.expense
        ? expenseCategories
        : incomeCategories;
    final parts = rawCategory.split('/');
    if (parts.length != 2) {
      throw LedgerImportException('第 $number 条 category 应为“主分类/子分类”');
    }
    final parent = categories
        .where((item) => item.isParent && item.name == parts.first)
        .firstOrNull;
    final child = parent == null
        ? null
        : categories
              .where(
                (item) => item.parentId == parent.id && item.name == parts.last,
              )
              .firstOrNull;
    if (child == null) {
      throw LedgerImportException('第 $number 条找不到分类“$rawCategory”');
    }
    categoryId = child.id;
    categoryPath = rawCategory;
  }
  _validateAccountRoles(number, type, account, target);
  final note = value['note'] ?? '';
  if (note is! String || note.length > 200) {
    throw LedgerImportException('第 $number 条 note 必须是最多 200 字的字符串');
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
) {
  var kind = inferred;
  if (rawKind != null) {
    if (rawKind is! String) {
      throw LedgerImportException('第 $number 条账户类型必须是字符串');
    }
    final parsed = AccountKind.values
        .where((item) => item.name == rawKind)
        .firstOrNull;
    if (parsed == null) {
      throw LedgerImportException(
        '第 $number 条账户类型必须是 cash、bank、wallet、creditLine 或 entrustedFunds',
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
) {
  if (type == LedgerTransactionType.borrowing &&
      (account.group != AccountGroup.liability ||
          target?.group != AccountGroup.personalAsset)) {
    throw LedgerImportException('第 $number 条借入必须从负债账户流向个人余额账户');
  }
  if (type == LedgerTransactionType.repayment &&
      (account.group != AccountGroup.personalAsset ||
          target?.group != AccountGroup.liability)) {
    throw LedgerImportException('第 $number 条还款必须从个人余额账户流向负债账户');
  }
  if (type == LedgerTransactionType.transfer &&
      (account.id == target?.id ||
          account.group != AccountGroup.personalAsset ||
          target?.group != AccountGroup.personalAsset)) {
    throw LedgerImportException('第 $number 条转账必须在两个不同的个人余额账户之间');
  }
  if ((type == LedgerTransactionType.expense ||
          type == LedgerTransactionType.income) &&
      target != null) {
    throw LedgerImportException('第 $number 条支出或收入不能包含 target_account');
  }
}

String _stripFence(String input) {
  var text = input.trim();
  if (text.startsWith('```')) {
    final firstLine = text.indexOf('\n');
    final lastFence = text.lastIndexOf('```');
    if (firstLine < 0 || lastFence <= firstLine) {
      throw const LedgerImportException('代码块围栏不完整');
    }
    text = text.substring(firstLine + 1, lastFence).trim();
  }
  return text;
}

const ledgerImportTemplate = '''{
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
