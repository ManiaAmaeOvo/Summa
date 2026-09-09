enum AccountKind { cash, bank, wallet, creditLine, entrustedFunds }

enum AccountGroup { personalAsset, entrustedFunds, liability }

class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.name,
    required this.kind,
  });

  final String id;
  final String name;
  final AccountKind kind;

  AccountGroup get group => _groupForKind(kind);
}

class AccountBalance {
  const AccountBalance({
    required this.id,
    required this.name,
    required this.kind,
    required this.openingBalanceMinor,
    required this.currentBalanceMinor,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final int openingBalanceMinor;
  final int currentBalanceMinor;

  AccountGroup get group => _groupForKind(kind);
}

AccountGroup _groupForKind(AccountKind kind) => switch (kind) {
  AccountKind.cash ||
  AccountKind.bank ||
  AccountKind.wallet => AccountGroup.personalAsset,
  AccountKind.entrustedFunds => AccountGroup.entrustedFunds,
  AccountKind.creditLine => AccountGroup.liability,
};
