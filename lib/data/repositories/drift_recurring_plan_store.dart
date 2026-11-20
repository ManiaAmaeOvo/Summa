import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/recurring_plan.dart';

class DriftRecurringPlanStore {
  DriftRecurringPlanStore(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _query() {
    final plans = _db.recurringPlans;
    final cycles = _db.recurringOccurrences;
    return _db.select(plans).join([
      leftOuterJoin(cycles, cycles.planId.equalsExp(plans.id)),
    ])..orderBy([
      OrderingTerm.asc(plans.paused),
      OrderingTerm.asc(plans.name),
      OrderingTerm.asc(plans.id),
      OrderingTerm.asc(cycles.cycle),
    ]);
  }

  List<RecurringPlan> _read(List<TypedResult> rows) {
    final grouped = <RecurringPlanRow, List<RecurringOccurrence>>{};
    for (final result in rows) {
      final occurrences = grouped.putIfAbsent(
        result.readTable(_db.recurringPlans),
        () => [],
      );
      if (result.readTableOrNull(_db.recurringOccurrences) case final row?) {
        occurrences.add((
          index: row.cycle,
          entryId: row.entryId,
          expectedMinor: row.expectedMinor,
        ));
      }
    }
    return [
      for (final entry in grouped.entries)
        RecurringPlan(
          id: entry.key.id,
          draft: _draft(entry.key),
          paused: entry.key.paused,
          occurrences: entry.value,
        ),
    ];
  }

  Stream<List<RecurringPlan>> watch() => _query().watch().map(_read);

  Future<void> add(String id, RecurringPlanDraft draft) async {
    if (!draft.isValid || !await _validReferences(draft, activeOnly: true)) {
      throw const RecurringPlanException(RecurringPlanError.invalid);
    }
    await _db
        .into(_db.recurringPlans)
        .insert(
          RecurringPlanRow(
            id: id,
            name: draft.name.trim(),
            kind: draft.kind.name,
            cadence: draft.cadence.name,
            firstDueOn: encodePlanningDay(draft.firstDueOn),
            customDays: draft.customDays,
            currency: draft.currency,
            expectedMinor: draft.expectedMinor,
            accountId: draft.accountId,
            categoryId: draft.categoryId,
            paused: false,
          ),
        );
  }

  Future<void> setPaused(String id, bool paused) async {
    final changed =
        await (_db.update(_db.recurringPlans)
              ..where((row) => row.id.equals(id)))
            .write(RecurringPlansCompanion(paused: Value(paused)));
    if (changed != 1) {
      throw const RecurringPlanException(RecurringPlanError.stale);
    }
  }

  Future<void> setExpectedAmount(String id, int amountMinor) async {
    if (amountMinor <= 0) {
      throw const RecurringPlanException(RecurringPlanError.invalid);
    }
    final changed =
        await (_db.update(_db.recurringPlans)
              ..where((row) => row.id.equals(id)))
            .write(RecurringPlansCompanion(expectedMinor: Value(amountMinor)));
    if (changed != 1) {
      throw const RecurringPlanException(RecurringPlanError.stale);
    }
  }

  Future<RecurringPlanDraft> requireOpenCycle(
    String id,
    int expectedIndex,
  ) async {
    final row = await _byId(id);
    if (row == null) {
      throw const RecurringPlanException(RecurringPlanError.stale);
    }
    if (row.paused) {
      throw const RecurringPlanException(RecurringPlanError.paused);
    }
    final latest =
        await (_db.select(_db.recurringOccurrences)
              ..where((cycle) => cycle.planId.equals(id))
              ..orderBy([(cycle) => OrderingTerm.desc(cycle.cycle)])
              ..limit(1))
            .getSingleOrNull();
    final draft = _draft(row);
    if (expectedIndex != (latest?.cycle ?? -1) + 1 ||
        draft.dueOn(expectedIndex) == null) {
      throw const RecurringPlanException(RecurringPlanError.stale);
    }
    return draft;
  }

  Future<RecurringOccurrenceRow?> _entryLink(String entryId) => (_db.select(
    _db.recurringOccurrences,
  )..where((row) => row.entryId.equals(entryId))).getSingleOrNull();

  Future<void> record(
    String id,
    int index,
    String entryId,
    int expectedMinor,
  ) async {
    if (await _entryLink(entryId) != null) {
      throw const RecurringPlanException(RecurringPlanError.alreadyLinked);
    }
    await _db
        .into(_db.recurringOccurrences)
        .insert(
          RecurringOccurrenceRow(
            planId: id,
            cycle: index,
            entryId: entryId,
            expectedMinor: expectedMinor,
          ),
        );
  }

  Future<RecurringPlanRow?> _byId(String id) => (_db.select(
    _db.recurringPlans,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<bool> _validReferences(
    RecurringPlanDraft draft, {
    required bool activeOnly,
  }) async {
    final accounts = _db.ledgerAccounts;
    final account = await (_db.select(
      accounts,
    )..where((row) => row.id.equals(draft.accountId))).getSingleOrNull();
    if (account == null ||
        account.currencyCode != draft.currency ||
        (activeOnly && account.isArchived) ||
        !draft.kind.supportsAccount(AccountKind.values.byName(account.kind))) {
      return false;
    }
    final categories = _db.ledgerCategories;
    final child = await (_db.select(
      categories,
    )..where((row) => row.id.equals(draft.categoryId))).getSingleOrNull();
    if (child == null ||
        child.parentId == null ||
        child.transactionType != draft.kind.transactionType.name ||
        (activeOnly && child.isArchived)) {
      return false;
    }
    final parent = await (_db.select(
      categories,
    )..where((row) => row.id.equals(child.parentId!))).getSingleOrNull();
    return parent != null &&
        parent.parentId == null &&
        parent.transactionType == child.transactionType &&
        (!activeOnly || !parent.isArchived);
  }

  Future<List<Map<String, Object?>>> backup() async => [
    for (final plan in _read(await _query().get()))
      {
        'id': plan.id,
        'name': plan.draft.name,
        'kind': plan.draft.kind.name,
        'cadence': plan.draft.cadence.name,
        'first_due_on': encodePlanningDay(plan.draft.firstDueOn),
        'custom_days': plan.draft.customDays,
        'currency_code': plan.draft.currency,
        'expected_minor': plan.draft.expectedMinor,
        'account_id': plan.draft.accountId,
        'category_id': plan.draft.categoryId,
        'paused': plan.paused,
        'occurrences': [
          for (final occurrence in plan.occurrences)
            {
              'cycle': occurrence.index,
              'entry_id': occurrence.entryId,
              'expected_minor': occurrence.expectedMinor,
            },
        ],
      },
  ];

  Future<void> restore(List<Map<String, dynamic>> source) async {
    final ids = <String>{};
    final linkedIds = <String>{};
    for (final raw in source) {
      final row = _planFromBackup(raw);
      final draft = _draft(row);
      if (!ids.add(row.id) ||
          !draft.isValid ||
          !await _validReferences(draft, activeOnly: false)) {
        throw recurringBackupConflict;
      }

      final old = await _byId(row.id);
      if (old == null) {
        await _db.into(_db.recurringPlans).insert(row);
      } else if (old.copyWith(
            name: row.name,
            expectedMinor: row.expectedMinor,
            paused: row.paused,
          ) !=
          row) {
        // A cycle index has meaning only for the original schedule.
        throw recurringBackupConflict;
      }

      final occurrences = raw['occurrences'] as List<dynamic>;
      for (final (index, item) in occurrences.indexed) {
        if (item
            case {
              'cycle': int cycle,
              'entry_id': String entryId,
              'expected_minor': int expectedMinor,
            }
            when cycle == index &&
                expectedMinor > 0 &&
                linkedIds.add(entryId) &&
                draft.dueOn(index) != null) {
          await _restoreOccurrence(
            RecurringOccurrenceRow(
              planId: row.id,
              cycle: index,
              entryId: entryId,
              expectedMinor: expectedMinor,
            ),
          );
        } else {
          throw recurringBackupConflict;
        }
      }
    }

    // An older backup may update the account or category of an existing plan.
    for (final row in await _db.select(_db.recurringPlans).get()) {
      if (!await _validReferences(_draft(row), activeOnly: false)) {
        throw recurringBackupConflict;
      }
    }
  }

  Future<void> _restoreOccurrence(RecurringOccurrenceRow item) async {
    final cycles = _db.recurringOccurrences;
    final current =
        await (_db.select(cycles)..where(
              (row) =>
                  row.planId.equals(item.planId) & row.cycle.equals(item.cycle),
            ))
            .getSingleOrNull();
    if (current != null) {
      if (current != item) throw recurringBackupConflict;
      return;
    }
    if (await _entryLink(item.entryId) != null) throw recurringBackupConflict;
    final entries = _db.ledgerEntries;
    final entry =
        await (_db.selectOnly(entries)
              ..addColumns([entries.id])
              ..where(entries.id.equals(item.entryId)))
            .getSingleOrNull();
    if (entry == null) throw recurringBackupConflict;
    await _db.into(cycles).insert(item);
  }
}

RecurringPlanDraft _draft(RecurringPlanRow row) => RecurringPlanDraft(
  name: row.name,
  kind: RecurringPlanKind.values.byName(row.kind),
  cadence: RecurringCadence.values.byName(row.cadence),
  firstDueOn: decodePlanningDay(row.firstDueOn)!,
  customDays: row.customDays,
  currency: row.currency,
  expectedMinor: row.expectedMinor,
  accountId: row.accountId,
  categoryId: row.categoryId,
);

RecurringPlanRow _planFromBackup(Map<String, dynamic> raw) {
  if (raw
      case {
        'id': String id,
        'name': String name,
        'kind': String kind,
        'cadence': String cadence,
        'first_due_on': String first,
        'currency_code': String currency,
        'expected_minor': int expected,
        'account_id': String account,
        'category_id': String category,
        'paused': bool paused,
        'occurrences': List<dynamic> _,
      }
      when id.isNotEmpty &&
          RecurringPlanKind.values.any((value) => value.name == kind) &&
          RecurringCadence.values.any((value) => value.name == cadence) &&
          decodePlanningDay(first) != null &&
          (raw['custom_days'] == null || raw['custom_days'] is int)) {
    return RecurringPlanRow(
      id: id,
      name: name,
      kind: kind,
      cadence: cadence,
      firstDueOn: first,
      customDays: raw['custom_days'] as int?,
      currency: currency,
      expectedMinor: expected,
      accountId: account,
      categoryId: category,
      paused: paused,
    );
  }
  throw recurringBackupConflict;
}

const recurringBackupConflict = LedgerBackupException('备份中的周期计划或交易关联无效或存在冲突');
