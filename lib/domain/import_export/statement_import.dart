import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:chinese_codec/chinese_codec.dart' show gb18030;
import 'package:xml/xml.dart';

import 'csv_import.dart';

typedef _StatementRow = ({int line, List<String> cells, Set<int> numeric});

enum _Vendor { wechat, alipay }

CsvImportFile parseStatementImport(String name, List<int> bytes) {
  if (bytes.length > maxCsvImportBytes) {
    throw const CsvImportException(CsvIssue.tooLarge);
  }
  if (name.toLowerCase().endsWith('.xlsx')) return _readWorkbook(name, bytes);
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    try {
      final decoded = gb18030.decode(bytes);
      final result = _parseVendor(name, _csvRows(decoded));
      if (result != null) return result;
    } on FormatException {
      // The caller gets one encoding error when neither decoder can read it.
    }
    throw const CsvImportException(CsvIssue.encoding);
  }
  return _parseVendor(name, _csvRows(text)) ?? parseCsvImport(name, bytes);
}

Iterable<_StatementRow> _csvRows(String text) sync* {
  for (final row in readCsvRecords(
    text.startsWith('\uFEFF') ? text.substring(1) : text,
  )) {
    yield (line: row.line, cells: row.cells, numeric: const <int>{});
  }
}

CsvImportFile? _parseVendor(
  String name,
  Iterable<_StatementRow> rows, {
  bool date1904 = false,
}) {
  final input = rows.iterator;
  while (input.moveNext()) {
    final header = input.current.cells.map(_clean).toList();
    if (!header.contains('交易时间') || !header.any({'收/支', '收支'}.contains)) {
      continue;
    }
    final vendor = header.contains('交易单号') && header.contains('交易类型')
        ? _Vendor.wechat
        : header.contains('交易订单号') && header.contains('交易分类')
        ? _Vendor.alipay
        : null;
    if (vendor == null) continue;
    final columns = _VendorColumns(header, vendor);
    return CsvImportFile.fromStatement(
      name,
      _vendorRows(input, columns, date1904),
    );
  }
  return null;
}

class _VendorColumns {
  _VendorColumns(this.headers, this.vendor) {
    time = headers.indexOf('交易时间');
    direction = _index(['收/支', '收支']);
    amount = _index(['金额(元)', '金额（元）', '金额']);
    status = _index(vendor == _Vendor.wechat ? ['当前状态', '交易状态'] : ['交易状态']);
    kind = headers.indexOf(vendor == _Vendor.wechat ? '交易类型' : '交易分类');
    order = headers.indexOf(vendor == _Vendor.wechat ? '交易单号' : '交易订单号');
    counterparty = headers.indexOf('交易对方');
    item = _index(['商品', '商品说明', '商品名称']);
    payment = _index(['支付方式', '收/付款方式', '收付款方式', '付款方式']);
    remark = headers.indexOf('备注');
    final required = [time, direction, amount, status, kind, order];
    final fields = headers.where((field) => field.isNotEmpty).toList();
    if (required.contains(-1) || fields.toSet().length != fields.length) {
      throw const CsvImportException(CsvIssue.headers);
    }
  }

  final List<String> headers;
  final _Vendor vendor;
  late final int time,
      direction,
      amount,
      status,
      kind,
      order,
      counterparty,
      item,
      payment,
      remark;

  int _index(List<String> names) {
    for (final name in names) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }
}

