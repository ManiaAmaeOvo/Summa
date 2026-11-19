import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';

class DriftReconciliationStore {
  DriftReconciliationStore(this._db);

  final AppDatabase _db;

  Stream<List<BalanceCheckpoint>> watch(String accountId) => _db
      .customSelect(
        """
    SELECT c.*, a.opening_balance_minor + COALESCE((
      SELECT SUM(p.debit_minor)
      FROM ledger_postings p
      JOIN ledger_entries e ON e.id = p.transaction_id
      WHERE p.account_id = c.account_id AND p.currency_code = c.currency_code
        AND e.status = 'posted' AND e.is_deleted = 0 AND e.occurred_at <= c.observed_at
    ), 0) * CASE WHEN a.kind IN ('creditLine', 'thirdPartyPayable') THEN -1 ELSE 1 END
      AS book_minor
    FROM balance_checkpoints c JOIN ledger_accounts a ON a.id = c.account_id
    WHERE c.account_id = ?
    ORDER BY c.observed_at DESC, c.created_at DESC, c.id DESC
    """,
        variables: [Variable.withString(accountId)],
        readsFrom: {
          _db.balanceCheckpoints,
          _db.ledgerEntries,
          _db.ledgerPostings,
          _db.ledgerAccounts,
        },
      )
      .watch()
      .map(
        (rows) => [
          for (final result in rows)
            BalanceCheckpoint(
              id: result.read<String>('id'),
              accountId: accountId,
              currencyCode: result.read<String>('currency_code'),
              observedAt: result.read<DateTime>('observed_at'),
              actualMinor: result.read<int>('actual_minor'),
              recordedBookMinor: result.read<int>('recorded_book_minor'),
              bookMinor: result.read<int>('book_minor'),
              note: result.read<String>('note'),
              adjustmentId: result.readNullable<String>('adjustment_id'),
              voidedAt: result.readNullable<DateTime>('voided_at'),
            ),
        ],
      );

