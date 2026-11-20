import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/transactions/expense_record.dart';

class FinancialReport {
  FinancialReport({
    required Iterable<LedgerRecord> records,
    required Iterable<AccountBalance> balances,
    required this.range,
    required this.currency,
    required LedgerFilter filter,
    required this.monthlyTimeline,
  }) : filter = filter.scoped(range: range, currency: currency) {
    final posted = records.where((record) => !record.isPending).toList();
    final categoryId = filter.categoryId;
    categoryName = categoryId == null
        ? null
        : posted
              .expand(ledgerRecordCategories)
              .map((category) {
                if (category.id == categoryId) return category.name;
                return category.parentId == categoryId
                    ? category.parentName
                    : null;
              })
              .whereType<String>()
              .firstOrNull;
    if (filter.accountId case final id?) {
      final account = balances.where((row) => row.id == id).firstOrNull;
      accountName =
          account?.name ??
          posted
              .expand((record) => record.accountPostings)
              .where((posting) => posting.accountId == id)
              .firstOrNull
              ?.accountName;
    } else {
      accountName = null;
    }
    analysis = analyzeLedger(posted, currency, this.filter);
    transactions = List.unmodifiable(posted.where(this.filter.matches));
    spendingTimeline = _spendingTimeline(analysis.spending, monthlyTimeline);
    position =
        filter.categoryId != null ||
            filter.funding != null ||
            filter.hasSourceDimensions
        ? null
        : ReportPosition._read(posted, balances, this.filter, range, currency);
  }

  final LedgerDateRange range;
  final String currency;
  final LedgerFilter filter;
  final bool monthlyTimeline;
  late final String? categoryName;
  late final String? accountName;
  late final LedgerAnalysis analysis;
  late final List<LedgerRecord> transactions;
  late final List<AnalysisSpendingPoint> spendingTimeline;
  late final ReportPosition? position;
}

typedef ReportBalance = ({
  AccountBalance account,
  BigInt openingMinor,
  BigInt closingMinor,
});

typedef ReportLiabilityPoint = ({DateTime date, BigInt amountMinor});
typedef ReportPositionTotals = ({
  BigInt assetsMinor,
  BigInt liabilitiesMinor,
  BigInt netWorthMinor,
});

class ReportPosition {
  const ReportPosition._({
    required this.balances,
    required this.opening,
    required this.closing,
    required this.currentLiabilitiesMinor,
    required this.liabilityTrend,
  });

  final List<ReportBalance> balances;
  final ReportPositionTotals opening;
  final ReportPositionTotals closing;
  final BigInt currentLiabilitiesMinor;
  final List<ReportLiabilityPoint> liabilityTrend;

  bool get hasLiabilities =>
      balances.any((row) => row.account.kind.isLiability);

  factory ReportPosition._read(
    List<LedgerRecord> posted,
    Iterable<AccountBalance> allBalances,
    LedgerFilter filter,
    LedgerDateRange range,
    String currency,
  ) {
    final accounts = {
      for (final account in allBalances)
        if (account.currencyCode == currency &&
            (filter.accountId == null || filter.accountId == account.id))
          account.id: account,
    };
    final sinceStart = <String, BigInt>{};
    final afterPeriod = <String, BigInt>{};
    final liabilityChanges = <DateTime, BigInt>{};
    for (final record in posted) {
      if (record.occurredAt.isBefore(range.start)) continue;
      final after = !record.occurredAt.isBefore(range.endExclusive);
      for (final leg in record.accountPostings) {
        final account = accounts[leg.accountId];
        if (leg.currencyCode != currency || account == null) continue;
        final debit = BigInt.from(leg.debitMinor);
        final change = account.kind.isLiability ? -debit : debit;
        _add(sinceStart, account.id, change);
        if (after) {
          _add(afterPeriod, account.id, change);
        } else if (account.kind.isLiability) {
          _add(liabilityChanges, record.occurredAt, change);
        }
      }
    }
    final balances = [
      for (final account in accounts.values)
        (
          account: account,
          openingMinor:
              BigInt.from(account.currentBalanceMinor) -
              (sinceStart[account.id] ?? BigInt.zero),
          closingMinor:
              BigInt.from(account.currentBalanceMinor) -
              (afterPeriod[account.id] ?? BigInt.zero),
        ),
    ];
    final opening = _totals(balances, (row) => row.openingMinor);
    final closing = _totals(balances, (row) => row.closingMinor);
    final dates = liabilityChanges.keys.toList()..sort();
    var running = opening.liabilitiesMinor;
    final trend = <ReportLiabilityPoint>[
      (date: range.start, amountMinor: running),
    ];
    for (final date in dates) {
      final change = liabilityChanges[date]!;
      if (change == BigInt.zero) continue;
      running += change;
      trend.add((date: date, amountMinor: running));
    }
    final last = range.endExclusive.subtract(const Duration(microseconds: 1));
    if (trend.last.date != last) {
      trend.add((date: last, amountMinor: closing.liabilitiesMinor));
    }
    return ReportPosition._(
      balances: List.unmodifiable(balances),
      opening: opening,
      closing: closing,
      currentLiabilitiesMinor: _totals(
        balances,
        (row) => BigInt.from(row.account.currentBalanceMinor),
      ).liabilitiesMinor,
      liabilityTrend: List.unmodifiable(trend),
    );
  }
}

ReportPositionTotals _totals(
  List<ReportBalance> balances,
  BigInt Function(ReportBalance) read,
) {
  var assets = BigInt.zero;
  var liabilities = BigInt.zero;
  for (final row in balances) {
    switch (row.account.group) {
      case AccountGroup.personalAsset:
      case AccountGroup.prepaid:
      case AccountGroup.receivable:
        assets += read(row);
      case AccountGroup.liability:
        liabilities += read(row);
      case AccountGroup.entrustedFunds:
      case AccountGroup.external:
        break;
    }
  }
  return (
    assetsMinor: assets,
    liabilitiesMinor: liabilities,
    netWorthMinor: assets - liabilities,
  );
}

List<AnalysisSpendingPoint> _spendingTimeline(
  List<AnalysisSpendingPoint> points,
  bool monthly,
) {
  final buckets = <DateTime, BigInt>{};
  for (final item in points) {
    final date = item.date.toLocal();
    final bucket = DateTime(date.year, date.month, monthly ? 1 : date.day);
    _add(buckets, bucket, item.amountMinor);
  }
  final days = buckets.keys.toList()..sort();
  return List.unmodifiable([
    for (final date in days) (date: date, amountMinor: buckets[date]!),
  ]);
}

void _add<K>(Map<K, BigInt> totals, K key, BigInt amount) {
  totals.update(key, (sum) => sum + amount, ifAbsent: () => amount);
}
