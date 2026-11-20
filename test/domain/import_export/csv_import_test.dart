import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:summa/domain/import_export/csv_import.dart';

void main() {
  CsvImportFile parse(String text) =>
      parseCsvImport('test.csv', utf8.encode(text));

  test('handles UTF-8 BOM, CRLF, escaped quotes, multiline fields and Chinese headers', () {
    final file = parse(
      '\uFEFF类型,金额,发生时间,账户,分类,备注,币种,来源,外部编号\r\n'
      '支出,12.50,2026-01-20T12:00:00+08:00,现金,饮食/午餐,"甲,乙""备注\r\n第二行",cny,店铺,001\r\n'
      '\r\n'
      '收入,3,2026-01-21,现金,,,CNY,,\r\n',
    );
    expect(file.rows.map((row) => (row.number, row.line)), [(1, 2), (2, 5)]);
    final row = file.rows.first;
    expect(row.movement?.note, '甲,乙"备注\n第二行');
    expect(row.movement?.amountMinor, 1250);
    expect(row.movement?.occurredAt.toUtc(), DateTime.utc(2026, 1, 20, 4));
    expect(row.raw['external_id'], '001');
  });

  test('normalizes identity across header ordering and line endings', () {
    final a = parse(
      'type,amount,occurred_at,account\r\nexpense,1,2026-01-20,Cash\r\n',
    );
    final b = parse(
      'account,amount,type,occurred_at\nCash,1,expense,2026-01-20\n',
    );
    expect(a.fingerprint, b.fingerprint);
    expect(a.rowKey(a.rows.single), b.rowKey(b.rows.single));
  });

  test('isolates invalid rows and rejects broken structure', () {
    final file = parse(
      'type,amount,occurred_at,account,currency_code,external_id,status\n'
      'expense,12,2026-02-30,Cash,CNY,,\n'
      'expense,1.5,2026-01-20,Cash,JPY,,\n'
      'expense,1,2026-01-20,Cash,CNY,abc,\n'
      'expense,1,2026-01-20,Cash,CNY,,pending\n'
      'expense,1,2026-01-20\n'
      'expense,1,2026-01-20,Cash,CNY,,\n',
    );
    expect(file.rows.map((row) => row.issue), [
      CsvIssue.date,
      CsvIssue.amount,
      CsvIssue.source,
      CsvIssue.advanced,
      CsvIssue.columns,
      null,
    ]);
    expect(
      () => parse(
        'type,amount,occurred_at,account\nexpense,1,2026-01-20,"Cash\n',
      ),
      throwsA(
        isA<CsvImportException>().having((error) => error.line, 'line', 2),
      ),
    );
    expect(
      () => parse(
        'type,amount,amount,occurred_at,account\nexpense,1,2,2026-01-20,Cash',
      ),
      throwsA(
        isA<CsvImportException>().having(
          (error) => error.issue,
          'issue',
          CsvIssue.headers,
        ),
      ),
    );
    expect(
      () => parseCsvImport('invalid.csv', [0xff]),
      throwsA(
        isA<CsvImportException>().having(
          (error) => error.issue,
          'issue',
          CsvIssue.encoding,
        ),
      ),
    );
  });
}