  Future<CheckpointRow?> read(String id) => (_db.select(
    _db.balanceCheckpoints,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<bool> hasCheckpoints(String accountId) async =>
      await (_db.select(_db.balanceCheckpoints)
            ..where((row) => row.accountId.equals(accountId))
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Future<bool> ownsAdjustment(String entryId) async =>
      await (_db.select(
        _db.balanceCheckpoints,
      )..where((row) => row.adjustmentId.equals(entryId))).getSingleOrNull() !=
      null;

  Future<void> insert(CheckpointRow row) =>
      _db.into(_db.balanceCheckpoints).insert(row);

  Future<void> setAdjustment(String id, String entryId, int bookMinor) =>
      (_db.update(
        _db.balanceCheckpoints,
      )..where((row) => row.id.equals(id))).write(
        BalanceCheckpointsCompanion(
          adjustmentId: Value(entryId),
          adjustedBookMinor: Value(bookMinor),
        ),
      );

  Future<void> voidCheckpoint(String id, DateTime at) =>
      (_db.update(_db.balanceCheckpoints)..where((row) => row.id.equals(id)))
          .write(BalanceCheckpointsCompanion(voidedAt: Value(at)));

  Future<List<Map<String, Object?>>> backup() async => [
    for (final row in await _db.select(_db.balanceCheckpoints).get())
      _backupRow(row),
  ];

  // Caller wraps the whole restore in the ledger transaction.
  Future<void> restore(List<Map<String, dynamic>> source) async {
    final ids = <String>{};
    for (final item in source) {
      final row = _restoreRow(item);
      if (!ids.add(row.id)) {
        throw const LedgerBackupException('备份包含重复的余额检查点');
      }
      final old = await read(row.id);
      if (old != null) {
        if (old != row) {
          throw const LedgerBackupException('备份与已有余额检查点冲突');
        }
        continue;
      }
      final account =
          await (_db.select(_db.ledgerAccounts)
                ..where((account) => account.id.equals(row.accountId)))
              .getSingleOrNull();
      if (account == null ||
          account.kind == 'familyDirect' ||
          account.currencyCode != row.currencyCode ||
          (row.adjustmentId != null &&
              await ownsAdjustment(row.adjustmentId!))) {
        throw const LedgerBackupException('备份的余额检查点关联无效');
      }
      if (row.adjustmentId case final id?) {
        final entry = await (_db.select(
          _db.ledgerEntries,
        )..where((entry) => entry.id.equals(id))).getSingleOrNull();
        if (entry == null) {
          throw const LedgerBackupException('备份的余额检查点缺少余额调整分录');
        }
      }
      await insert(row);
    }

    final conflict = await _db.customSelect("""
      SELECT 1
      FROM balance_checkpoints c
      JOIN ledger_accounts a ON a.id = c.account_id
      LEFT JOIN ledger_entries e ON e.id = c.adjustment_id
      WHERE a.currency_code <> c.currency_code OR a.kind = 'familyDirect'
        OR (c.adjustment_id IS NOT NULL AND (
          e.id IS NULL OR e.transaction_type <> 'adjustment' OR e.terms_json IS NOT NULL
            OR e.status <> 'posted' OR e.account_id <> c.account_id
            OR e.currency_code <> c.currency_code OR e.occurred_at <> c.observed_at
            OR e.is_deleted <> (c.voided_at IS NOT NULL)
            OR c.actual_minor <> c.adjusted_book_minor +
              e.amount_minor * CASE WHEN a.kind IN ('creditLine', 'thirdPartyPayable') THEN -1 ELSE 1 END
            OR EXISTS (SELECT 1 FROM ledger_entries r WHERE r.is_deleted = 0
              AND json_extract(r.terms_json, '\$.reversal_of_id') = e.id)
        )) LIMIT 1
    """).getSingleOrNull();
    if (conflict != null) {
      throw const LedgerBackupException('备份与余额检查点的账户或调整分录冲突');
    }
  }
}

Map<String, Object?> _backupRow(CheckpointRow row) => {
  'id': row.id,
  'account_id': row.accountId,
  'currency_code': row.currencyCode,
  'observed_at': row.observedAt.toUtc().toIso8601String(),
  'actual_minor': row.actualMinor,
  'recorded_book_minor': row.recordedBookMinor,
  'adjustment_id': row.adjustmentId,
  'adjusted_book_minor': row.adjustedBookMinor,
  'note': row.note,
  'created_at': row.createdAt.toUtc().toIso8601String(),
  'voided_at': row.voidedAt?.toUtc().toIso8601String(),
};

CheckpointRow _restoreRow(Map<String, dynamic> item) {
  if (item case {
    'id': String id,
    'account_id': String accountId,
    'currency_code': String currencyCode,
    'observed_at': String observed,
    'actual_minor': int actual,
    'recorded_book_minor': int book,
    'adjustment_id': String? adjustmentId,
    'adjusted_book_minor': int? adjustedBookMinor,
    'note': String note,
    'created_at': String created,
    'voided_at': String? voided,
  }) {
    final observedAt = DateTime.tryParse(observed)?.toLocal();
    final createdAt = DateTime.tryParse(created)?.toLocal();
    final voidedAt = voided == null
        ? null
        : DateTime.tryParse(voided)?.toLocal();
    if (id.isNotEmpty &&
        actual >= 0 &&
        observedAt != null &&
        createdAt != null &&
        (adjustmentId == null) == (adjustedBookMinor == null) &&
        !observedAt.isAfter(createdAt) &&
        (voided == null || voidedAt != null && !voidedAt.isBefore(createdAt))) {
      return CheckpointRow(
        id: id,
        accountId: accountId,
        currencyCode: currencyCode,
        observedAt: observedAt,
        actualMinor: actual,
        recordedBookMinor: book,
        adjustmentId: adjustmentId,
        adjustedBookMinor: adjustedBookMinor,
        note: note,
        createdAt: createdAt,
        voidedAt: voidedAt,
      );
    }
  }
  throw const LedgerBackupException('备份中的余额检查点字段无效');
}
