import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';

enum RecurringPlanKind {
  subscription,
  expense,
  income;

  LedgerTransactionType get transactionType => this == income
      ? LedgerTransactionType.income
      : LedgerTransactionType.expense;

  bool supportsAccount(AccountKind account) => switch (this) {
    RecurringPlanKind.income =>
      account.isPersonalCash ||
          account == AccountKind.prepaid ||
          account == AccountKind.entrustedFunds,
    _ =>
      account != AccountKind.familyDirect && account != AccountKind.receivable,
  };
}

enum RecurringCadence { daily, weekly, monthly, quarterly, yearly, custom }

class RecurringPlanDraft {
  const RecurringPlanDraft({
    required this.name,
    required this.kind,
    required this.cadence,
    required this.firstDueOn,
    required this.currency,
    required this.expectedMinor,
    required this.accountId,
    required this.categoryId,
    this.customDays,
  });

  final String name;
  final RecurringPlanKind kind;
  final RecurringCadence cadence;
  final DateTime firstDueOn;
  final String currency;
  final int expectedMinor;
  final String accountId;
  final String categoryId;
  final int? customDays;

  bool get isValid =>
      isValidRecurringName(name) &&
      currencyMinorDigits.containsKey(currency) &&
      expectedMinor > 0 &&
      isPlanningDay(firstDueOn) &&
      accountId.isNotEmpty &&
      categoryId.isNotEmpty &&
      (cadence == RecurringCadence.custom
          ? customDays != null &&
                customDays! >= 1 &&
                customDays! <= maxCustomDays
          : customDays == null);

  DateTime? dueOn(int index) {
    // A daily plan cannot have more cycles than days in the date range.
    if (index < 0 ||
        index >= (lastPlanningYear - firstPlanningYear + 1) * 366) {
      return null;
    }
    final months = switch (cadence) {
      RecurringCadence.monthly => 1,
      RecurringCadence.quarterly => 3,
      RecurringCadence.yearly => 12,
      _ => null,
    };
    if (months != null) {
      final date = monthlyPlanningDate(firstDueOn, index * months);
      return isPlanningDay(date) ? date : null;
    }
    final days =
        index * (customDays ?? (cadence == RecurringCadence.weekly ? 7 : 1));
    final last = DateTime.utc(lastPlanningYear, 12, 31);
    return days <= last.difference(firstDueOn).inDays
        ? firstDueOn.add(Duration(days: days))
        : null;
  }

  bool matches(LedgerRecord record) =>
      !record.isPending &&
      !record.isRefund &&
      !record.isReversal &&
      !record.hasReversal &&
      !record.needsReview &&
      record.type == kind.transactionType &&
      record.currencyCode == currency &&
      record.accountPostings.any(
        (posting) =>
            posting.accountId == accountId && posting.currencyCode == currency,
      );
}

const maxCustomDays = 3650;

bool isValidRecurringName(String value) =>
    value.trim().isNotEmpty && value.trim().length <= 60;

class RecurringPlan {
  const RecurringPlan({
    required this.id,
    required this.draft,
    required this.paused,
    required this.occurrences,
  });

  final String id;
  final RecurringPlanDraft draft;
  final bool paused;
  final List<RecurringOccurrence> occurrences;

  int get nextIndex => occurrences.length;
  DateTime? get nextDueOn => draft.dueOn(nextIndex);
}

typedef RecurringOccurrence = ({int index, String entryId, int expectedMinor});

enum RecurringPlanError { invalid, stale, paused, ineligible, alreadyLinked }

class RecurringPlanException implements Exception {
  const RecurringPlanException(this.error);
  final RecurringPlanError error;
}
