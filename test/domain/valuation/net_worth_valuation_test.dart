import 'package:flutter_test/flutter_test.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

void main() {
  test('values assets minus liabilities across minor-unit scales', () {
    final result = estimateNetWorth(
      [
        _balance('CNY', 3000),
        _balance('CNY', 900, AccountKind.creditLine),
        _balance('USD', 1200),
        _balance('USD', 200, AccountKind.creditLine),
        _balance('JPY', 500),
        _balance('KWD', 125),
        _balance('EUR', 99900, AccountKind.entrustedFunds),
      ],
      ValuationSettings(
        rates: [
          _rate('USD', '7.2'),
          _rate('JPY', '0.05'),
          _rate('KWD', '22.912'),
        ],
      ),
    );
    expect(result.totalMinor, BigInt.from(12086));
    expect(formatMoneyTotal(result.totalMinor!, 'CNY'), '¥120.86');
    expect(result.missingCurrencies, isEmpty);
  });

  test('requires direct rates for the selected base and reports unknown currencies', () {
    final result = estimateNetWorth(
      [
        _balance('USD', 1000),
        _balance('JPY', 1),
        _balance('OLD', 5),
        _balance('EUR', 0),
      ],
      ValuationSettings(
        baseCurrency: 'GBP',
        rates: [
          _rate('USD', '7.2'),
          _rate('GBP', '1.25', 'USD'),
          _rate('JPY', '0.0049', 'GBP'),
        ],
      ),
    );
    expect(result.totalMinor, isNull);
    expect(result.missingCurrencies, ['USD']);
    expect(result.unsupportedCurrencies, ['OLD']);
  });

  test(
    'rounds the exact net amount once, with signed halves away from zero',
    () {
      final settings = ValuationSettings(
        rates: [_rate('USD', '0.25'), _rate('JPY', '0.0025')],
      );
      final positive = estimateNetWorth([
        _balance('USD', 1),
        _balance('JPY', 1),
      ], settings);
      final negative = estimateNetWorth([
        _balance('USD', 1, AccountKind.creditLine),
        _balance('JPY', 1, AccountKind.creditLine),
      ], settings);
      expect(positive.totalMinor, BigInt.one);
      expect(negative.totalMinor, -BigInt.one);
    },
  );

  test(
    'handles credit balances, and totals larger than a single SQLite integer',
    () {
      final result = estimateNetWorth([
        _balance('CNY', 9223372036854775807),
        _balance('CNY', 9223372036854775807),
        _balance('USD', -1, AccountKind.creditLine),
      ], ValuationSettings(rates: [_rate('USD', '2')]));
      expect(result.totalMinor, BigInt.parse('18446744073709551616'));
      expect(
        formatMoneyTotal(result.totalMinor!, 'CNY'),
        '¥184467440737095516.16',
      );
    },
  );
}

AccountBalance _balance(
  String code,
  int minor, [
  AccountKind kind = AccountKind.bank,
]) => AccountBalance(
  id: '$code-${kind.name}-$minor',
  name: code,
  kind: kind,
  openingBalanceMinor: minor,
  currentBalanceMinor: minor,
  currencyCode: code,
);

ValuationRate _rate(String from, String rate, [String to = 'CNY']) =>
    ValuationRate(
      sourceCurrency: from,
      baseCurrency: to,
      rate: rate,
      updatedAt: DateTime.utc(2026, 11, 19),
    );
