import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [LedgerAccounts, LedgerCategories, LedgerEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedDefaults();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await _addVersion2Defaults();
      if (from < 3) await _addVersion3Defaults();
      if (from < 4) {
        await migrator.addColumn(ledgerEntries, ledgerEntries.isDeleted);
      }
      if (from < 5) {
        await migrator.addColumn(ledgerEntries, ledgerEntries.targetAccountId);
        await _addVersion5Categories();
      }
      if (from < 6) await _addVersion6Categories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
      await delete(ledgerEntries).go();
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
      await delete(ledgerEntries).go();
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

  Future<void> _addVersion6Categories() async {
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
    return NativeDatabase.createInBackground(
      File(p.join(documents.path, 'ledger_pro.sqlite')),
    );
  });
}
