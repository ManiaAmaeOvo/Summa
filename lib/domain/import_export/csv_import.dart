import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/transactions/expense_record.dart';

const csvImportTemplate =
    'type,amount,occurred_at,account,category,note,currency_code,target_account,source,external_id\r\n'
    'expense,12.50,2026-01-15T12:30:00+08:00,Cash,Food/Lunch,Lunch,CNY,,example,order-1\r\n';

const maxCsvImportBytes = 2 * 1024 * 1024;
const maxCsvImportRows = 500;

enum CsvIssue {
  encoding,
  tooLarge,
  empty,
  headers,
  syntax,
  columns,
  type,
  amount,
  date,
  currency,
  source,
  advanced,
  statementSkipped,
  workbook,
}

class CsvImportException implements Exception {
  const CsvImportException(this.issue, {this.line});
  final CsvIssue issue;
  final int? line;
}

typedef CsvMovement = ({
  LedgerTransactionType type,
  int amountMinor,
  DateTime occurredAt,
  String currency,
  String account,
  String target,
  String category,
  String note,
});

class CsvImportRow {
  const CsvImportRow._({
    required this.number,
    required this.line,
    required this.raw,
    this.movement,
    this.signature,
    this.sourceKey,
    this.issue,
  });

  final int number;
  final int line;
  final Map<String, String> raw;
  final CsvMovement? movement;
  final String? signature;
  final String? sourceKey;
  final CsvIssue? issue;

  factory CsvImportRow.invalid(
    int number,
    int line,
    CsvIssue issue, {
    Map<String, String> raw = const {},
  }) => CsvImportRow._(
    number: number,
    line: line,
    raw: Map.unmodifiable(raw),
    issue: issue,
  );

  factory CsvImportRow.fromCells(
    int number,
    int line,
    Map<String, String> raw,
  ) {
    final cells = Map<String, String>.unmodifiable(raw);
    String get(String key) => cells[key]?.trim() ?? '';
    CsvImportRow invalid(CsvIssue issue) =>
        CsvImportRow._(number: number, line: line, raw: cells, issue: issue);
    if (_advanced.any((field) => get(field).isNotEmpty) ||
        (get('status').isNotEmpty &&
            !['posted', '已入账'].contains(get('status')))) {
      return invalid(CsvIssue.advanced);
    }
    final type = _types[get('type').toLowerCase()];
    if (type == null) return invalid(CsvIssue.type);
    final currency = get('currency_code').isEmpty
        ? defaultCurrency
        : get('currency_code').toUpperCase();
    if (!currencyMinorDigits.containsKey(currency)) {
      return invalid(CsvIssue.currency);
    }
    final int amount;
    try {
      amount = parseMoney(get('amount'), currency);
    } on MoneyInputException {
      return invalid(CsvIssue.amount);
    }
    final time = _parseDate(get('occurred_at'));
    if (time == null) return invalid(CsvIssue.date);
    final occurredAt = time.instant;
    final source = get('source').toLowerCase();
    final externalId = get('external_id');
    if (externalId.isNotEmpty && source.isEmpty) {
      return invalid(CsvIssue.source);
    }
    final movement = (
      type: type,
      amountMinor: amount,
      occurredAt: occurredAt,
      currency: currency,
      account: get('account'),
      target: get('target_account'),
      category: get('category'),
      note: get('note'),
    );
    return CsvImportRow._(
      number: number,
      line: line,
      raw: cells,
      movement: movement,
      sourceKey: externalId.isEmpty ? null : csvDigest([source, externalId]),
      signature: csvDigest([
        type.name,
        amount,
        time.key,
        currency,
        movement.account,
        movement.target,
        movement.category,
        movement.note,
        source,
      ]),
    );
  }
}

class CsvImportFile {
  const CsvImportFile._(this.name, this.fingerprint, this.rows);
  final String name;
  final String fingerprint;
  final List<CsvImportRow> rows;

  factory CsvImportFile.fromStatement(
    String name,
    Iterable<CsvImportRow> rows,
  ) {
    final result = List<CsvImportRow>.unmodifiable(rows);
    if (result.isEmpty) throw const CsvImportException(CsvIssue.empty);
    if (result.length > maxCsvImportRows) {
      throw const CsvImportException(CsvIssue.tooLarge);
    }
    return CsvImportFile._(
      name,
      csvDigest([
        for (final row in result) [row.issue?.name, csvRawCellsJson(row.raw)],
      ]),
      result,
    );
  }

  String rowKey(CsvImportRow row) => csvDigest([fingerprint, row.number]);
}

