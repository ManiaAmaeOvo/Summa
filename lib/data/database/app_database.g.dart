// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LedgerAccountsTable extends LedgerAccounts
    with TableInfo<$LedgerAccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    currencyCode,
    openingBalanceMinor,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LedgerAccountsTable createAlias(String alias) {
    return $LedgerAccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String name;
  final String kind;
  final String currencyCode;
  final int openingBalanceMinor;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AccountRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.currencyCode,
    required this.openingBalanceMinor,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['currency_code'] = Variable<String>(currencyCode);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LedgerAccountsCompanion toCompanion(bool nullToAbsent) {
    return LedgerAccountsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      currencyCode: Value(currencyCode),
      openingBalanceMinor: Value(openingBalanceMinor),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? name,
    String? kind,
    String? currencyCode,
    int? openingBalanceMinor,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    currencyCode: currencyCode ?? this.currencyCode,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountRow copyWithCompanion(LedgerAccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    currencyCode,
    openingBalanceMinor,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.currencyCode == this.currencyCode &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerAccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> currencyCode;
  final Value<int> openingBalanceMinor;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LedgerAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerAccountsCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.currencyCode = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? currencyCode,
    Expression<int>? openingBalanceMinor,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? currencyCode,
    Value<int>? openingBalanceMinor,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LedgerAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerCategoriesTable extends LedgerCategories
    with TableInfo<$LedgerCategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_categories (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    transactionType,
    parentId,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LedgerCategoriesTable createAlias(String alias) {
    return $LedgerCategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String transactionType;
  final String? parentId;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.transactionType,
    this.parentId,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['transaction_type'] = Variable<String>(transactionType);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LedgerCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      transactionType: Value(transactionType),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'transactionType': serializer.toJson<String>(transactionType),
      'parentId': serializer.toJson<String?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    String? transactionType,
    Value<String?> parentId = const Value.absent(),
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    transactionType: transactionType ?? this.transactionType,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryRow copyWithCompanion(LedgerCategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transactionType: $transactionType, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    transactionType,
    parentId,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.transactionType == this.transactionType &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerCategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> transactionType;
  final Value<String?> parentId;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LedgerCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerCategoriesCompanion.insert({
    required String id,
    required String name,
    this.transactionType = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? transactionType,
    Expression<String>? parentId,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (transactionType != null) 'transaction_type': transactionType,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? transactionType,
    Value<String?>? parentId,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LedgerCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transactionType: $transactionType, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, EntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneOffsetMinutesMeta =
      const VerificationMeta('timezoneOffsetMinutes');
  @override
  late final GeneratedColumn<int> timezoneOffsetMinutes = GeneratedColumn<int>(
    'timezone_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_categories (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_accounts (id)',
    ),
  );
  static const VerificationMeta _targetAccountIdMeta = const VerificationMeta(
    'targetAccountId',
  );
  @override
  late final GeneratedColumn<String> targetAccountId = GeneratedColumn<String>(
    'target_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_accounts (id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () =>
        const CustomExpression<bool>("status IN ('posted', 'pending')"),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('posted'),
  );
  static const VerificationMeta _refundOfIdMeta = const VerificationMeta(
    'refundOfId',
  );
  @override
  late final GeneratedColumn<String> refundOfId = GeneratedColumn<String>(
    'refund_of_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_entries (id)',
    ),
  );
  static const VerificationMeta _settlementAmountMinorMeta =
      const VerificationMeta('settlementAmountMinor');
  @override
  late final GeneratedColumn<int> settlementAmountMinor = GeneratedColumn<int>(
    'settlement_amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settlementCurrencyCodeMeta =
      const VerificationMeta('settlementCurrencyCode');
  @override
  late final GeneratedColumn<String> settlementCurrencyCode =
      GeneratedColumn<String>(
        'settlement_currency_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _quotedExchangeRateMeta =
      const VerificationMeta('quotedExchangeRate');
  @override
  late final GeneratedColumn<String> quotedExchangeRate =
      GeneratedColumn<String>(
        'quoted_exchange_rate',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _termsJsonMeta = const VerificationMeta(
    'termsJson',
  );
  @override
  late final GeneratedColumn<String> termsJson = GeneratedColumn<String>(
    'terms_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionType,
    amountMinor,
    currencyCode,
    occurredAt,
    timezoneOffsetMinutes,
    categoryId,
    accountId,
    targetAccountId,
    note,
    createdAt,
    updatedAt,
    isDeleted,
    status,
    refundOfId,
    settlementAmountMinor,
    settlementCurrencyCode,
    quotedExchangeRate,
    termsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('timezone_offset_minutes')) {
      context.handle(
        _timezoneOffsetMinutesMeta,
        timezoneOffsetMinutes.isAcceptableOrUnknown(
          data['timezone_offset_minutes']!,
          _timezoneOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timezoneOffsetMinutesMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('target_account_id')) {
      context.handle(
        _targetAccountIdMeta,
        targetAccountId.isAcceptableOrUnknown(
          data['target_account_id']!,
          _targetAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('refund_of_id')) {
      context.handle(
        _refundOfIdMeta,
        refundOfId.isAcceptableOrUnknown(
          data['refund_of_id']!,
          _refundOfIdMeta,
        ),
      );
    }
    if (data.containsKey('settlement_amount_minor')) {
      context.handle(
        _settlementAmountMinorMeta,
        settlementAmountMinor.isAcceptableOrUnknown(
          data['settlement_amount_minor']!,
          _settlementAmountMinorMeta,
        ),
      );
    }
    if (data.containsKey('settlement_currency_code')) {
      context.handle(
        _settlementCurrencyCodeMeta,
        settlementCurrencyCode.isAcceptableOrUnknown(
          data['settlement_currency_code']!,
          _settlementCurrencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('quoted_exchange_rate')) {
      context.handle(
        _quotedExchangeRateMeta,
        quotedExchangeRate.isAcceptableOrUnknown(
          data['quoted_exchange_rate']!,
          _quotedExchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('terms_json')) {
      context.handle(
        _termsJsonMeta,
        termsJson.isAcceptableOrUnknown(data['terms_json']!, _termsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      timezoneOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timezone_offset_minutes'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      targetAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_account_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      refundOfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_of_id'],
      ),
      settlementAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settlement_amount_minor'],
      ),
      settlementCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settlement_currency_code'],
      ),
      quotedExchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quoted_exchange_rate'],
      ),
      termsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms_json'],
      ),
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class EntryRow extends DataClass implements Insertable<EntryRow> {
  final String id;
  final String transactionType;
  final int amountMinor;
  final String currencyCode;
  final DateTime occurredAt;
  final int timezoneOffsetMinutes;
  final String categoryId;
  final String accountId;
  final String? targetAccountId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String status;
  final String? refundOfId;
  final int? settlementAmountMinor;
  final String? settlementCurrencyCode;
  final String? quotedExchangeRate;
  final String? termsJson;
  const EntryRow({
    required this.id,
    required this.transactionType,
    required this.amountMinor,
    required this.currencyCode,
    required this.occurredAt,
    required this.timezoneOffsetMinutes,
    required this.categoryId,
    required this.accountId,
    this.targetAccountId,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.status,
    this.refundOfId,
    this.settlementAmountMinor,
    this.settlementCurrencyCode,
    this.quotedExchangeRate,
    this.termsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_type'] = Variable<String>(transactionType);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['timezone_offset_minutes'] = Variable<int>(timezoneOffsetMinutes);
    map['category_id'] = Variable<String>(categoryId);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || targetAccountId != null) {
      map['target_account_id'] = Variable<String>(targetAccountId);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || refundOfId != null) {
      map['refund_of_id'] = Variable<String>(refundOfId);
    }
    if (!nullToAbsent || settlementAmountMinor != null) {
      map['settlement_amount_minor'] = Variable<int>(settlementAmountMinor);
    }
    if (!nullToAbsent || settlementCurrencyCode != null) {
      map['settlement_currency_code'] = Variable<String>(
        settlementCurrencyCode,
      );
    }
    if (!nullToAbsent || quotedExchangeRate != null) {
      map['quoted_exchange_rate'] = Variable<String>(quotedExchangeRate);
    }
    if (!nullToAbsent || termsJson != null) {
      map['terms_json'] = Variable<String>(termsJson);
    }
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      transactionType: Value(transactionType),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      occurredAt: Value(occurredAt),
      timezoneOffsetMinutes: Value(timezoneOffsetMinutes),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      targetAccountId: targetAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAccountId),
      note: Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      status: Value(status),
      refundOfId: refundOfId == null && nullToAbsent
          ? const Value.absent()
          : Value(refundOfId),
      settlementAmountMinor: settlementAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(settlementAmountMinor),
      settlementCurrencyCode: settlementCurrencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(settlementCurrencyCode),
      quotedExchangeRate: quotedExchangeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(quotedExchangeRate),
      termsJson: termsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(termsJson),
    );
  }

  factory EntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRow(
      id: serializer.fromJson<String>(json['id']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      timezoneOffsetMinutes: serializer.fromJson<int>(
        json['timezoneOffsetMinutes'],
      ),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      targetAccountId: serializer.fromJson<String?>(json['targetAccountId']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      status: serializer.fromJson<String>(json['status']),
      refundOfId: serializer.fromJson<String?>(json['refundOfId']),
      settlementAmountMinor: serializer.fromJson<int?>(
        json['settlementAmountMinor'],
      ),
      settlementCurrencyCode: serializer.fromJson<String?>(
        json['settlementCurrencyCode'],
      ),
      quotedExchangeRate: serializer.fromJson<String?>(
        json['quotedExchangeRate'],
      ),
      termsJson: serializer.fromJson<String?>(json['termsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionType': serializer.toJson<String>(transactionType),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'timezoneOffsetMinutes': serializer.toJson<int>(timezoneOffsetMinutes),
      'categoryId': serializer.toJson<String>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'targetAccountId': serializer.toJson<String?>(targetAccountId),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'status': serializer.toJson<String>(status),
      'refundOfId': serializer.toJson<String?>(refundOfId),
      'settlementAmountMinor': serializer.toJson<int?>(settlementAmountMinor),
      'settlementCurrencyCode': serializer.toJson<String?>(
        settlementCurrencyCode,
      ),
      'quotedExchangeRate': serializer.toJson<String?>(quotedExchangeRate),
      'termsJson': serializer.toJson<String?>(termsJson),
    };
  }

  EntryRow copyWith({
    String? id,
    String? transactionType,
    int? amountMinor,
    String? currencyCode,
    DateTime? occurredAt,
    int? timezoneOffsetMinutes,
    String? categoryId,
    String? accountId,
    Value<String?> targetAccountId = const Value.absent(),
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? status,
    Value<String?> refundOfId = const Value.absent(),
    Value<int?> settlementAmountMinor = const Value.absent(),
    Value<String?> settlementCurrencyCode = const Value.absent(),
    Value<String?> quotedExchangeRate = const Value.absent(),
    Value<String?> termsJson = const Value.absent(),
  }) => EntryRow(
    id: id ?? this.id,
    transactionType: transactionType ?? this.transactionType,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    occurredAt: occurredAt ?? this.occurredAt,
    timezoneOffsetMinutes: timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    targetAccountId: targetAccountId.present
        ? targetAccountId.value
        : this.targetAccountId,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    status: status ?? this.status,
    refundOfId: refundOfId.present ? refundOfId.value : this.refundOfId,
    settlementAmountMinor: settlementAmountMinor.present
        ? settlementAmountMinor.value
        : this.settlementAmountMinor,
    settlementCurrencyCode: settlementCurrencyCode.present
        ? settlementCurrencyCode.value
        : this.settlementCurrencyCode,
    quotedExchangeRate: quotedExchangeRate.present
        ? quotedExchangeRate.value
        : this.quotedExchangeRate,
    termsJson: termsJson.present ? termsJson.value : this.termsJson,
  );
  EntryRow copyWithCompanion(LedgerEntriesCompanion data) {
    return EntryRow(
      id: data.id.present ? data.id.value : this.id,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      timezoneOffsetMinutes: data.timezoneOffsetMinutes.present
          ? data.timezoneOffsetMinutes.value
          : this.timezoneOffsetMinutes,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      targetAccountId: data.targetAccountId.present
          ? data.targetAccountId.value
          : this.targetAccountId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      status: data.status.present ? data.status.value : this.status,
      refundOfId: data.refundOfId.present
          ? data.refundOfId.value
          : this.refundOfId,
      settlementAmountMinor: data.settlementAmountMinor.present
          ? data.settlementAmountMinor.value
          : this.settlementAmountMinor,
      settlementCurrencyCode: data.settlementCurrencyCode.present
          ? data.settlementCurrencyCode.value
          : this.settlementCurrencyCode,
      quotedExchangeRate: data.quotedExchangeRate.present
          ? data.quotedExchangeRate.value
          : this.quotedExchangeRate,
      termsJson: data.termsJson.present ? data.termsJson.value : this.termsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRow(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('timezoneOffsetMinutes: $timezoneOffsetMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('targetAccountId: $targetAccountId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('status: $status, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('settlementAmountMinor: $settlementAmountMinor, ')
          ..write('settlementCurrencyCode: $settlementCurrencyCode, ')
          ..write('quotedExchangeRate: $quotedExchangeRate, ')
          ..write('termsJson: $termsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionType,
    amountMinor,
    currencyCode,
    occurredAt,
    timezoneOffsetMinutes,
    categoryId,
    accountId,
    targetAccountId,
    note,
    createdAt,
    updatedAt,
    isDeleted,
    status,
    refundOfId,
    settlementAmountMinor,
    settlementCurrencyCode,
    quotedExchangeRate,
    termsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRow &&
          other.id == this.id &&
          other.transactionType == this.transactionType &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.occurredAt == this.occurredAt &&
          other.timezoneOffsetMinutes == this.timezoneOffsetMinutes &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.targetAccountId == this.targetAccountId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.status == this.status &&
          other.refundOfId == this.refundOfId &&
          other.settlementAmountMinor == this.settlementAmountMinor &&
          other.settlementCurrencyCode == this.settlementCurrencyCode &&
          other.quotedExchangeRate == this.quotedExchangeRate &&
          other.termsJson == this.termsJson);
}

class LedgerEntriesCompanion extends UpdateCompanion<EntryRow> {
  final Value<String> id;
  final Value<String> transactionType;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<DateTime> occurredAt;
  final Value<int> timezoneOffsetMinutes;
  final Value<String> categoryId;
  final Value<String> accountId;
  final Value<String?> targetAccountId;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<String> status;
  final Value<String?> refundOfId;
  final Value<int?> settlementAmountMinor;
  final Value<String?> settlementCurrencyCode;
  final Value<String?> quotedExchangeRate;
  final Value<String?> termsJson;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.timezoneOffsetMinutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.targetAccountId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.status = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.settlementAmountMinor = const Value.absent(),
    this.settlementCurrencyCode = const Value.absent(),
    this.quotedExchangeRate = const Value.absent(),
    this.termsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String transactionType,
    required int amountMinor,
    this.currencyCode = const Value.absent(),
    required DateTime occurredAt,
    required int timezoneOffsetMinutes,
    required String categoryId,
    required String accountId,
    this.targetAccountId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.status = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.settlementAmountMinor = const Value.absent(),
    this.settlementCurrencyCode = const Value.absent(),
    this.quotedExchangeRate = const Value.absent(),
    this.termsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionType = Value(transactionType),
       amountMinor = Value(amountMinor),
       occurredAt = Value(occurredAt),
       timezoneOffsetMinutes = Value(timezoneOffsetMinutes),
       categoryId = Value(categoryId),
       accountId = Value(accountId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EntryRow> custom({
    Expression<String>? id,
    Expression<String>? transactionType,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<DateTime>? occurredAt,
    Expression<int>? timezoneOffsetMinutes,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? targetAccountId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<String>? status,
    Expression<String>? refundOfId,
    Expression<int>? settlementAmountMinor,
    Expression<String>? settlementCurrencyCode,
    Expression<String>? quotedExchangeRate,
    Expression<String>? termsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionType != null) 'transaction_type': transactionType,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (timezoneOffsetMinutes != null)
        'timezone_offset_minutes': timezoneOffsetMinutes,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (targetAccountId != null) 'target_account_id': targetAccountId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (status != null) 'status': status,
      if (refundOfId != null) 'refund_of_id': refundOfId,
      if (settlementAmountMinor != null)
        'settlement_amount_minor': settlementAmountMinor,
      if (settlementCurrencyCode != null)
        'settlement_currency_code': settlementCurrencyCode,
      if (quotedExchangeRate != null)
        'quoted_exchange_rate': quotedExchangeRate,
      if (termsJson != null) 'terms_json': termsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionType,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<DateTime>? occurredAt,
    Value<int>? timezoneOffsetMinutes,
    Value<String>? categoryId,
    Value<String>? accountId,
    Value<String?>? targetAccountId,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<String>? status,
    Value<String?>? refundOfId,
    Value<int?>? settlementAmountMinor,
    Value<String?>? settlementCurrencyCode,
    Value<String?>? quotedExchangeRate,
    Value<String?>? termsJson,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      occurredAt: occurredAt ?? this.occurredAt,
      timezoneOffsetMinutes:
          timezoneOffsetMinutes ?? this.timezoneOffsetMinutes,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      refundOfId: refundOfId ?? this.refundOfId,
      settlementAmountMinor:
          settlementAmountMinor ?? this.settlementAmountMinor,
      settlementCurrencyCode:
          settlementCurrencyCode ?? this.settlementCurrencyCode,
      quotedExchangeRate: quotedExchangeRate ?? this.quotedExchangeRate,
      termsJson: termsJson ?? this.termsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (timezoneOffsetMinutes.present) {
      map['timezone_offset_minutes'] = Variable<int>(
        timezoneOffsetMinutes.value,
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (targetAccountId.present) {
      map['target_account_id'] = Variable<String>(targetAccountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (refundOfId.present) {
      map['refund_of_id'] = Variable<String>(refundOfId.value);
    }
    if (settlementAmountMinor.present) {
      map['settlement_amount_minor'] = Variable<int>(
        settlementAmountMinor.value,
      );
    }
    if (settlementCurrencyCode.present) {
      map['settlement_currency_code'] = Variable<String>(
        settlementCurrencyCode.value,
      );
    }
    if (quotedExchangeRate.present) {
      map['quoted_exchange_rate'] = Variable<String>(quotedExchangeRate.value);
    }
    if (termsJson.present) {
      map['terms_json'] = Variable<String>(termsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('timezoneOffsetMinutes: $timezoneOffsetMinutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('targetAccountId: $targetAccountId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('status: $status, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('settlementAmountMinor: $settlementAmountMinor, ')
          ..write('settlementCurrencyCode: $settlementCurrencyCode, ')
          ..write('quotedExchangeRate: $quotedExchangeRate, ')
          ..write('termsJson: $termsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerPostingsTable extends LedgerPostings
    with TableInfo<$LedgerPostingsTable, PostingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerPostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_accounts (id)',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debitMinorMeta = const VerificationMeta(
    'debitMinor',
  );
  @override
  late final GeneratedColumn<int> debitMinor = GeneratedColumn<int>(
    'debit_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    transactionId,
    position,
    accountId,
    currencyCode,
    debitMinor,
    role,
    needsReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_postings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('debit_minor')) {
      context.handle(
        _debitMinorMeta,
        debitMinor.isAcceptableOrUnknown(data['debit_minor']!, _debitMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_debitMinorMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, position};
  @override
  PostingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostingRow(
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      debitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debit_minor'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
    );
  }

  @override
  $LedgerPostingsTable createAlias(String alias) {
    return $LedgerPostingsTable(attachedDatabase, alias);
  }
}

class PostingRow extends DataClass implements Insertable<PostingRow> {
  final String transactionId;
  final int position;
  final String? accountId;
  final String currencyCode;
  final int debitMinor;
  final String role;
  final bool needsReview;
  const PostingRow({
    required this.transactionId,
    required this.position,
    this.accountId,
    required this.currencyCode,
    required this.debitMinor,
    required this.role,
    required this.needsReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['debit_minor'] = Variable<int>(debitMinor);
    map['role'] = Variable<String>(role);
    map['needs_review'] = Variable<bool>(needsReview);
    return map;
  }

  LedgerPostingsCompanion toCompanion(bool nullToAbsent) {
    return LedgerPostingsCompanion(
      transactionId: Value(transactionId),
      position: Value(position),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      currencyCode: Value(currencyCode),
      debitMinor: Value(debitMinor),
      role: Value(role),
      needsReview: Value(needsReview),
    );
  }

  factory PostingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostingRow(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      position: serializer.fromJson<int>(json['position']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      debitMinor: serializer.fromJson<int>(json['debitMinor']),
      role: serializer.fromJson<String>(json['role']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'position': serializer.toJson<int>(position),
      'accountId': serializer.toJson<String?>(accountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'debitMinor': serializer.toJson<int>(debitMinor),
      'role': serializer.toJson<String>(role),
      'needsReview': serializer.toJson<bool>(needsReview),
    };
  }

  PostingRow copyWith({
    String? transactionId,
    int? position,
    Value<String?> accountId = const Value.absent(),
    String? currencyCode,
    int? debitMinor,
    String? role,
    bool? needsReview,
  }) => PostingRow(
    transactionId: transactionId ?? this.transactionId,
    position: position ?? this.position,
    accountId: accountId.present ? accountId.value : this.accountId,
    currencyCode: currencyCode ?? this.currencyCode,
    debitMinor: debitMinor ?? this.debitMinor,
    role: role ?? this.role,
    needsReview: needsReview ?? this.needsReview,
  );
  PostingRow copyWithCompanion(LedgerPostingsCompanion data) {
    return PostingRow(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      position: data.position.present ? data.position.value : this.position,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      debitMinor: data.debitMinor.present
          ? data.debitMinor.value
          : this.debitMinor,
      role: data.role.present ? data.role.value : this.role,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PostingRow(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('debitMinor: $debitMinor, ')
          ..write('role: $role, ')
          ..write('needsReview: $needsReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    transactionId,
    position,
    accountId,
    currencyCode,
    debitMinor,
    role,
    needsReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostingRow &&
          other.transactionId == this.transactionId &&
          other.position == this.position &&
          other.accountId == this.accountId &&
          other.currencyCode == this.currencyCode &&
          other.debitMinor == this.debitMinor &&
          other.role == this.role &&
          other.needsReview == this.needsReview);
}

class LedgerPostingsCompanion extends UpdateCompanion<PostingRow> {
  final Value<String> transactionId;
  final Value<int> position;
  final Value<String?> accountId;
  final Value<String> currencyCode;
  final Value<int> debitMinor;
  final Value<String> role;
  final Value<bool> needsReview;
  final Value<int> rowid;
  const LedgerPostingsCompanion({
    this.transactionId = const Value.absent(),
    this.position = const Value.absent(),
    this.accountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.debitMinor = const Value.absent(),
    this.role = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerPostingsCompanion.insert({
    required String transactionId,
    required int position,
    this.accountId = const Value.absent(),
    required String currencyCode,
    required int debitMinor,
    required String role,
    this.needsReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : transactionId = Value(transactionId),
       position = Value(position),
       currencyCode = Value(currencyCode),
       debitMinor = Value(debitMinor),
       role = Value(role);
  static Insertable<PostingRow> custom({
    Expression<String>? transactionId,
    Expression<int>? position,
    Expression<String>? accountId,
    Expression<String>? currencyCode,
    Expression<int>? debitMinor,
    Expression<String>? role,
    Expression<bool>? needsReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (position != null) 'position': position,
      if (accountId != null) 'account_id': accountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (debitMinor != null) 'debit_minor': debitMinor,
      if (role != null) 'role': role,
      if (needsReview != null) 'needs_review': needsReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerPostingsCompanion copyWith({
    Value<String>? transactionId,
    Value<int>? position,
    Value<String?>? accountId,
    Value<String>? currencyCode,
    Value<int>? debitMinor,
    Value<String>? role,
    Value<bool>? needsReview,
    Value<int>? rowid,
  }) {
    return LedgerPostingsCompanion(
      transactionId: transactionId ?? this.transactionId,
      position: position ?? this.position,
      accountId: accountId ?? this.accountId,
      currencyCode: currencyCode ?? this.currencyCode,
      debitMinor: debitMinor ?? this.debitMinor,
      role: role ?? this.role,
      needsReview: needsReview ?? this.needsReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (debitMinor.present) {
      map['debit_minor'] = Variable<int>(debitMinor.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerPostingsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('debitMinor: $debitMinor, ')
          ..write('role: $role, ')
          ..write('needsReview: $needsReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ValuationPreferencesTable extends ValuationPreferences
    with TableInfo<$ValuationPreferencesTable, ValuationBaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValuationPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('id = 1'),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, baseCurrency];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'valuation_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ValuationBaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ValuationBaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValuationBaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
    );
  }

  @override
  $ValuationPreferencesTable createAlias(String alias) {
    return $ValuationPreferencesTable(attachedDatabase, alias);
  }
}

class ValuationBaseRow extends DataClass
    implements Insertable<ValuationBaseRow> {
  final int id;
  final String baseCurrency;
  const ValuationBaseRow({required this.id, required this.baseCurrency});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_currency'] = Variable<String>(baseCurrency);
    return map;
  }

  ValuationPreferencesCompanion toCompanion(bool nullToAbsent) {
    return ValuationPreferencesCompanion(
      id: Value(id),
      baseCurrency: Value(baseCurrency),
    );
  }

  factory ValuationBaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValuationBaseRow(
      id: serializer.fromJson<int>(json['id']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
    };
  }

  ValuationBaseRow copyWith({int? id, String? baseCurrency}) =>
      ValuationBaseRow(
        id: id ?? this.id,
        baseCurrency: baseCurrency ?? this.baseCurrency,
      );
  ValuationBaseRow copyWithCompanion(ValuationPreferencesCompanion data) {
    return ValuationBaseRow(
      id: data.id.present ? data.id.value : this.id,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValuationBaseRow(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, baseCurrency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValuationBaseRow &&
          other.id == this.id &&
          other.baseCurrency == this.baseCurrency);
}

class ValuationPreferencesCompanion extends UpdateCompanion<ValuationBaseRow> {
  final Value<int> id;
  final Value<String> baseCurrency;
  const ValuationPreferencesCompanion({
    this.id = const Value.absent(),
    this.baseCurrency = const Value.absent(),
  });
  ValuationPreferencesCompanion.insert({
    this.id = const Value.absent(),
    required String baseCurrency,
  }) : baseCurrency = Value(baseCurrency);
  static Insertable<ValuationBaseRow> custom({
    Expression<int>? id,
    Expression<String>? baseCurrency,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCurrency != null) 'base_currency': baseCurrency,
    });
  }

  ValuationPreferencesCompanion copyWith({
    Value<int>? id,
    Value<String>? baseCurrency,
  }) {
    return ValuationPreferencesCompanion(
      id: id ?? this.id,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValuationPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency')
          ..write(')'))
        .toString();
  }
}

class $ValuationRatesTable extends ValuationRates
    with TableInfo<$ValuationRatesTable, ValuationRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValuationRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceCurrencyMeta = const VerificationMeta(
    'sourceCurrency',
  );
  @override
  late final GeneratedColumn<String> sourceCurrency = GeneratedColumn<String>(
    'source_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<String> rate = GeneratedColumn<String>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    baseCurrency,
    sourceCurrency,
    rate,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'valuation_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ValuationRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('source_currency')) {
      context.handle(
        _sourceCurrencyMeta,
        sourceCurrency.isAcceptableOrUnknown(
          data['source_currency']!,
          _sourceCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {baseCurrency, sourceCurrency};
  @override
  ValuationRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValuationRateRow(
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      sourceCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_currency'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ValuationRatesTable createAlias(String alias) {
    return $ValuationRatesTable(attachedDatabase, alias);
  }
}

class ValuationRateRow extends DataClass
    implements Insertable<ValuationRateRow> {
  final String baseCurrency;
  final String sourceCurrency;
  final String rate;
  final DateTime updatedAt;
  const ValuationRateRow({
    required this.baseCurrency,
    required this.sourceCurrency,
    required this.rate,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['base_currency'] = Variable<String>(baseCurrency);
    map['source_currency'] = Variable<String>(sourceCurrency);
    map['rate'] = Variable<String>(rate);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ValuationRatesCompanion toCompanion(bool nullToAbsent) {
    return ValuationRatesCompanion(
      baseCurrency: Value(baseCurrency),
      sourceCurrency: Value(sourceCurrency),
      rate: Value(rate),
      updatedAt: Value(updatedAt),
    );
  }

  factory ValuationRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValuationRateRow(
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      sourceCurrency: serializer.fromJson<String>(json['sourceCurrency']),
      rate: serializer.fromJson<String>(json['rate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'sourceCurrency': serializer.toJson<String>(sourceCurrency),
      'rate': serializer.toJson<String>(rate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ValuationRateRow copyWith({
    String? baseCurrency,
    String? sourceCurrency,
    String? rate,
    DateTime? updatedAt,
  }) => ValuationRateRow(
    baseCurrency: baseCurrency ?? this.baseCurrency,
    sourceCurrency: sourceCurrency ?? this.sourceCurrency,
    rate: rate ?? this.rate,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ValuationRateRow copyWithCompanion(ValuationRatesCompanion data) {
    return ValuationRateRow(
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      sourceCurrency: data.sourceCurrency.present
          ? data.sourceCurrency.value
          : this.sourceCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValuationRateRow(')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('sourceCurrency: $sourceCurrency, ')
          ..write('rate: $rate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(baseCurrency, sourceCurrency, rate, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValuationRateRow &&
          other.baseCurrency == this.baseCurrency &&
          other.sourceCurrency == this.sourceCurrency &&
          other.rate == this.rate &&
          other.updatedAt == this.updatedAt);
}

class ValuationRatesCompanion extends UpdateCompanion<ValuationRateRow> {
  final Value<String> baseCurrency;
  final Value<String> sourceCurrency;
  final Value<String> rate;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ValuationRatesCompanion({
    this.baseCurrency = const Value.absent(),
    this.sourceCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ValuationRatesCompanion.insert({
    required String baseCurrency,
    required String sourceCurrency,
    required String rate,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : baseCurrency = Value(baseCurrency),
       sourceCurrency = Value(sourceCurrency),
       rate = Value(rate),
       updatedAt = Value(updatedAt);
  static Insertable<ValuationRateRow> custom({
    Expression<String>? baseCurrency,
    Expression<String>? sourceCurrency,
    Expression<String>? rate,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (sourceCurrency != null) 'source_currency': sourceCurrency,
      if (rate != null) 'rate': rate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ValuationRatesCompanion copyWith({
    Value<String>? baseCurrency,
    Value<String>? sourceCurrency,
    Value<String>? rate,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ValuationRatesCompanion(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      sourceCurrency: sourceCurrency ?? this.sourceCurrency,
      rate: rate ?? this.rate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (sourceCurrency.present) {
      map['source_currency'] = Variable<String>(sourceCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<String>(rate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValuationRatesCompanion(')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('sourceCurrency: $sourceCurrency, ')
          ..write('rate: $rate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceCheckpointsTable extends BalanceCheckpoints
    with TableInfo<$BalanceCheckpointsTable, CheckpointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_accounts (id)',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualMinorMeta = const VerificationMeta(
    'actualMinor',
  );
  @override
  late final GeneratedColumn<int> actualMinor = GeneratedColumn<int>(
    'actual_minor',
    aliasedName,
    false,
    check: () => const CustomExpression<bool>('actual_minor >= 0'),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedBookMinorMeta = const VerificationMeta(
    'recordedBookMinor',
  );
  @override
  late final GeneratedColumn<int> recordedBookMinor = GeneratedColumn<int>(
    'recorded_book_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustmentIdMeta = const VerificationMeta(
    'adjustmentId',
  );
  @override
  late final GeneratedColumn<String> adjustmentId = GeneratedColumn<String>(
    'adjustment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES ledger_entries (id)',
    ),
  );
  static const VerificationMeta _adjustedBookMinorMeta = const VerificationMeta(
    'adjustedBookMinor',
  );
  @override
  late final GeneratedColumn<int> adjustedBookMinor = GeneratedColumn<int>(
    'adjusted_book_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    currencyCode,
    observedAt,
    actualMinor,
    recordedBookMinor,
    adjustmentId,
    adjustedBookMinor,
    note,
    createdAt,
    voidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckpointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('actual_minor')) {
      context.handle(
        _actualMinorMeta,
        actualMinor.isAcceptableOrUnknown(
          data['actual_minor']!,
          _actualMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualMinorMeta);
    }
    if (data.containsKey('recorded_book_minor')) {
      context.handle(
        _recordedBookMinorMeta,
        recordedBookMinor.isAcceptableOrUnknown(
          data['recorded_book_minor']!,
          _recordedBookMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedBookMinorMeta);
    }
    if (data.containsKey('adjustment_id')) {
      context.handle(
        _adjustmentIdMeta,
        adjustmentId.isAcceptableOrUnknown(
          data['adjustment_id']!,
          _adjustmentIdMeta,
        ),
      );
    }
    if (data.containsKey('adjusted_book_minor')) {
      context.handle(
        _adjustedBookMinorMeta,
        adjustedBookMinor.isAcceptableOrUnknown(
          data['adjusted_book_minor']!,
          _adjustedBookMinorMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckpointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckpointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      actualMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minor'],
      )!,
      recordedBookMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_book_minor'],
      )!,
      adjustmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjustment_id'],
      ),
      adjustedBookMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjusted_book_minor'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
    );
  }

  @override
  $BalanceCheckpointsTable createAlias(String alias) {
    return $BalanceCheckpointsTable(attachedDatabase, alias);
  }
}

class CheckpointRow extends DataClass implements Insertable<CheckpointRow> {
  final String id;
  final String accountId;
  final String currencyCode;
  final DateTime observedAt;
  final int actualMinor;
  final int recordedBookMinor;
  final String? adjustmentId;
  final int? adjustedBookMinor;
  final String note;
  final DateTime createdAt;
  final DateTime? voidedAt;
  const CheckpointRow({
    required this.id,
    required this.accountId,
    required this.currencyCode,
    required this.observedAt,
    required this.actualMinor,
    required this.recordedBookMinor,
    this.adjustmentId,
    this.adjustedBookMinor,
    required this.note,
    required this.createdAt,
    this.voidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['currency_code'] = Variable<String>(currencyCode);
    map['observed_at'] = Variable<DateTime>(observedAt);
    map['actual_minor'] = Variable<int>(actualMinor);
    map['recorded_book_minor'] = Variable<int>(recordedBookMinor);
    if (!nullToAbsent || adjustmentId != null) {
      map['adjustment_id'] = Variable<String>(adjustmentId);
    }
    if (!nullToAbsent || adjustedBookMinor != null) {
      map['adjusted_book_minor'] = Variable<int>(adjustedBookMinor);
    }
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    return map;
  }

  BalanceCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return BalanceCheckpointsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      currencyCode: Value(currencyCode),
      observedAt: Value(observedAt),
      actualMinor: Value(actualMinor),
      recordedBookMinor: Value(recordedBookMinor),
      adjustmentId: adjustmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentId),
      adjustedBookMinor: adjustedBookMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustedBookMinor),
      note: Value(note),
      createdAt: Value(createdAt),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
    );
  }

  factory CheckpointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckpointRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      actualMinor: serializer.fromJson<int>(json['actualMinor']),
      recordedBookMinor: serializer.fromJson<int>(json['recordedBookMinor']),
      adjustmentId: serializer.fromJson<String?>(json['adjustmentId']),
      adjustedBookMinor: serializer.fromJson<int?>(json['adjustedBookMinor']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'actualMinor': serializer.toJson<int>(actualMinor),
      'recordedBookMinor': serializer.toJson<int>(recordedBookMinor),
      'adjustmentId': serializer.toJson<String?>(adjustmentId),
      'adjustedBookMinor': serializer.toJson<int?>(adjustedBookMinor),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
    };
  }

  CheckpointRow copyWith({
    String? id,
    String? accountId,
    String? currencyCode,
    DateTime? observedAt,
    int? actualMinor,
    int? recordedBookMinor,
    Value<String?> adjustmentId = const Value.absent(),
    Value<int?> adjustedBookMinor = const Value.absent(),
    String? note,
    DateTime? createdAt,
    Value<DateTime?> voidedAt = const Value.absent(),
  }) => CheckpointRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    currencyCode: currencyCode ?? this.currencyCode,
    observedAt: observedAt ?? this.observedAt,
    actualMinor: actualMinor ?? this.actualMinor,
    recordedBookMinor: recordedBookMinor ?? this.recordedBookMinor,
    adjustmentId: adjustmentId.present ? adjustmentId.value : this.adjustmentId,
    adjustedBookMinor: adjustedBookMinor.present
        ? adjustedBookMinor.value
        : this.adjustedBookMinor,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
  );
  CheckpointRow copyWithCompanion(BalanceCheckpointsCompanion data) {
    return CheckpointRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      actualMinor: data.actualMinor.present
          ? data.actualMinor.value
          : this.actualMinor,
      recordedBookMinor: data.recordedBookMinor.present
          ? data.recordedBookMinor.value
          : this.recordedBookMinor,
      adjustmentId: data.adjustmentId.present
          ? data.adjustmentId.value
          : this.adjustmentId,
      adjustedBookMinor: data.adjustedBookMinor.present
          ? data.adjustedBookMinor.value
          : this.adjustedBookMinor,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckpointRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('observedAt: $observedAt, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('recordedBookMinor: $recordedBookMinor, ')
          ..write('adjustmentId: $adjustmentId, ')
          ..write('adjustedBookMinor: $adjustedBookMinor, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('voidedAt: $voidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    currencyCode,
    observedAt,
    actualMinor,
    recordedBookMinor,
    adjustmentId,
    adjustedBookMinor,
    note,
    createdAt,
    voidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckpointRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.currencyCode == this.currencyCode &&
          other.observedAt == this.observedAt &&
          other.actualMinor == this.actualMinor &&
          other.recordedBookMinor == this.recordedBookMinor &&
          other.adjustmentId == this.adjustmentId &&
          other.adjustedBookMinor == this.adjustedBookMinor &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.voidedAt == this.voidedAt);
}

class BalanceCheckpointsCompanion extends UpdateCompanion<CheckpointRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> currencyCode;
  final Value<DateTime> observedAt;
  final Value<int> actualMinor;
  final Value<int> recordedBookMinor;
  final Value<String?> adjustmentId;
  final Value<int?> adjustedBookMinor;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> voidedAt;
  final Value<int> rowid;
  const BalanceCheckpointsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.actualMinor = const Value.absent(),
    this.recordedBookMinor = const Value.absent(),
    this.adjustmentId = const Value.absent(),
    this.adjustedBookMinor = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceCheckpointsCompanion.insert({
    required String id,
    required String accountId,
    required String currencyCode,
    required DateTime observedAt,
    required int actualMinor,
    required int recordedBookMinor,
    this.adjustmentId = const Value.absent(),
    this.adjustedBookMinor = const Value.absent(),
    required String note,
    required DateTime createdAt,
    this.voidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       currencyCode = Value(currencyCode),
       observedAt = Value(observedAt),
       actualMinor = Value(actualMinor),
       recordedBookMinor = Value(recordedBookMinor),
       note = Value(note),
       createdAt = Value(createdAt);
  static Insertable<CheckpointRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? currencyCode,
    Expression<DateTime>? observedAt,
    Expression<int>? actualMinor,
    Expression<int>? recordedBookMinor,
    Expression<String>? adjustmentId,
    Expression<int>? adjustedBookMinor,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? voidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (observedAt != null) 'observed_at': observedAt,
      if (actualMinor != null) 'actual_minor': actualMinor,
      if (recordedBookMinor != null) 'recorded_book_minor': recordedBookMinor,
      if (adjustmentId != null) 'adjustment_id': adjustmentId,
      if (adjustedBookMinor != null) 'adjusted_book_minor': adjustedBookMinor,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceCheckpointsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? currencyCode,
    Value<DateTime>? observedAt,
    Value<int>? actualMinor,
    Value<int>? recordedBookMinor,
    Value<String?>? adjustmentId,
    Value<int?>? adjustedBookMinor,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? voidedAt,
    Value<int>? rowid,
  }) {
    return BalanceCheckpointsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      currencyCode: currencyCode ?? this.currencyCode,
      observedAt: observedAt ?? this.observedAt,
      actualMinor: actualMinor ?? this.actualMinor,
      recordedBookMinor: recordedBookMinor ?? this.recordedBookMinor,
      adjustmentId: adjustmentId ?? this.adjustmentId,
      adjustedBookMinor: adjustedBookMinor ?? this.adjustedBookMinor,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      voidedAt: voidedAt ?? this.voidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (actualMinor.present) {
      map['actual_minor'] = Variable<int>(actualMinor.value);
    }
    if (recordedBookMinor.present) {
      map['recorded_book_minor'] = Variable<int>(recordedBookMinor.value);
    }
    if (adjustmentId.present) {
      map['adjustment_id'] = Variable<String>(adjustmentId.value);
    }
    if (adjustedBookMinor.present) {
      map['adjusted_book_minor'] = Variable<int>(adjustedBookMinor.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceCheckpointsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('observedAt: $observedAt, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('recordedBookMinor: $recordedBookMinor, ')
          ..write('adjustmentId: $adjustmentId, ')
          ..write('adjustedBookMinor: $adjustedBookMinor, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CsvImportBatchesTable extends CsvImportBatches
    with TableInfo<$CsvImportBatchesTable, CsvBatchRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CsvImportBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _undoneAtMeta = const VerificationMeta(
    'undoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
    'undone_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    fingerprint,
    createdAt,
    undoneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'csv_import_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CsvBatchRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('undone_at')) {
      context.handle(
        _undoneAtMeta,
        undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CsvBatchRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CsvBatchRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      undoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}undone_at'],
      ),
    );
  }

  @override
  $CsvImportBatchesTable createAlias(String alias) {
    return $CsvImportBatchesTable(attachedDatabase, alias);
  }
}

class CsvBatchRecord extends DataClass implements Insertable<CsvBatchRecord> {
  final String id;
  final String name;
  final String fingerprint;
  final DateTime createdAt;
  final DateTime? undoneAt;
  const CsvBatchRecord({
    required this.id,
    required this.name,
    required this.fingerprint,
    required this.createdAt,
    this.undoneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['fingerprint'] = Variable<String>(fingerprint);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    return map;
  }

  CsvImportBatchesCompanion toCompanion(bool nullToAbsent) {
    return CsvImportBatchesCompanion(
      id: Value(id),
      name: Value(name),
      fingerprint: Value(fingerprint),
      createdAt: Value(createdAt),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
    );
  }

  factory CsvBatchRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CsvBatchRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
    };
  }

  CsvBatchRecord copyWith({
    String? id,
    String? name,
    String? fingerprint,
    DateTime? createdAt,
    Value<DateTime?> undoneAt = const Value.absent(),
  }) => CsvBatchRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    fingerprint: fingerprint ?? this.fingerprint,
    createdAt: createdAt ?? this.createdAt,
    undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
  );
  CsvBatchRecord copyWithCompanion(CsvImportBatchesCompanion data) {
    return CsvBatchRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CsvBatchRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('undoneAt: $undoneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, fingerprint, createdAt, undoneAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CsvBatchRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.fingerprint == this.fingerprint &&
          other.createdAt == this.createdAt &&
          other.undoneAt == this.undoneAt);
}

class CsvImportBatchesCompanion extends UpdateCompanion<CsvBatchRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> fingerprint;
  final Value<DateTime> createdAt;
  final Value<DateTime?> undoneAt;
  final Value<int> rowid;
  const CsvImportBatchesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CsvImportBatchesCompanion.insert({
    required String id,
    required String name,
    required String fingerprint,
    required DateTime createdAt,
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fingerprint = Value(fingerprint),
       createdAt = Value(createdAt);
  static Insertable<CsvBatchRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? fingerprint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? undoneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (createdAt != null) 'created_at': createdAt,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CsvImportBatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? fingerprint,
    Value<DateTime>? createdAt,
    Value<DateTime?>? undoneAt,
    Value<int>? rowid,
  }) {
    return CsvImportBatchesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
      undoneAt: undoneAt ?? this.undoneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CsvImportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CsvImportRowsTable extends CsvImportRows
    with TableInfo<$CsvImportRowsTable, CsvImportRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CsvImportRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES csv_import_batches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rowNumberMeta = const VerificationMeta(
    'rowNumber',
  );
  @override
  late final GeneratedColumn<int> rowNumber = GeneratedColumn<int>(
    'row_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineMeta = const VerificationMeta('line');
  @override
  late final GeneratedColumn<int> line = GeneratedColumn<int>(
    'line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileRowKeyMeta = const VerificationMeta(
    'fileRowKey',
  );
  @override
  late final GeneratedColumn<String> fileRowKey = GeneratedColumn<String>(
    'file_row_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_entries (id)',
    ),
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    rowNumber,
    line,
    fileRowKey,
    sourceKey,
    signature,
    rawJson,
    entryId,
    snapshot,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'csv_import_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CsvImportRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('row_number')) {
      context.handle(
        _rowNumberMeta,
        rowNumber.isAcceptableOrUnknown(data['row_number']!, _rowNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_rowNumberMeta);
    }
    if (data.containsKey('line')) {
      context.handle(
        _lineMeta,
        line.isAcceptableOrUnknown(data['line']!, _lineMeta),
      );
    } else if (isInserting) {
      context.missing(_lineMeta);
    }
    if (data.containsKey('file_row_key')) {
      context.handle(
        _fileRowKeyMeta,
        fileRowKey.isAcceptableOrUnknown(
          data['file_row_key']!,
          _fileRowKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileRowKeyMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId, rowNumber};
  @override
  CsvImportRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CsvImportRecord(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      rowNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_number'],
      )!,
      line: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line'],
      )!,
      fileRowKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_row_key'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $CsvImportRowsTable createAlias(String alias) {
    return $CsvImportRowsTable(attachedDatabase, alias);
  }
}

class CsvImportRecord extends DataClass implements Insertable<CsvImportRecord> {
  final String batchId;
  final int rowNumber;
  final int line;
  final String fileRowKey;
  final String? sourceKey;
  final String signature;
  final String rawJson;
  final String entryId;
  final String? snapshot;
  final bool active;
  const CsvImportRecord({
    required this.batchId,
    required this.rowNumber,
    required this.line,
    required this.fileRowKey,
    this.sourceKey,
    required this.signature,
    required this.rawJson,
    required this.entryId,
    this.snapshot,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['row_number'] = Variable<int>(rowNumber);
    map['line'] = Variable<int>(line);
    map['file_row_key'] = Variable<String>(fileRowKey);
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    map['signature'] = Variable<String>(signature);
    map['raw_json'] = Variable<String>(rawJson);
    map['entry_id'] = Variable<String>(entryId);
    if (!nullToAbsent || snapshot != null) {
      map['snapshot'] = Variable<String>(snapshot);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  CsvImportRowsCompanion toCompanion(bool nullToAbsent) {
    return CsvImportRowsCompanion(
      batchId: Value(batchId),
      rowNumber: Value(rowNumber),
      line: Value(line),
      fileRowKey: Value(fileRowKey),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      signature: Value(signature),
      rawJson: Value(rawJson),
      entryId: Value(entryId),
      snapshot: snapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshot),
      active: Value(active),
    );
  }

  factory CsvImportRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CsvImportRecord(
      batchId: serializer.fromJson<String>(json['batchId']),
      rowNumber: serializer.fromJson<int>(json['rowNumber']),
      line: serializer.fromJson<int>(json['line']),
      fileRowKey: serializer.fromJson<String>(json['fileRowKey']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      signature: serializer.fromJson<String>(json['signature']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      entryId: serializer.fromJson<String>(json['entryId']),
      snapshot: serializer.fromJson<String?>(json['snapshot']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'rowNumber': serializer.toJson<int>(rowNumber),
      'line': serializer.toJson<int>(line),
      'fileRowKey': serializer.toJson<String>(fileRowKey),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'signature': serializer.toJson<String>(signature),
      'rawJson': serializer.toJson<String>(rawJson),
      'entryId': serializer.toJson<String>(entryId),
      'snapshot': serializer.toJson<String?>(snapshot),
      'active': serializer.toJson<bool>(active),
    };
  }

  CsvImportRecord copyWith({
    String? batchId,
    int? rowNumber,
    int? line,
    String? fileRowKey,
    Value<String?> sourceKey = const Value.absent(),
    String? signature,
    String? rawJson,
    String? entryId,
    Value<String?> snapshot = const Value.absent(),
    bool? active,
  }) => CsvImportRecord(
    batchId: batchId ?? this.batchId,
    rowNumber: rowNumber ?? this.rowNumber,
    line: line ?? this.line,
    fileRowKey: fileRowKey ?? this.fileRowKey,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    signature: signature ?? this.signature,
    rawJson: rawJson ?? this.rawJson,
    entryId: entryId ?? this.entryId,
    snapshot: snapshot.present ? snapshot.value : this.snapshot,
    active: active ?? this.active,
  );
  CsvImportRecord copyWithCompanion(CsvImportRowsCompanion data) {
    return CsvImportRecord(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      rowNumber: data.rowNumber.present ? data.rowNumber.value : this.rowNumber,
      line: data.line.present ? data.line.value : this.line,
      fileRowKey: data.fileRowKey.present
          ? data.fileRowKey.value
          : this.fileRowKey,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      signature: data.signature.present ? data.signature.value : this.signature,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CsvImportRecord(')
          ..write('batchId: $batchId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('line: $line, ')
          ..write('fileRowKey: $fileRowKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('signature: $signature, ')
          ..write('rawJson: $rawJson, ')
          ..write('entryId: $entryId, ')
          ..write('snapshot: $snapshot, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    rowNumber,
    line,
    fileRowKey,
    sourceKey,
    signature,
    rawJson,
    entryId,
    snapshot,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CsvImportRecord &&
          other.batchId == this.batchId &&
          other.rowNumber == this.rowNumber &&
          other.line == this.line &&
          other.fileRowKey == this.fileRowKey &&
          other.sourceKey == this.sourceKey &&
          other.signature == this.signature &&
          other.rawJson == this.rawJson &&
          other.entryId == this.entryId &&
          other.snapshot == this.snapshot &&
          other.active == this.active);
}

class CsvImportRowsCompanion extends UpdateCompanion<CsvImportRecord> {
  final Value<String> batchId;
  final Value<int> rowNumber;
  final Value<int> line;
  final Value<String> fileRowKey;
  final Value<String?> sourceKey;
  final Value<String> signature;
  final Value<String> rawJson;
  final Value<String> entryId;
  final Value<String?> snapshot;
  final Value<bool> active;
  final Value<int> rowid;
  const CsvImportRowsCompanion({
    this.batchId = const Value.absent(),
    this.rowNumber = const Value.absent(),
    this.line = const Value.absent(),
    this.fileRowKey = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.signature = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.entryId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CsvImportRowsCompanion.insert({
    required String batchId,
    required int rowNumber,
    required int line,
    required String fileRowKey,
    this.sourceKey = const Value.absent(),
    required String signature,
    required String rawJson,
    required String entryId,
    this.snapshot = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       rowNumber = Value(rowNumber),
       line = Value(line),
       fileRowKey = Value(fileRowKey),
       signature = Value(signature),
       rawJson = Value(rawJson),
       entryId = Value(entryId);
  static Insertable<CsvImportRecord> custom({
    Expression<String>? batchId,
    Expression<int>? rowNumber,
    Expression<int>? line,
    Expression<String>? fileRowKey,
    Expression<String>? sourceKey,
    Expression<String>? signature,
    Expression<String>? rawJson,
    Expression<String>? entryId,
    Expression<String>? snapshot,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (rowNumber != null) 'row_number': rowNumber,
      if (line != null) 'line': line,
      if (fileRowKey != null) 'file_row_key': fileRowKey,
      if (sourceKey != null) 'source_key': sourceKey,
      if (signature != null) 'signature': signature,
      if (rawJson != null) 'raw_json': rawJson,
      if (entryId != null) 'entry_id': entryId,
      if (snapshot != null) 'snapshot': snapshot,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CsvImportRowsCompanion copyWith({
    Value<String>? batchId,
    Value<int>? rowNumber,
    Value<int>? line,
    Value<String>? fileRowKey,
    Value<String?>? sourceKey,
    Value<String>? signature,
    Value<String>? rawJson,
    Value<String>? entryId,
    Value<String?>? snapshot,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return CsvImportRowsCompanion(
      batchId: batchId ?? this.batchId,
      rowNumber: rowNumber ?? this.rowNumber,
      line: line ?? this.line,
      fileRowKey: fileRowKey ?? this.fileRowKey,
      sourceKey: sourceKey ?? this.sourceKey,
      signature: signature ?? this.signature,
      rawJson: rawJson ?? this.rawJson,
      entryId: entryId ?? this.entryId,
      snapshot: snapshot ?? this.snapshot,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (rowNumber.present) {
      map['row_number'] = Variable<int>(rowNumber.value);
    }
    if (line.present) {
      map['line'] = Variable<int>(line.value);
    }
    if (fileRowKey.present) {
      map['file_row_key'] = Variable<String>(fileRowKey.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CsvImportRowsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('line: $line, ')
          ..write('fileRowKey: $fileRowKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('signature: $signature, ')
          ..write('rawJson: $rawJson, ')
          ..write('entryId: $entryId, ')
          ..write('snapshot: $snapshot, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportCategoryRulesTable extends ImportCategoryRules
    with TableInfo<$ImportCategoryRulesTable, ImportCategoryRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportCategoryRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_categories (id)',
    ),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    field,
    keyword,
    categoryId,
    priority,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_category_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportCategoryRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportCategoryRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportCategoryRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      keyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $ImportCategoryRulesTable createAlias(String alias) {
    return $ImportCategoryRulesTable(attachedDatabase, alias);
  }
}

class ImportCategoryRuleRow extends DataClass
    implements Insertable<ImportCategoryRuleRow> {
  final String id;
  final String field;
  final String keyword;
  final String categoryId;
  final int priority;
  final bool enabled;
  const ImportCategoryRuleRow({
    required this.id,
    required this.field,
    required this.keyword,
    required this.categoryId,
    required this.priority,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['field'] = Variable<String>(field);
    map['keyword'] = Variable<String>(keyword);
    map['category_id'] = Variable<String>(categoryId);
    map['priority'] = Variable<int>(priority);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  ImportCategoryRulesCompanion toCompanion(bool nullToAbsent) {
    return ImportCategoryRulesCompanion(
      id: Value(id),
      field: Value(field),
      keyword: Value(keyword),
      categoryId: Value(categoryId),
      priority: Value(priority),
      enabled: Value(enabled),
    );
  }

  factory ImportCategoryRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportCategoryRuleRow(
      id: serializer.fromJson<String>(json['id']),
      field: serializer.fromJson<String>(json['field']),
      keyword: serializer.fromJson<String>(json['keyword']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      priority: serializer.fromJson<int>(json['priority']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'field': serializer.toJson<String>(field),
      'keyword': serializer.toJson<String>(keyword),
      'categoryId': serializer.toJson<String>(categoryId),
      'priority': serializer.toJson<int>(priority),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  ImportCategoryRuleRow copyWith({
    String? id,
    String? field,
    String? keyword,
    String? categoryId,
    int? priority,
    bool? enabled,
  }) => ImportCategoryRuleRow(
    id: id ?? this.id,
    field: field ?? this.field,
    keyword: keyword ?? this.keyword,
    categoryId: categoryId ?? this.categoryId,
    priority: priority ?? this.priority,
    enabled: enabled ?? this.enabled,
  );
  ImportCategoryRuleRow copyWithCompanion(ImportCategoryRulesCompanion data) {
    return ImportCategoryRuleRow(
      id: data.id.present ? data.id.value : this.id,
      field: data.field.present ? data.field.value : this.field,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      priority: data.priority.present ? data.priority.value : this.priority,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportCategoryRuleRow(')
          ..write('id: $id, ')
          ..write('field: $field, ')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, field, keyword, categoryId, priority, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportCategoryRuleRow &&
          other.id == this.id &&
          other.field == this.field &&
          other.keyword == this.keyword &&
          other.categoryId == this.categoryId &&
          other.priority == this.priority &&
          other.enabled == this.enabled);
}

class ImportCategoryRulesCompanion
    extends UpdateCompanion<ImportCategoryRuleRow> {
  final Value<String> id;
  final Value<String> field;
  final Value<String> keyword;
  final Value<String> categoryId;
  final Value<int> priority;
  final Value<bool> enabled;
  final Value<int> rowid;
  const ImportCategoryRulesCompanion({
    this.id = const Value.absent(),
    this.field = const Value.absent(),
    this.keyword = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportCategoryRulesCompanion.insert({
    required String id,
    required String field,
    required String keyword,
    required String categoryId,
    required int priority,
    required bool enabled,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       field = Value(field),
       keyword = Value(keyword),
       categoryId = Value(categoryId),
       priority = Value(priority),
       enabled = Value(enabled);
  static Insertable<ImportCategoryRuleRow> custom({
    Expression<String>? id,
    Expression<String>? field,
    Expression<String>? keyword,
    Expression<String>? categoryId,
    Expression<int>? priority,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (field != null) 'field': field,
      if (keyword != null) 'keyword': keyword,
      if (categoryId != null) 'category_id': categoryId,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportCategoryRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? field,
    Value<String>? keyword,
    Value<String>? categoryId,
    Value<int>? priority,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return ImportCategoryRulesCompanion(
      id: id ?? this.id,
      field: field ?? this.field,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportCategoryRulesCompanion(')
          ..write('id: $id, ')
          ..write('field: $field, ')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpendingPlansTable extends SpendingPlans
    with TableInfo<$SpendingPlansTable, SpendingPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpendingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitMinorMeta = const VerificationMeta(
    'limitMinor',
  );
  @override
  late final GeneratedColumn<int> limitMinor = GeneratedColumn<int>(
    'limit_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsOnMeta = const VerificationMeta(
    'startsOn',
  );
  @override
  late final GeneratedColumn<String> startsOn = GeneratedColumn<String>(
    'starts_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rolloverMeta = const VerificationMeta(
    'rollover',
  );
  @override
  late final GeneratedColumn<bool> rollover = GeneratedColumn<bool>(
    'rollover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rollover" IN (0, 1))',
    ),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_accounts (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledger_categories (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currency,
    scope,
    limitMinor,
    startsOn,
    endsOn,
    rollover,
    archived,
    accountId,
    categoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spending_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpendingPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('limit_minor')) {
      context.handle(
        _limitMinorMeta,
        limitMinor.isAcceptableOrUnknown(data['limit_minor']!, _limitMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_limitMinorMeta);
    }
    if (data.containsKey('starts_on')) {
      context.handle(
        _startsOnMeta,
        startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_startsOnMeta);
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('rollover')) {
      context.handle(
        _rolloverMeta,
        rollover.isAcceptableOrUnknown(data['rollover']!, _rolloverMeta),
      );
    } else if (isInserting) {
      context.missing(_rolloverMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    } else if (isInserting) {
      context.missing(_archivedMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpendingPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpendingPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      limitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_minor'],
      )!,
      startsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_on'],
      )!,
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      rollover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rollover'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
    );
  }

  @override
  $SpendingPlansTable createAlias(String alias) {
    return $SpendingPlansTable(attachedDatabase, alias);
  }
}

class SpendingPlanRow extends DataClass implements Insertable<SpendingPlanRow> {
  final String id;
  final String name;
  final String currency;
  final String scope;
  final int limitMinor;
  final String startsOn;
  final String? endsOn;
  final bool rollover;
  final bool archived;
  final String? accountId;
  final String? categoryId;
  const SpendingPlanRow({
    required this.id,
    required this.name,
    required this.currency,
    required this.scope,
    required this.limitMinor,
    required this.startsOn,
    this.endsOn,
    required this.rollover,
    required this.archived,
    this.accountId,
    this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['scope'] = Variable<String>(scope);
    map['limit_minor'] = Variable<int>(limitMinor);
    map['starts_on'] = Variable<String>(startsOn);
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    map['rollover'] = Variable<bool>(rollover);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    return map;
  }

  SpendingPlansCompanion toCompanion(bool nullToAbsent) {
    return SpendingPlansCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      scope: Value(scope),
      limitMinor: Value(limitMinor),
      startsOn: Value(startsOn),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      rollover: Value(rollover),
      archived: Value(archived),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
    );
  }

  factory SpendingPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpendingPlanRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      scope: serializer.fromJson<String>(json['scope']),
      limitMinor: serializer.fromJson<int>(json['limitMinor']),
      startsOn: serializer.fromJson<String>(json['startsOn']),
      endsOn: serializer.fromJson<String?>(json['endsOn']),
      rollover: serializer.fromJson<bool>(json['rollover']),
      archived: serializer.fromJson<bool>(json['archived']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'scope': serializer.toJson<String>(scope),
      'limitMinor': serializer.toJson<int>(limitMinor),
      'startsOn': serializer.toJson<String>(startsOn),
      'endsOn': serializer.toJson<String?>(endsOn),
      'rollover': serializer.toJson<bool>(rollover),
      'archived': serializer.toJson<bool>(archived),
      'accountId': serializer.toJson<String?>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
    };
  }

  SpendingPlanRow copyWith({
    String? id,
    String? name,
    String? currency,
    String? scope,
    int? limitMinor,
    String? startsOn,
    Value<String?> endsOn = const Value.absent(),
    bool? rollover,
    bool? archived,
    Value<String?> accountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
  }) => SpendingPlanRow(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    scope: scope ?? this.scope,
    limitMinor: limitMinor ?? this.limitMinor,
    startsOn: startsOn ?? this.startsOn,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    rollover: rollover ?? this.rollover,
    archived: archived ?? this.archived,
    accountId: accountId.present ? accountId.value : this.accountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  SpendingPlanRow copyWithCompanion(SpendingPlansCompanion data) {
    return SpendingPlanRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      scope: data.scope.present ? data.scope.value : this.scope,
      limitMinor: data.limitMinor.present
          ? data.limitMinor.value
          : this.limitMinor,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      rollover: data.rollover.present ? data.rollover.value : this.rollover,
      archived: data.archived.present ? data.archived.value : this.archived,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpendingPlanRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('scope: $scope, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('rollover: $rollover, ')
          ..write('archived: $archived, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    currency,
    scope,
    limitMinor,
    startsOn,
    endsOn,
    rollover,
    archived,
    accountId,
    categoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpendingPlanRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.scope == this.scope &&
          other.limitMinor == this.limitMinor &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.rollover == this.rollover &&
          other.archived == this.archived &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId);
}

class SpendingPlansCompanion extends UpdateCompanion<SpendingPlanRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<String> scope;
  final Value<int> limitMinor;
  final Value<String> startsOn;
  final Value<String?> endsOn;
  final Value<bool> rollover;
  final Value<bool> archived;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<int> rowid;
  const SpendingPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.scope = const Value.absent(),
    this.limitMinor = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.rollover = const Value.absent(),
    this.archived = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpendingPlansCompanion.insert({
    required String id,
    required String name,
    required String currency,
    required String scope,
    required int limitMinor,
    required String startsOn,
    this.endsOn = const Value.absent(),
    required bool rollover,
    required bool archived,
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       currency = Value(currency),
       scope = Value(scope),
       limitMinor = Value(limitMinor),
       startsOn = Value(startsOn),
       rollover = Value(rollover),
       archived = Value(archived);
  static Insertable<SpendingPlanRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<String>? scope,
    Expression<int>? limitMinor,
    Expression<String>? startsOn,
    Expression<String>? endsOn,
    Expression<bool>? rollover,
    Expression<bool>? archived,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (scope != null) 'scope': scope,
      if (limitMinor != null) 'limit_minor': limitMinor,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (rollover != null) 'rollover': rollover,
      if (archived != null) 'archived': archived,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpendingPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<String>? scope,
    Value<int>? limitMinor,
    Value<String>? startsOn,
    Value<String?>? endsOn,
    Value<bool>? rollover,
    Value<bool>? archived,
    Value<String?>? accountId,
    Value<String?>? categoryId,
    Value<int>? rowid,
  }) {
    return SpendingPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      scope: scope ?? this.scope,
      limitMinor: limitMinor ?? this.limitMinor,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      rollover: rollover ?? this.rollover,
      archived: archived ?? this.archived,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (limitMinor.present) {
      map['limit_minor'] = Variable<int>(limitMinor.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<String>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (rollover.present) {
      map['rollover'] = Variable<bool>(rollover.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpendingPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('scope: $scope, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('rollover: $rollover, ')
          ..write('archived: $archived, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpendingPlanLimitsTable extends SpendingPlanLimits
    with TableInfo<$SpendingPlanLimitsTable, SpendingPlanLimitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpendingPlanLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES spending_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<String> periodStart = GeneratedColumn<String>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitMinorMeta = const VerificationMeta(
    'limitMinor',
  );
  @override
  late final GeneratedColumn<int> limitMinor = GeneratedColumn<int>(
    'limit_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ongoingMeta = const VerificationMeta(
    'ongoing',
  );
  @override
  late final GeneratedColumn<bool> ongoing = GeneratedColumn<bool>(
    'ongoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ongoing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _savedAtMicrosMeta = const VerificationMeta(
    'savedAtMicros',
  );
  @override
  late final GeneratedColumn<int> savedAtMicros = GeneratedColumn<int>(
    'saved_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    periodStart,
    limitMinor,
    ongoing,
    savedAtMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spending_plan_limits';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpendingPlanLimitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('limit_minor')) {
      context.handle(
        _limitMinorMeta,
        limitMinor.isAcceptableOrUnknown(data['limit_minor']!, _limitMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_limitMinorMeta);
    }
    if (data.containsKey('ongoing')) {
      context.handle(
        _ongoingMeta,
        ongoing.isAcceptableOrUnknown(data['ongoing']!, _ongoingMeta),
      );
    } else if (isInserting) {
      context.missing(_ongoingMeta);
    }
    if (data.containsKey('saved_at_micros')) {
      context.handle(
        _savedAtMicrosMeta,
        savedAtMicros.isAcceptableOrUnknown(
          data['saved_at_micros']!,
          _savedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedAtMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpendingPlanLimitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpendingPlanLimitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_start'],
      )!,
      limitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_minor'],
      )!,
      ongoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ongoing'],
      )!,
      savedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_at_micros'],
      )!,
    );
  }

  @override
  $SpendingPlanLimitsTable createAlias(String alias) {
    return $SpendingPlanLimitsTable(attachedDatabase, alias);
  }
}

class SpendingPlanLimitRow extends DataClass
    implements Insertable<SpendingPlanLimitRow> {
  final String id;
  final String planId;
  final String periodStart;
  final int limitMinor;
  final bool ongoing;
  final int savedAtMicros;
  const SpendingPlanLimitRow({
    required this.id,
    required this.planId,
    required this.periodStart,
    required this.limitMinor,
    required this.ongoing,
    required this.savedAtMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['period_start'] = Variable<String>(periodStart);
    map['limit_minor'] = Variable<int>(limitMinor);
    map['ongoing'] = Variable<bool>(ongoing);
    map['saved_at_micros'] = Variable<int>(savedAtMicros);
    return map;
  }

  SpendingPlanLimitsCompanion toCompanion(bool nullToAbsent) {
    return SpendingPlanLimitsCompanion(
      id: Value(id),
      planId: Value(planId),
      periodStart: Value(periodStart),
      limitMinor: Value(limitMinor),
      ongoing: Value(ongoing),
      savedAtMicros: Value(savedAtMicros),
    );
  }

  factory SpendingPlanLimitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpendingPlanLimitRow(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      periodStart: serializer.fromJson<String>(json['periodStart']),
      limitMinor: serializer.fromJson<int>(json['limitMinor']),
      ongoing: serializer.fromJson<bool>(json['ongoing']),
      savedAtMicros: serializer.fromJson<int>(json['savedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'periodStart': serializer.toJson<String>(periodStart),
      'limitMinor': serializer.toJson<int>(limitMinor),
      'ongoing': serializer.toJson<bool>(ongoing),
      'savedAtMicros': serializer.toJson<int>(savedAtMicros),
    };
  }

  SpendingPlanLimitRow copyWith({
    String? id,
    String? planId,
    String? periodStart,
    int? limitMinor,
    bool? ongoing,
    int? savedAtMicros,
  }) => SpendingPlanLimitRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    periodStart: periodStart ?? this.periodStart,
    limitMinor: limitMinor ?? this.limitMinor,
    ongoing: ongoing ?? this.ongoing,
    savedAtMicros: savedAtMicros ?? this.savedAtMicros,
  );
  SpendingPlanLimitRow copyWithCompanion(SpendingPlanLimitsCompanion data) {
    return SpendingPlanLimitRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      limitMinor: data.limitMinor.present
          ? data.limitMinor.value
          : this.limitMinor,
      ongoing: data.ongoing.present ? data.ongoing.value : this.ongoing,
      savedAtMicros: data.savedAtMicros.present
          ? data.savedAtMicros.value
          : this.savedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpendingPlanLimitRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('ongoing: $ongoing, ')
          ..write('savedAtMicros: $savedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planId, periodStart, limitMinor, ongoing, savedAtMicros);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpendingPlanLimitRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.periodStart == this.periodStart &&
          other.limitMinor == this.limitMinor &&
          other.ongoing == this.ongoing &&
          other.savedAtMicros == this.savedAtMicros);
}

class SpendingPlanLimitsCompanion
    extends UpdateCompanion<SpendingPlanLimitRow> {
  final Value<String> id;
  final Value<String> planId;
  final Value<String> periodStart;
  final Value<int> limitMinor;
  final Value<bool> ongoing;
  final Value<int> savedAtMicros;
  final Value<int> rowid;
  const SpendingPlanLimitsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.limitMinor = const Value.absent(),
    this.ongoing = const Value.absent(),
    this.savedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpendingPlanLimitsCompanion.insert({
    required String id,
    required String planId,
    required String periodStart,
    required int limitMinor,
    required bool ongoing,
    required int savedAtMicros,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       periodStart = Value(periodStart),
       limitMinor = Value(limitMinor),
       ongoing = Value(ongoing),
       savedAtMicros = Value(savedAtMicros);
  static Insertable<SpendingPlanLimitRow> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<String>? periodStart,
    Expression<int>? limitMinor,
    Expression<bool>? ongoing,
    Expression<int>? savedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (periodStart != null) 'period_start': periodStart,
      if (limitMinor != null) 'limit_minor': limitMinor,
      if (ongoing != null) 'ongoing': ongoing,
      if (savedAtMicros != null) 'saved_at_micros': savedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpendingPlanLimitsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<String>? periodStart,
    Value<int>? limitMinor,
    Value<bool>? ongoing,
    Value<int>? savedAtMicros,
    Value<int>? rowid,
  }) {
    return SpendingPlanLimitsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      periodStart: periodStart ?? this.periodStart,
      limitMinor: limitMinor ?? this.limitMinor,
      ongoing: ongoing ?? this.ongoing,
      savedAtMicros: savedAtMicros ?? this.savedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<String>(periodStart.value);
    }
    if (limitMinor.present) {
      map['limit_minor'] = Variable<int>(limitMinor.value);
    }
    if (ongoing.present) {
      map['ongoing'] = Variable<bool>(ongoing.value);
    }
    if (savedAtMicros.present) {
      map['saved_at_micros'] = Variable<int>(savedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpendingPlanLimitsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('periodStart: $periodStart, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('ongoing: $ongoing, ')
          ..write('savedAtMicros: $savedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LedgerAccountsTable ledgerAccounts = $LedgerAccountsTable(this);
  late final $LedgerCategoriesTable ledgerCategories = $LedgerCategoriesTable(
    this,
  );
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $LedgerPostingsTable ledgerPostings = $LedgerPostingsTable(this);
  late final $ValuationPreferencesTable valuationPreferences =
      $ValuationPreferencesTable(this);
  late final $ValuationRatesTable valuationRates = $ValuationRatesTable(this);
  late final $BalanceCheckpointsTable balanceCheckpoints =
      $BalanceCheckpointsTable(this);
  late final $CsvImportBatchesTable csvImportBatches = $CsvImportBatchesTable(
    this,
  );
  late final $CsvImportRowsTable csvImportRows = $CsvImportRowsTable(this);
  late final $ImportCategoryRulesTable importCategoryRules =
      $ImportCategoryRulesTable(this);
  late final $SpendingPlansTable spendingPlans = $SpendingPlansTable(this);
  late final $SpendingPlanLimitsTable spendingPlanLimits =
      $SpendingPlanLimitsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ledgerAccounts,
    ledgerCategories,
    ledgerEntries,
    ledgerPostings,
    valuationPreferences,
    valuationRates,
    balanceCheckpoints,
    csvImportBatches,
    csvImportRows,
    importCategoryRules,
    spendingPlans,
    spendingPlanLimits,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ledger_postings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'csv_import_batches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('csv_import_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'spending_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('spending_plan_limits', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LedgerAccountsTableCreateCompanionBuilder =
    LedgerAccountsCompanion Function({
      required String id,
      required String name,
      required String kind,
      Value<String> currencyCode,
      Value<int> openingBalanceMinor,
      Value<int> sortOrder,
      Value<bool> isArchived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LedgerAccountsTableUpdateCompanionBuilder =
    LedgerAccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String> currencyCode,
      Value<int> openingBalanceMinor,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LedgerAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerAccountsTable, AccountRow> {
  $$LedgerAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LedgerEntriesTable, List<EntryRow>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'ledger_accounts__id__ledger_entries__account_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<EntryRow>>
  _targetLedgerEntriesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'ledger_accounts__id__ledger_entries__target_account_id',
  );

  $$LedgerEntriesTableProcessedTableManager get targetLedgerEntries {
    final manager = $$LedgerEntriesTableTableManager($_db, $_db.ledgerEntries)
        .filter(
          (f) => f.targetAccountId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _targetLedgerEntriesTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerPostingsTable, List<PostingRow>>
  _ledgerPostingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerPostings,
    aliasName: 'ledger_accounts__id__ledger_postings__account_id',
  );

  $$LedgerPostingsTableProcessedTableManager get ledgerPostingsRefs {
    final manager = $$LedgerPostingsTableTableManager(
      $_db,
      $_db.ledgerPostings,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerPostingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BalanceCheckpointsTable, List<CheckpointRow>>
  _balanceCheckpointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.balanceCheckpoints,
        aliasName: 'ledger_accounts__id__balance_checkpoints__account_id',
      );

  $$BalanceCheckpointsTableProcessedTableManager get balanceCheckpointsRefs {
    final manager = $$BalanceCheckpointsTableTableManager(
      $_db,
      $_db.balanceCheckpoints,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _balanceCheckpointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SpendingPlansTable, List<SpendingPlanRow>>
  _spendingPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.spendingPlans,
    aliasName: 'ledger_accounts__id__spending_plans__account_id',
  );

  $$SpendingPlansTableProcessedTableManager get spendingPlansRefs {
    final manager = $$SpendingPlansTableTableManager(
      $_db,
      $_db.spendingPlans,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_spendingPlansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LedgerAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> targetLedgerEntries(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.targetAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerPostingsRefs(
    Expression<bool> Function($$LedgerPostingsTableFilterComposer f) f,
  ) {
    final $$LedgerPostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerPostings,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerPostingsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerPostings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> balanceCheckpointsRefs(
    Expression<bool> Function($$BalanceCheckpointsTableFilterComposer f) f,
  ) {
    final $$BalanceCheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceCheckpoints,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceCheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.balanceCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> spendingPlansRefs(
    Expression<bool> Function($$SpendingPlansTableFilterComposer f) f,
  ) {
    final $$SpendingPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableFilterComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgerAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerAccountsTable> {
  $$LedgerAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> targetLedgerEntries<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.targetAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerPostingsRefs<T extends Object>(
    Expression<T> Function($$LedgerPostingsTableAnnotationComposer a) f,
  ) {
    final $$LedgerPostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerPostings,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerPostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerPostings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> balanceCheckpointsRefs<T extends Object>(
    Expression<T> Function($$BalanceCheckpointsTableAnnotationComposer a) f,
  ) {
    final $$BalanceCheckpointsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.balanceCheckpoints,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BalanceCheckpointsTableAnnotationComposer(
                $db: $db,
                $table: $db.balanceCheckpoints,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> spendingPlansRefs<T extends Object>(
    Expression<T> Function($$SpendingPlansTableAnnotationComposer a) f,
  ) {
    final $$SpendingPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerAccountsTable,
          AccountRow,
          $$LedgerAccountsTableFilterComposer,
          $$LedgerAccountsTableOrderingComposer,
          $$LedgerAccountsTableAnnotationComposer,
          $$LedgerAccountsTableCreateCompanionBuilder,
          $$LedgerAccountsTableUpdateCompanionBuilder,
          (AccountRow, $$LedgerAccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool ledgerEntriesRefs,
            bool targetLedgerEntries,
            bool ledgerPostingsRefs,
            bool balanceCheckpointsRefs,
            bool spendingPlansRefs,
          })
        > {
  $$LedgerAccountsTableTableManager(
    _$AppDatabase db,
    $LedgerAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerAccountsCompanion(
                id: id,
                name: name,
                kind: kind,
                currencyCode: currencyCode,
                openingBalanceMinor: openingBalanceMinor,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<String> currencyCode = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerAccountsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                currencyCode: currencyCode,
                openingBalanceMinor: openingBalanceMinor,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerAccountsTable, AccountRow>(table),
                  $$LedgerAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ledgerEntriesRefs = false,
                targetLedgerEntries = false,
                ledgerPostingsRefs = false,
                balanceCheckpointsRefs = false,
                spendingPlansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (targetLedgerEntries) db.ledgerEntries,
                    if (ledgerPostingsRefs) db.ledgerPostings,
                    if (balanceCheckpointsRefs) db.balanceCheckpoints,
                    if (spendingPlansRefs) db.spendingPlans,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $LedgerAccountsTable,
                          EntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerAccountsTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (targetLedgerEntries)
                        await $_getPrefetchedData<
                          AccountRow,
                          $LedgerAccountsTable,
                          EntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerAccountsTableReferences
                              ._targetLedgerEntriesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).targetLedgerEntries,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.targetAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerPostingsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $LedgerAccountsTable,
                          PostingRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerAccountsTableReferences
                              ._ledgerPostingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerPostingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (balanceCheckpointsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $LedgerAccountsTable,
                          CheckpointRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerAccountsTableReferences
                              ._balanceCheckpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).balanceCheckpointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (spendingPlansRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $LedgerAccountsTable,
                          SpendingPlanRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerAccountsTableReferences
                              ._spendingPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).spendingPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LedgerAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerAccountsTable,
      AccountRow,
      $$LedgerAccountsTableFilterComposer,
      $$LedgerAccountsTableOrderingComposer,
      $$LedgerAccountsTableAnnotationComposer,
      $$LedgerAccountsTableCreateCompanionBuilder,
      $$LedgerAccountsTableUpdateCompanionBuilder,
      (AccountRow, $$LedgerAccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool ledgerEntriesRefs,
        bool targetLedgerEntries,
        bool ledgerPostingsRefs,
        bool balanceCheckpointsRefs,
        bool spendingPlansRefs,
      })
    >;
typedef $$LedgerCategoriesTableCreateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String> transactionType,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<bool> isArchived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LedgerCategoriesTableUpdateCompanionBuilder =
    LedgerCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> transactionType,
      Value<String?> parentId,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LedgerCategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerCategoriesTable, CategoryRow> {
  $$LedgerCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerCategoriesTable _parentIdTable(_$AppDatabase db) => db
      .ledgerCategories
      .createAlias('ledger_categories__parent_id__ledger_categories__id');

  $$LedgerCategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$LedgerCategoriesTableTableManager(
      $_db,
      $_db.ledgerCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<EntryRow>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'ledger_categories__id__ledger_entries__category_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ImportCategoryRulesTable,
    List<ImportCategoryRuleRow>
  >
  _importCategoryRulesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.importCategoryRules,
        aliasName: 'ledger_categories__id__import_category_rules__category_id',
      );

  $$ImportCategoryRulesTableProcessedTableManager get importCategoryRulesRefs {
    final manager = $$ImportCategoryRulesTableTableManager(
      $_db,
      $_db.importCategoryRules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _importCategoryRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SpendingPlansTable, List<SpendingPlanRow>>
  _spendingPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.spendingPlans,
    aliasName: 'ledger_categories__id__spending_plans__category_id',
  );

  $$SpendingPlansTableProcessedTableManager get spendingPlansRefs {
    final manager = $$SpendingPlansTableTableManager(
      $_db,
      $_db.spendingPlans,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_spendingPlansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LedgerCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerCategoriesTableFilterComposer get parentId {
    final $$LedgerCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> importCategoryRulesRefs(
    Expression<bool> Function($$ImportCategoryRulesTableFilterComposer f) f,
  ) {
    final $$ImportCategoryRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importCategoryRules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportCategoryRulesTableFilterComposer(
            $db: $db,
            $table: $db.importCategoryRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> spendingPlansRefs(
    Expression<bool> Function($$SpendingPlansTableFilterComposer f) f,
  ) {
    final $$SpendingPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableFilterComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerCategoriesTableOrderingComposer get parentId {
    final $$LedgerCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerCategoriesTable> {
  $$LedgerCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LedgerCategoriesTableAnnotationComposer get parentId {
    final $$LedgerCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> importCategoryRulesRefs<T extends Object>(
    Expression<T> Function($$ImportCategoryRulesTableAnnotationComposer a) f,
  ) {
    final $$ImportCategoryRulesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.importCategoryRules,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ImportCategoryRulesTableAnnotationComposer(
                $db: $db,
                $table: $db.importCategoryRules,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> spendingPlansRefs<T extends Object>(
    Expression<T> Function($$SpendingPlansTableAnnotationComposer a) f,
  ) {
    final $$SpendingPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerCategoriesTable,
          CategoryRow,
          $$LedgerCategoriesTableFilterComposer,
          $$LedgerCategoriesTableOrderingComposer,
          $$LedgerCategoriesTableAnnotationComposer,
          $$LedgerCategoriesTableCreateCompanionBuilder,
          $$LedgerCategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$LedgerCategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool parentId,
            bool ledgerEntriesRefs,
            bool importCategoryRulesRefs,
            bool spendingPlansRefs,
          })
        > {
  $$LedgerCategoriesTableTableManager(
    _$AppDatabase db,
    $LedgerCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion(
                id: id,
                name: name,
                transactionType: transactionType,
                parentId: parentId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> transactionType = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoriesCompanion.insert(
                id: id,
                name: name,
                transactionType: transactionType,
                parentId: parentId,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerCategoriesTable, CategoryRow>(table),
                  $$LedgerCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                ledgerEntriesRefs = false,
                importCategoryRulesRefs = false,
                spendingPlansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (importCategoryRulesRefs) db.importCategoryRules,
                    if (spendingPlansRefs) db.spendingPlans,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$LedgerCategoriesTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$LedgerCategoriesTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $LedgerCategoriesTable,
                          EntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerCategoriesTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (importCategoryRulesRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $LedgerCategoriesTable,
                          ImportCategoryRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerCategoriesTableReferences
                              ._importCategoryRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).importCategoryRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (spendingPlansRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $LedgerCategoriesTable,
                          SpendingPlanRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerCategoriesTableReferences
                              ._spendingPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerCategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).spendingPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LedgerCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerCategoriesTable,
      CategoryRow,
      $$LedgerCategoriesTableFilterComposer,
      $$LedgerCategoriesTableOrderingComposer,
      $$LedgerCategoriesTableAnnotationComposer,
      $$LedgerCategoriesTableCreateCompanionBuilder,
      $$LedgerCategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$LedgerCategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool parentId,
        bool ledgerEntriesRefs,
        bool importCategoryRulesRefs,
        bool spendingPlansRefs,
      })
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required String transactionType,
      required int amountMinor,
      Value<String> currencyCode,
      required DateTime occurredAt,
      required int timezoneOffsetMinutes,
      required String categoryId,
      required String accountId,
      Value<String?> targetAccountId,
      Value<String> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<String> status,
      Value<String?> refundOfId,
      Value<int?> settlementAmountMinor,
      Value<String?> settlementCurrencyCode,
      Value<String?> quotedExchangeRate,
      Value<String?> termsJson,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> transactionType,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<DateTime> occurredAt,
      Value<int> timezoneOffsetMinutes,
      Value<String> categoryId,
      Value<String> accountId,
      Value<String?> targetAccountId,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<String> status,
      Value<String?> refundOfId,
      Value<int?> settlementAmountMinor,
      Value<String?> settlementCurrencyCode,
      Value<String?> quotedExchangeRate,
      Value<String?> termsJson,
      Value<int> rowid,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, EntryRow> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .ledgerCategories
      .createAlias('ledger_entries__category_id__ledger_categories__id');

  $$LedgerCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$LedgerCategoriesTableTableManager(
      $_db,
      $_db.ledgerCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerAccountsTable _accountIdTable(_$AppDatabase db) => db
      .ledgerAccounts
      .createAlias('ledger_entries__account_id__ledger_accounts__id');

  $$LedgerAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$LedgerAccountsTableTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerAccountsTable _targetAccountIdTable(_$AppDatabase db) => db
      .ledgerAccounts
      .createAlias('ledger_entries__target_account_id__ledger_accounts__id');

  $$LedgerAccountsTableProcessedTableManager? get targetAccountId {
    final $_column = $_itemColumn<String>('target_account_id');
    if ($_column == null) return null;
    final manager = $$LedgerAccountsTableTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerEntriesTable _refundOfIdTable(_$AppDatabase db) => db
      .ledgerEntries
      .createAlias('ledger_entries__refund_of_id__ledger_entries__id');

  $$LedgerEntriesTableProcessedTableManager? get refundOfId {
    final $_column = $_itemColumn<String>('refund_of_id');
    if ($_column == null) return null;
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_refundOfIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerPostingsTable, List<PostingRow>>
  _ledgerPostingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerPostings,
    aliasName: 'ledger_entries__id__ledger_postings__transaction_id',
  );

  $$LedgerPostingsTableProcessedTableManager get ledgerPostingsRefs {
    final manager = $$LedgerPostingsTableTableManager(
      $_db,
      $_db.ledgerPostings,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerPostingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BalanceCheckpointsTable, List<CheckpointRow>>
  _balanceCheckpointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.balanceCheckpoints,
        aliasName: 'ledger_entries__id__balance_checkpoints__adjustment_id',
      );

  $$BalanceCheckpointsTableProcessedTableManager get balanceCheckpointsRefs {
    final manager = $$BalanceCheckpointsTableTableManager(
      $_db,
      $_db.balanceCheckpoints,
    ).filter((f) => f.adjustmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _balanceCheckpointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CsvImportRowsTable, List<CsvImportRecord>>
  _csvImportRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.csvImportRows,
    aliasName: 'ledger_entries__id__csv_import_rows__entry_id',
  );

  $$CsvImportRowsTableProcessedTableManager get csvImportRowsRefs {
    final manager = $$CsvImportRowsTableTableManager(
      $_db,
      $_db.csvImportRows,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_csvImportRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get settlementAmountMinor => $composableBuilder(
    column: $table.settlementAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settlementCurrencyCode => $composableBuilder(
    column: $table.settlementCurrencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotedExchangeRate => $composableBuilder(
    column: $table.quotedExchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termsJson => $composableBuilder(
    column: $table.termsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerCategoriesTableFilterComposer get categoryId {
    final $$LedgerCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableFilterComposer get accountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableFilterComposer get targetAccountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableFilterComposer get refundOfId {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOfId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerPostingsRefs(
    Expression<bool> Function($$LedgerPostingsTableFilterComposer f) f,
  ) {
    final $$LedgerPostingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerPostings,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerPostingsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerPostings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> balanceCheckpointsRefs(
    Expression<bool> Function($$BalanceCheckpointsTableFilterComposer f) f,
  ) {
    final $$BalanceCheckpointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.balanceCheckpoints,
      getReferencedColumn: (t) => t.adjustmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BalanceCheckpointsTableFilterComposer(
            $db: $db,
            $table: $db.balanceCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> csvImportRowsRefs(
    Expression<bool> Function($$CsvImportRowsTableFilterComposer f) f,
  ) {
    final $$CsvImportRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.csvImportRows,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportRowsTableFilterComposer(
            $db: $db,
            $table: $db.csvImportRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get settlementAmountMinor => $composableBuilder(
    column: $table.settlementAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settlementCurrencyCode => $composableBuilder(
    column: $table.settlementCurrencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotedExchangeRate => $composableBuilder(
    column: $table.quotedExchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termsJson => $composableBuilder(
    column: $table.termsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerCategoriesTableOrderingComposer get categoryId {
    final $$LedgerCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableOrderingComposer get accountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableOrderingComposer get targetAccountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableOrderingComposer get refundOfId {
    final $$LedgerEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOfId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timezoneOffsetMinutes => $composableBuilder(
    column: $table.timezoneOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get settlementAmountMinor => $composableBuilder(
    column: $table.settlementAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settlementCurrencyCode => $composableBuilder(
    column: $table.settlementCurrencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quotedExchangeRate => $composableBuilder(
    column: $table.quotedExchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get termsJson =>
      $composableBuilder(column: $table.termsJson, builder: (column) => column);

  $$LedgerCategoriesTableAnnotationComposer get categoryId {
    final $$LedgerCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableAnnotationComposer get accountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableAnnotationComposer get targetAccountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetAccountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableAnnotationComposer get refundOfId {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.refundOfId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerPostingsRefs<T extends Object>(
    Expression<T> Function($$LedgerPostingsTableAnnotationComposer a) f,
  ) {
    final $$LedgerPostingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerPostings,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerPostingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerPostings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> balanceCheckpointsRefs<T extends Object>(
    Expression<T> Function($$BalanceCheckpointsTableAnnotationComposer a) f,
  ) {
    final $$BalanceCheckpointsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.balanceCheckpoints,
          getReferencedColumn: (t) => t.adjustmentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BalanceCheckpointsTableAnnotationComposer(
                $db: $db,
                $table: $db.balanceCheckpoints,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> csvImportRowsRefs<T extends Object>(
    Expression<T> Function($$CsvImportRowsTableAnnotationComposer a) f,
  ) {
    final $$CsvImportRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.csvImportRows,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.csvImportRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          EntryRow,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (EntryRow, $$LedgerEntriesTableReferences),
          EntryRow,
          PrefetchHooks Function({
            bool categoryId,
            bool accountId,
            bool targetAccountId,
            bool refundOfId,
            bool ledgerPostingsRefs,
            bool balanceCheckpointsRefs,
            bool csvImportRowsRefs,
          })
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> timezoneOffsetMinutes = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> targetAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> refundOfId = const Value.absent(),
                Value<int?> settlementAmountMinor = const Value.absent(),
                Value<String?> settlementCurrencyCode = const Value.absent(),
                Value<String?> quotedExchangeRate = const Value.absent(),
                Value<String?> termsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                transactionType: transactionType,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                occurredAt: occurredAt,
                timezoneOffsetMinutes: timezoneOffsetMinutes,
                categoryId: categoryId,
                accountId: accountId,
                targetAccountId: targetAccountId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                status: status,
                refundOfId: refundOfId,
                settlementAmountMinor: settlementAmountMinor,
                settlementCurrencyCode: settlementCurrencyCode,
                quotedExchangeRate: quotedExchangeRate,
                termsJson: termsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionType,
                required int amountMinor,
                Value<String> currencyCode = const Value.absent(),
                required DateTime occurredAt,
                required int timezoneOffsetMinutes,
                required String categoryId,
                required String accountId,
                Value<String?> targetAccountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> refundOfId = const Value.absent(),
                Value<int?> settlementAmountMinor = const Value.absent(),
                Value<String?> settlementCurrencyCode = const Value.absent(),
                Value<String?> quotedExchangeRate = const Value.absent(),
                Value<String?> termsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                transactionType: transactionType,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                occurredAt: occurredAt,
                timezoneOffsetMinutes: timezoneOffsetMinutes,
                categoryId: categoryId,
                accountId: accountId,
                targetAccountId: targetAccountId,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                status: status,
                refundOfId: refundOfId,
                settlementAmountMinor: settlementAmountMinor,
                settlementCurrencyCode: settlementCurrencyCode,
                quotedExchangeRate: quotedExchangeRate,
                termsJson: termsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, EntryRow>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                accountId = false,
                targetAccountId = false,
                refundOfId = false,
                ledgerPostingsRefs = false,
                balanceCheckpointsRefs = false,
                csvImportRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerPostingsRefs) db.ledgerPostings,
                    if (balanceCheckpointsRefs) db.balanceCheckpoints,
                    if (csvImportRowsRefs) db.csvImportRows,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$LedgerEntriesTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$LedgerEntriesTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$LedgerEntriesTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$LedgerEntriesTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (targetAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.targetAccountId,
                            referencedTable: $$LedgerEntriesTableReferences
                                ._targetAccountIdTable(db),
                            referencedColumn: $$LedgerEntriesTableReferences
                                ._targetAccountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (refundOfId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.refundOfId,
                            referencedTable: $$LedgerEntriesTableReferences
                                ._refundOfIdTable(db),
                            referencedColumn: $$LedgerEntriesTableReferences
                                ._refundOfIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerPostingsRefs)
                        await $_getPrefetchedData<
                          EntryRow,
                          $LedgerEntriesTable,
                          PostingRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerEntriesTableReferences
                              ._ledgerPostingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerPostingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (balanceCheckpointsRefs)
                        await $_getPrefetchedData<
                          EntryRow,
                          $LedgerEntriesTable,
                          CheckpointRow
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerEntriesTableReferences
                              ._balanceCheckpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).balanceCheckpointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.adjustmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (csvImportRowsRefs)
                        await $_getPrefetchedData<
                          EntryRow,
                          $LedgerEntriesTable,
                          CsvImportRecord
                        >(
                          currentTable: table,
                          referencedTable: $$LedgerEntriesTableReferences
                              ._csvImportRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgerEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).csvImportRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      EntryRow,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (EntryRow, $$LedgerEntriesTableReferences),
      EntryRow,
      PrefetchHooks Function({
        bool categoryId,
        bool accountId,
        bool targetAccountId,
        bool refundOfId,
        bool ledgerPostingsRefs,
        bool balanceCheckpointsRefs,
        bool csvImportRowsRefs,
      })
    >;
typedef $$LedgerPostingsTableCreateCompanionBuilder =
    LedgerPostingsCompanion Function({
      required String transactionId,
      required int position,
      Value<String?> accountId,
      required String currencyCode,
      required int debitMinor,
      required String role,
      Value<bool> needsReview,
      Value<int> rowid,
    });
typedef $$LedgerPostingsTableUpdateCompanionBuilder =
    LedgerPostingsCompanion Function({
      Value<String> transactionId,
      Value<int> position,
      Value<String?> accountId,
      Value<String> currencyCode,
      Value<int> debitMinor,
      Value<String> role,
      Value<bool> needsReview,
      Value<int> rowid,
    });

final class $$LedgerPostingsTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerPostingsTable, PostingRow> {
  $$LedgerPostingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerEntriesTable _transactionIdTable(_$AppDatabase db) => db
      .ledgerEntries
      .createAlias('ledger_postings__transaction_id__ledger_entries__id');

  $$LedgerEntriesTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerAccountsTable _accountIdTable(_$AppDatabase db) => db
      .ledgerAccounts
      .createAlias('ledger_postings__account_id__ledger_accounts__id');

  $$LedgerAccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$LedgerAccountsTableTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerPostingsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerPostingsTable> {
  $$LedgerPostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debitMinor => $composableBuilder(
    column: $table.debitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerEntriesTableFilterComposer get transactionId {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableFilterComposer get accountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerPostingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerPostingsTable> {
  $$LedgerPostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debitMinor => $composableBuilder(
    column: $table.debitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerEntriesTableOrderingComposer get transactionId {
    final $$LedgerEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableOrderingComposer get accountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerPostingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerPostingsTable> {
  $$LedgerPostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get debitMinor => $composableBuilder(
    column: $table.debitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  $$LedgerEntriesTableAnnotationComposer get transactionId {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerAccountsTableAnnotationComposer get accountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerPostingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerPostingsTable,
          PostingRow,
          $$LedgerPostingsTableFilterComposer,
          $$LedgerPostingsTableOrderingComposer,
          $$LedgerPostingsTableAnnotationComposer,
          $$LedgerPostingsTableCreateCompanionBuilder,
          $$LedgerPostingsTableUpdateCompanionBuilder,
          (PostingRow, $$LedgerPostingsTableReferences),
          PostingRow,
          PrefetchHooks Function({bool transactionId, bool accountId})
        > {
  $$LedgerPostingsTableTableManager(
    _$AppDatabase db,
    $LedgerPostingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerPostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerPostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerPostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> transactionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> debitMinor = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerPostingsCompanion(
                transactionId: transactionId,
                position: position,
                accountId: accountId,
                currencyCode: currencyCode,
                debitMinor: debitMinor,
                role: role,
                needsReview: needsReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String transactionId,
                required int position,
                Value<String?> accountId = const Value.absent(),
                required String currencyCode,
                required int debitMinor,
                required String role,
                Value<bool> needsReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerPostingsCompanion.insert(
                transactionId: transactionId,
                position: position,
                accountId: accountId,
                currencyCode: currencyCode,
                debitMinor: debitMinor,
                role: role,
                needsReview: needsReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerPostingsTable, PostingRow>(table),
                  $$LedgerPostingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$LedgerPostingsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$LedgerPostingsTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$LedgerPostingsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$LedgerPostingsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LedgerPostingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerPostingsTable,
      PostingRow,
      $$LedgerPostingsTableFilterComposer,
      $$LedgerPostingsTableOrderingComposer,
      $$LedgerPostingsTableAnnotationComposer,
      $$LedgerPostingsTableCreateCompanionBuilder,
      $$LedgerPostingsTableUpdateCompanionBuilder,
      (PostingRow, $$LedgerPostingsTableReferences),
      PostingRow,
      PrefetchHooks Function({bool transactionId, bool accountId})
    >;
typedef $$ValuationPreferencesTableCreateCompanionBuilder =
    ValuationPreferencesCompanion Function({
      Value<int> id,
      required String baseCurrency,
    });
typedef $$ValuationPreferencesTableUpdateCompanionBuilder =
    ValuationPreferencesCompanion Function({
      Value<int> id,
      Value<String> baseCurrency,
    });

class $$ValuationPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $ValuationPreferencesTable> {
  $$ValuationPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ValuationPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $ValuationPreferencesTable> {
  $$ValuationPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ValuationPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ValuationPreferencesTable> {
  $$ValuationPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );
}

class $$ValuationPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ValuationPreferencesTable,
          ValuationBaseRow,
          $$ValuationPreferencesTableFilterComposer,
          $$ValuationPreferencesTableOrderingComposer,
          $$ValuationPreferencesTableAnnotationComposer,
          $$ValuationPreferencesTableCreateCompanionBuilder,
          $$ValuationPreferencesTableUpdateCompanionBuilder,
          (
            ValuationBaseRow,
            BaseReferences<
              _$AppDatabase,
              $ValuationPreferencesTable,
              ValuationBaseRow
            >,
          ),
          ValuationBaseRow,
          PrefetchHooks Function()
        > {
  $$ValuationPreferencesTableTableManager(
    _$AppDatabase db,
    $ValuationPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValuationPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValuationPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ValuationPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
              }) => ValuationPreferencesCompanion(
                id: id,
                baseCurrency: baseCurrency,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baseCurrency,
              }) => ValuationPreferencesCompanion.insert(
                id: id,
                baseCurrency: baseCurrency,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ValuationPreferencesTable, ValuationBaseRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ValuationPreferencesTable,
                    ValuationBaseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ValuationPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ValuationPreferencesTable,
      ValuationBaseRow,
      $$ValuationPreferencesTableFilterComposer,
      $$ValuationPreferencesTableOrderingComposer,
      $$ValuationPreferencesTableAnnotationComposer,
      $$ValuationPreferencesTableCreateCompanionBuilder,
      $$ValuationPreferencesTableUpdateCompanionBuilder,
      (
        ValuationBaseRow,
        BaseReferences<
          _$AppDatabase,
          $ValuationPreferencesTable,
          ValuationBaseRow
        >,
      ),
      ValuationBaseRow,
      PrefetchHooks Function()
    >;
typedef $$ValuationRatesTableCreateCompanionBuilder =
    ValuationRatesCompanion Function({
      required String baseCurrency,
      required String sourceCurrency,
      required String rate,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ValuationRatesTableUpdateCompanionBuilder =
    ValuationRatesCompanion Function({
      Value<String> baseCurrency,
      Value<String> sourceCurrency,
      Value<String> rate,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ValuationRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ValuationRatesTable> {
  $$ValuationRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceCurrency => $composableBuilder(
    column: $table.sourceCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ValuationRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ValuationRatesTable> {
  $$ValuationRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceCurrency => $composableBuilder(
    column: $table.sourceCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ValuationRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ValuationRatesTable> {
  $$ValuationRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceCurrency => $composableBuilder(
    column: $table.sourceCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ValuationRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ValuationRatesTable,
          ValuationRateRow,
          $$ValuationRatesTableFilterComposer,
          $$ValuationRatesTableOrderingComposer,
          $$ValuationRatesTableAnnotationComposer,
          $$ValuationRatesTableCreateCompanionBuilder,
          $$ValuationRatesTableUpdateCompanionBuilder,
          (
            ValuationRateRow,
            BaseReferences<
              _$AppDatabase,
              $ValuationRatesTable,
              ValuationRateRow
            >,
          ),
          ValuationRateRow,
          PrefetchHooks Function()
        > {
  $$ValuationRatesTableTableManager(
    _$AppDatabase db,
    $ValuationRatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValuationRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValuationRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ValuationRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> baseCurrency = const Value.absent(),
                Value<String> sourceCurrency = const Value.absent(),
                Value<String> rate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ValuationRatesCompanion(
                baseCurrency: baseCurrency,
                sourceCurrency: sourceCurrency,
                rate: rate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String baseCurrency,
                required String sourceCurrency,
                required String rate,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ValuationRatesCompanion.insert(
                baseCurrency: baseCurrency,
                sourceCurrency: sourceCurrency,
                rate: rate,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ValuationRatesTable, ValuationRateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ValuationRatesTable,
                    ValuationRateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ValuationRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ValuationRatesTable,
      ValuationRateRow,
      $$ValuationRatesTableFilterComposer,
      $$ValuationRatesTableOrderingComposer,
      $$ValuationRatesTableAnnotationComposer,
      $$ValuationRatesTableCreateCompanionBuilder,
      $$ValuationRatesTableUpdateCompanionBuilder,
      (
        ValuationRateRow,
        BaseReferences<_$AppDatabase, $ValuationRatesTable, ValuationRateRow>,
      ),
      ValuationRateRow,
      PrefetchHooks Function()
    >;
typedef $$BalanceCheckpointsTableCreateCompanionBuilder =
    BalanceCheckpointsCompanion Function({
      required String id,
      required String accountId,
      required String currencyCode,
      required DateTime observedAt,
      required int actualMinor,
      required int recordedBookMinor,
      Value<String?> adjustmentId,
      Value<int?> adjustedBookMinor,
      required String note,
      required DateTime createdAt,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });
typedef $$BalanceCheckpointsTableUpdateCompanionBuilder =
    BalanceCheckpointsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> currencyCode,
      Value<DateTime> observedAt,
      Value<int> actualMinor,
      Value<int> recordedBookMinor,
      Value<String?> adjustmentId,
      Value<int?> adjustedBookMinor,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<DateTime?> voidedAt,
      Value<int> rowid,
    });

final class $$BalanceCheckpointsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BalanceCheckpointsTable, CheckpointRow> {
  $$BalanceCheckpointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerAccountsTable _accountIdTable(_$AppDatabase db) => db
      .ledgerAccounts
      .createAlias('balance_checkpoints__account_id__ledger_accounts__id');

  $$LedgerAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$LedgerAccountsTableTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerEntriesTable _adjustmentIdTable(_$AppDatabase db) => db
      .ledgerEntries
      .createAlias('balance_checkpoints__adjustment_id__ledger_entries__id');

  $$LedgerEntriesTableProcessedTableManager? get adjustmentId {
    final $_column = $_itemColumn<String>('adjustment_id');
    if ($_column == null) return null;
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_adjustmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BalanceCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedBookMinor => $composableBuilder(
    column: $table.recordedBookMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustedBookMinor => $composableBuilder(
    column: $table.adjustedBookMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerAccountsTableFilterComposer get accountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableFilterComposer get adjustmentId {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedBookMinor => $composableBuilder(
    column: $table.recordedBookMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustedBookMinor => $composableBuilder(
    column: $table.adjustedBookMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerAccountsTableOrderingComposer get accountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableOrderingComposer get adjustmentId {
    final $$LedgerEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceCheckpointsTable> {
  $$BalanceCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedBookMinor => $composableBuilder(
    column: $table.recordedBookMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get adjustedBookMinor => $composableBuilder(
    column: $table.adjustedBookMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  $$LedgerAccountsTableAnnotationComposer get accountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableAnnotationComposer get adjustmentId {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.adjustmentId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BalanceCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceCheckpointsTable,
          CheckpointRow,
          $$BalanceCheckpointsTableFilterComposer,
          $$BalanceCheckpointsTableOrderingComposer,
          $$BalanceCheckpointsTableAnnotationComposer,
          $$BalanceCheckpointsTableCreateCompanionBuilder,
          $$BalanceCheckpointsTableUpdateCompanionBuilder,
          (CheckpointRow, $$BalanceCheckpointsTableReferences),
          CheckpointRow,
          PrefetchHooks Function({bool accountId, bool adjustmentId})
        > {
  $$BalanceCheckpointsTableTableManager(
    _$AppDatabase db,
    $BalanceCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceCheckpointsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> observedAt = const Value.absent(),
                Value<int> actualMinor = const Value.absent(),
                Value<int> recordedBookMinor = const Value.absent(),
                Value<String?> adjustmentId = const Value.absent(),
                Value<int?> adjustedBookMinor = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceCheckpointsCompanion(
                id: id,
                accountId: accountId,
                currencyCode: currencyCode,
                observedAt: observedAt,
                actualMinor: actualMinor,
                recordedBookMinor: recordedBookMinor,
                adjustmentId: adjustmentId,
                adjustedBookMinor: adjustedBookMinor,
                note: note,
                createdAt: createdAt,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String currencyCode,
                required DateTime observedAt,
                required int actualMinor,
                required int recordedBookMinor,
                Value<String?> adjustmentId = const Value.absent(),
                Value<int?> adjustedBookMinor = const Value.absent(),
                required String note,
                required DateTime createdAt,
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceCheckpointsCompanion.insert(
                id: id,
                accountId: accountId,
                currencyCode: currencyCode,
                observedAt: observedAt,
                actualMinor: actualMinor,
                recordedBookMinor: recordedBookMinor,
                adjustmentId: adjustmentId,
                adjustedBookMinor: adjustedBookMinor,
                note: note,
                createdAt: createdAt,
                voidedAt: voidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BalanceCheckpointsTable, CheckpointRow>(table),
                  $$BalanceCheckpointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false, adjustmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$BalanceCheckpointsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$BalanceCheckpointsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (adjustmentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.adjustmentId,
                        referencedTable: $$BalanceCheckpointsTableReferences
                            ._adjustmentIdTable(db),
                        referencedColumn: $$BalanceCheckpointsTableReferences
                            ._adjustmentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BalanceCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceCheckpointsTable,
      CheckpointRow,
      $$BalanceCheckpointsTableFilterComposer,
      $$BalanceCheckpointsTableOrderingComposer,
      $$BalanceCheckpointsTableAnnotationComposer,
      $$BalanceCheckpointsTableCreateCompanionBuilder,
      $$BalanceCheckpointsTableUpdateCompanionBuilder,
      (CheckpointRow, $$BalanceCheckpointsTableReferences),
      CheckpointRow,
      PrefetchHooks Function({bool accountId, bool adjustmentId})
    >;
typedef $$CsvImportBatchesTableCreateCompanionBuilder =
    CsvImportBatchesCompanion Function({
      required String id,
      required String name,
      required String fingerprint,
      required DateTime createdAt,
      Value<DateTime?> undoneAt,
      Value<int> rowid,
    });
typedef $$CsvImportBatchesTableUpdateCompanionBuilder =
    CsvImportBatchesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> fingerprint,
      Value<DateTime> createdAt,
      Value<DateTime?> undoneAt,
      Value<int> rowid,
    });

final class $$CsvImportBatchesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CsvImportBatchesTable, CsvBatchRecord> {
  $$CsvImportBatchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CsvImportRowsTable, List<CsvImportRecord>>
  _csvImportRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.csvImportRows,
    aliasName: 'csv_import_batches__id__csv_import_rows__batch_id',
  );

  $$CsvImportRowsTableProcessedTableManager get csvImportRowsRefs {
    final manager = $$CsvImportRowsTableTableManager(
      $_db,
      $_db.csvImportRows,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_csvImportRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CsvImportBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $CsvImportBatchesTable> {
  $$CsvImportBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> csvImportRowsRefs(
    Expression<bool> Function($$CsvImportRowsTableFilterComposer f) f,
  ) {
    final $$CsvImportRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.csvImportRows,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportRowsTableFilterComposer(
            $db: $db,
            $table: $db.csvImportRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CsvImportBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CsvImportBatchesTable> {
  $$CsvImportBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CsvImportBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CsvImportBatchesTable> {
  $$CsvImportBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);

  Expression<T> csvImportRowsRefs<T extends Object>(
    Expression<T> Function($$CsvImportRowsTableAnnotationComposer a) f,
  ) {
    final $$CsvImportRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.csvImportRows,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.csvImportRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CsvImportBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CsvImportBatchesTable,
          CsvBatchRecord,
          $$CsvImportBatchesTableFilterComposer,
          $$CsvImportBatchesTableOrderingComposer,
          $$CsvImportBatchesTableAnnotationComposer,
          $$CsvImportBatchesTableCreateCompanionBuilder,
          $$CsvImportBatchesTableUpdateCompanionBuilder,
          (CsvBatchRecord, $$CsvImportBatchesTableReferences),
          CsvBatchRecord,
          PrefetchHooks Function({bool csvImportRowsRefs})
        > {
  $$CsvImportBatchesTableTableManager(
    _$AppDatabase db,
    $CsvImportBatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CsvImportBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CsvImportBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CsvImportBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CsvImportBatchesCompanion(
                id: id,
                name: name,
                fingerprint: fingerprint,
                createdAt: createdAt,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String fingerprint,
                required DateTime createdAt,
                Value<DateTime?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CsvImportBatchesCompanion.insert(
                id: id,
                name: name,
                fingerprint: fingerprint,
                createdAt: createdAt,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CsvImportBatchesTable, CsvBatchRecord>(table),
                  $$CsvImportBatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({csvImportRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (csvImportRowsRefs) db.csvImportRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (csvImportRowsRefs)
                    await $_getPrefetchedData<
                      CsvBatchRecord,
                      $CsvImportBatchesTable,
                      CsvImportRecord
                    >(
                      currentTable: table,
                      referencedTable: $$CsvImportBatchesTableReferences
                          ._csvImportRowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CsvImportBatchesTableReferences(
                            db,
                            table,
                            p0,
                          ).csvImportRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.batchId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CsvImportBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CsvImportBatchesTable,
      CsvBatchRecord,
      $$CsvImportBatchesTableFilterComposer,
      $$CsvImportBatchesTableOrderingComposer,
      $$CsvImportBatchesTableAnnotationComposer,
      $$CsvImportBatchesTableCreateCompanionBuilder,
      $$CsvImportBatchesTableUpdateCompanionBuilder,
      (CsvBatchRecord, $$CsvImportBatchesTableReferences),
      CsvBatchRecord,
      PrefetchHooks Function({bool csvImportRowsRefs})
    >;
typedef $$CsvImportRowsTableCreateCompanionBuilder =
    CsvImportRowsCompanion Function({
      required String batchId,
      required int rowNumber,
      required int line,
      required String fileRowKey,
      Value<String?> sourceKey,
      required String signature,
      required String rawJson,
      required String entryId,
      Value<String?> snapshot,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$CsvImportRowsTableUpdateCompanionBuilder =
    CsvImportRowsCompanion Function({
      Value<String> batchId,
      Value<int> rowNumber,
      Value<int> line,
      Value<String> fileRowKey,
      Value<String?> sourceKey,
      Value<String> signature,
      Value<String> rawJson,
      Value<String> entryId,
      Value<String?> snapshot,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$CsvImportRowsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CsvImportRowsTable, CsvImportRecord> {
  $$CsvImportRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CsvImportBatchesTable _batchIdTable(_$AppDatabase db) => db
      .csvImportBatches
      .createAlias('csv_import_rows__batch_id__csv_import_batches__id');

  $$CsvImportBatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$CsvImportBatchesTableTableManager(
      $_db,
      $_db.csvImportBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerEntriesTable _entryIdTable(_$AppDatabase db) => db.ledgerEntries
      .createAlias('csv_import_rows__entry_id__ledger_entries__id');

  $$LedgerEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CsvImportRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CsvImportRowsTable> {
  $$CsvImportRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowNumber => $composableBuilder(
    column: $table.rowNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileRowKey => $composableBuilder(
    column: $table.fileRowKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  $$CsvImportBatchesTableFilterComposer get batchId {
    final $$CsvImportBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.csvImportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportBatchesTableFilterComposer(
            $db: $db,
            $table: $db.csvImportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableFilterComposer get entryId {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CsvImportRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CsvImportRowsTable> {
  $$CsvImportRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowNumber => $composableBuilder(
    column: $table.rowNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get line => $composableBuilder(
    column: $table.line,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileRowKey => $composableBuilder(
    column: $table.fileRowKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  $$CsvImportBatchesTableOrderingComposer get batchId {
    final $$CsvImportBatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.csvImportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportBatchesTableOrderingComposer(
            $db: $db,
            $table: $db.csvImportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableOrderingComposer get entryId {
    final $$LedgerEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CsvImportRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CsvImportRowsTable> {
  $$CsvImportRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowNumber =>
      $composableBuilder(column: $table.rowNumber, builder: (column) => column);

  GeneratedColumn<int> get line =>
      $composableBuilder(column: $table.line, builder: (column) => column);

  GeneratedColumn<String> get fileRowKey => $composableBuilder(
    column: $table.fileRowKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  $$CsvImportBatchesTableAnnotationComposer get batchId {
    final $$CsvImportBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.csvImportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CsvImportBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.csvImportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerEntriesTableAnnotationComposer get entryId {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CsvImportRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CsvImportRowsTable,
          CsvImportRecord,
          $$CsvImportRowsTableFilterComposer,
          $$CsvImportRowsTableOrderingComposer,
          $$CsvImportRowsTableAnnotationComposer,
          $$CsvImportRowsTableCreateCompanionBuilder,
          $$CsvImportRowsTableUpdateCompanionBuilder,
          (CsvImportRecord, $$CsvImportRowsTableReferences),
          CsvImportRecord,
          PrefetchHooks Function({bool batchId, bool entryId})
        > {
  $$CsvImportRowsTableTableManager(_$AppDatabase db, $CsvImportRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CsvImportRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CsvImportRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CsvImportRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> batchId = const Value.absent(),
                Value<int> rowNumber = const Value.absent(),
                Value<int> line = const Value.absent(),
                Value<String> fileRowKey = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String?> snapshot = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CsvImportRowsCompanion(
                batchId: batchId,
                rowNumber: rowNumber,
                line: line,
                fileRowKey: fileRowKey,
                sourceKey: sourceKey,
                signature: signature,
                rawJson: rawJson,
                entryId: entryId,
                snapshot: snapshot,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String batchId,
                required int rowNumber,
                required int line,
                required String fileRowKey,
                Value<String?> sourceKey = const Value.absent(),
                required String signature,
                required String rawJson,
                required String entryId,
                Value<String?> snapshot = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CsvImportRowsCompanion.insert(
                batchId: batchId,
                rowNumber: rowNumber,
                line: line,
                fileRowKey: fileRowKey,
                sourceKey: sourceKey,
                signature: signature,
                rawJson: rawJson,
                entryId: entryId,
                snapshot: snapshot,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CsvImportRowsTable, CsvImportRecord>(table),
                  $$CsvImportRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.batchId,
                        referencedTable: $$CsvImportRowsTableReferences
                            ._batchIdTable(db),
                        referencedColumn: $$CsvImportRowsTableReferences
                            ._batchIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$CsvImportRowsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$CsvImportRowsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CsvImportRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CsvImportRowsTable,
      CsvImportRecord,
      $$CsvImportRowsTableFilterComposer,
      $$CsvImportRowsTableOrderingComposer,
      $$CsvImportRowsTableAnnotationComposer,
      $$CsvImportRowsTableCreateCompanionBuilder,
      $$CsvImportRowsTableUpdateCompanionBuilder,
      (CsvImportRecord, $$CsvImportRowsTableReferences),
      CsvImportRecord,
      PrefetchHooks Function({bool batchId, bool entryId})
    >;
typedef $$ImportCategoryRulesTableCreateCompanionBuilder =
    ImportCategoryRulesCompanion Function({
      required String id,
      required String field,
      required String keyword,
      required String categoryId,
      required int priority,
      required bool enabled,
      Value<int> rowid,
    });
typedef $$ImportCategoryRulesTableUpdateCompanionBuilder =
    ImportCategoryRulesCompanion Function({
      Value<String> id,
      Value<String> field,
      Value<String> keyword,
      Value<String> categoryId,
      Value<int> priority,
      Value<bool> enabled,
      Value<int> rowid,
    });

final class $$ImportCategoryRulesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ImportCategoryRulesTable,
          ImportCategoryRuleRow
        > {
  $$ImportCategoryRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .ledgerCategories
      .createAlias('import_category_rules__category_id__ledger_categories__id');

  $$LedgerCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$LedgerCategoriesTableTableManager(
      $_db,
      $_db.ledgerCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImportCategoryRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ImportCategoryRulesTable> {
  $$ImportCategoryRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerCategoriesTableFilterComposer get categoryId {
    final $$LedgerCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportCategoryRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportCategoryRulesTable> {
  $$ImportCategoryRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerCategoriesTableOrderingComposer get categoryId {
    final $$LedgerCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportCategoryRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportCategoryRulesTable> {
  $$ImportCategoryRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$LedgerCategoriesTableAnnotationComposer get categoryId {
    final $$LedgerCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImportCategoryRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportCategoryRulesTable,
          ImportCategoryRuleRow,
          $$ImportCategoryRulesTableFilterComposer,
          $$ImportCategoryRulesTableOrderingComposer,
          $$ImportCategoryRulesTableAnnotationComposer,
          $$ImportCategoryRulesTableCreateCompanionBuilder,
          $$ImportCategoryRulesTableUpdateCompanionBuilder,
          (ImportCategoryRuleRow, $$ImportCategoryRulesTableReferences),
          ImportCategoryRuleRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$ImportCategoryRulesTableTableManager(
    _$AppDatabase db,
    $ImportCategoryRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportCategoryRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportCategoryRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ImportCategoryRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> keyword = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportCategoryRulesCompanion(
                id: id,
                field: field,
                keyword: keyword,
                categoryId: categoryId,
                priority: priority,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String field,
                required String keyword,
                required String categoryId,
                required int priority,
                required bool enabled,
                Value<int> rowid = const Value.absent(),
              }) => ImportCategoryRulesCompanion.insert(
                id: id,
                field: field,
                keyword: keyword,
                categoryId: categoryId,
                priority: priority,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportCategoryRulesTable, ImportCategoryRuleRow>(
                    table,
                  ),
                  $$ImportCategoryRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$ImportCategoryRulesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$ImportCategoryRulesTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImportCategoryRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportCategoryRulesTable,
      ImportCategoryRuleRow,
      $$ImportCategoryRulesTableFilterComposer,
      $$ImportCategoryRulesTableOrderingComposer,
      $$ImportCategoryRulesTableAnnotationComposer,
      $$ImportCategoryRulesTableCreateCompanionBuilder,
      $$ImportCategoryRulesTableUpdateCompanionBuilder,
      (ImportCategoryRuleRow, $$ImportCategoryRulesTableReferences),
      ImportCategoryRuleRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$SpendingPlansTableCreateCompanionBuilder =
    SpendingPlansCompanion Function({
      required String id,
      required String name,
      required String currency,
      required String scope,
      required int limitMinor,
      required String startsOn,
      Value<String?> endsOn,
      required bool rollover,
      required bool archived,
      Value<String?> accountId,
      Value<String?> categoryId,
      Value<int> rowid,
    });
typedef $$SpendingPlansTableUpdateCompanionBuilder =
    SpendingPlansCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currency,
      Value<String> scope,
      Value<int> limitMinor,
      Value<String> startsOn,
      Value<String?> endsOn,
      Value<bool> rollover,
      Value<bool> archived,
      Value<String?> accountId,
      Value<String?> categoryId,
      Value<int> rowid,
    });

final class $$SpendingPlansTableReferences
    extends
        BaseReferences<_$AppDatabase, $SpendingPlansTable, SpendingPlanRow> {
  $$SpendingPlansTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgerAccountsTable _accountIdTable(_$AppDatabase db) => db
      .ledgerAccounts
      .createAlias('spending_plans__account_id__ledger_accounts__id');

  $$LedgerAccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$LedgerAccountsTableTableManager(
      $_db,
      $_db.ledgerAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LedgerCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .ledgerCategories
      .createAlias('spending_plans__category_id__ledger_categories__id');

  $$LedgerCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$LedgerCategoriesTableTableManager(
      $_db,
      $_db.ledgerCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SpendingPlanLimitsTable,
    List<SpendingPlanLimitRow>
  >
  _spendingPlanLimitsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.spendingPlanLimits,
        aliasName: 'spending_plans__id__spending_plan_limits__plan_id',
      );

  $$SpendingPlanLimitsTableProcessedTableManager get spendingPlanLimitsRefs {
    final manager = $$SpendingPlanLimitsTableTableManager(
      $_db,
      $_db.spendingPlanLimits,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _spendingPlanLimitsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SpendingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $SpendingPlansTable> {
  $$SpendingPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgerAccountsTableFilterComposer get accountId {
    final $$LedgerAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerCategoriesTableFilterComposer get categoryId {
    final $$LedgerCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> spendingPlanLimitsRefs(
    Expression<bool> Function($$SpendingPlanLimitsTableFilterComposer f) f,
  ) {
    final $$SpendingPlanLimitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spendingPlanLimits,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlanLimitsTableFilterComposer(
            $db: $db,
            $table: $db.spendingPlanLimits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpendingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $SpendingPlansTable> {
  $$SpendingPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rollover => $composableBuilder(
    column: $table.rollover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgerAccountsTableOrderingComposer get accountId {
    final $$LedgerAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerCategoriesTableOrderingComposer get categoryId {
    final $$LedgerCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpendingPlansTable> {
  $$SpendingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<bool> get rollover =>
      $composableBuilder(column: $table.rollover, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  $$LedgerAccountsTableAnnotationComposer get accountId {
    final $$LedgerAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.ledgerAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LedgerCategoriesTableAnnotationComposer get categoryId {
    final $$LedgerCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.ledgerCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> spendingPlanLimitsRefs<T extends Object>(
    Expression<T> Function($$SpendingPlanLimitsTableAnnotationComposer a) f,
  ) {
    final $$SpendingPlanLimitsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.spendingPlanLimits,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SpendingPlanLimitsTableAnnotationComposer(
                $db: $db,
                $table: $db.spendingPlanLimits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SpendingPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpendingPlansTable,
          SpendingPlanRow,
          $$SpendingPlansTableFilterComposer,
          $$SpendingPlansTableOrderingComposer,
          $$SpendingPlansTableAnnotationComposer,
          $$SpendingPlansTableCreateCompanionBuilder,
          $$SpendingPlansTableUpdateCompanionBuilder,
          (SpendingPlanRow, $$SpendingPlansTableReferences),
          SpendingPlanRow,
          PrefetchHooks Function({
            bool accountId,
            bool categoryId,
            bool spendingPlanLimitsRefs,
          })
        > {
  $$SpendingPlansTableTableManager(_$AppDatabase db, $SpendingPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpendingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpendingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpendingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<int> limitMinor = const Value.absent(),
                Value<String> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<bool> rollover = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpendingPlansCompanion(
                id: id,
                name: name,
                currency: currency,
                scope: scope,
                limitMinor: limitMinor,
                startsOn: startsOn,
                endsOn: endsOn,
                rollover: rollover,
                archived: archived,
                accountId: accountId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String currency,
                required String scope,
                required int limitMinor,
                required String startsOn,
                Value<String?> endsOn = const Value.absent(),
                required bool rollover,
                required bool archived,
                Value<String?> accountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpendingPlansCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                scope: scope,
                limitMinor: limitMinor,
                startsOn: startsOn,
                endsOn: endsOn,
                rollover: rollover,
                archived: archived,
                accountId: accountId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpendingPlansTable, SpendingPlanRow>(table),
                  $$SpendingPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                categoryId = false,
                spendingPlanLimitsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (spendingPlanLimitsRefs) db.spendingPlanLimits,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$SpendingPlansTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$SpendingPlansTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$SpendingPlansTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$SpendingPlansTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (spendingPlanLimitsRefs)
                        await $_getPrefetchedData<
                          SpendingPlanRow,
                          $SpendingPlansTable,
                          SpendingPlanLimitRow
                        >(
                          currentTable: table,
                          referencedTable: $$SpendingPlansTableReferences
                              ._spendingPlanLimitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SpendingPlansTableReferences(
                                db,
                                table,
                                p0,
                              ).spendingPlanLimitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SpendingPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpendingPlansTable,
      SpendingPlanRow,
      $$SpendingPlansTableFilterComposer,
      $$SpendingPlansTableOrderingComposer,
      $$SpendingPlansTableAnnotationComposer,
      $$SpendingPlansTableCreateCompanionBuilder,
      $$SpendingPlansTableUpdateCompanionBuilder,
      (SpendingPlanRow, $$SpendingPlansTableReferences),
      SpendingPlanRow,
      PrefetchHooks Function({
        bool accountId,
        bool categoryId,
        bool spendingPlanLimitsRefs,
      })
    >;
typedef $$SpendingPlanLimitsTableCreateCompanionBuilder =
    SpendingPlanLimitsCompanion Function({
      required String id,
      required String planId,
      required String periodStart,
      required int limitMinor,
      required bool ongoing,
      required int savedAtMicros,
      Value<int> rowid,
    });
typedef $$SpendingPlanLimitsTableUpdateCompanionBuilder =
    SpendingPlanLimitsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<String> periodStart,
      Value<int> limitMinor,
      Value<bool> ongoing,
      Value<int> savedAtMicros,
      Value<int> rowid,
    });

final class $$SpendingPlanLimitsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SpendingPlanLimitsTable,
          SpendingPlanLimitRow
        > {
  $$SpendingPlanLimitsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SpendingPlansTable _planIdTable(_$AppDatabase db) => db.spendingPlans
      .createAlias('spending_plan_limits__plan_id__spending_plans__id');

  $$SpendingPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$SpendingPlansTableTableManager(
      $_db,
      $_db.spendingPlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SpendingPlanLimitsTableFilterComposer
    extends Composer<_$AppDatabase, $SpendingPlanLimitsTable> {
  $$SpendingPlanLimitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ongoing => $composableBuilder(
    column: $table.ongoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  $$SpendingPlansTableFilterComposer get planId {
    final $$SpendingPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableFilterComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingPlanLimitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SpendingPlanLimitsTable> {
  $$SpendingPlanLimitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ongoing => $composableBuilder(
    column: $table.ongoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  $$SpendingPlansTableOrderingComposer get planId {
    final $$SpendingPlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableOrderingComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingPlanLimitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpendingPlanLimitsTable> {
  $$SpendingPlanLimitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ongoing =>
      $composableBuilder(column: $table.ongoing, builder: (column) => column);

  GeneratedColumn<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => column,
  );

  $$SpendingPlansTableAnnotationComposer get planId {
    final $$SpendingPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.spendingPlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.spendingPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingPlanLimitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpendingPlanLimitsTable,
          SpendingPlanLimitRow,
          $$SpendingPlanLimitsTableFilterComposer,
          $$SpendingPlanLimitsTableOrderingComposer,
          $$SpendingPlanLimitsTableAnnotationComposer,
          $$SpendingPlanLimitsTableCreateCompanionBuilder,
          $$SpendingPlanLimitsTableUpdateCompanionBuilder,
          (SpendingPlanLimitRow, $$SpendingPlanLimitsTableReferences),
          SpendingPlanLimitRow,
          PrefetchHooks Function({bool planId})
        > {
  $$SpendingPlanLimitsTableTableManager(
    _$AppDatabase db,
    $SpendingPlanLimitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpendingPlanLimitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpendingPlanLimitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpendingPlanLimitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<String> periodStart = const Value.absent(),
                Value<int> limitMinor = const Value.absent(),
                Value<bool> ongoing = const Value.absent(),
                Value<int> savedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpendingPlanLimitsCompanion(
                id: id,
                planId: planId,
                periodStart: periodStart,
                limitMinor: limitMinor,
                ongoing: ongoing,
                savedAtMicros: savedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required String periodStart,
                required int limitMinor,
                required bool ongoing,
                required int savedAtMicros,
                Value<int> rowid = const Value.absent(),
              }) => SpendingPlanLimitsCompanion.insert(
                id: id,
                planId: planId,
                periodStart: periodStart,
                limitMinor: limitMinor,
                ongoing: ongoing,
                savedAtMicros: savedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpendingPlanLimitsTable, SpendingPlanLimitRow>(
                    table,
                  ),
                  $$SpendingPlanLimitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planId,
                        referencedTable: $$SpendingPlanLimitsTableReferences
                            ._planIdTable(db),
                        referencedColumn: $$SpendingPlanLimitsTableReferences
                            ._planIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SpendingPlanLimitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpendingPlanLimitsTable,
      SpendingPlanLimitRow,
      $$SpendingPlanLimitsTableFilterComposer,
      $$SpendingPlanLimitsTableOrderingComposer,
      $$SpendingPlanLimitsTableAnnotationComposer,
      $$SpendingPlanLimitsTableCreateCompanionBuilder,
      $$SpendingPlanLimitsTableUpdateCompanionBuilder,
      (SpendingPlanLimitRow, $$SpendingPlanLimitsTableReferences),
      SpendingPlanLimitRow,
      PrefetchHooks Function({bool planId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgerAccountsTableTableManager get ledgerAccounts =>
      $$LedgerAccountsTableTableManager(_db, _db.ledgerAccounts);
  $$LedgerCategoriesTableTableManager get ledgerCategories =>
      $$LedgerCategoriesTableTableManager(_db, _db.ledgerCategories);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$LedgerPostingsTableTableManager get ledgerPostings =>
      $$LedgerPostingsTableTableManager(_db, _db.ledgerPostings);
  $$ValuationPreferencesTableTableManager get valuationPreferences =>
      $$ValuationPreferencesTableTableManager(_db, _db.valuationPreferences);
  $$ValuationRatesTableTableManager get valuationRates =>
      $$ValuationRatesTableTableManager(_db, _db.valuationRates);
  $$BalanceCheckpointsTableTableManager get balanceCheckpoints =>
      $$BalanceCheckpointsTableTableManager(_db, _db.balanceCheckpoints);
  $$CsvImportBatchesTableTableManager get csvImportBatches =>
      $$CsvImportBatchesTableTableManager(_db, _db.csvImportBatches);
  $$CsvImportRowsTableTableManager get csvImportRows =>
      $$CsvImportRowsTableTableManager(_db, _db.csvImportRows);
  $$ImportCategoryRulesTableTableManager get importCategoryRules =>
      $$ImportCategoryRulesTableTableManager(_db, _db.importCategoryRules);
  $$SpendingPlansTableTableManager get spendingPlans =>
      $$SpendingPlansTableTableManager(_db, _db.spendingPlans);
  $$SpendingPlanLimitsTableTableManager get spendingPlanLimits =>
      $$SpendingPlanLimitsTableTableManager(_db, _db.spendingPlanLimits);
}
