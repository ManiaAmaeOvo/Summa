import 'dart:convert';

import 'package:ledger_pro/domain/defaults/default_ledger_names.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

enum LedgerExportFormat { json, csv, markdown }

String exportLedgerRecords(
  List<LedgerRecord> records,
  LedgerExportFormat format, {
  String languageCode = 'zh',
}) => switch (format) {
  LedgerExportFormat.json => _json(records, languageCode),
  LedgerExportFormat.csv => _csv(records, languageCode),
  LedgerExportFormat.markdown => _markdown(records, languageCode),
};

String _json(List<LedgerRecord> records, String languageCode) {
  final payload = {
    'schema_version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'transactions': records
        .map((record) => _jsonRecord(record, languageCode))
        .toList(growable: false),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

Map<String, Object?> _jsonRecord(LedgerRecord record, String languageCode) => {
  'type': record.type.name,
  'amount': _amount(record.amountMinor),
  'occurred_at': record.occurredAt.toIso8601String(),
  if (record.type == LedgerTransactionType.expense ||
      record.type == LedgerTransactionType.income)
    'category': _categoryPath(record, languageCode),
  'account': _accountName(record, languageCode),
  'account_kind': record.accountKind,
  if (record.targetAccountName != null)
    'target_account': _targetAccountName(record, languageCode),
  if (record.targetAccountKind != null)
    'target_account_kind': record.targetAccountKind,
  'note': record.note,
};

String _csv(List<LedgerRecord> records, String languageCode) {
  final english = languageCode != 'zh';
  final rows = <List<String>>[
    english
        ? [
            'type',
            'amount',
            'occurred_at',
            'category',
            'account',
            'account_kind',
            'target_account',
            'target_account_kind',
            'note',
          ]
        : ['类型', '金额', '发生时间', '分类', '账户', '账户类型', '目标账户', '目标账户类型', '备注'],
    for (final record in records)
      [
        _typeName(record.type, languageCode),
        _amount(record.amountMinor),
        record.occurredAt.toIso8601String(),
        record.type == LedgerTransactionType.expense ||
                record.type == LedgerTransactionType.income
            ? _categoryPath(record, languageCode)
            : '',
        _accountName(record, languageCode),
        record.accountKind,
        _targetAccountName(record, languageCode) ?? '',
        record.targetAccountKind ?? '',
        record.note,
      ],
  ];
  return '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}';
}

String _markdown(List<LedgerRecord> records, String languageCode) {
  final english = languageCode != 'zh';
  final buffer = StringBuffer()
    ..writeln(english ? '# Summa Transaction Export' : '# Summa 账单导出')
    ..writeln()
    ..writeln(
      english
          ? '| Type | Amount | Time | Category | Account flow | Note |'
          : '| 类型 | 金额 | 时间 | 分类 | 账户流向 | 备注 |',
    )
    ..writeln('|---|---:|---|---|---|---|');
  for (final record in records) {
    final category =
        record.type == LedgerTransactionType.expense ||
            record.type == LedgerTransactionType.income
        ? _categoryPath(record, languageCode)
        : '';
    final flow = record.targetAccountName == null
        ? _accountName(record, languageCode)
        : '${_accountName(record, languageCode)} → '
              '${_targetAccountName(record, languageCode)}';
    buffer.writeln(
      '| ${_typeName(record.type, languageCode)} | ¥${_amount(record.amountMinor)} | '
      '${record.occurredAt.toIso8601String()} | ${_md(category)} | '
      '${_md(flow)} | ${_md(record.note)} |',
    );
  }
  return buffer.toString();
}

String _amount(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

String _csvCell(String value) =>
    '"${value.replaceAll('"', '""').replaceAll('\r', ' ').replaceAll('\n', ' ')}"';

String _md(String value) => value.replaceAll('|', r'\|').replaceAll('\n', ' ');

String _categoryPath(LedgerRecord record, String languageCode) {
  return '${DefaultLedgerNames.categoryName(languageCode, record.parentCategoryId, record.parentCategoryName)}/'
      '${DefaultLedgerNames.categoryName(languageCode, record.categoryId, record.categoryName)}';
}

String _accountName(LedgerRecord record, String languageCode) =>
    DefaultLedgerNames.accountName(
      languageCode,
      record.accountId,
      record.accountName,
    );

String? _targetAccountName(LedgerRecord record, String languageCode) =>
    record.targetAccountId == null
    ? null
    : DefaultLedgerNames.accountName(
        languageCode,
        record.targetAccountId!,
        record.targetAccountName!,
      );

String _typeName(LedgerTransactionType type, String languageCode) {
  if (languageCode != 'zh') return type.name;
  return switch (type) {
    LedgerTransactionType.expense => '支出',
    LedgerTransactionType.income => '收入',
    LedgerTransactionType.transfer => '转账',
    LedgerTransactionType.borrowing => '借入',
    LedgerTransactionType.repayment => '还款',
  };
}
