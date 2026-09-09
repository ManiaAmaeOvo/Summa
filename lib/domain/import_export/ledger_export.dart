import 'dart:convert';

import 'package:ledger_pro/domain/transactions/expense_record.dart';

enum LedgerExportFormat { json, csv, markdown }

String exportLedgerRecords(
  List<LedgerRecord> records,
  LedgerExportFormat format,
) => switch (format) {
  LedgerExportFormat.json => _json(records),
  LedgerExportFormat.csv => _csv(records),
  LedgerExportFormat.markdown => _markdown(records),
};

String _json(List<LedgerRecord> records) {
  final payload = {
    'schema_version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'transactions': records.map(_jsonRecord).toList(growable: false),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

Map<String, Object?> _jsonRecord(LedgerRecord record) => {
  'type': record.type.name,
  'amount': _amount(record.amountMinor),
  'occurred_at': record.occurredAt.toIso8601String(),
  if (record.type == LedgerTransactionType.expense ||
      record.type == LedgerTransactionType.income)
    'category': '${record.parentCategoryName}/${record.categoryName}',
  'account': record.accountName,
  'account_kind': record.accountKind,
  if (record.targetAccountName != null)
    'target_account': record.targetAccountName,
  if (record.targetAccountKind != null)
    'target_account_kind': record.targetAccountKind,
  'note': record.note,
};

String _csv(List<LedgerRecord> records) {
  final rows = <List<String>>[
    [
      'type',
      'amount',
      'occurred_at',
      'category',
      'account',
      'account_kind',
      'target_account',
      'target_account_kind',
      'note',
    ],
    for (final record in records)
      [
        record.type.name,
        _amount(record.amountMinor),
        record.occurredAt.toIso8601String(),
        record.type == LedgerTransactionType.expense ||
                record.type == LedgerTransactionType.income
            ? '${record.parentCategoryName}/${record.categoryName}'
            : '',
        record.accountName,
        record.accountKind,
        record.targetAccountName ?? '',
        record.targetAccountKind ?? '',
        record.note,
      ],
  ];
  return '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}';
}

String _markdown(List<LedgerRecord> records) {
  final buffer = StringBuffer()
    ..writeln('# Summa 账单导出')
    ..writeln()
    ..writeln('| 类型 | 金额 | 时间 | 分类 | 账户流向 | 备注 |')
    ..writeln('|---|---:|---|---|---|---|');
  for (final record in records) {
    final category =
        record.type == LedgerTransactionType.expense ||
            record.type == LedgerTransactionType.income
        ? '${record.parentCategoryName}/${record.categoryName}'
        : '';
    final flow = record.targetAccountName == null
        ? record.accountName
        : '${record.accountName} → ${record.targetAccountName}';
    buffer.writeln(
      '| ${record.type.name} | ¥${_amount(record.amountMinor)} | '
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
