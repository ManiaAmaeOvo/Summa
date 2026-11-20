import 'dart:math' as math;

import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/transactions/expense_record.dart';

class CashForecastInputs {
  const CashForecastInputs({
    required this.balances,
    required this.transactions,
    required this.recurringPlans,
    required this.contracts,
  });

  final List<AccountBalance> balances;
  final List<LedgerRecord> transactions;
  final List<RecurringPlan> recurringPlans;
  final List<DebtContract> contracts;

  Iterable<String> get currencies => {
    for (final account in balances)
      if (account.kind.isPersonalCash) account.currencyCode,
    for (final contract in contracts) contract.draft.currency,
  };
}

enum CashForecastSource {
  futurePosted,
  recurringIncome,
  recurringExpense,
  subscription,
  debtRepayment,
  receivableCollection,
}

class CashForecastEvent {
  const CashForecastEvent({
    required this.source,
    required this.name,
    required this.dueOn,
    required this.changeMinor,
    this.record,
    this.overdueCycles = 0,
    this.included = true,
  });

  final CashForecastSource source;
  final String name;
  final DateTime dueOn;
  final BigInt changeMinor;
  final LedgerRecord? record;
  final int overdueCycles;
  final bool included;
}

typedef CashForecastDay = ({
  DateTime date,
  BigInt closingMinor,
  List<CashForecastEvent> events,
});

typedef UnscheduledPrincipal = ({
  String name,
  DebtDirection direction,
  BigInt amountMinor,
});

class CashForecast {
  const CashForecast({
    required this.openingMinor,
    required this.days,
    required this.unscheduledPrincipal,
  });

  final BigInt openingMinor;
  final List<CashForecastDay> days;
  final List<UnscheduledPrincipal> unscheduledPrincipal;

  BigInt get closingMinor => days.last.closingMinor;

  CashForecastDay? get firstShortfall =>
      days.where((day) => day.closingMinor.isNegative).firstOrNull;

  BigInt get peakShortfallMinor => days.fold(
    BigInt.zero,
    (peak, day) => -day.closingMinor > peak ? -day.closingMinor : peak,
  );
}

