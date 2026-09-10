import 'package:flutter/widgets.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/defaults/default_ledger_names.dart';

class DefaultLedgerLabels {
  const DefaultLedgerLabels._();

  static String account(BuildContext context, LedgerAccount account) =>
      DefaultLedgerNames.accountName(
        Localizations.localeOf(context).languageCode,
        account.id,
        account.name,
      );

  static String balance(BuildContext context, AccountBalance account) =>
      DefaultLedgerNames.accountName(
        Localizations.localeOf(context).languageCode,
        account.id,
        account.name,
      );

  static String category(BuildContext context, LedgerCategory category) =>
      DefaultLedgerNames.categoryName(
        Localizations.localeOf(context).languageCode,
        category.id,
        category.name,
      );

  static String accountName(Locale locale, String id, String storedName) =>
      DefaultLedgerNames.accountName(locale.languageCode, id, storedName);

  static String categoryName(Locale locale, String id, String storedName) =>
      DefaultLedgerNames.categoryName(locale.languageCode, id, storedName);

  static bool isProtectedOther(LedgerCategory category) =>
      DefaultLedgerNames.isProtectedOther(category);
}
