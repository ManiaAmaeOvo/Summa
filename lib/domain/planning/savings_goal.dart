import 'package:summa/core/money/money.dart';
import 'package:summa/domain/planning/planning_date.dart';

enum SavingsPriority { high, normal, low }

class SavingsGoalDraft {
  const SavingsGoalDraft({
    required this.name,
    required this.accountId,
    required this.currency,
    required this.targetMinor,
    required this.priority,
    this.targetOn,
  });

  final String name;
  final String accountId;
  final String currency;
  final int targetMinor;
  final SavingsPriority priority;
  final DateTime? targetOn;

  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length <= 60 &&
      accountId.isNotEmpty &&
      currencyMinorDigits.containsKey(currency) &&
      targetMinor > 0 &&
      (targetOn == null || isPlanningDay(targetOn!));
}

typedef SavingsActivity = ({
  String id,
  int changeMinor,
  DateTime recordedAt,
  String note,
});

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.draft,
    required this.activity,
  });

  final String id;
  final SavingsGoalDraft draft;
  final List<SavingsActivity> activity;

  BigInt get allocatedMinor => activity.fold(
    BigInt.zero,
    (sum, row) => sum + BigInt.from(row.changeMinor),
  );

  bool get reached => allocatedMinor >= BigInt.from(draft.targetMinor);
}

class SavingsAccountAllocation {
  const SavingsAccountAllocation({
    required this.accountId,
    required this.accountName,
    required this.currency,
    required this.archived,
    required this.balanceMinor,
    required this.goals,
  });

  final String accountId;
  final String accountName;
  final String currency;
  final bool archived;
  final int balanceMinor;
  final List<SavingsGoal> goals;

  BigInt get reservedMinor =>
      goals.fold(BigInt.zero, (sum, goal) => sum + goal.allocatedMinor);

  BigInt get unallocatedMinor =>
      savingsUnallocated(balanceMinor, reservedMinor);

  BigInt get shortfallMinor => savingsNonnegative(
    reservedMinor - savingsNonnegative(BigInt.from(balanceMinor)),
  );
}

BigInt savingsUnallocated(int balanceMinor, BigInt reservedMinor) =>
    savingsNonnegative(BigInt.from(balanceMinor) - reservedMinor);

BigInt savingsNonnegative(BigInt value) =>
    value.isNegative ? BigInt.zero : value;

enum SavingsGoalError {
  invalid,
  unavailable,
  notEnoughUnallocated,
  notEnoughReserved,
}

class SavingsGoalException implements Exception {
  const SavingsGoalException(this.error);
  final SavingsGoalError error;
}
