import 'package:flutter/widgets.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/l10n/l10n.dart';

String localizedMoneyInputError(
  BuildContext context,
  MoneyInputException exception, {
  String currency = defaultCurrency,
}) => switch (exception.error) {
  MoneyInputError.invalidFormat =>
    currency == defaultCurrency
        ? context.l10n.moneyInvalidFormat
        : context.l10n.invalidCurrencyAmount(currency),
  MoneyInputError.negative => context.l10n.moneyNotNegative,
  MoneyInputError.notPositive => context.l10n.moneyGreaterThanZero,
};
