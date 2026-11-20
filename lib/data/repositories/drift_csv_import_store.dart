import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/defaults/default_ledger_names.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';

class DriftCsvImportStore {
  DriftCsvImportStore(this._db);
  final AppDatabase _db;

  Future<List<CsvReviewRow>> review(
    CsvImportFile file,
    Map<int, CsvMapping> overrides,
    List<ImportCategoryRule> rules,
  ) async {
    final valid = file.rows.where((row) => row.movement != null).toList();
    if (valid.isEmpty) {
      return [
        for (final row in file.rows) _unavailable(row, CsvReviewState.invalid),
      ];
    }
    final accounts = {
      for (final row in await _db.select(_db.ledgerAccounts).get()) row.id: row,
    };
    final categoryRows = await (_db.select(
      _db.ledgerCategories,
    )..where((row) => row.isArchived.equals(false))).get();
    final activeRows =
        await (_db.select(_db.csvImportRows)..where(
              (row) =>
                  row.active.equals(true) &
                  (row.fileRowKey.isIn(valid.map(file.rowKey)) |
                      row.sourceKey.isIn(
                        valid.map((item) => item.sourceKey).nonNulls,
                      ) |
                      row.signature.isIn(valid.map((item) => item.signature!))),
            ))
            .get();
    final byFile = {for (final row in activeRows) row.fileRowKey: row};
    final bySource = {
      for (final row in activeRows)
        if (row.sourceKey != null) row.sourceKey!: row,
    };
    final bySignature = <String, Set<String>>{};
    for (final row in activeRows) {
      (bySignature[row.signature] ??= {}).add(row.entryId);
    }
    final sourceSignatures = <String, Set<String>>{};
    for (final row in valid) {
      if (row.sourceKey case final key?) {
        (sourceSignatures[key] ??= {}).add(row.signature!);
      }
    }
    final movements = await _matchableEntries(valid);
    final byMovement = <_MovementKey, List<EntryRow>>{};
    final byId = <String, EntryRow>{};
    for (final entry in movements) {
      byId[entry.id] = entry;
      (byMovement[_keyForEntry(entry)] ??= []).add(entry);
    }

    final seenSources = <String>{};
    return [
      for (final row in file.rows)
        if (row.movement case final movement?)
          _reviewMovement(
            row,
            movement,
            file: file,
            overrides: overrides,
            rules: rules,
            accounts: accounts,
            categories: categoryRows,
            byFile: byFile,
            bySource: bySource,
            sourceSignatures: sourceSignatures,
            seenSources: seenSources,
            bySignature: bySignature,
            byMovement: byMovement,
            byId: byId,
          )
        else
          _unavailable(row, CsvReviewState.invalid),
    ];
  }

