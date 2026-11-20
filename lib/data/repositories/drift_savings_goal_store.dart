import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/savings_goal.dart';

class DriftSavingsGoalStore {
  DriftSavingsGoalStore(this._db);

  final AppDatabase _db;

  Future<List<SavingsGoal>> _readGoals({String? accountId}) async {
    final query = _db.select(_db.savingsGoals);
    if (accountId != null) {
      query.where((row) => row.accountId.equals(accountId));
    }
    final rows = await query.get();
    if (rows.isEmpty) return [];
    final allocations = _db.savingsAllocations;
    final activity =
        await (_db.select(allocations)
              ..where((row) => row.goalId.isIn(rows.map((goal) => goal.id)))
              ..orderBy([
                (row) => OrderingTerm.asc(row.savedAtMicros),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    final grouped = <String, List<SavingsActivityRow>>{};
    for (final row in activity) {
      (grouped[row.goalId] ??= []).add(row);
    }
    return [
      for (final row in rows) _goal(row, grouped[row.id] ?? const []),
    ]..sort((a, b) {
      final priority = a.draft.priority.index.compareTo(b.draft.priority.index);
      if (priority != 0) return priority;
      final name = a.draft.name.compareTo(b.draft.name);
      return name == 0 ? a.id.compareTo(b.id) : name;
    });
  }

  Stream<List<SavingsAccountAllocation>> watch(Selectable<QueryRow> balances) =>
      _db
          .customSelect(
            'SELECT id FROM savings_goals',
            readsFrom: {
              _db.savingsGoals,
              _db.savingsAllocations,
              _db.ledgerAccounts,
              _db.ledgerEntries,
              _db.ledgerPostings,
            },
          )
          .watch()
          .asyncMap(
            (_) => _db.transaction(() async {
              final goals = await _readGoals();
              if (goals.isEmpty) return <SavingsAccountAllocation>[];
              final grouped = <String, List<SavingsGoal>>{};
              for (final goal in goals) {
                (grouped[goal.draft.accountId] ??= []).add(goal);
              }
              return [
                for (final row in await balances.get())
                  SavingsAccountAllocation(
                    accountId: row.read<String>('id'),
                    accountName: row.read<String>('name'),
                    currency: row.read<String>('currency_code'),
                    archived: row.read<bool>('is_archived'),
                    balanceMinor: row.read<int>('current_balance'),
                    goals: grouped[row.read<String>('id')]!,
                  ),
              ];
            }),
          );

  Future<void> save(
    String id,
    SavingsGoalDraft draft, {
    required bool editing,
  }) async {
    final previous = editing ? await _find(id) : null;
    if (editing && previous == null) {
      throw const SavingsGoalException(SavingsGoalError.unavailable);
    }
    final account = await _account(draft.accountId);
    if (!draft.isValid ||
        !_validAccount(account, draft) ||
        (previous == null && account!.isArchived) ||
        (previous != null &&
            (previous.accountId != draft.accountId ||
                previous.currency != draft.currency))) {
      throw const SavingsGoalException(SavingsGoalError.invalid);
    }
    final row = SavingsGoalRow(
      id: id,
      accountId: draft.accountId,
      name: draft.name.trim(),
      currency: draft.currency,
      targetMinor: draft.targetMinor,
      priority: draft.priority.name,
      targetOn: draft.targetOn == null
          ? null
          : encodePlanningDay(draft.targetOn!),
    );
    if (editing) {
      await _db.update(_db.savingsGoals).replace(row);
    } else {
      await _db.into(_db.savingsGoals).insert(row);
    }
  }

  Future<void> change(
    String id,
    String eventId,
    int amount,
    String note,
    Future<int> Function(String accountId) balance,
  ) async {
    if (!_validChange(amount, note)) {
      throw const SavingsGoalException(SavingsGoalError.invalid);
    }
    final row = await _find(id);
    if (row == null) {
      throw const SavingsGoalException(SavingsGoalError.unavailable);
    }
    final goals = await _readGoals(accountId: row.accountId);
    final goal = goals.singleWhere((item) => item.id == id);
    final change = BigInt.from(amount);
    if (amount < 0) {
      if (goal.allocatedMinor + change < BigInt.zero) {
        throw const SavingsGoalException(SavingsGoalError.notEnoughReserved);
      }
    } else {
      final account = await _account(row.accountId);
      if (account == null || account.isArchived) {
        throw const SavingsGoalException(SavingsGoalError.unavailable);
      }
      final reserved = _reserved(goals)[row.accountId]!;
      if (change > savingsUnallocated(await balance(row.accountId), reserved)) {
        throw const SavingsGoalException(SavingsGoalError.notEnoughUnallocated);
      }
    }
    final now = DateTime.now().microsecondsSinceEpoch;
    final latest =
        goal.activity.lastOrNull?.recordedAt.microsecondsSinceEpoch ?? 0;
    await _db
        .into(_db.savingsAllocations)
        .insert(
          SavingsActivityRow(
            id: eventId,
            goalId: id,
            changeMinor: amount,
            savedAtMicros: math.max(now, latest + 1),
            note: note.trim(),
          ),
        );
  }

  Future<SavingsGoalRow?> _find(String id) => (_db.select(
    _db.savingsGoals,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<AccountRow?> _account(String id) => (_db.select(
    _db.ledgerAccounts,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<Map<String, Object?>>> backup() async => [
    for (final goal in await _readGoals())
      {
        'id': goal.id,
        'account_id': goal.draft.accountId,
        'name': goal.draft.name,
        'currency_code': goal.draft.currency,
        'target_minor': goal.draft.targetMinor,
        'priority': goal.draft.priority.name,
        'target_on': goal.draft.targetOn == null
            ? null
            : encodePlanningDay(goal.draft.targetOn!),
        'activity': [
          for (final event in goal.activity)
            {
              'id': event.id,
              'change_minor': event.changeMinor,
              'saved_at_micros': event.recordedAt.microsecondsSinceEpoch,
              'note': event.note,
            },
        ],
      },
  ];

  Future<void> restore(
    List<Map<String, dynamic>> source, {
    required bool merging,
    required Future<int> Function(String accountId) balance,
  }) async {
    final oldReserved = _reserved(await _readGoals());
    final goalIds = <String>{};
    final eventIds = <String>{};
    final incoming = <SavingsGoal>[];
    final allocations = _db.savingsAllocations;
    for (final raw in source) {
      final row = _restoreGoal(raw);
      final activity =
          [
            for (final item in raw['activity'] as List<dynamic>)
              _restoreActivity(row.id, item),
          ]..sort((a, b) {
            final time = a.savedAtMicros.compareTo(b.savedAtMicros);
            return time == 0 ? a.id.compareTo(b.id) : time;
          });
      final goal = _goal(row, activity);
      if (!goalIds.add(row.id) ||
          !goal.draft.isValid ||
          !_validAccount(await _account(row.accountId), goal.draft) ||
          !_validHistory(goal)) {
        throw savingsBackupConflict;
      }
      incoming.add(goal);
      final current = await _find(row.id);
      if (current == null) {
        await _db.into(_db.savingsGoals).insert(row);
      } else if (current.accountId != row.accountId ||
          current.currency != row.currency) {
        throw savingsBackupConflict;
      }
      for (final event in activity) {
        if (!eventIds.add(event.id)) throw savingsBackupConflict;
        final previous = await (_db.select(
          allocations,
        )..where((item) => item.id.equals(event.id))).getSingleOrNull();
        if (previous == null) {
          await _db.into(allocations).insert(event);
        } else if (previous != event) {
          throw savingsBackupConflict;
        }
      }
    }
    final restored = await _readGoals();
    for (final goal in restored) {
      if (!_validAccount(await _account(goal.draft.accountId), goal.draft) ||
          !_validHistory(goal)) {
        throw savingsBackupConflict;
      }
    }
    if (!merging) return;
    final incomingReserved = _reserved(incoming);
    for (final entry in _reserved(restored).entries) {
      final accountId = entry.key;
      final existing = oldReserved[accountId] ?? BigInt.zero;
      final source = incomingReserved[accountId] ?? BigInt.zero;
      // A single snapshot can have a shortfall caused by later spending.
      // Merging two sets of reservations cannot create a larger one.
      if (entry.value > existing &&
          entry.value > source &&
          entry.value >
              savingsNonnegative(BigInt.from(await balance(accountId)))) {
        throw savingsBackupConflict;
      }
    }
  }
}

Map<String, BigInt> _reserved(Iterable<SavingsGoal> goals) {
  final totals = <String, BigInt>{};
  for (final goal in goals) {
    final amount = goal.allocatedMinor;
    totals.update(
      goal.draft.accountId,
      (sum) => sum + amount,
      ifAbsent: () => amount,
    );
  }
  return totals;
}

bool _validAccount(AccountRow? account, SavingsGoalDraft goal) =>
    account != null &&
    account.currencyCode == goal.currency &&
    AccountKind.values.byName(account.kind).isPersonalCash;

bool _validHistory(SavingsGoal goal) {
  var balance = BigInt.zero;
  final max = BigInt.from(0x7fffffffffffffff);
  for (final event in goal.activity) {
    balance += BigInt.from(event.changeMinor);
    if (balance.isNegative || balance > max) return false;
  }
  return true;
}

bool _validChange(int amount, String note) =>
    amount != 0 && amount >= -0x7fffffffffffffff && note.trim().length <= 200;

SavingsGoal _goal(SavingsGoalRow row, List<SavingsActivityRow> activity) =>
    SavingsGoal(
      id: row.id,
      draft: SavingsGoalDraft(
        name: row.name,
        accountId: row.accountId,
        currency: row.currency,
        targetMinor: row.targetMinor,
        priority: SavingsPriority.values.byName(row.priority),
        targetOn: row.targetOn == null
            ? null
            : decodePlanningDay(row.targetOn!),
      ),
      activity: [
        for (final event in activity)
          (
            id: event.id,
            changeMinor: event.changeMinor,
            note: event.note,
            recordedAt: DateTime.fromMicrosecondsSinceEpoch(
              event.savedAtMicros,
              isUtc: true,
            ),
          ),
      ],
    );

SavingsGoalRow _restoreGoal(Map<String, dynamic> raw) {
  final targetOn = raw['target_on'];
  if (raw
      case {
        'id': String id,
        'account_id': String account,
        'name': String name,
        'currency_code': String currency,
        'target_minor': int targetMinor,
        'priority': String priority,
        'activity': List<dynamic> _,
      }
      when id.isNotEmpty &&
          SavingsPriority.values.any((value) => value.name == priority) &&
          (targetOn == null ||
              targetOn is String && decodePlanningDay(targetOn) != null)) {
    return SavingsGoalRow(
      id: id,
      accountId: account,
      name: name,
      currency: currency,
      targetMinor: targetMinor,
      priority: priority,
      targetOn: targetOn as String?,
    );
  }
  throw savingsBackupConflict;
}

SavingsActivityRow _restoreActivity(String goal, Object? raw) {
  if (raw
      case {
        'id': String id,
        'change_minor': int change,
        'saved_at_micros': int saved,
        'note': String note,
      }
      when id.isNotEmpty &&
          _validChange(change, note) &&
          saved > 0 &&
          saved < DateTime.utc(lastPlanningYear + 1).microsecondsSinceEpoch) {
    return SavingsActivityRow(
      id: id,
      goalId: goal,
      changeMinor: change,
      savedAtMicros: saved,
      note: note,
    );
  }
  throw savingsBackupConflict;
}

const savingsBackupConflict = LedgerBackupException('备份中的储蓄目标或资金分配无效或存在冲突');