Iterable<CsvImportRow> _vendorRows(
  Iterator<_StatementRow> source,
  _VendorColumns column,
  bool date1904,
) sync* {
  var number = 0;
  final width = column.headers.lastIndexWhere((field) => field.isNotEmpty) + 1;
  final lastRequired = [
    column.time,
    column.direction,
    column.amount,
    column.kind,
    column.status,
  ].reduce((left, right) => left > right ? left : right);
  while (source.moveNext()) {
    final row = source.current;
    final values = row.cells;
    if (values.every((value) => value.trim().isEmpty)) continue;
    final first = _clean(values.first);
    if (first.startsWith('---') ||
        first.startsWith('合计') ||
        first.startsWith('共计') ||
        first == '交易时间') {
      continue;
    }
    if (++number > maxCsvImportRows) {
      throw const CsvImportException(CsvIssue.tooLarge);
    }

    String at(int index) =>
        index < 0 || index >= values.length ? '' : _clean(values[index]);
    final raw = {
      for (var index = 0; index < width; index++)
        if (column.headers[index].isNotEmpty)
          column.headers[index]: index < values.length ? values[index] : '',
    };
    if (values.length > column.headers.length ||
        values.skip(width).any((value) => value.trim().isNotEmpty) ||
        values.length <= lastRequired) {
      yield CsvImportRow.invalid(number, row.line, CsvIssue.columns, raw: raw);
      continue;
    }
    final flow = at(column.direction);
    final status = at(column.status);
    final kind = at(column.kind);
    if (!_ordinaryMovement(column.vendor, flow, status, kind)) {
      yield CsvImportRow.invalid(
        number,
        row.line,
        CsvIssue.statementSkipped,
        raw: raw,
      );
      continue;
    }
    final merchant = at(column.counterparty);
    final description = at(column.item);
    final channel = at(column.payment);
    final note = [
      merchant,
      description,
      at(column.remark),
    ].where((value) => value.isNotEmpty && value != '/').toSet().join(' · ');
    final time = row.numeric.contains(column.time)
        ? _serialDate(at(column.time), date1904)
        : at(column.time);
    final amount = at(column.amount).replaceFirst(RegExp(r'^[¥￥]\s*'), '');
    final normalizedAmount =
        RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(amount)
        ? amount.replaceAll(',', '')
        : amount;
    final order = at(column.order);
    yield CsvImportRow.fromCells(number, row.line, {
      ...raw,
      'type': flow == '支出' ? 'expense' : 'income',
      'amount': normalizedAmount,
      'occurred_at': time,
      'account': _walletName(column.vendor, channel),
      'currency_code': 'CNY',
      if (column.vendor == _Vendor.alipay) 'category': kind,
      'source': column.vendor == _Vendor.wechat ? 'wechat-pay' : 'alipay',
      // Excel numeric cells can truncate long reference numbers.
      if (order.isNotEmpty &&
          order != '/' &&
          !row.numeric.contains(column.order))
        'external_id': order,
      'merchant': merchant,
      'description': description,
      'payment_channel': channel,
      'note': note,
    });
  }
}

bool _ordinaryMovement(
  _Vendor vendor,
  String flow,
  String status,
  String kind,
) {
  if (flow != '收入' && flow != '支出') return false;
  if (vendor == _Vendor.wechat) {
    return switch ((flow, kind, status)) {
      ('支出', '商户消费', '支付成功') => true,
      ('收入', '商户收款', '已存入零钱' || '支付成功') => true,
      _ => false,
    };
  }
  if (kind.isEmpty || !{'交易成功', '支付成功', '已到账', '已收款'}.contains(status)) {
    return false;
  }
  return ![
    '退款',
    '转账',
    '红包',
    '信用借还',
    '借款',
    '还款',
    '理财',
    '充值',
    '提现',
    '互转',
  ].any(kind.contains);
}

String _walletName(_Vendor vendor, String channel) =>
    switch ((vendor, channel)) {
      (_Vendor.wechat, '零钱' || '微信零钱') => 'account-wechat',
      (_Vendor.alipay, '余额' || '支付宝余额') => 'account-alipay',
      _ => channel == '/' ? '' : channel,
    };

String _clean(String value) => value.replaceAll('\uFEFF', '').trim();

String _serialDate(String value, bool date1904) {
  final serial = double.tryParse(value);
  if (serial == null ||
      !serial.isFinite ||
      serial < (date1904 ? 0 : 61) ||
      serial > 2957000) {
    return '';
  }
  final start = date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
  // Leave Excel dates in civil time, just like the platform's CSV timestamp.
  return start
      .add(Duration(seconds: (serial * 86400).round()))
      .toIso8601String()
      .split('.')
      .first;
}