  CsvReviewRow _reviewMovement(
    CsvImportRow row,
    CsvMovement movement, {
    required CsvImportFile file,
    required Map<int, CsvMapping> overrides,
    required List<ImportCategoryRule> rules,
    required Map<String, AccountRow> accounts,
    required List<CategoryRow> categories,
    required Map<String, CsvImportRecord> byFile,
    required Map<String, CsvImportRecord> bySource,
    required Map<String, Set<String>> sourceSignatures,
    required Set<String> seenSources,
    required Map<String, Set<String>> bySignature,
    required Map<_MovementKey, List<EntryRow>> byMovement,
    required Map<String, EntryRow> byId,
  }) {
    final source = row.sourceKey;
    if (source != null &&
        (sourceSignatures[source]!.length > 1 ||
            bySource[source] != null &&
                bySource[source]!.signature != row.signature)) {
      return _unavailable(row, CsvReviewState.conflict);
    }
    if (byFile.containsKey(file.rowKey(row)) ||
        (source != null &&
            (bySource.containsKey(source) || !seenSources.add(source)))) {
      return _unavailable(row, CsvReviewState.duplicate);
    }

    bool usableAccount(AccountRow? account, {required bool target}) =>
        account != null &&
        !account.isArchived &&
        account.currencyCode == movement.currency &&
        csvAccountAllowed(
          movement.type,
          AccountKind.values.byName(account.kind),
          target: target,
        );
    String? guessAccount(String name, {required bool target}) {
      if (name.isEmpty) return null;
      final known = accounts.values
          .where(
            (account) =>
                usableAccount(account, target: target) &&
                (account.id == name ||
                    DefaultLedgerNames.accountMatches(
                      LedgerAccount(
                        id: account.id,
                        name: account.name,
                        kind: AccountKind.values.byName(account.kind),
                      ),
                      name,
                    )),
          )
          .toList();
      return known.length == 1 ? known.single.id : null;
    }

    final hasTarget = csvNeedsTarget(movement.type);
    final hasCategory = csvNeedsCategory(movement.type);
    final override = overrides[row.number];
    final categoryRows = hasCategory
        ? categories
              .where(
                (category) => category.transactionType == movement.type.name,
              )
              .toList()
        : const <CategoryRow>[];
    final activeParents = {
      for (final row in categoryRows)
        if (row.parentId == null) row.id: row,
    };
    final children = categoryRows
        .where((row) => activeParents.containsKey(row.parentId))
        .toList();
    final requestedAccount = override == null
        ? guessAccount(movement.account, target: false)
        : override.accountId;
    final requestedTarget = !hasTarget
        ? null
        : override == null
        ? guessAccount(movement.target, target: true)
        : override.targetId;
    final explicitCategory = hasCategory
        ? _guessCategory(movement.category, children, activeParents)
        : null;
    final eligible = children.map((child) => child.id).toSet();
    final suggestion =
        hasCategory && override == null && explicitCategory == null
        ? suggestImportCategory(
            rules: rules,
            fields: {
              ImportRuleField.merchant: row.raw['merchant'] ?? '',
              ImportRuleField.description: [
                ?row.raw['description'],
                row.raw['备注'] ?? movement.note,
              ].join('\n'),
              ImportRuleField.paymentChannel: row.raw['payment_channel'] ?? '',
              ImportRuleField.account:
                  accounts[requestedAccount]?.name ?? movement.account,
              ImportRuleField.source: row.raw['source'] ?? '',
            },
            eligibleCategories: eligible,
          )
        : null;
    final requestedCategory = override == null
        ? explicitCategory ?? suggestion?.categoryId
        : override.categoryId;
    final mapping = (
      accountId: usableAccount(accounts[requestedAccount], target: false)
          ? requestedAccount
          : null,
      targetId: usableAccount(accounts[requestedTarget], target: true)
          ? requestedTarget
          : null,
      categoryId: children.any((row) => row.id == requestedCategory)
          ? requestedCategory
          : null,
    );
    final accountsResolved =
        mapping.accountId != null &&
        (!hasTarget ||
            mapping.targetId != null && mapping.targetId != mapping.accountId);
    final candidates = mapping.accountId == null
        ? const <EntryRow>[]
        : byMovement[_keyForMovement(movement, mapping)] ?? const <EntryRow>[];
    final candidateIds = candidates.map((entry) => entry.id).toSet();
    final exactSource = bySignature[row.signature] ?? const <String>{};
    final matches = [
      for (final id in {...exactSource, ...candidateIds})
        if (byId[id] case final entry?)
          (
            id: entry.id,
            occurredAt: entry.occurredAt,
            accountName: accounts[entry.accountId]?.name ?? entry.accountId,
            targetName: accounts[entry.targetAccountId]?.name,
            note: entry.note,
            sameSourceRow: exactSource.contains(id),
            canLink: candidateIds.contains(id),
          ),
    ];
    final state = !accountsResolved
        ? CsvReviewState.unresolved
        : candidates.isNotEmpty
        ? CsvReviewState.similar
        : hasCategory && mapping.categoryId == null
        ? CsvReviewState.unresolved
        : exactSource.isNotEmpty
        ? CsvReviewState.similar
        : CsvReviewState.ready;
    return (
      row: row,
      state: state,
      mapping: mapping,
      matches: matches,
      suggestion: suggestion,
    );
  }

