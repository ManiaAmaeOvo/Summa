import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';

class DriftImportRuleStore {
  DriftImportRuleStore(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$ImportCategoryRulesTable, ImportCategoryRuleRow>
  _sorted() => _db.select(_db.importCategoryRules)
    ..orderBy([
      (row) => OrderingTerm.asc(row.priority),
      (row) => OrderingTerm.asc(row.id),
    ]);

  Future<List<ImportCategoryRule>> read() async =>
      (await _sorted().get()).map(_domain).toList();

  Stream<List<ImportCategoryRule>> watch() =>
      _sorted().watch().map((rows) => rows.map(_domain).toList());

  Future<void> save(ImportCategoryRule rule) async {
    if (rule.id.isEmpty ||
        !rule.isValid ||
        !await _validCategory(rule.categoryId, activeOnly: true)) {
      throw ArgumentError('Invalid import classification rule');
    }
    await _db.into(_db.importCategoryRules).insertOnConflictUpdate(_row(rule));
  }

  Future<void> delete(String id) => (_db.delete(
    _db.importCategoryRules,
  )..where((row) => row.id.equals(id))).go();

  Future<bool> _validCategory(String id, {required bool activeOnly}) async {
    final categories = _db.ledgerCategories;
    final child = await (_db.select(
      categories,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (child == null ||
        child.parentId == null ||
        (activeOnly && child.isArchived) ||
        !{'expense', 'income'}.contains(child.transactionType)) {
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

  Future<List<Map<String, Object>>> backup() async => [
    for (final row in await _sorted().get())
      {
        'id': row.id,
        if (row.conditionsJson case final json?)
          ...((jsonDecode(json) as Map).cast<String, Object>())
        else ...{
          'field': row.field,
          'keyword': row.keyword,
        },
        'category_id': row.categoryId,
        'priority': row.priority,
        'enabled': row.enabled,
      },
  ];

  Future<void> restore(
    List<Map<String, dynamic>> source, {
    required bool advanced,
  }) async {
    final ids = <String>{};
    for (final item in source) {
      if (item case {
        'id': String id,
        'category_id': String category,
        'priority': int priority,
        'enabled': bool enabled,
      }) {
        final hasConditions =
            item.containsKey('conditions') || item.containsKey('match_mode');
        final predicate = hasConditions
            ? advanced
                  ? _predicate(item)
                  : null
            : _legacyPredicate(item['field'], item['keyword']);
        if (predicate == null || id.isEmpty || !ids.add(id)) {
          throw _conflict;
        }
        final rule = ImportCategoryRule(
          id: id,
          categoryId: category,
          priority: priority,
          enabled: enabled,
          conditions: predicate.conditions,
          mode: predicate.mode,
        );
        if (!rule.isValid ||
            !await _validCategory(category, activeOnly: false)) {
          throw _conflict;
        }
        final row = _row(rule);
        final old = await (_db.select(
          _db.importCategoryRules,
        )..where((row) => row.id.equals(id))).getSingleOrNull();
        if (old == null) {
          await _db.into(_db.importCategoryRules).insert(row);
        } else if (old != row) {
          throw _conflict;
        }
      } else {
        throw _conflict;
      }
    }
  }
}

const _conflict = LedgerBackupException('备份中的导入分类规则无效或存在冲突');

typedef _Predicate = ({
  ImportRuleMode mode,
  List<ImportRuleCondition> conditions,
});

_Predicate? _legacyPredicate(Object? field, Object? keyword) {
  if (field is! String || keyword is! String) return null;
  final condition = ImportRuleCondition.fromJson({
    'field': field,
    'operator': 'contains',
    'value': keyword,
  });
  return condition == null
      ? null
      : (mode: ImportRuleMode.all, conditions: [condition]);
}

_Predicate? _predicate(Object? source) {
  if (source case {'match_mode': String value, 'conditions': List items}) {
    final mode = ImportRuleMode.values.asNameMap()[value];
    if (mode == null || items.isEmpty) return null;
    final conditions = <ImportRuleCondition>[];
    for (final item in items) {
      final condition = ImportRuleCondition.fromJson(item);
      if (condition == null) return null;
      conditions.add(condition);
    }
    return (mode: mode, conditions: conditions);
  }
  return null;
}

ImportCategoryRuleRow _row(ImportCategoryRule rule) {
  final first = rule.conditions.first;
  final legacy =
      rule.conditions.length == 1 &&
      rule.mode == ImportRuleMode.all &&
      first.operator == ImportRuleOperator.contains;
  return ImportCategoryRuleRow(
    id: rule.id,
    field: first.field.name,
    keyword: first.value,
    conditionsJson: legacy
        ? null
        : jsonEncode({
            'match_mode': rule.mode.name,
            'conditions': rule.conditions
                .map((condition) => condition.toJson())
                .toList(),
          }),
    categoryId: rule.categoryId,
    priority: rule.priority,
    enabled: rule.enabled,
  );
}

ImportCategoryRule _domain(ImportCategoryRuleRow row) {
  final json = row.conditionsJson;
  final predicate = json == null
      ? _legacyPredicate(row.field, row.keyword)
      : _predicate(jsonDecode(json));
  if (predicate == null) throw const FormatException('Invalid import rule');
  return ImportCategoryRule(
    id: row.id,
    categoryId: row.categoryId,
    priority: row.priority,
    enabled: row.enabled,
    mode: predicate.mode,
    conditions: List.unmodifiable(predicate.conditions),
  );
}
