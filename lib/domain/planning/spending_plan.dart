import 'package:summa/core/money/money.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';

enum SpendingScope {
  total,
  personal,
  familyDirect,
  entrusted,
  category,
  account,
  allowance;

  bool get usesAccount => this == account || this == allowance;
}

class SpendingPlanDraft {
  const SpendingPlanDraft({
    required this.name,
    required this.currency,
    required this.scope,
    required this.limitMinor,
    required this.startsOn,
    this.endsOn,
    this.rollover = false,
    this.accountId,
    this.categoryId,
  });

  final String name;
  final String currency;
  final SpendingScope scope;
  final int limitMinor;
  final DateTime startsOn;

  /// The last included day of a fixed period. Null for monthly plans.
  final DateTime? endsOn;
  final bool rollover;
  final String? accountId;
  final String? categoryId;

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.length <= 60 &&
      currencyMinorDigits.containsKey(currency) &&
      limitMinor > 0 &&
      isPlanningDay(startsOn) &&
      (endsOn == null ||
          isPlanningDay(endsOn!) && !endsOn!.isBefore(startsOn) && !rollover) &&
      scope.usesAccount == (accountId != null) &&
      (scope == SpendingScope.category) == (categoryId != null);

  DateTime periodStart(int index) => monthlyPlanningDate(startsOn, index);

  int? periodIndex(DateTime day) {
    if (day.isBefore(startsOn)) return null;
    if (endsOn case final end?) return day.isAfter(end) ? null : 0;
    final months = (day.year - startsOn.year) * 12 + day.month - startsOn.month;
    return day.isBefore(periodStart(months)) ? months - 1 : months;
  }
}

class SpendingPlan {
  const SpendingPlan({
    required this.id,
    required this.draft,
    required this.archived,
    required this.limits,
  });

  final String id;
  final SpendingPlanDraft draft;
  final bool archived;
  final List<SpendingPlanRevision> limits;
}

typedef SpendingPlanLimit = ({
  DateTime periodStart,
  int limitMinor,
  bool ongoing,
});

typedef SpendingPlanRevision = ({
  String id,
  DateTime savedAt,
  SpendingPlanLimit limit,
});

typedef SpendingPlanItem = ({LedgerRecord record, BigInt amountMinor});

typedef SpendingPeriod = ({
  DateTime start,
  DateTime endExclusive,
  BigInt baseMinor,
  BigInt carriedMinor,
  BigInt usedMinor,
  BigInt remainingMinor,
  BigInt? projectedMinor,
  List<SpendingPlanItem> items,
});

SpendingPeriod summarizeSpendingPlan(
  SpendingPlan plan,
  Iterable<LedgerRecord> transactions, {
  required int periodIndex,
  required DateTime today,
}) {
  final draft = plan.draft;
  final day = planningDay(today);
  final start = draft.periodStart(periodIndex);
  final end =
      draft.endsOn?.add(const Duration(days: 1)) ??
      draft.periodStart(periodIndex + 1);
  final usage = <int, BigInt>{};
  final items = <SpendingPlanItem>[];
  for (final record in transactions) {
    final date = planningDay(record.occurredAt);
    if (date.isAfter(day)) continue;
    final index = draft.periodIndex(date);
    if (index == null ||
        index > periodIndex ||
        (!draft.rollover && index != periodIndex)) {
      continue;
    }
    final amount = _spending(draft, record);
    if (amount == BigInt.zero) continue;
    usage.update(index, (sum) => sum + amount, ifAbsent: () => amount);
    if (index == periodIndex) items.add((record: record, amountMinor: amount));
  }

  final recurring = <int, int>{};
  final overrides = <int, int>{};
  for (final revision in plan.limits) {
    final limit = revision.limit;
    final index = draft.periodIndex(limit.periodStart)!;
    if (limit.ongoing) recurring[index] = limit.limitMinor;
    overrides[index] = limit.limitMinor;
  }
  var regular = draft.limitMinor;
  var carried = BigInt.zero;
  for (var index = 0; index <= periodIndex; index++) {
    regular = recurring[index] ?? regular;
    if (!draft.rollover || index == periodIndex) continue;
    final remaining =
        BigInt.from(overrides[index] ?? regular) +
        carried -
        (usage[index] ?? BigInt.zero);
    carried = remaining.isNegative ? BigInt.zero : remaining;
  }

  final base = BigInt.from(overrides[periodIndex] ?? regular);
  final used = usage[periodIndex] ?? BigInt.zero;
  return (
    start: start,
    endExclusive: end,
    baseMinor: base,
    carriedMinor: carried,
    usedMinor: used,
    remainingMinor: base + carried - used,
    projectedMinor:
        draft.scope != SpendingScope.allowance &&
            !day.isBefore(start) &&
            day.isBefore(end) &&
            used > BigInt.zero
        ? used *
              BigInt.from(end.difference(start).inDays) ~/
              BigInt.from(day.difference(start).inDays + 1)
        : null,
    items: items,
  );
}

BigInt _spending(SpendingPlanDraft plan, LedgerRecord record) {
  if (record.isPending || record.currencyCode != plan.currency) {
    return BigInt.zero;
  }
  switch (plan.scope) {
    case SpendingScope.total:
      return BigInt.from(record.spendingMinor);
    case SpendingScope.personal:
    case SpendingScope.familyDirect:
    case SpendingScope.entrusted:
      final activity = summarizeFinancialActivity([record], plan.currency);
      return switch (plan.scope) {
        SpendingScope.personal => activity.personalSpending,
        SpendingScope.familyDirect => activity.familyDirectSpending,
        _ => activity.entrustedSpending,
      };
    case SpendingScope.category:
      return record.spendingCategories
          .where(
            (part) =>
                part.categoryId == plan.categoryId ||
                (record.allocationLabels[part.categoryId]?.parentId ??
                        record.parentCategoryId) ==
                    plan.categoryId,
          )
          .fold(
            BigInt.zero,
            (sum, part) => sum + BigInt.from(part.amountMinor),
          );
    case SpendingScope.account:
    case SpendingScope.allowance:
      return _accountSpending(record, plan.accountId!);
  }
}

BigInt _accountSpending(LedgerRecord record, String accountId) {
  final charges = record.accountId == accountId
      ? BigInt.from(record.direction * record.chargesMinor)
      : BigInt.zero;
  if (record.type != LedgerTransactionType.expense) return charges;

  final total = BigInt.from(record.amountMinor);
  final actual = BigInt.from(record.actualExpenseMinor).abs();
  final sign = BigInt.from(record.isRefund ? -1 : record.direction);
  var paid = BigInt.zero;
  var attributed = BigInt.zero;
  for (final posting in record.accountPostings) {
    if (posting.needsReview ||
        posting.currencyCode != record.currencyCode ||
        posting.accountId == record.terms.advance?.accountId) {
      continue;
    }
    // Round the cumulative share so the split sums back to the expense.
    paid += BigInt.from(posting.debitMinor).abs();
    final cumulative = paid * actual ~/ total;
    if (posting.accountId == accountId) {
      return charges + sign * (cumulative - attributed);
    }
    attributed = cumulative;
  }
  return charges;
}

class SpendingPlanException implements Exception {
  const SpendingPlanException();
}