  Future<List<EntryRow>> _matchableEntries(List<CsvImportRow> rows) async {
    final minutes = rows
        .map((row) => _minute(row.movement!.occurredAt))
        .toSet();
    final seconds = minutes.map((minute) => minute * 60).toList()..sort();
    final result = await _db
        .customSelect(
          """
      SELECT e.* FROM ledger_entries e
      WHERE e.is_deleted = 0 AND e.status = 'posted'
        AND e.occurred_at >= ? AND e.occurred_at < ?
        AND e.refund_of_id IS NULL AND e.terms_json IS NULL
        AND e.settlement_amount_minor IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM ledger_postings p WHERE p.transaction_id = e.id AND p.needs_review = 1
        )
        AND (e.transaction_type <> 'expense' OR (
          SELECT COUNT(*) FROM ledger_postings p WHERE p.transaction_id = e.id AND p.account_id IS NOT NULL
        ) = 1)
        AND NOT EXISTS (
          SELECT 1 FROM ledger_entries r WHERE r.is_deleted = 0 AND
            json_extract(r.terms_json, '\$.reversal_of_id') = e.id
        )
      ORDER BY e.occurred_at DESC, e.id
    """,
          variables: [
            Variable.withInt(seconds.first),
            Variable.withInt(seconds.last + 60),
          ],
        )
        .get();
    return [
      for (final row in result)
        if (minutes.contains(_minute(row.read<DateTime>('occurred_at'))))
          _db.ledgerEntries.map(row.data),
    ];
  }

