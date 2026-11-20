import 'package:flutter_test/flutter_test.dart';
import 'package:summa/domain/import_export/payment_notice.dart';
import 'package:summa/domain/transactions/expense_record.dart';

void main() {
  test('extracts one explicit CNY amount without copying identifiers', () {
    expect(tryParsePaymentNotice('微信支付\n支付金额：￥1,028.50\n交易单号：00800\n商户：午餐店'), (
      type: LedgerTransactionType.expense,
      amountMinor: 102850,
      note: '午餐店',
    ));
    expect(tryParsePaymentNotice('支付宝\n收款金额: 20.5元'), (
      type: LedgerTransactionType.income,
      amountMinor: 2050,
      note: '',
    ));
  });

  test('leaves ambiguous, unsupported and non-CNY notices unparsed', () {
    for (final body in [
      '支付金额：12.50',
      '支付金额：USD 12.50',
      '支付金额：¥0',
      '支付金额：¥1,28.50',
      '支付金额：¥1.001',
      '付款失败\n支付金额：¥12.50',
      '退款成功\n到账金额：¥12.50',
      '待收款\n收款金额：¥12.50',
      '支付金额：¥12.50\n收款金额：¥12.50',
      '商户：¥12.50',
    ]) {
      expect(tryParsePaymentNotice('微信支付\n$body'), isNull, reason: body);
    }
    expect(tryParsePaymentNotice('短信提醒\n支付金额：¥12.50'), isNull);
  });
}
