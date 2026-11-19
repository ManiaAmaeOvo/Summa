import 'package:summa/core/money/money.dart';

enum AccountKind {
  cash,
  bank,
  wallet,
  creditLine,
  entrustedFunds,
  receivable,
  thirdPartyPayable,
  familyDirect;

  AccountGroup get group => _groupForKind(this);
  bool get isAdvancedFunding =>
      this == receivable || this == thirdPartyPayable || this == familyDirect;
  bool get isLiability => group == AccountGroup.liability;
  bool get isPersonalCash => group == AccountGroup.personalAsset;
}

enum AccountGroup {
  personalAsset,
  entrustedFunds,
  liability,
  receivable,
  external,
}

class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.name,
    required this.kind,
    this.currencyCode = defaultCurrency,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final String currencyCode;

  AccountGroup get group => kind.group;
}

class AccountBalance {
  const AccountBalance({
    required this.id,
    required this.name,
    required this.kind,
    required this.openingBalanceMinor,
    required this.currentBalanceMinor,
    this.currencyCode = defaultCurrency,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final int openingBalanceMinor;
  final int currentBalanceMinor;
  final String currencyCode;

  AccountGroup get group => kind.group;
}

AccountGroup _groupForKind(AccountKind kind) => switch (kind) {
  AccountKind.cash ||
  AccountKind.bank ||
  AccountKind.wallet => AccountGroup.personalAsset,
  AccountKind.entrustedFunds => AccountGroup.entrustedFunds,
  AccountKind.creditLine ||
  AccountKind.thirdPartyPayable => AccountGroup.liability,
  AccountKind.receivable => AccountGroup.receivable,
  AccountKind.familyDirect => AccountGroup.external,
};
