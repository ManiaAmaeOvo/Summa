import 'dart:convert';

import 'package:summa/core/money/money.dart';
import 'package:summa/domain/defaults/default_ledger_names.dart';
import 'package:summa/domain/transactions/expense_record.dart';

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
  final detailed = records.any(_requiresDetails);
  final payload = {
    'schema_version': detailed ? 2 : 1,
    'exported_at': DateTime.now().toIso8601String(),
    'transactions': records
        .map((record) => _jsonRecord(record, languageCode, detailed: detailed))
        .toList(growable: false),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

bool _requiresDetails(LedgerRecord record) =>
    record.currencyCode != defaultCurrency ||
    record.settlement != null ||
    record.isPending ||
    record.type.isReceivableFlow ||
    record.accountPostings.any(
      (posting) => posting.kind?.isAdvancedFunding == true,
    ) ||
    record.isRefund ||
    (record.type == LedgerTransactionType.expense &&
        record.accountPostings.length > 1);

Map<String, Object?> _jsonRecord(
  LedgerRecord record,
  String languageCode, {
  required bool detailed,
}) => {
  'type': record.isRefund ? 'refund' : record.type.name,
  if (detailed) 'id': record.id,
  if (detailed) 'status': record.status.name,
  if (detailed) 'currency_code': record.currencyCode,
  if (record.settlement case final settlement?) ...{
    'settlement_amount': moneyInputText(
      settlement.amountMinor,
      settlement.currencyCode,
    ),
    'settlement_currency_code': settlement.currencyCode,
    if (settlement.quotedRate != null)
      'quoted_exchange_rate': settlement.quotedRate,
  },
  if (record.isRefund) 'refund_of_id': record.refundOfId,
  if (record.type == LedgerTransactionType.expense &&
      !record.isRefund &&
      record.accountPostings.length > 1)
    'payments': [
      for (final leg in record.accountPostings)
        {
          'account': _postingAccountName(leg, languageCode),
          'account_kind': leg.accountKind,
          'amount': moneyInputText(-leg.debitMinor, leg.currencyCode),
        },
    ],
  'amount': moneyInputText(record.amountMinor, record.currencyCode),
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
  final detailed = records.any(_requiresDetails);
  final rows = <List<String>>[
    [
      if (english) ...[
        'type',
        'amount',
        'occurred_at',
        'category',
        'account',
        'account_kind',
        'target_account',
        'target_account_kind',
        'note',
      ] else ...[
        '类型',
        '金额',
        '发生时间',
        '分类',
        '账户',
        '账户类型',
        '目标账户',
        '目标账户类型',
        '备注',
      ],
      if (detailed)
        ...english
            ? [
                'status',
                'transaction_id',
                'refund_of_id',
                'payments',
                'currency_code',
                'settlement_amount',
                'settlement_currency_code',
                'quoted_exchange_rate',
              ]
            : [
                '入账状态',
                '交易 ID',
                '原消费 ID',
                '付款明细',
                '原币',
                '实际到账金额',
                '到账币种',
                '报价汇率',
              ],
    ],
    for (final record in records)
      [
        _typeName(record, languageCode),
        moneyInputText(record.amountMinor, record.currencyCode),
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
        if (detailed) ...[
          _statusName(record, languageCode),
          record.id,
          record.refundOfId ?? '',
          _paymentSummary(record, languageCode) ?? '',
          record.currencyCode,
          if (record.settlement case final settlement?) ...[
            moneyInputText(settlement.amountMinor, settlement.currencyCode),
            settlement.currencyCode,
            settlement.quotedRate ?? '',
          ] else ...[
            '',
            '',
            '',
          ],
        ],
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
    final split = _paymentSummary(record, languageCode);
    final flow = record.targetAccountName == null
        ? split ?? _accountName(record, languageCode)
        : '${_accountName(record, languageCode)} → '
              '${_targetAccountName(record, languageCode)}';
    final type = [
      _typeName(record, languageCode),
      if (record.isPending) _statusName(record, languageCode),
    ].join(' · ');
    final settlement = record.settlement;
    final amount = formatMoney(record.amountMinor, record.currencyCode);
    final note = [
      record.note,
      if (record.isRefund)
        '${english ? 'Original purchase' : '原消费'} ${record.refundOfId}',
      if (settlement?.quotedRate case final quote?)
        "${english ? 'Quoted rate' : '报价汇率'} 1 ${record.currencyCode} = $quote ${settlement!.currencyCode}",
    ].where((part) => part.isNotEmpty).join(' · ');
    buffer.writeln(
      '| $type | $amount'
      '${settlement == null ? '' : ' → ${formatMoney(settlement.amountMinor, settlement.currencyCode)}'} | '
      '${record.occurredAt.toIso8601String()} | ${_md(category)} | '
      '${_md(flow)} | ${_md(note)} |',
    );
  }
  return buffer.toString();
}

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

String _typeName(LedgerRecord record, String languageCode) {
  if (record.isRefund) return languageCode == 'zh' ? '退款' : 'refund';
  if (languageCode != 'zh') return record.type.name;
  return switch (record.type) {
    LedgerTransactionType.expense => '支出',
    LedgerTransactionType.income => '收入',
    LedgerTransactionType.transfer => '转账',
    LedgerTransactionType.borrowing => '借入',
    LedgerTransactionType.repayment => '还款',
    LedgerTransactionType.lending => '借出',
    LedgerTransactionType.advance => '垫付',
    LedgerTransactionType.collection => '收回本金',
    LedgerTransactionType.reimbursement => '报销到账',
  };
}

String _statusName(LedgerRecord record, String languageCode) =>
    languageCode == 'zh'
    ? (record.isPending ? '待入账' : '已入账')
    : record.status.name;

String? _paymentSummary(LedgerRecord record, String languageCode) =>
    record.type == LedgerTransactionType.expense &&
        record.accountPostings.length > 1
    ? record.accountPostings
          .map(
            (leg) =>
                '${_postingAccountName(leg, languageCode)} ${formatMoney(-leg.debitMinor, leg.currencyCode)}',
          )
          .join(' + ')
    : null;

String _postingAccountName(AccountPosting posting, String languageCode) =>
    DefaultLedgerNames.accountName(
      languageCode,
      posting.accountId,
      posting.accountName,
    );
