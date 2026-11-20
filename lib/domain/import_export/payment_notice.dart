import 'package:summa/core/money/money.dart';
import 'package:summa/domain/transactions/expense_record.dart';

typedef PaymentNoticeDraft = ({
  LedgerTransactionType type,
  int amountMinor,
  String note,
});

final _supportedSource = RegExp(r'^(微信支付|支付宝)');
final _unsupported = RegExp(r'退款|退回|撤销|取消|失败|待支付|待收款|待到账|处理中|未支付|预授权|转账|还款|红包');
final _amountField = RegExp(r'^(实付金额|支付金额|付款金额|收款金额|到账金额)\s*[:：]\s*(.+)$');
final _amount = RegExp(
  r'^(¥|￥|CNY|RMB)?\s*(\d+|\d{1,3}(?:,\d{3})+)(\.\d{1,2})?\s*(元|CNY|RMB)?$',
  caseSensitive: false,
);
final _counterparty = RegExp(r'^(商户名称|商户|交易对方)\s*[:：]\s*(.{1,100})$');

/// Parses one explicitly labelled CNY payment or receipt from pasted text.
/// Unsupported or ambiguous notices are left for manual entry.
PaymentNoticeDraft? tryParsePaymentNotice(String text) {
  if (text.length > 2000 || !_supportedSource.hasMatch(text.trimLeft())) {
    return null;
  }
  PaymentNoticeDraft? draft;
  var note = '';
  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    final party = _counterparty.firstMatch(line);
    if (party != null) {
      note = party[2]!.trim();
      continue;
    }
    if (_unsupported.hasMatch(line)) return null;
    final field = _amountField.firstMatch(line);
    if (field == null) continue;
    final value = _amount.firstMatch(field[2]!);
    if (draft != null ||
        value == null ||
        value[1] == null && value[4] == null) {
      return null;
    }
    try {
      final amountMinor = parseMoney(
        '${value[2]!.replaceAll(',', '')}${value[3] ?? ''}',
        defaultCurrency,
      );
      draft = (
        type: switch (field[1]) {
          '收款金额' || '到账金额' => LedgerTransactionType.income,
          _ => LedgerTransactionType.expense,
        },
        amountMinor: amountMinor,
        note: '',
      );
    } on MoneyInputException {
      return null;
    }
  }
  return draft == null
      ? null
      : (type: draft.type, amountMinor: draft.amountMinor, note: note);
}