CsvImportFile parseCsvImport(String name, List<int> bytes) {
  if (bytes.length > maxCsvImportBytes) {
    throw const CsvImportException(CsvIssue.tooLarge);
  }
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const CsvImportException(CsvIssue.encoding);
  }
  final records = readCsvRecords(
    text.startsWith('\uFEFF') ? text.substring(1) : text,
  );
  final input = records.iterator;
  if (!input.moveNext()) throw const CsvImportException(CsvIssue.empty);
  final headers = [
    for (final field in input.current.cells)
      _headers[field.trim().toLowerCase()] ?? field.trim().toLowerCase(),
  ];
  if (headers.contains('') ||
      headers.toSet().length != headers.length ||
      !headers.toSet().containsAll([
        'type',
        'amount',
        'occurred_at',
        'account',
      ])) {
    throw const CsvImportException(CsvIssue.headers);
  }

  final rows = <CsvImportRow>[];
  final canonicalRows = <Object>[];
  while (input.moveNext()) {
    final (line: line, cells: cells) = input.current;
    if (rows.length == maxCsvImportRows) {
      throw const CsvImportException(CsvIssue.tooLarge);
    }
    final number = rows.length + 1;
    if (cells.length != headers.length) {
      rows.add(
        CsvImportRow._(
          number: number,
          line: line,
          raw: const {},
          issue: CsvIssue.columns,
        ),
      );
      canonicalRows.add(cells);
      continue;
    }
    final fields = {
      for (final (index, header) in headers.indexed) header: cells[index],
    };
    rows.add(CsvImportRow.fromCells(number, line, fields));
    canonicalRows.add({
      for (final field in fields.keys.toList()..sort()) field: fields[field],
    });
  }
  if (rows.isEmpty) throw const CsvImportException(CsvIssue.empty);
  return CsvImportFile._(
    name,
    csvDigest(canonicalRows),
    List.unmodifiable(rows),
  );
}

String csvDigest(Object content) =>
    sha256.convert(utf8.encode(jsonEncode(content))).toString();

String csvRawCellsJson(Map<String, String> raw) =>
    jsonEncode({for (final key in raw.keys.toList()..sort()) key: raw[key]});

const _types = {
  'expense': LedgerTransactionType.expense,
  '支出': LedgerTransactionType.expense,
  'income': LedgerTransactionType.income,
  '收入': LedgerTransactionType.income,
  'transfer': LedgerTransactionType.transfer,
  '转账': LedgerTransactionType.transfer,
  'borrowing': LedgerTransactionType.borrowing,
  '借入': LedgerTransactionType.borrowing,
  'repayment': LedgerTransactionType.repayment,
  '还款': LedgerTransactionType.repayment,
};

const _headers = {
  '类型': 'type',
  '金额': 'amount',
  '发生时间': 'occurred_at',
  '账户': 'account',
  '分类': 'category',
  '备注': 'note',
  '币种': 'currency_code',
  '原币': 'currency_code',
  '目标账户': 'target_account',
  '来源': 'source',
  '外部编号': 'external_id',
  '入账状态': 'status',
  '商户': 'merchant',
  '商品说明': 'description',
  '支付渠道': 'payment_channel',
  '原消费 id': 'refund_of_id',
  '付款明细': 'payments',
  '实际到账金额': 'settlement_amount',
  '到账币种': 'settlement_currency_code',
  '报价汇率': 'quoted_exchange_rate',
  '财务明细': 'financial_details',
};

const _advanced = {
  'refund_of_id',
  'payments',
  'settlement_amount',
  'settlement_amount_minor',
  'settlement_currency_code',
  'quoted_exchange_rate',
  'financial_details',
  'reversal_of_id',
};

({DateTime instant, Object key})? _parseDate(String input) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[Tt ](\d{2}):(\d{2})(?::(\d{2})(?:[.,]\d{1,6})?)?(?:[Zz]|[+-](\d{2}):?(\d{2}))?)?$',
  ).firstMatch(input);
  if (match == null) return null;
  int part(int i) => int.parse(match[i] ?? '0');
  final date = DateTime.utc(part(1), part(2), part(3));
  if (part(1) < 1 ||
      date.month != part(2) ||
      date.day != part(3) ||
      part(4) > 23 ||
      part(5) > 59 ||
      part(6) > 59 ||
      part(7) > 23 ||
      part(8) > 59) {
    return null;
  }
  final instant = DateTime.tryParse(input)?.toLocal();
  if (instant == null) return null;
  final zoned =
      input.length > 10 &&
      RegExp(r'(?:[Zz]|[+-]\d{2}:?\d{2})$').hasMatch(input.substring(10));
  // A civil date entered without an offset keeps the same import identity
  // when the file or a backup is reopened in a different time zone.
  final key = zoned
      ? instant.millisecondsSinceEpoch ~/ 1000
      : ['local', part(1), part(2), part(3), part(4), part(5), part(6)];
  return (instant: instant, key: key);
}