  Future<void> insertBatch(CsvBatchRecord batch) =>
      _db.into(_db.csvImportBatches).insert(batch);
  Future<void> insertRow(CsvImportRecord row) =>
      _db.into(_db.csvImportRows).insert(row);
  Future<CsvBatchRecord?> readBatch(String id) => (_db.select(
    _db.csvImportBatches,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
  Future<List<CsvImportRecord>> readRows(String id) =>
      (_db.select(_db.csvImportRows)
            ..where((row) => row.batchId.equals(id))
            ..orderBy([(row) => OrderingTerm.asc(row.rowNumber)]))
          .get();

  Future<bool> hasOtherLink(String entryId, String batchId) async =>
      await (_db.select(_db.csvImportRows)
            ..where(
              (row) =>
                  row.entryId.equals(entryId) &
                  row.batchId.equals(batchId).not() &
                  row.active.equals(true),
            )
            ..limit(1))
          .getSingleOrNull() !=
      null;

  Future<void> markUndone(String id, DateTime at) async {
    await (_db.update(_db.csvImportRows)
          ..where((row) => row.batchId.equals(id)))
        .write(const CsvImportRowsCompanion(active: Value(false)));
    await (_db.update(_db.csvImportBatches)..where((row) => row.id.equals(id)))
        .write(CsvImportBatchesCompanion(undoneAt: Value(at)));
  }

  Stream<List<CsvBatchSummary>> watchBatches() => _db
      .customSelect(
        """
    SELECT b.id, b.name, b.created_at, b.undone_at, COUNT(r.snapshot) AS added,
      COUNT(r.row_number) - COUNT(r.snapshot) AS matched
    FROM csv_import_batches b JOIN csv_import_rows r ON r.batch_id = b.id
    GROUP BY b.id ORDER BY b.created_at DESC, b.id DESC
  """,
        readsFrom: {_db.csvImportBatches, _db.csvImportRows},
      )
      .watch()
      .map(
        (result) => [
          for (final row in result)
            (
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              createdAt: row.read<DateTime>('created_at'),
              undoneAt: row.readNullable<DateTime>('undone_at'),
              added: row.read<int>('added'),
              matched: row.read<int>('matched'),
            ),
        ],
      );

  Future<List<CsvBatchItem>> items(String id) async => [
    for (final row in await readRows(id))
      (
        line: row.line,
        entryId: row.entryId,
        created: row.snapshot != null,
        raw: _rawCells(row.rawJson),
      ),
  ];

  Future<Map<String, Object>> backup() async => {
    'batches': [
      for (final row in await _db.select(_db.csvImportBatches).get())
        {
          'id': row.id,
          'name': row.name,
          'fingerprint': row.fingerprint,
          'created_at': row.createdAt.toUtc().toIso8601String(),
          'undone_at': row.undoneAt?.toUtc().toIso8601String(),
        },
    ],
    'rows': [
      for (final row in await _db.select(_db.csvImportRows).get())
        {
          'batch_id': row.batchId,
          'row_number': row.rowNumber,
          'line': row.line,
          'file_row_key': row.fileRowKey,
          'source_key': row.sourceKey,
          'signature': row.signature,
          'raw': _rawCells(row.rawJson),
          'entry_id': row.entryId,
          'snapshot': row.snapshot,
          'active': row.active,
        },
    ],
  };

  Future<void> restore(
    List<Map<String, dynamic>> batches,
    List<Map<String, dynamic>> rows,
  ) async {
    final known = <String, CsvBatchRecord>{};
    for (final raw in batches) {
      final batch = _restoreBatch(raw);
      if (known.containsKey(batch.id)) throw _conflict;
      known[batch.id] = batch;
      final existing = await readBatch(batch.id);
      if (existing == null) {
        await insertBatch(batch);
      } else if (existing != batch) {
        throw _conflict;
      }
    }
    final rowNumbers = <String, Set<int>>{};
    final currentRows = <String, Map<int, CsvImportRecord>>{};
    final knownEntries = <String>{};
    for (final raw in rows) {
      final row = _restoreRow(raw, known);
      if (!(rowNumbers[row.batchId] ??= {}).add(row.rowNumber)) throw _conflict;
      final batchRows = currentRows[row.batchId] ??= {
        for (final row in await readRows(row.batchId)) row.rowNumber: row,
      };
      final existing = batchRows[row.rowNumber];
      if (existing != null) {
        if (existing != row) throw _conflict;
        continue;
      }
      if (knownEntries.add(row.entryId)) {
        final entry = await (_db.select(
          _db.ledgerEntries,
        )..where((entry) => entry.id.equals(row.entryId))).getSingleOrNull();
        if (entry == null) throw _conflict;
      }
      if (row.active) {
        final same =
            await (_db.select(_db.csvImportRows)
                  ..where(
                    (item) =>
                        item.active.equals(true) &
                        (item.fileRowKey.equals(row.fileRowKey) |
                            (row.sourceKey == null
                                ? const Constant(false)
                                : item.sourceKey.equals(row.sourceKey!))),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (same != null) throw _conflict;
      }
      await insertRow(row);
    }
    if (known.keys.any(
      (id) =>
          !(rowNumbers[id]?.containsAll(currentRows[id]?.keys ?? []) ?? false),
    )) {
      throw _conflict;
    }
    final restoredUndoneEntry = await _db.customSelect("""
      SELECT 1 FROM csv_import_rows r JOIN ledger_entries e ON e.id = r.entry_id
      WHERE r.active = 0 AND r.snapshot IS NOT NULL AND e.is_deleted = 0 LIMIT 1
    """).getSingleOrNull();
    if (restoredUndoneEntry != null) throw _conflict;
  }
}

String? _guessCategory(
  String name,
  List<CategoryRow> children,
  Map<String, CategoryRow> parents,
) {
  if (name.isEmpty) return null;
  bool matches(CategoryRow row, String value) =>
      row.id == value ||
      DefaultLedgerNames.categoryMatches(
        LedgerCategory(id: row.id, name: row.name, parentId: row.parentId),
        value,
      );
  final parts = name.split('/').map((part) => part.trim()).toList();
  final choices = children
      .where(
        (row) =>
            row.id == name ||
            (matches(row, parts.last) &&
                (parts.length == 1 ||
                    parts.length == 2 &&
                        matches(parents[row.parentId]!, parts.first))),
      )
      .toList();
  return choices.length == 1 ? choices.single.id : null;
}

typedef _MovementKey = (String, int, int, String, String?, String?);
int _minute(DateTime time) {
  final milliseconds = time.millisecondsSinceEpoch;
  return (milliseconds - milliseconds % 60000) ~/ 60000;
}

_MovementKey _keyForEntry(EntryRow entry) => (
  entry.transactionType,
  entry.amountMinor,
  _minute(entry.occurredAt),
  entry.currencyCode,
  entry.accountId,
  entry.targetAccountId,
);
_MovementKey _keyForMovement(CsvMovement movement, CsvMapping mapping) => (
  movement.type.name,
  movement.amountMinor,
  _minute(movement.occurredAt),
  movement.currency,
  mapping.accountId,
  mapping.targetId,
);
CsvReviewRow _unavailable(CsvImportRow row, CsvReviewState state) => (
  row: row,
  state: state,
  mapping: (accountId: null, categoryId: null, targetId: null),
  matches: const [],
  suggestion: null,
);

Map<String, String> _rawCells(String json) =>
    (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();

const _conflict = LedgerBackupException('备份中的 CSV 导入批次无效或与现有批次冲突');
bool _isDigest(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

CsvBatchRecord _restoreBatch(Map<String, dynamic> raw) {
  if (raw case {
    'id': String id,
    'name': String name,
    'fingerprint': String fingerprint,
    'created_at': String created,
    'undone_at': String? undone,
  }) {
    final date = DateTime.tryParse(created)?.toLocal();
    final end = undone == null ? null : DateTime.tryParse(undone)?.toLocal();
    if (id.isNotEmpty &&
        name.isNotEmpty &&
        _isDigest(fingerprint) &&
        date != null &&
        (undone == null || end != null && !end.isBefore(date))) {
      return CsvBatchRecord(
        id: id,
        name: name,
        fingerprint: fingerprint,
        createdAt: date,
        undoneAt: end,
      );
    }
  }
  throw _conflict;
}

CsvImportRecord _restoreRow(
  Map<String, dynamic> raw,
  Map<String, CsvBatchRecord> batches,
) {
  if (raw case {
    'batch_id': String batchId,
    'row_number': int number,
    'line': int line,
    'file_row_key': String rowKey,
    'source_key': String? sourceKey,
    'signature': String signature,
    'raw': Map<String, dynamic> cells,
    'entry_id': String entryId,
    'snapshot': String? snapshot,
    'active': bool active,
  }) {
    final batch = batches[batchId];
    if (batch != null &&
        number >= 1 &&
        number <= maxCsvImportRows &&
        line > 1 &&
        cells.values.every((value) => value is String) &&
        (snapshot == null || _isDigest(snapshot)) &&
        active == (batch.undoneAt == null)) {
      final parsed = CsvImportRow.fromCells(
        number,
        line,
        cells.cast<String, String>(),
      );
      if (parsed.movement != null &&
          sourceKey == parsed.sourceKey &&
          signature == parsed.signature &&
          rowKey == csvDigest([batch.fingerprint, number])) {
        return CsvImportRecord(
          batchId: batchId,
          rowNumber: number,
          line: line,
          fileRowKey: rowKey,
          sourceKey: sourceKey,
          signature: signature,
          rawJson: csvRawCellsJson(cells.cast<String, String>()),
          entryId: entryId,
          snapshot: snapshot,
          active: active,
        );
      }
    }
  }
  throw _conflict;
}
