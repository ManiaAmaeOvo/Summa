import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:chinese_codec/chinese_codec.dart' show gb18030;
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/statement_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:xml/xml.dart';

const wechatHeader = '交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注';
const alipayHeader =
    '交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注';
const date = '2026-05-20 12:00:00';
const wechatPayment = '$date,商户消费,样例咖啡,午餐,支出,¥18.50,零钱,支付成功,wx-test-1,,';
const alipayPayment = '$date,餐饮美食,样例咖啡,,午餐,支出,18.50,余额,交易成功,ali-test-1,,';

List<int> workbook(List<List<Object>> rows, {bool with1904Epoch = false}) {
  // Keep the test workbook independent of the import implementation.
  final sheetData = XmlBuilder();
  sheetData.element(
    'worksheet',
    nest: () {
      sheetData.element(
        'sheetData',
        nest: () {
          for (final (index, row) in rows.indexed) {
            sheetData.element(
              'row',
              attributes: {'r': (index + 1).toString()},
              nest: () {
                for (final (column, value) in row.indexed) {
                  final ref = '${String.fromCharCode(65 + column)}${index + 1}';
                  sheetData.element(
                    'c',
                    attributes: {
                      'r': ref,
                      if (value is String) 't': 'inlineStr',
                    },
                    nest: () {
                      if (value is String) {
                        sheetData.element(
                          'is',
                          nest: () => sheetData.element('t', nest: value),
                        );
                      } else {
                        sheetData.element('v', nest: value.toString());
                      }
                    },
                  );
                }
              },
            );
          }
        },
      );
    },
  );
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'xl/workbook.xml',
        '<workbook><workbookPr date1904="${with1904Epoch ? 1 : 0}"/></workbook>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet1.xml',
        sheetData.buildDocument().toXmlString(),
      ),
    );
  return ZipEncoder().encode(archive);
}

void main() {
  test(
    'WeChat CSV skips ambiguous money movements and reports malformed rows',
    () {
      final file = parseStatementImport(
        'wechat.csv',
        utf8.encode(
          '\uFEFF微信支付账单明细\r\n说明区\r\n$wechatHeader\r\n'
          '$wechatPayment\r\n'
          '$date,商户消费,退货,待退款,支出,￥1.00,零钱,已退款,wx-refund,,\r\n'
          '$date,转账,样例甲,转账,收入,10,零钱,已存入零钱,wx-transfer,,\r\n'
          '$date,商户消费,错列,商品,中有逗号,支出,￥18.50,零钱,支付成功,wx-test-2,,\r\n'
          '----------------------\r\n',
        ),
      );
      expect(file.rows.map((row) => row.line), [4, 5, 6, 7]);
      expect(file.rows.map((row) => row.issue), [
        null,
        CsvIssue.statementSkipped,
        CsvIssue.statementSkipped,
        CsvIssue.columns,
      ]);
      final row = file.rows.first;
      expect(row.movement?.amountMinor, 1850);
      expect(row.movement?.account, 'account-wechat');
      expect(row.raw['merchant'], '样例咖啡');
      expect(row.raw['交易单号'], 'wx-test-1');
    },
  );

  test(
    'GB18030 Alipay CSV handles completed income and preserves bank channel',
    () {
      final file = parseStatementImport(
        'alipay.csv',
        gb18030.encode(
          '支付宝交易明细\n$alipayHeader\n$alipayPayment\n'
          '$date,工资收入,样例公司,,工资𰻞,收入,"1,500.00",样例银行卡(1234),已到账,ali-test-2,,\n'
          '$date,信用借还,样例公司,,还款,支出,35,余额,交易成功,ali-transfer,,\n',
        ),
      );
      expect(file.rows.map((row) => row.issue), [
        null,
        null,
        CsvIssue.statementSkipped,
      ]);
      expect(file.rows[0].movement?.account, 'account-alipay');
      final income = file.rows[1];
      expect(income.movement?.type, LedgerTransactionType.income);
      expect(income.movement?.amountMinor, 150000);
      expect(income.movement?.account, '样例银行卡(1234)');
      expect(income.raw['description'], '工资𰻞');
    },
  );

  test('CSV and XLSX produce equal source identity and monetary amounts for each vendor', () {
    for (final (header, payment) in [
      (wechatHeader, wechatPayment),
      (alipayHeader, alipayPayment),
    ]) {
      final csv = parseStatementImport(
        'a.csv',
        utf8.encode('$header\n$payment\n'),
      );
      final paymentCells = <Object>[...payment.split(',')];
      paymentCells[header
              .split(',')
              .indexWhere((title) => title.startsWith('金额'))] =
          18.50;
      final xlsx = parseStatementImport(
        'a.xlsx',
        workbook([
          ['说明区'],
          header.split(','),
          paymentCells,
        ]),
      );
      expect(xlsx.rows.single.line, 3);
      expect(xlsx.rows.single.sourceKey, csv.rows.single.sourceKey);
      expect(xlsx.rows.single.signature, csv.rows.single.signature);
      expect(xlsx.rows.single.movement?.amountMinor, 1850);
    }
  });

  test('Excel numeric dates are parsed, while numeric transaction IDs stay out of strong dedup', () {
    final cells = <Object>[...alipayPayment.split(',')];
    cells[0] = 1.5;
    cells[9] = 123456789012345678;
    final row = parseStatementImport(
      'dates.xlsx',
      workbook([alipayHeader.split(','), cells], with1904Epoch: true),
    ).rows.single;
    expect(row.movement?.occurredAt, DateTime(1904, 1, 2, 12));
    expect(row.sourceKey, isNull);
  });

  test(
    'unknown workbook layout remains unsupported and generic CSV still works',
    () {
      expect(
        () => parseStatementImport(
          'x.xlsx',
          workbook([
            ['Amount', 'Time'],
            [1, 2],
          ]),
        ),
        throwsA(
          isA<CsvImportException>().having(
            (e) => e.issue,
            'issue',
            CsvIssue.headers,
          ),
        ),
      );
      final generic = parseStatementImport(
        'rows.csv',
        utf8.encode(
          'type,amount,occurred_at,account\nexpense,2,2026-11-20,Cash\n',
        ),
      );
      expect(generic.rows.single.movement?.amountMinor, 200);
    },
  );
}
