import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';

class ValuationRate {
  const ValuationRate({
    required this.sourceCurrency,
    required this.baseCurrency,
    required this.rate,
    required this.updatedAt,
  });

  final String sourceCurrency;
  final String baseCurrency;
  final String rate;
  final DateTime updatedAt;
}

class ValuationSettings {
  const ValuationSettings({
    this.baseCurrency = defaultCurrency,
    this.rates = const [],
  });

  final String baseCurrency;
  final List<ValuationRate> rates;
}

class NetWorthValuation {
  const NetWorthValuation({
    required this.totalMinor,
    required this.missingCurrencies,
    required this.unsupportedCurrencies,
  });

  final BigInt? totalMinor;
  final List<String> missingCurrencies;
  final List<String> unsupportedCurrencies;
}

bool isValuationCurrency(String code) => currencyMinorDigits.containsKey(code);

bool isValidValuationRate({
  required String sourceCurrency,
  required String baseCurrency,
  required String rate,
}) =>
    sourceCurrency != baseCurrency &&
    isValuationCurrency(sourceCurrency) &&
    isValuationCurrency(baseCurrency) &&
    isValidExchangeQuote(rate);

NetWorthValuation estimateNetWorth(
  Iterable<AccountBalance> balances,
  ValuationSettings settings,
) {
  final base = settings.baseCurrency;
  final baseDigits = currencyMinorDigits[base];
  if (baseDigits == null) {
    throw ArgumentError.value(base, 'baseCurrency', 'unsupported currency');
  }
  final rates = {
    for (final item in settings.rates)
      if (item.baseCurrency == base) item.sourceCurrency: item.rate,
  };
  final subtotals = <String, BigInt>{};
  for (final balance in balances) {
    if (balance.currentBalanceMinor == 0 ||
        balance.group == AccountGroup.entrustedFunds ||
        balance.group == AccountGroup.external) {
      continue;
    }
    final amount = BigInt.from(balance.currentBalanceMinor);
    final signed = balance.group == AccountGroup.liability ? -amount : amount;
    subtotals.update(
      balance.currencyCode,
      (value) => value + signed,
      ifAbsent: () => signed,
    );
  }

  final missing = <String>[];
  final unsupported = <String>[];
  var numerator = subtotals[base] ?? BigInt.zero;
  var scale = 0;
  for (final code in subtotals.keys.toList()..sort()) {
    if (code == base) continue;
    final sourceDigits = currencyMinorDigits[code];
    if (sourceDigits == null) {
      unsupported.add(code);
      continue;
    }
    final rate = rates[code];
    if (rate == null || !isValidExchangeQuote(rate)) {
      missing.add(code);
      continue;
    }
    final parts = rate.split('.');
    final decimalPlaces = parts.length == 2 ? parts.last.length : 0;
    final multiplier = BigInt.parse(parts.join());
    // Align decimal scales and sum exact minor-unit values before rounding.
    final termScale = sourceDigits + decimalPlaces;
    final power = BigInt.from(10);
    if (termScale > scale) {
      numerator *= power.pow(termScale - scale);
      scale = termScale;
    }
    numerator +=
        subtotals[code]! *
        multiplier *
        power.pow(baseDigits + scale - termScale);
  }

  final denominator = BigInt.from(10).pow(scale);
  final rounded = (numerator.abs() + denominator ~/ BigInt.two) ~/ denominator;
  return NetWorthValuation(
    totalMinor: missing.isEmpty && unsupported.isEmpty
        ? (numerator.isNegative ? -rounded : rounded)
        : null,
    missingCurrencies: List.unmodifiable(missing),
    unsupportedCurrencies: List.unmodifiable(unsupported),
  );
}