CsvImportFile _readWorkbook(String name, List<int> bytes) {
  try {
    final directory = ZipDirectory()
      ..read(InputMemoryStream(bytes), verify: true);
    const maximumExpanded = 12 * 1024 * 1024;
    if (directory.fileHeaders.length > 150) {
      throw const CsvImportException(CsvIssue.tooLarge);
    }
    var expandedSize = 0;
    for (final header in directory.fileHeaders) {
      final size = header.file?.uncompressedSize;
      if (size == null ||
          size < 0 ||
          ((header.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
        throw const CsvImportException(CsvIssue.workbook);
      }
      expandedSize += size;
      if (expandedSize > maximumExpanded) {
        throw const CsvImportException(CsvIssue.tooLarge);
      }
    }
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    XmlDocument? readXml(String path) {
      final file = archive.findFile(path);
      if (file == null) return null;
      final xml = utf8.decode(file.content);
      if (xml.contains('<!DOCTYPE') || xml.contains('<!ENTITY')) {
        throw const CsvImportException(CsvIssue.workbook);
      }
      return XmlDocument.parse(xml);
    }

    final workbook = readXml('xl/workbook.xml');
    if (workbook == null) throw const CsvImportException(CsvIssue.workbook);
    final epoch = workbook
        .findAllElements('workbookPr', namespaceUri: '*')
        .firstOrNull
        ?.getAttribute('date1904');
    final strings = [
      for (final item
          in readXml('xl/sharedStrings.xml')
                  ?.findAllElements('si', namespaceUri: '*') ??
              const <XmlElement>[])
        item
            .findAllElements('t', namespaceUri: '*')
            .map((child) => child.innerText)
            .join(),
    ];
    CsvImportFile? result;
    for (final file in archive.files.where(
      (file) => RegExp(r'^xl/worksheets/[^/]+\.xml$').hasMatch(file.name),
    )) {
      final sheet = readXml(file.name)!;
      final adapted = _parseVendor(
        name,
        _sheetRows(sheet, strings),
        date1904: epoch == '1' || epoch == 'true',
      );
      if (adapted == null) continue;
      if (result != null) throw const CsvImportException(CsvIssue.workbook);
      result = adapted;
    }
    return result ?? (throw const CsvImportException(CsvIssue.headers));
  } on CsvImportException {
    rethrow;
  } catch (_) {
    throw const CsvImportException(CsvIssue.workbook);
  }
}

Iterable<_StatementRow> _sheetRows(
  XmlDocument sheet,
  List<String> strings,
) sync* {
  var line = 0;
  final sheetData = sheet.rootElement
      .findElements('sheetData', namespaceUri: '*')
      .firstOrNull;
  if (sheetData == null) return;
  for (final row in sheetData.findElements('row', namespaceUri: '*')) {
    line = int.tryParse(row.getAttribute('r') ?? '') ?? line + 1;
    final cells = <String>[];
    final numeric = <int>{};
    var index = 0;
    for (final cell in row.findElements('c', namespaceUri: '*')) {
      final reference = cell.getAttribute('r');
      if (reference != null) {
        final prefix = RegExp(r'^[A-Z]+').stringMatch(reference) ?? '';
        if (prefix.isEmpty || prefix.length > 2) continue;
        index =
            prefix.codeUnits.fold(
              0,
              (number, letter) => number * 26 + letter - 64,
            ) -
            1;
      }
      while (cells.length <= index) {
        cells.add('');
      }
      final kind = cell.getAttribute('t');
      final value =
          cell.findElements('v', namespaceUri: '*').firstOrNull?.innerText ??
          '';
      if (kind == 'n' || kind == null) numeric.add(index);
      if (cell.findElements('f', namespaceUri: '*').isEmpty) {
        cells[index] = switch (kind) {
          's' => strings[int.parse(value)],
          'inlineStr' =>
            cell
                .findAllElements('t', namespaceUri: '*')
                .map((text) => text.innerText)
                .join(),
          'e' || 'b' => '',
          _ => value,
        };
      }
      index++;
    }
    while (cells.isNotEmpty && cells.last.isEmpty) {
      cells.removeLast();
    }
    if (cells.isNotEmpty) yield (line: line, cells: cells, numeric: numeric);
  }
}
