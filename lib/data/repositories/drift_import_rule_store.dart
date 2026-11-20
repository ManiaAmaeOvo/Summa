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
    final row = ImportCategoryRuleRow(
      id: rule.id,
      field: rule.field.name,
      keyword: rule.keyword.trim(),
      categoryId: rule.categoryId,
      priority: rule.priority,
      enabled: rule.enabled,
    );
    if (!_valid(row) ||
        !await _validCategory(row.categoryId, activeOnly: true)) {
      throw ArgumentError('Invalid import classification rule');
    }
    await _db.into(_db.importCategoryRules).insertOnConflictUpdate(row);
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
        'field': row.field,
        'keyword': row.keyword,
        'category_id': row.categoryId,
        'priority': row.priority,
        'enabled': row.enabled,
      },
  ];

  Future<void> restore(List<Map<String, dynamic>> source) async {
    final ids = <String>{};
    for (final item in source) {
      if (item case {
        'id': String id,
        'field': String field,
        'keyword': String keyword,
        'category_id': String category,
        'priority': int priority,
        'enabled': bool enabled,
      }) {
        final row = ImportCategoryRuleRow(
          id: id,
          field: field,
          keyword: keyword,
          categoryId: category,
          priority: priority,
          enabled: enabled,
        );
        if (!ids.add(id) ||
            !_valid(row) ||
            !await _validCategory(category, activeOnly: false)) {
          throw _conflict;
        }
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

bool _valid(ImportCategoryRuleRow rule) =>
    rule.id.isNotEmpty &&
    rule.keyword.trim().isNotEmpty &&
    rule.keyword.length <= 80 &&
    rule.priority >= 0 &&
    rule.priority <= 9999 &&
    ImportRuleField.values.any((field) => field.name == rule.field);

ImportCategoryRule _domain(ImportCategoryRuleRow row) => ImportCategoryRule(
  id: row.id,
  field: ImportRuleField.values.byName(row.field),
  keyword: row.keyword,
  categoryId: row.categoryId,
  priority: row.priority,
  enabled: row.enabled,
);