CashForecast forecastCash(
  CashForecastInputs inputs, {
  required String currency,
  required DateTime today,
  required int horizonDays,
}) {
  RangeError.checkValueInInterval(horizonDays, 1, 366, 'horizonDays');
  final start = planningDay(today);
  final end = start.add(Duration(days: horizonDays));
  final cashAccounts = {
    for (final account in inputs.balances)
      if (account.kind.isPersonalCash && account.currencyCode == currency)
        account.id,
  };
  var opening = inputs.balances
      .where((account) => cashAccounts.contains(account.id))
      .fold(
        BigInt.zero,
        (sum, account) => sum + BigInt.from(account.currentBalanceMinor),
      );
  final eventsByDate = <DateTime, List<CashForecastEvent>>{};
  void add(CashForecastEvent event) {
    final day = event.dueOn.isBefore(start) ? start : event.dueOn;
    if (day.isBefore(end)) (eventsByDate[day] ??= []).add(event);
  }

  for (final record in inputs.transactions) {
    final day = planningDay(record.occurredAt.toLocal());
    if (record.isPending || !day.isAfter(start)) continue;
    final delta = record.accountPostings
        .where(
          (posting) =>
              cashAccounts.contains(posting.accountId) &&
              posting.currencyCode == currency,
        )
        .fold(
          BigInt.zero,
          (sum, posting) => sum + BigInt.from(posting.debitMinor),
        );
    if (delta == BigInt.zero) continue;
    // The live ledger balance includes already-posted entries with future dates.
    opening -= delta;
    add(
      CashForecastEvent(
        source: CashForecastSource.futurePosted,
        name: record.note,
        dueOn: day,
        changeMinor: delta,
        record: record,
      ),
    );
  }

  for (final plan in inputs.recurringPlans) {
    final draft = plan.draft;
    final next = plan.nextDueOn;
    if (plan.paused ||
        next == null ||
        draft.currency != currency ||
        !cashAccounts.contains(draft.accountId)) {
      continue;
    }
    final income = draft.kind == RecurringPlanKind.income;
    final source = switch (draft.kind) {
      RecurringPlanKind.subscription => CashForecastSource.subscription,
      RecurringPlanKind.expense => CashForecastSource.recurringExpense,
      RecurringPlanKind.income => CashForecastSource.recurringIncome,
    };
    final signed = BigInt.from(
      income ? draft.expectedMinor : -draft.expectedMinor,
    );
    final current = math.max(plan.nextIndex, draft.firstIndexOnOrAfter(start));
    final overdue = current - plan.nextIndex;
    if (overdue > 0) {
      add(
        CashForecastEvent(
          source: source,
          name: draft.name,
          dueOn: next,
          changeMinor: signed * BigInt.from(overdue),
          overdueCycles: overdue,
          included: !income,
        ),
      );
    }
    for (var index = current; ; index++) {
      final due = draft.dueOn(index);
      if (due == null || !due.isBefore(end)) break;
      add(
        CashForecastEvent(
          source: source,
          name: draft.name,
          dueOn: due,
          changeMinor: signed,
        ),
      );
    }
  }

  final unscheduled = <UnscheduledPrincipal>[];
  for (final contract in inputs.contracts.where(
    (item) => item.draft.currency == currency,
  )) {
    final draft = contract.draft;
    final progress = summarizeDebtContract(contract, inputs.transactions);
    final scheduled = progress.installments.fold(
      BigInt.zero,
      (sum, row) => sum + BigInt.from(row.principalRemainingMinor),
    );
    final balance = BigInt.from(math.max(0, contract.balanceMinor));
    // Recognized posted principal moves the earliest unpaid installment forward
    // even when the user has not linked it. The ledger balance also caps the
    // schedule after principal corrections or a historical opening balance.
    var principalCredit = _larger(
      progress.unlinkedPrincipalMinor,
      scheduled - balance,
    );
    var interestCredit = progress.unlinkedInterestMinor;
    var projectedPrincipal = BigInt.zero;
    final receiving = draft.direction == DebtDirection.receivable;
    for (final row in progress.installments) {
      final principal = BigInt.from(row.principalRemainingMinor);
      final interest = BigInt.from(row.interestRemainingMinor);
      final usedPrincipal = _smaller(principal, principalCredit);
      final usedInterest = _smaller(interest, interestCredit);
      principalCredit -= usedPrincipal;
      interestCredit -= usedInterest;
      projectedPrincipal += principal - usedPrincipal;
      final amount = principal - usedPrincipal + interest - usedInterest;
      if (amount == BigInt.zero) continue;
      final due = row.installment.dueOn;
      add(
        CashForecastEvent(
          source: receiving
              ? CashForecastSource.receivableCollection
              : CashForecastSource.debtRepayment,
          name: draft.name,
          dueOn: due,
          changeMinor: receiving ? amount : -amount,
          included: !receiving || !due.isBefore(start),
        ),
      );
    }
    if (balance > projectedPrincipal) {
      unscheduled.add((
        name: draft.name,
        direction: draft.direction,
        amountMinor: balance - projectedPrincipal,
      ));
    }
  }

  var balance = opening;
  final days = <CashForecastDay>[];
  for (var index = 0; index < horizonDays; index++) {
    final day = start.add(Duration(days: index));
    final events = eventsByDate[day] ?? const <CashForecastEvent>[];
    for (final event in events) {
      if (event.included) balance += event.changeMinor;
    }
    days.add((date: day, closingMinor: balance, events: events));
  }
  return CashForecast(
    openingMinor: opening,
    days: days,
    unscheduledPrincipal: unscheduled,
  );
}

BigInt _larger(BigInt a, BigInt b) => a > b ? a : b;
BigInt _smaller(BigInt a, BigInt b) => a < b ? a : b;