enum _CsvState { start, plain, quoted, closed }

Iterable<({int line, List<String> cells})> readCsvRecords(String text) sync* {
  var line = 1;
  var startLine = 1;
  var state = _CsvState.start;
  var cells = <String>[];
  final field = StringBuffer();
  void endField() {
    cells.add(field.toString());
    field.clear();
    state = _CsvState.start;
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final newline = char == '\r' || char == '\n';
    if (newline && char == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
      i++;
    }
    if (state == _CsvState.quoted) {
      if (char == '"') {
        state = _CsvState.closed;
      } else {
        field.write(newline ? '\n' : char);
        if (newline) line++;
      }
    } else if (char == ',') {
      endField();
    } else if (newline) {
      endField();
      if (cells.length != 1 || cells.single.trim().isNotEmpty) {
        yield (line: startLine, cells: cells);
      }
      cells = <String>[];
      startLine = ++line;
    } else if (state == _CsvState.closed && char == '"') {
      field.write('"');
      state = _CsvState.quoted;
    } else if (state == _CsvState.start && char == '"') {
      state = _CsvState.quoted;
    } else if (state == _CsvState.closed || char == '"') {
      throw CsvImportException(CsvIssue.syntax, line: line);
    } else {
      state = _CsvState.plain;
      field.write(char);
    }
  }
  if (state == _CsvState.quoted) {
    throw CsvImportException(CsvIssue.syntax, line: startLine);
  }
  if (cells.isNotEmpty || field.isNotEmpty || state == _CsvState.closed) {
    endField();
    if (cells.length != 1 || cells.single.trim().isNotEmpty) {
      yield (line: startLine, cells: cells);
    }
  }
}

enum CsvReviewState { ready, unresolved, similar, duplicate, conflict, invalid }

typedef CsvMapping = ({
  String? accountId,
  String? targetId,
  String? categoryId,
});

typedef CsvMatch = ({
  String id,
  DateTime occurredAt,
  String accountName,
  String? targetName,
  String note,
  bool sameSourceRow,
  bool canLink,
});

typedef CsvReviewRow = ({
  CsvImportRow row,
  CsvReviewState state,
  CsvMapping mapping,
  List<CsvMatch> matches,
  ImportCategorySuggestion? suggestion,
});

typedef CsvRuleTrialRow = ({
  CsvImportRow row,
  String? explicitCategoryId,
  ImportCategorySuggestion? suggestion,
});

class CsvSelection {
  const CsvSelection(
    this.number,
    this.mapping, {
    this.matchId,
    this.reviewedMatchIds,
  });
  final int number;
  final CsvMapping mapping;
  final String? matchId;
  final Set<String>? reviewedMatchIds;
  bool get acceptSimilar => reviewedMatchIds != null;
}

enum CsvBatchError { reviewChanged, modified, linked, unavailable }

class CsvPostingException implements Exception {
  const CsvPostingException(this.line, this.cause);
  final int line;
  final Object cause;
}

class CsvBatchException implements Exception {
  const CsvBatchException(this.error, {this.line});
  final CsvBatchError error;
  final int? line;
}

typedef CsvBatchSummary = ({
  String id,
  String name,
  DateTime createdAt,
  DateTime? undoneAt,
  int added,
  int matched,
});
typedef CsvBatchItem = ({
  int line,
  String entryId,
  bool created,
  Map<String, String> raw,
});
typedef CsvImportResult = ({String batchId, int added, int matched});

bool csvNeedsCategory(LedgerTransactionType type) =>
    type == LedgerTransactionType.expense ||
    type == LedgerTransactionType.income;
bool csvNeedsTarget(LedgerTransactionType type) => !csvNeedsCategory(type);

bool csvAccountAllowed(
  LedgerTransactionType type,
  AccountKind kind, {
  bool target = false,
}) {
  final transferAccount =
      kind.isPersonalCash ||
      kind == AccountKind.entrustedFunds ||
      kind == AccountKind.prepaid;
  return switch (type) {
    LedgerTransactionType.expense =>
      !target &&
          kind != AccountKind.familyDirect &&
          kind != AccountKind.receivable,
    LedgerTransactionType.income => !target && transferAccount,
    LedgerTransactionType.transfer => transferAccount,
    LedgerTransactionType.borrowing =>
      target ? kind.isPersonalCash : kind.isLiability,
    LedgerTransactionType.repayment =>
      target
          ? kind.isLiability
          : kind.isPersonalCash || kind == AccountKind.entrustedFunds,
    _ => false,
  };
}
