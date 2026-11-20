import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ledger_postings_sql.dart';

part 'app_database.g.dart';

@DataClassName('AccountRow')
class LedgerAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('CNY'))();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class LedgerCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get transactionType =>
      text().withDefault(const Constant('expense'))();
  TextColumn get parentId =>
      text().nullable().references(LedgerCategories, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryRow')
class LedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionType => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('CNY'))();
  DateTimeColumn get occurredAt => dateTime()();
  IntColumn get timezoneOffsetMinutes => integer()();
  TextColumn get categoryId => text().references(LedgerCategories, #id)();
  TextColumn get accountId => text().references(LedgerAccounts, #id)();
  @ReferenceName('targetLedgerEntries')
  TextColumn get targetAccountId =>
      text().nullable().references(LedgerAccounts, #id)();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()
      .withDefault(const Constant('posted'))
      .check(const CustomExpression<bool>("status IN ('posted', 'pending')"))();
  TextColumn get refundOfId =>
      text().nullable().references(LedgerEntries, #id)();
  IntColumn get settlementAmountMinor => integer().nullable()();
  TextColumn get settlementCurrencyCode => text().nullable()();
  TextColumn get quotedExchangeRate => text().nullable()();
  TextColumn get termsJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PostingRow')
class LedgerPostings extends Table {
  TextColumn get transactionId =>
      text().references(LedgerEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get accountId =>
      text().nullable().references(LedgerAccounts, #id)();
  TextColumn get currencyCode => text()();
  IntColumn get debitMinor => integer()();
  TextColumn get role => text()();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, position};
}

@DataClassName('ValuationBaseRow')
class ValuationPreferences extends Table {
  IntColumn get id => integer().check(const CustomExpression<bool>('id = 1'))();
  TextColumn get baseCurrency => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ValuationRateRow')
class ValuationRates extends Table {
  TextColumn get baseCurrency => text()();
  TextColumn get sourceCurrency => text()();
  TextColumn get rate => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {baseCurrency, sourceCurrency};
}

@DataClassName('CheckpointRow')
class BalanceCheckpoints extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(LedgerAccounts, #id)();
  TextColumn get currencyCode => text()();
  DateTimeColumn get observedAt => dateTime()();
  IntColumn get actualMinor =>
      integer().check(const CustomExpression<bool>('actual_minor >= 0'))();
  IntColumn get recordedBookMinor => integer()();
  TextColumn get adjustmentId =>
      text().nullable().unique().references(LedgerEntries, #id)();
  IntColumn get adjustedBookMinor => integer().nullable()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get voidedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CsvBatchRecord')
class CsvImportBatches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get fingerprint => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get undoneAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CsvImportRecord')
class CsvImportRows extends Table {
  TextColumn get batchId =>
      text().references(CsvImportBatches, #id, onDelete: KeyAction.cascade)();
  IntColumn get rowNumber => integer()();
  IntColumn get line => integer()();
  TextColumn get fileRowKey => text()();
  TextColumn get sourceKey => text().nullable()();
  TextColumn get signature => text()();
  TextColumn get rawJson => text()();
  TextColumn get entryId => text().references(LedgerEntries, #id)();
  TextColumn get snapshot => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {batchId, rowNumber};
}

@DataClassName('ImportCategoryRuleRow')
class ImportCategoryRules extends Table {
  TextColumn get id => text()();
  TextColumn get field => text()();
  TextColumn get keyword => text()();
  TextColumn get categoryId => text().references(LedgerCategories, #id)();
  IntColumn get priority => integer()();
  BoolColumn get enabled => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SpendingPlanRow')
class SpendingPlans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  TextColumn get scope => text()();
  IntColumn get limitMinor => integer()();
  TextColumn get startsOn => text()();
  TextColumn get endsOn => text().nullable()();
  BoolColumn get rollover => boolean()();
  BoolColumn get archived => boolean()();
  TextColumn get accountId =>
      text().nullable().references(LedgerAccounts, #id)();
  TextColumn get categoryId =>
      text().nullable().references(LedgerCategories, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SpendingPlanLimitRow')
class SpendingPlanLimits extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(SpendingPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get periodStart => text()();
  IntColumn get limitMinor => integer()();
  BoolColumn get ongoing => boolean()();
  IntColumn get savedAtMicros => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LedgerAccounts,
    LedgerCategories,
    LedgerEntries,
    LedgerPostings,
    ValuationPreferences,
    ValuationRates,
    BalanceCheckpoints,
    CsvImportBatches,
    CsvImportRows,
    ImportCategoryRules,
    SpendingPlans,
    SpendingPlanLimits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => transaction(() async {
      await migrator.createAll();
      await _createPostingIndexes();
      await _createReversalIndex();
      await _createCheckpointIndex();
      await _createCsvIndexes();
      await _createSpendingPlanIndex();
      await _seedDefaults();
      await customStatement('PRAGMA user_version = $schemaVersion');
    }),
    onUpgrade: (migrator, from, to) async {
      if (from > to) {
        throw UnsupportedError(
          'Cannot open ledger schema $from with schema $to',
        );
      }
      await transaction(() async {
        if (from < 2) await _addVersion2Defaults();
        if (from < 3) await _addVersion3Defaults();
        if (from < 4) {
          await migrator.addColumn(ledgerEntries, ledgerEntries.isDeleted);
        }
        if (from < 5) {
          await migrator.addColumn(
            ledgerEntries,
            ledgerEntries.targetAccountId,
          );
          await _addVersion5Categories();
        }
        if (from < 6) await ensureTransferCategory();
        if (from < 8) {
          if (from == 7) {
            await customStatement('DROP VIEW ledger_postings');
            await customStatement('DROP VIEW ledger_account_postings');
            await customStatement('DROP INDEX ledger_entries_active_account');
            await customStatement('DROP INDEX ledger_entries_active_target');
          }
          await migrator.addColumn(ledgerEntries, ledgerEntries.status);
          await migrator.addColumn(ledgerEntries, ledgerEntries.refundOfId);
          await migrator.createTable(ledgerPostings);
          await _createPostingIndexes();
          await backfillLegacyPostings();
        }
        if (from < 9) {
          await migrator.addColumn(
            ledgerEntries,
            ledgerEntries.settlementAmountMinor,
          );
          await migrator.addColumn(
            ledgerEntries,
            ledgerEntries.settlementCurrencyCode,
          );
          await migrator.addColumn(
            ledgerEntries,
            ledgerEntries.quotedExchangeRate,
          );
        }
        if (from < 10) {
          await migrator.createTable(valuationPreferences);
          await migrator.createTable(valuationRates);
        }
        if (from < 12) {
          await migrator.addColumn(ledgerEntries, ledgerEntries.termsJson);
          await _createReversalIndex();
        }
        if (from < 13) {
          await migrator.createTable(balanceCheckpoints);
          await _createCheckpointIndex();
        }
        if (from < 14) {
          await migrator.createTable(csvImportBatches);
          await migrator.createTable(csvImportRows);
          await _createCsvIndexes();
        }
        if (from < 15) {
          await migrator.createTable(importCategoryRules);
        }
        if (from < 16) {
          await migrator.createTable(spendingPlans);
          await migrator.createTable(spendingPlanLimits);
          await _createSpendingPlanIndex();
        }
        // Drift updates the version after this callback. Set it in the same
        // transaction as the schema so an interrupted open cannot replay DDL.
        await customStatement('PRAGMA user_version = $to');
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createPostingIndexes() async {
    await customStatement('''
      CREATE INDEX ledger_postings_account ON ledger_postings (account_id, transaction_id)
      WHERE account_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE INDEX ledger_entries_refund_of ON ledger_entries (refund_of_id)
      WHERE refund_of_id IS NOT NULL
    ''');
  }

  Future<void> _createReversalIndex() => customStatement("""
    CREATE UNIQUE INDEX ledger_entries_active_reversal
    ON ledger_entries (json_extract(terms_json, '\$.reversal_of_id'))
    WHERE is_deleted = 0 AND json_extract(terms_json, '\$.reversal_of_id') IS NOT NULL
  """);

  Future<void> _createCheckpointIndex() => customStatement('''
    CREATE INDEX balance_checkpoints_account_date
    ON balance_checkpoints (account_id, observed_at DESC)
  ''');

  Future<void> _createSpendingPlanIndex() => customStatement('''
    CREATE INDEX spending_plan_limits_plan ON spending_plan_limits (plan_id)
  ''');

  Future<void> _createCsvIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX csv_import_rows_active_file ON csv_import_rows (file_row_key)
      WHERE active = 1
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX csv_import_rows_active_source ON csv_import_rows (source_key)
      WHERE active = 1 AND source_key IS NOT NULL
    ''');
    await customStatement('''
      CREATE INDEX csv_import_rows_active_signature ON csv_import_rows (signature)
      WHERE active = 1
    ''');
    await customStatement('''
      CREATE INDEX csv_import_rows_entry ON csv_import_rows (entry_id)
    ''');
  }

  Future<void> backfillLegacyPostings() =>
      customInsert(insertLegacyPostings, updates: {ledgerPostings});

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(ledgerAccounts, [
        _account('account-cash', '现金', 'cash', 0, now),
        _account('account-bank', '银行卡', 'bank', 1, now),
        _account('account-alipay', '支付宝', 'wallet', 2, now),
        _account('account-wechat', '微信', 'wallet', 3, now),
        _account('account-huabei', '花呗', 'creditLine', 4, now),
        _account('account-jd-baitiao', '白条', 'creditLine', 5, now),
        _account('account-douyin-pay', '抖音月付', 'creditLine', 6, now),
        _account('account-meituan-pay', '美团月付', 'creditLine', 7, now),
        _account('account-family-card', '亲情卡', 'entrustedFunds', 8, now),
      ]);

      const categoryGroups = <String, List<String>>{
        '饮食': ['早餐', '午餐', '晚餐', '零食饮料', '食材', '其他'],
        '交通': ['公交地铁', '网约车', '骑行', '长途交通', '其他'],
        '日用': ['生活用品', '衣物', '数码', '医疗健康', '其他'],
        '娱乐': ['游戏', '影音', '社交', '旅行', '其他'],
        '其他': ['未分类'],
      };
      var parentOrder = 0;
      for (final group in categoryGroups.entries) {
        final parentId = 'expense-parent-$parentOrder';
        batch.insert(
          ledgerCategories,
          _category(parentId, group.key, null, parentOrder * 100, now),
        );
        for (
          var childOrder = 0;
          childOrder < group.value.length;
          childOrder++
        ) {
          batch.insert(
            ledgerCategories,
            _category(
              '$parentId-child-$childOrder',
              group.value[childOrder],
              parentId,
              parentOrder * 100 + childOrder,
              now,
            ),
          );
        }
        parentOrder++;
      }
      _insertIncomeAndFlowCategories(batch, now);
    });
  }

  Future<void> resetLedgerData() async {
    await transaction(() async {
      await delete(csvImportBatches).go();
      await delete(balanceCheckpoints).go();
      await delete(ledgerEntries).go();
      await (delete(
        spendingPlans,
      )..where((row) => row.accountId.isNotNull())).go();
      await delete(ledgerAccounts).go();
      final now = DateTime.now();
      await batch((batch) {
        for (final item in defaultAccounts) {
          batch.insert(
            ledgerAccounts,
            _account(item.id, item.name, item.kind, item.sortOrder, now),
          );
        }
      });
    });
  }

  Future<void> resetToFactoryDefaults() async {
    await transaction(() async {
      await delete(valuationPreferences).go();
      await delete(valuationRates).go();
      await delete(csvImportBatches).go();
      await delete(balanceCheckpoints).go();
      await delete(ledgerEntries).go();
      await delete(importCategoryRules).go();
      await delete(spendingPlans).go();
      await delete(ledgerCategories).go();
      await delete(ledgerAccounts).go();
      await _seedDefaults();
    });
  }

  Future<void> _addVersion2Defaults() async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insert(
        ledgerAccounts,
        _account('account-family-card', '亲情卡', 'entrustedFunds', 5, now),
        mode: InsertMode.insertOrIgnore,
      );
      const otherChildren = <(String, int)>[
        ('expense-parent-0', 5),
        ('expense-parent-1', 4),
        ('expense-parent-2', 4),
        ('expense-parent-3', 4),
      ];
      for (final (parentId, childOrder) in otherChildren) {
        batch.insert(
          ledgerCategories,
          _category(
            '$parentId-child-$childOrder',
            '其他',
            parentId,
            int.parse(parentId.split('-').last) * 100 + childOrder,
            now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> _addVersion3Defaults() async {
    final now = DateTime.now();
    await transaction(() async {
      await (update(ledgerAccounts)
            ..where((table) => table.id.equals('account-family-card')))
          .write(const LedgerAccountsCompanion(sortOrder: Value(8)));
      await batch((batch) {
        batch.insert(
          ledgerAccounts,
          _account('account-jd-baitiao', '白条', 'creditLine', 5, now),
          mode: InsertMode.insertOrIgnore,
        );
        batch.insert(
          ledgerAccounts,
          _account('account-douyin-pay', '抖音月付', 'creditLine', 6, now),
          mode: InsertMode.insertOrIgnore,
        );
        batch.insert(
          ledgerAccounts,
          _account('account-meituan-pay', '美团月付', 'creditLine', 7, now),
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  Future<void> _addVersion5Categories() async {
    final now = DateTime.now();
    await batch((batch) => _insertIncomeAndFlowCategories(batch, now));
  }

  Future<void> ensureReceivableCategories() async {
    final now = DateTime.now();
    const categories = [
      ('lending', '借出'),
      ('advance', '垫付'),
      ('collection', '收回本金'),
      ('reimbursement', '报销到账'),
    ];
    await batch((batch) {
      for (final (index, (type, label)) in categories.indexed) {
        final id = 'flow-$type';
        final order = 2300 + index * 100;
        batch.insert(
          ledgerCategories,
          _category(
            '$id-parent',
            label,
            null,
            order,
            now,
            transactionType: type,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        batch.insert(
          ledgerCategories,
          _category(
            id,
            label,
            '$id-parent',
            order + 1,
            now,
            transactionType: type,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> ensureTransferCategory() async {
    final now = DateTime.now();
    await batch((batch) => _insertTransferCategories(batch, now));
  }

  void _insertIncomeAndFlowCategories(Batch batch, DateTime now) {
    const incomeGroups = <String, List<String>>{
      '劳动所得': ['工资', '兼职', '其他'],
      '家庭支持': ['生活费', '亲属赠予', '采购结余', '其他'],
      '退款报销': ['退款', '报销', '其他'],
      '其他收入': ['礼金', '投资收益', '未分类'],
    };
    var parentOrder = 0;
    for (final group in incomeGroups.entries) {
      final parentId = 'income-parent-$parentOrder';
      batch.insert(
        ledgerCategories,
        _category(
          parentId,
          group.key,
          null,
          1000 + parentOrder * 100,
          now,
          transactionType: 'income',
        ),
        mode: InsertMode.insertOrIgnore,
      );
      for (var childOrder = 0; childOrder < group.value.length; childOrder++) {
        batch.insert(
          ledgerCategories,
          _category(
            '$parentId-child-$childOrder',
            group.value[childOrder],
            parentId,
            1000 + parentOrder * 100 + childOrder,
            now,
            transactionType: 'income',
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      parentOrder++;
    }
    batch.insert(
      ledgerCategories,
      _category(
        'flow-borrowing-parent',
        '借入',
        null,
        2000,
        now,
        transactionType: 'borrowing',
      ),
      mode: InsertMode.insertOrIgnore,
    );
    batch.insert(
      ledgerCategories,
      _category(
        'flow-borrowing',
        '借入资金',
        'flow-borrowing-parent',
        2001,
        now,
        transactionType: 'borrowing',
      ),
      mode: InsertMode.insertOrIgnore,
    );
    batch.insert(
      ledgerCategories,
      _category(
        'flow-repayment-parent',
        '还款',
        null,
        2100,
        now,
        transactionType: 'repayment',
      ),
      mode: InsertMode.insertOrIgnore,
    );
    batch.insert(
      ledgerCategories,
      _category(
        'flow-repayment',
        '偿还负债',
        'flow-repayment-parent',
        2101,
        now,
        transactionType: 'repayment',
      ),
      mode: InsertMode.insertOrIgnore,
    );
    _insertTransferCategories(batch, now);
  }

  void _insertTransferCategories(Batch batch, DateTime now) {
    batch.insert(
      ledgerCategories,
      _category(
        'flow-transfer-parent',
        '转账',
        null,
        2200,
        now,
        transactionType: 'transfer',
      ),
      mode: InsertMode.insertOrIgnore,
    );
    batch.insert(
      ledgerCategories,
      _category(
        'flow-transfer',
        '账户间转账',
        'flow-transfer-parent',
        2201,
        now,
        transactionType: 'transfer',
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  static const defaultAccounts =
      <({String id, String name, String kind, int sortOrder})>[
        (id: 'account-cash', name: '现金', kind: 'cash', sortOrder: 0),
        (id: 'account-bank', name: '银行卡', kind: 'bank', sortOrder: 1),
        (id: 'account-alipay', name: '支付宝', kind: 'wallet', sortOrder: 2),
        (id: 'account-wechat', name: '微信', kind: 'wallet', sortOrder: 3),
        (id: 'account-huabei', name: '花呗', kind: 'creditLine', sortOrder: 4),
        (
          id: 'account-jd-baitiao',
          name: '白条',
          kind: 'creditLine',
          sortOrder: 5,
        ),
        (
          id: 'account-douyin-pay',
          name: '抖音月付',
          kind: 'creditLine',
          sortOrder: 6,
        ),
        (
          id: 'account-meituan-pay',
          name: '美团月付',
          kind: 'creditLine',
          sortOrder: 7,
        ),
        (
          id: 'account-family-card',
          name: '亲情卡',
          kind: 'entrustedFunds',
          sortOrder: 8,
        ),
      ];

  LedgerAccountsCompanion _account(
    String id,
    String name,
    String kind,
    int sortOrder,
    DateTime now,
  ) => LedgerAccountsCompanion.insert(
    id: id,
    name: name,
    kind: kind,
    sortOrder: Value(sortOrder),
    createdAt: now,
    updatedAt: now,
  );

  LedgerCategoriesCompanion _category(
    String id,
    String name,
    String? parentId,
    int sortOrder,
    DateTime now, {
    String transactionType = 'expense',
  }) => LedgerCategoriesCompanion.insert(
    id: id,
    name: name,
    transactionType: Value(transactionType),
    parentId: Value(parentId),
    sortOrder: Value(sortOrder),
    createdAt: now,
    updatedAt: now,
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documents = await getApplicationDocumentsDirectory();
    final database = File(p.join(documents.path, 'summa.sqlite'));
    final legacy = File(p.join(documents.path, 'ledger_pro.sqlite'));
    // Keep any database already present in this sandbox with its SQLite sidecars.
    final file = await database.exists() || !await legacy.exists()
        ? database
        : legacy;
    return NativeDatabase.createInBackground(file);
  });
}
