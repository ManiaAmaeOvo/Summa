import 'package:flutter/widgets.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/l10n/l10n.dart';

String localizedMoneyInputError(
  BuildContext context,
  MoneyInputException exception,
) => switch (exception.error) {
  MoneyInputError.invalidFormat => context.l10n.moneyInvalidFormat,
  MoneyInputError.negative => context.l10n.moneyNotNegative,
  MoneyInputError.notPositive => context.l10n.moneyGreaterThanZero,
};
