import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/spending_plan.dart';

class DriftSpendingPlanStore {
  DriftSpendingPlanStore(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _query() {
    final plans = _db.spendingPlans;
    final limits = _db.spendingPlanLimits;
    return _db.select(plans).join([
      leftOuterJoin(limits, limits.planId.equalsExp(plans.id)),
    ])..orderBy([
      OrderingTerm.asc(plans.archived),
      OrderingTerm.asc(plans.name),
      OrderingTerm.asc(plans.id),
      OrderingTerm.asc(limits.savedAtMicros),
      OrderingTerm.asc(limits.id),
    ]);
  }

  List<SpendingPlan> _readPlans(List<TypedResult> rows) {
    final grouped = <SpendingPlanRow, List<SpendingPlanRevision>>{};
    for (final row in rows) {
      final limits = grouped.putIfAbsent(
        row.readTable(_db.spendingPlans),
        () => [],
      );
      if (row.readTableOrNull(_db.spendingPlanLimits) case final limit?) {
        limits.add(_limit(limit));
      }
    }
    return [
      for (final entry in grouped.entries)
        SpendingPlan(
          id: entry.key.id,
          draft: _draft(entry.key),
          archived: entry.key.archived,
          limits: entry.value,
        ),
    ];
  }

  Stream<List<SpendingPlan>> watch() => _query().watch().map(_readPlans);

  Future<void> add(String id, SpendingPlanDraft draft) async {
    final row = SpendingPlanRow(
      id: id,
      name: draft.name.trim(),
      currency: draft.currency,
      scope: draft.scope.name,
      limitMinor: draft.limitMinor,
      startsOn: _date(draft.startsOn),
      endsOn: draft.endsOn == null ? null : _date(draft.endsOn!),
      rollover: draft.rollover,
      archived: false,
      accountId: draft.accountId,
      categoryId: draft.categoryId,
    );
    if (!draft.isValid ||
        !await _validTarget(row, activeOnly: true) ||
        !await _uniqueAllowance(row)) {
      throw const SpendingPlanException();
    }
    await _db.into(_db.spendingPlans).insert(row);
  }

  Future<void> setLimit(
    String id,
    String revisionId,
    SpendingPlanLimit limit,
  ) async {
    final row = await _byId(id);
    if (row == null || row.archived || !_validLimit(_draft(row), limit)) {
      throw const SpendingPlanException();
    }
    final table = _db.spendingPlanLimits;
    final latest =
        await (_db.select(table)
              ..where((entry) => entry.planId.equals(id))
              ..orderBy([(entry) => OrderingTerm.desc(entry.savedAtMicros)])
              ..limit(1))
            .getSingleOrNull();
    final now = DateTime.now().microsecondsSinceEpoch;
    final previous = latest?.savedAtMicros ?? 0;
    await _db
        .into(table)
        .insert(
          SpendingPlanLimitRow(
            id: revisionId,
            planId: id,
            periodStart: _date(limit.periodStart),
            limitMinor: limit.limitMinor,
            ongoing: limit.ongoing,
            savedAtMicros: now > previous ? now : previous + 1,
          ),
        );
  }

  Future<void> setArchived(String id, bool archived) async {
    final row = await _byId(id);
    if (row == null ||
        (!archived &&
            (!await _validTarget(row, activeOnly: true) ||
                !await _uniqueAllowance(row.copyWith(archived: false))))) {
      throw const SpendingPlanException();
    }
    await _db
        .update(_db.spendingPlans)
        .replace(row.copyWith(archived: archived));
  }

  Future<SpendingPlanRow?> _byId(String id) => (_db.select(
    _db.spendingPlans,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<bool> _validTarget(
    SpendingPlanRow plan, {
    required bool activeOnly,
  }) async {
    if (plan.accountId case final id?) {
      final account = await (_db.select(
        _db.ledgerAccounts,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      return account != null &&
          account.currencyCode == plan.currency &&
          (!activeOnly || !account.isArchived) &&
          (plan.scope == SpendingScope.allowance.name
              ? account.kind == AccountKind.entrustedFunds.name
              : account.kind != AccountKind.receivable.name &&
                    account.kind != AccountKind.familyDirect.name);
    }
    if (plan.categoryId case final id?) {
      final category = await (_db.select(
        _db.ledgerCategories,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (category == null ||
          category.transactionType != 'expense' ||
          (activeOnly && category.isArchived)) {
        return false;
      }
      if (activeOnly && (category.parentId != null)) {
        final parent = await (_db.select(
          _db.ledgerCategories,
        )..where((row) => row.id.equals(category.parentId!))).getSingle();
        return !parent.isArchived;
      }
    }
    return true;
  }

  Future<bool> _uniqueAllowance(SpendingPlanRow plan) async {
    if (plan.archived || plan.scope != SpendingScope.allowance.name) {
      return true;
    }
    final conflicting =
        await (_db.select(_db.spendingPlans)
              ..where(
                (row) =>
                    row.scope.equals(SpendingScope.allowance.name) &
                    row.accountId.equals(plan.accountId!) &
                    row.archived.equals(false) &
                    row.id.equals(plan.id).not(),
              )
              ..limit(1))
            .getSingleOrNull();
    return conflicting == null;
  }

  Future<List<Map<String, Object?>>> backup() async => [
    for (final plan in _readPlans(await _query().get()))
      {
        'id': plan.id,
        'name': plan.draft.name,
        'currency_code': plan.draft.currency,
        'scope': plan.draft.scope.name,
        'limit_minor': plan.draft.limitMinor,
        'starts_on': _date(plan.draft.startsOn),
        'ends_on': plan.draft.endsOn == null ? null : _date(plan.draft.endsOn!),
        'rollover': plan.draft.rollover,
        'archived': plan.archived,
        'account_id': plan.draft.accountId,
        'category_id': plan.draft.categoryId,
        'limits': [
          for (final revision in plan.limits)
            {
              'id': revision.id,
              'saved_at_micros': revision.savedAt.microsecondsSinceEpoch,
              'period_start': _date(revision.limit.periodStart),
              'limit_minor': revision.limit.limitMinor,
              'ongoing': revision.limit.ongoing,
            },
        ],
      },
  ];

  Future<void> restore(List<Map<String, dynamic>> source) async {
    final ids = <String>{};
    final revisions = <String>{};
    for (final item in source) {
      final row = _restoreRow(item);
      final draft = _draft(row);
      if (!ids.add(row.id) ||
          !draft.isValid ||
          !await _validTarget(row, activeOnly: false) ||
          !await _uniqueAllowance(row)) {
        throw _conflict;
      }
      final current = await _byId(row.id);
      if (current == null) {
        await _db.into(_db.spendingPlans).insert(row);
      } else if (current != row) {
        throw _conflict;
      }

      for (final raw in item['limits'] as List<dynamic>) {
        if (raw case {
          'id': String revisionId,
          'saved_at_micros': int timestamp,
          'period_start': String date,
          'limit_minor': int minor,
          'ongoing': bool ongoing,
        }) {
          final limit = (
            periodStart: _parseDate(date),
            limitMinor: minor,
            ongoing: ongoing,
          );
          if (revisionId.isEmpty ||
              !revisions.add(revisionId) ||
              timestamp <= 0 ||
              timestamp >= 8640000000000000000 ||
              !_validLimit(draft, limit)) {
            throw _conflict;
          }
          final table = _db.spendingPlanLimits;
          final revision = SpendingPlanLimitRow(
            id: revisionId,
            planId: row.id,
            periodStart: date,
            limitMinor: minor,
            ongoing: ongoing,
            savedAtMicros: timestamp,
          );
          final previous = await (_db.select(
            table,
          )..where((entry) => entry.id.equals(revisionId))).getSingleOrNull();
          if (previous == null) {
            await _db.into(table).insert(revision);
          } else if (previous != revision) {
            throw _conflict;
          }
        } else {
          throw _conflict;
        }
      }
    }

    // An older backup can also change the account linked to a local plan.
    for (final row in await _db.select(_db.spendingPlans).get()) {
      if (!await _validTarget(row, activeOnly: false)) throw _conflict;
    }
  }
}

SpendingPlanRow _restoreRow(Map<String, dynamic> item) {
  if (item
      case {
        'id': String id,
        'name': String name,
        'currency_code': String currency,
        'scope': String scope,
        'limit_minor': int limit,
        'starts_on': String starts,
        'rollover': bool rollover,
        'archived': bool archived,
        'limits': List<dynamic> _,
      }
      when id.isNotEmpty &&
          SpendingScope.values.any((value) => value.name == scope) &&
          (item['ends_on'] == null || item['ends_on'] is String) &&
          (item['account_id'] == null || item['account_id'] is String) &&
          (item['category_id'] == null || item['category_id'] is String)) {
    return SpendingPlanRow(
      id: id,
      name: name,
      currency: currency,
      scope: scope,
      limitMinor: limit,
      startsOn: starts,
      endsOn: item['ends_on'] as String?,
      rollover: rollover,
      archived: archived,
      accountId: item['account_id'] as String?,
      categoryId: item['category_id'] as String?,
    );
  }
  throw _conflict;
}

SpendingPlanDraft _draft(SpendingPlanRow row) => SpendingPlanDraft(
  name: row.name,
  currency: row.currency,
  scope: SpendingScope.values.byName(row.scope),
  limitMinor: row.limitMinor,
  startsOn: _parseDate(row.startsOn),
  endsOn: row.endsOn == null ? null : _parseDate(row.endsOn!),
  rollover: row.rollover,
  accountId: row.accountId,
  categoryId: row.categoryId,
);

SpendingPlanRevision _limit(SpendingPlanLimitRow row) => (
  id: row.id,
  savedAt: DateTime.fromMicrosecondsSinceEpoch(row.savedAtMicros, isUtc: true),
  limit: (
    periodStart: _parseDate(row.periodStart),
    limitMinor: row.limitMinor,
    ongoing: row.ongoing,
  ),
);

bool _validLimit(SpendingPlanDraft draft, SpendingPlanLimit limit) {
  if (!isPlanningDay(limit.periodStart) ||
      limit.limitMinor < 0 ||
      (limit.ongoing && draft.endsOn != null)) {
    return false;
  }
  final index = draft.periodIndex(limit.periodStart);
  return index != null && draft.periodStart(index) == limit.periodStart;
}

String _date(DateTime value) => value.toIso8601String().split('T').first;

DateTime _parseDate(String value) {
  final date = DateTime.tryParse('${value}T00:00:00Z');
  if (date == null || !isPlanningDay(date) || _date(date) != value) {
    throw _conflict;
  }
  return date;
}

const _conflict = LedgerBackupException('备份中的预算或外部额度无效或存在冲突');
