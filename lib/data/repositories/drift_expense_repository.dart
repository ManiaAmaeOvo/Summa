import 'dart:math' as math;
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ledger_pro/data/database/app_database.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';
import 'package:ledger_pro/domain/defaults/default_ledger_names.dart';
import 'package:uuid/uuid.dart';

class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<LedgerAccount>> watchAccounts() {
    final query = _database.select(_database.ledgerAccounts)
      ..where((table) => table.isArchived.equals(false))
      ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => LedgerAccount(
              id: row.id,
              name: row.name,
              kind: AccountKind.values.byName(row.kind),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Stream<List<AccountBalance>> watchAccountBalances() {
    final query = _database.customSelect(
      '''
      SELECT
        a.id,
        a.name,
        a.kind,
        a.opening_balance_minor,
        COALESCE(SUM(
          CASE
            WHEN e.is_deleted = 1 THEN 0
            WHEN e.transaction_type = 'expense' AND e.account_id = a.id
              THEN CASE WHEN a.kind = 'creditLine'
                THEN e.amount_minor ELSE -e.amount_minor END
            WHEN e.transaction_type = 'income' AND e.account_id = a.id
              THEN CASE WHEN a.kind = 'creditLine'
                THEN -e.amount_minor ELSE e.amount_minor END
            WHEN e.transaction_type = 'borrowing' AND
              (e.account_id = a.id OR e.target_account_id = a.id)
              THEN e.amount_minor
            WHEN e.transaction_type = 'repayment' AND
              (e.account_id = a.id OR e.target_account_id = a.id)
              THEN -e.amount_minor
            WHEN e.transaction_type = 'transfer' AND e.account_id = a.id
              THEN -e.amount_minor
            WHEN e.transaction_type = 'transfer' AND e.target_account_id = a.id
              THEN e.amount_minor
            ELSE 0
          END
        ), 0) AS net_change
      FROM ledger_accounts AS a
      LEFT JOIN ledger_entries AS e
        ON e.account_id = a.id OR e.target_account_id = a.id
      WHERE a.is_archived = 0
      GROUP BY a.id, a.name, a.kind, a.opening_balance_minor, a.sort_order
      ORDER BY a.sort_order
      ''',
      readsFrom: {_database.ledgerAccounts, _database.ledgerEntries},
    );
    return query.watch().map(
      (rows) => rows
          .map((row) {
            final kind = AccountKind.values.byName(row.read<String>('kind'));
            final opening = row.read<int>('opening_balance_minor');
            final netChange = row.read<int>('net_change');
            final current = opening + netChange;
            return AccountBalance(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              kind: kind,
              openingBalanceMinor: opening,
              currentBalanceMinor: current,
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Stream<List<LedgerCategory>> watchExpenseCategories() {
    return _watchCategories('expense');
  }

  @override
  Stream<List<LedgerCategory>> watchIncomeCategories() {
    return _watchCategories('income');
  }

  Stream<List<LedgerCategory>> _watchCategories(String transactionType) {
    final query = _database.select(_database.ledgerCategories)
      ..where(
        (table) =>
            table.transactionType.equals(transactionType) &
            table.isArchived.equals(false),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
    return query.watch().map((rows) {
      final ordered = [...rows]..sort(_compareCategoryRows);
      return ordered
          .map(
            (row) => LedgerCategory(
              id: row.id,
              name: row.name,
              parentId: row.parentId,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Stream<List<LedgerRecord>> watchTransactions() {
    final entry = _database.ledgerEntries;
    final child = _database.ledgerCategories;
    final parent = _database.alias(
      _database.ledgerCategories,
      'parent_category',
    );
    final account = _database.ledgerAccounts;
    final targetAccount = _database.alias(
      _database.ledgerAccounts,
      'target_account',
    );
    final query =
        _database.select(entry).join([
            innerJoin(child, child.id.equalsExp(entry.categoryId)),
            innerJoin(parent, parent.id.equalsExp(child.parentId)),
            innerJoin(account, account.id.equalsExp(entry.accountId)),
            leftOuterJoin(
              targetAccount,
              targetAccount.id.equalsExp(entry.targetAccountId),
            ),
          ])
          ..where(entry.isDeleted.equals(false))
          ..orderBy([OrderingTerm.desc(entry.occurredAt)]);

    return query.watch().map(
      (rows) => rows
          .map((row) {
            final item = row.readTable(entry);
            final target = row.readTableOrNull(targetAccount);
            return LedgerRecord(
              id: item.id,
              type: LedgerTransactionType.values.byName(item.transactionType),
              amountMinor: item.amountMinor,
              occurredAt: item.occurredAt,
              parentCategoryId: row.readTable(parent).id,
              parentCategoryName: row.readTable(parent).name,
              categoryId: row.readTable(child).id,
              categoryName: row.readTable(child).name,
              accountId: row.readTable(account).id,
              accountName: row.readTable(account).name,
              accountKind: row.readTable(account).kind,
              targetAccountId: target?.id,
              targetAccountName: target?.name,
              targetAccountKind: target?.kind,
              note: item.note,
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Future<void> addExpense({
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) async {
    await addTransaction(
      type: LedgerTransactionType.expense,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  @override
  Future<void> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) async {
    await updateTransaction(
      id: id,
      type: LedgerTransactionType.expense,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  @override
  Future<void> addTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  }) async {
    await _database.transaction(() async {
      final resolvedCategoryId = await _validateTransaction(
        type: type,
        amountMinor: amountMinor,
        categoryId: categoryId,
        accountId: accountId,
        targetAccountId: targetAccountId,
      );
      final now = DateTime.now();
      await _database
          .into(_database.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              id: _uuid.v4(),
              transactionType: type.name,
              amountMinor: amountMinor,
              occurredAt: occurredAt,
              timezoneOffsetMinutes: occurredAt.timeZoneOffset.inMinutes,
              categoryId: resolvedCategoryId,
              accountId: accountId,
              targetAccountId: Value(targetAccountId),
              note: Value(note.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  @override
  Future<void> updateTransaction({
    required String id,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  }) async {
    await _database.transaction(() async {
      final resolvedCategoryId = await _validateTransaction(
        type: type,
        amountMinor: amountMinor,
        categoryId: categoryId,
        accountId: accountId,
        targetAccountId: targetAccountId,
        excludingEntryId: id,
      );
      final updated =
          await (_database.update(_database.ledgerEntries)..where(
                (table) => table.id.equals(id) & table.isDeleted.equals(false),
              ))
              .write(
                LedgerEntriesCompanion(
                  transactionType: Value(type.name),
                  amountMinor: Value(amountMinor),
                  occurredAt: Value(occurredAt),
                  timezoneOffsetMinutes: Value(
                    occurredAt.timeZoneOffset.inMinutes,
                  ),
                  categoryId: Value(resolvedCategoryId),
                  accountId: Value(accountId),
                  targetAccountId: Value(targetAccountId),
                  note: Value(note.trim()),
                  updatedAt: Value(DateTime.now()),
                ),
              );
      if (updated != 1) {
        throw ArgumentError.value(id, 'id', 'transaction not found');
      }
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final updated =
        await (_database.update(_database.ledgerEntries)..where(
              (table) => table.id.equals(id) & table.isDeleted.equals(false),
            ))
            .write(
              LedgerEntriesCompanion(
                isDeleted: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
    if (updated != 1) {
      throw ArgumentError.value(id, 'id', 'expense not found');
    }
  }

  @override
  Future<void> importTransactions(List<LedgerImportDraft> drafts) async {
    if (drafts.isEmpty) return;
    await _database.transaction(() async {
      final resolvedIds = <String, String>{};
      final openingBalances = _requiredImportOpeningBalances(drafts);
      for (final draft in drafts) {
        final accountId = await _resolveImportedAccount(
          importId: draft.accountId,
          name: draft.accountName,
          kind: draft.accountKind,
          openingBalanceMinor: openingBalances[draft.accountId] ?? 0,
          resolvedIds: resolvedIds,
        );
        final targetAccountId = draft.targetAccountId == null
            ? null
            : await _resolveImportedAccount(
                importId: draft.targetAccountId!,
                name: draft.targetAccountName!,
                kind: draft.targetAccountKind!,
                openingBalanceMinor:
                    openingBalances[draft.targetAccountId!] ?? 0,
                resolvedIds: resolvedIds,
              );
        await addTransaction(
          type: draft.type,
          amountMinor: draft.amountMinor,
          occurredAt: draft.occurredAt,
          accountId: accountId,
          targetAccountId: targetAccountId,
          categoryId: draft.categoryId,
          note: draft.note,
        );
      }
    });
  }

  Future<String> _resolveImportedAccount({
    required String importId,
    required String name,
    required AccountKind kind,
    required int openingBalanceMinor,
    required Map<String, String> resolvedIds,
  }) async {
    if (!importId.startsWith('__new__:')) return importId;
    final alreadyResolved = resolvedIds[importId];
    if (alreadyResolved != null) return alreadyResolved;

    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 30) {
      throw LedgerImportException('账户名称必须为 1 至 30 个字符');
    }
    final accountRows = await _database.select(_database.ledgerAccounts).get();
    final existing = accountRows
        .where(
          (row) => DefaultLedgerNames.accountMatches(
            LedgerAccount(
              id: row.id,
              name: row.name,
              kind: AccountKind.values.byName(row.kind),
            ),
            normalizedName,
          ),
        )
        .firstOrNull;
    if (existing != null) {
      if (existing.kind != kind.name) {
        throw LedgerImportException(
          '账户“$normalizedName”已存在，但类型与 JSON 中的 ${kind.name} 不一致',
        );
      }
      if (existing.isArchived) {
        await (_database.update(
          _database.ledgerAccounts,
        )..where((table) => table.id.equals(existing.id))).write(
          LedgerAccountsCompanion(
            isArchived: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      resolvedIds[importId] = existing.id;
      return existing.id;
    }

    final lastSortOrder = accountRows.fold<int>(
      -1,
      (maximum, item) => math.max(maximum, item.sortOrder),
    );
    final id = _uuid.v4();
    final now = DateTime.now();
    await _database
        .into(_database.ledgerAccounts)
        .insert(
          LedgerAccountsCompanion.insert(
            id: id,
            name: normalizedName,
            kind: kind.name,
            openingBalanceMinor: Value(openingBalanceMinor),
            sortOrder: Value(lastSortOrder + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
    resolvedIds[importId] = id;
    return id;
  }

  Future<String> _validateTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    String? categoryId,
    required String accountId,
    String? targetAccountId,
    String? excludingEntryId,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
    final resolvedCategoryId = switch (type) {
      LedgerTransactionType.borrowing => 'flow-borrowing',
      LedgerTransactionType.repayment => 'flow-repayment',
      LedgerTransactionType.transfer => 'flow-transfer',
      _ => categoryId,
    };
    if (resolvedCategoryId == null) {
      throw ArgumentError.notNull('categoryId');
    }
    final category = await (_database.select(
      _database.ledgerCategories,
    )..where((table) => table.id.equals(resolvedCategoryId))).getSingleOrNull();
    if (category == null ||
        category.parentId == null ||
        category.transactionType != type.name) {
      throw ArgumentError.value(
        resolvedCategoryId,
        'categoryId',
        'must match transaction type',
      );
    }
    final account = await (_database.select(
      _database.ledgerAccounts,
    )..where((table) => table.id.equals(accountId))).getSingleOrNull();
    if (account == null) {
      throw ArgumentError.value(accountId, 'accountId', 'account not found');
    }
    final target = targetAccountId == null
        ? null
        : await (_database.select(_database.ledgerAccounts)
                ..where((table) => table.id.equals(targetAccountId)))
              .getSingleOrNull();
    if (targetAccountId != null && target == null) {
      throw ArgumentError.value(
        targetAccountId,
        'targetAccountId',
        'account not found',
      );
    }
    if (accountId == targetAccountId) {
      throw ArgumentError('source and target accounts must differ');
    }
    final accountKind = AccountKind.values.byName(account.kind);
    final targetKind = target == null
        ? null
        : AccountKind.values.byName(target.kind);
    switch (type) {
      case LedgerTransactionType.expense:
        if (target != null) {
          throw ArgumentError('expense and income have no target account');
        }
        if (accountKind != AccountKind.creditLine) {
          await _requireAvailableBalance(
            accountId: account.id,
            accountName: account.name,
            requiredMinor: amountMinor,
            excludingEntryId: excludingEntryId,
          );
        }
        break;
      case LedgerTransactionType.income:
        if (target != null) {
          throw ArgumentError('expense and income have no target account');
        }
        if (accountKind == AccountKind.creditLine) {
          await _requireOutstandingLiability(
            accountId: account.id,
            accountName: account.name,
            requiredMinor: amountMinor,
            excludingEntryId: excludingEntryId,
          );
        }
        break;
      case LedgerTransactionType.borrowing:
        if (accountKind != AccountKind.creditLine ||
            targetKind == null ||
            targetKind == AccountKind.creditLine ||
            targetKind == AccountKind.entrustedFunds) {
          throw ArgumentError('borrowing requires liability to personal asset');
        }
        break;
      case LedgerTransactionType.transfer:
        if (accountKind != AccountKind.creditLine &&
            accountKind != AccountKind.entrustedFunds &&
            targetKind != null &&
            targetKind != AccountKind.creditLine &&
            targetKind != AccountKind.entrustedFunds) {
          await _requireAvailableBalance(
            accountId: account.id,
            accountName: account.name,
            requiredMinor: amountMinor,
            excludingEntryId: excludingEntryId,
          );
          break;
        }
        throw ArgumentError('transfer requires two personal asset accounts');
      case LedgerTransactionType.repayment:
        if (accountKind == AccountKind.creditLine ||
            accountKind == AccountKind.entrustedFunds ||
            targetKind != AccountKind.creditLine) {
          throw ArgumentError('repayment requires personal asset to liability');
        }
        await _requireAvailableBalance(
          accountId: account.id,
          accountName: account.name,
          requiredMinor: amountMinor,
          excludingEntryId: excludingEntryId,
        );
        await _requireOutstandingLiability(
          accountId: target!.id,
          accountName: target.name,
          requiredMinor: amountMinor,
          excludingEntryId: excludingEntryId,
        );
        break;
    }
    return resolvedCategoryId;
  }

  Future<void> _requireAvailableBalance({
    required String accountId,
    required String accountName,
    required int requiredMinor,
    String? excludingEntryId,
  }) async {
    final available = await _currentBalance(
      accountId,
      excludingEntryId: excludingEntryId,
    );
    if (available < requiredMinor) {
      throw TransactionRuleException(
        TransactionRuleError.insufficientBalance,
        accountId: accountId,
        accountName: accountName,
        amountMinor: available,
      );
    }
  }

  Future<void> _requireOutstandingLiability({
    required String accountId,
    required String accountName,
    required int requiredMinor,
    String? excludingEntryId,
  }) async {
    final outstanding = await _currentBalance(
      accountId,
      excludingEntryId: excludingEntryId,
    );
    if (outstanding < requiredMinor) {
      throw TransactionRuleException(
        TransactionRuleError.overpayment,
        accountId: accountId,
        accountName: accountName,
        amountMinor: outstanding,
      );
    }
  }

  Future<int> _currentBalance(
    String accountId, {
    String? excludingEntryId,
  }) async {
    final exclusion = excludingEntryId == null ? '' : 'AND e.id != ?';
    final row = await _database
        .customSelect(
          '''
      SELECT a.opening_balance_minor + COALESCE(SUM(
        CASE
          WHEN e.transaction_type = 'expense' AND e.account_id = a.id
            THEN CASE WHEN a.kind = 'creditLine'
              THEN e.amount_minor ELSE -e.amount_minor END
          WHEN e.transaction_type = 'income' AND e.account_id = a.id
            THEN CASE WHEN a.kind = 'creditLine'
              THEN -e.amount_minor ELSE e.amount_minor END
          WHEN e.transaction_type = 'borrowing' AND
            (e.account_id = a.id OR e.target_account_id = a.id)
            THEN e.amount_minor
          WHEN e.transaction_type = 'repayment' AND
            (e.account_id = a.id OR e.target_account_id = a.id)
            THEN -e.amount_minor
          WHEN e.transaction_type = 'transfer' AND e.account_id = a.id
            THEN -e.amount_minor
          WHEN e.transaction_type = 'transfer' AND e.target_account_id = a.id
            THEN e.amount_minor
          ELSE 0
        END
      ), 0) AS current_balance
      FROM ledger_accounts AS a
      LEFT JOIN ledger_entries AS e ON
        (e.account_id = a.id OR e.target_account_id = a.id)
        AND e.is_deleted = 0
        $exclusion
      WHERE a.id = ?
      GROUP BY a.id, a.opening_balance_minor
      ''',
          variables: [
            if (excludingEntryId != null) Variable.withString(excludingEntryId),
            Variable.withString(accountId),
          ],
          readsFrom: {_database.ledgerAccounts, _database.ledgerEntries},
        )
        .getSingle();
    return row.read<int>('current_balance');
  }

  @override
  Future<void> setCurrentBalance({
    required String accountId,
    required int amountMinor,
  }) async {
    if (amountMinor < 0) {
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'must not be negative',
      );
    }
    final snapshot = await _database
        .customSelect(
          '''
      SELECT
        a.kind,
        COALESCE(SUM(
          CASE
            WHEN e.is_deleted = 1 THEN 0
            WHEN e.transaction_type = 'expense' AND e.account_id = a.id
              THEN CASE WHEN a.kind = 'creditLine'
                THEN e.amount_minor ELSE -e.amount_minor END
            WHEN e.transaction_type = 'income' AND e.account_id = a.id
              THEN CASE WHEN a.kind = 'creditLine'
                THEN -e.amount_minor ELSE e.amount_minor END
            WHEN e.transaction_type = 'borrowing' AND
              (e.account_id = a.id OR e.target_account_id = a.id)
              THEN e.amount_minor
            WHEN e.transaction_type = 'repayment' AND
              (e.account_id = a.id OR e.target_account_id = a.id)
              THEN -e.amount_minor
            WHEN e.transaction_type = 'transfer' AND e.account_id = a.id
              THEN -e.amount_minor
            WHEN e.transaction_type = 'transfer' AND e.target_account_id = a.id
              THEN e.amount_minor
            ELSE 0
          END
        ), 0) AS net_change
      FROM ledger_accounts AS a
      LEFT JOIN ledger_entries AS e
        ON e.account_id = a.id OR e.target_account_id = a.id
      WHERE a.id = ?
      GROUP BY a.id, a.kind
      ''',
          variables: [Variable.withString(accountId)],
          readsFrom: {_database.ledgerAccounts, _database.ledgerEntries},
        )
        .getSingleOrNull();
    if (snapshot == null) {
      throw ArgumentError.value(accountId, 'accountId', 'account not found');
    }
    final netChange = snapshot.read<int>('net_change');
    final recalculatedOpening = amountMinor - netChange;
    final updated =
        await (_database.update(
          _database.ledgerAccounts,
        )..where((table) => table.id.equals(accountId))).write(
          LedgerAccountsCompanion(
            openingBalanceMinor: Value(recalculatedOpening),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated != 1) {
      throw ArgumentError.value(accountId, 'accountId', 'account not found');
    }
  }

  @override
  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    required int currentBalanceMinor,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 30) {
      throw ArgumentError.value(
        name,
        'name',
        'must contain 1 to 30 characters',
      );
    }
    if (currentBalanceMinor < 0) {
      throw ArgumentError.value(
        currentBalanceMinor,
        'currentBalanceMinor',
        'must not be negative',
      );
    }
    final accounts = await _database.select(_database.ledgerAccounts).get();
    if (accounts.any(
      (row) => DefaultLedgerNames.accountMatches(
        LedgerAccount(
          id: row.id,
          name: row.name,
          kind: AccountKind.values.byName(row.kind),
        ),
        normalizedName,
      ),
    )) {
      throw StateError('An account with this name already exists');
    }
    final lastSortOrder = accounts.fold<int>(
      -1,
      (maximum, account) =>
          account.sortOrder > maximum ? account.sortOrder : maximum,
    );
    final now = DateTime.now();
    await _database
        .into(_database.ledgerAccounts)
        .insert(
          LedgerAccountsCompanion.insert(
            id: _uuid.v4(),
            name: normalizedName,
            kind: kind.name,
            openingBalanceMinor: Value(currentBalanceMinor),
            sortOrder: Value(lastSortOrder + 1),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> archiveAccount(String id) async {
    final updated =
        await (_database.update(_database.ledgerAccounts)..where(
              (table) => table.id.equals(id) & table.isArchived.equals(false),
            ))
            .write(
              LedgerAccountsCompanion(
                isArchived: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
    if (updated != 1) {
      throw ArgumentError.value(id, 'id', 'account not found');
    }
  }

  @override
  Future<void> restoreDefaultAccounts() async {
    final now = DateTime.now();
    await _database.transaction(() async {
      for (final item in AppDatabase.defaultAccounts) {
        final existing = await (_database.select(
          _database.ledgerAccounts,
        )..where((table) => table.id.equals(item.id))).getSingleOrNull();
        if (existing == null) {
          await _database
              .into(_database.ledgerAccounts)
              .insert(
                LedgerAccountsCompanion.insert(
                  id: item.id,
                  name: item.name,
                  kind: item.kind,
                  sortOrder: Value(item.sortOrder),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        } else if (existing.isArchived) {
          await (_database.update(
            _database.ledgerAccounts,
          )..where((table) => table.id.equals(item.id))).write(
            LedgerAccountsCompanion(
              isArchived: const Value(false),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  @override
  Future<void> addCategory({
    required LedgerTransactionType type,
    required String name,
    String? parentId,
  }) async {
    if (type != LedgerTransactionType.expense &&
        type != LedgerTransactionType.income) {
      throw ArgumentError.value(type, 'type', 'must be expense or income');
    }
    final normalized = _validatedCategoryName(name);
    await _database.transaction(() async {
      CategoryRow? parent;
      if (parentId != null) {
        parent = await (_database.select(
          _database.ledgerCategories,
        )..where((table) => table.id.equals(parentId))).getSingleOrNull();
        if (parent == null ||
            parent.parentId != null ||
            parent.transactionType != type.name ||
            parent.isArchived) {
          throw ArgumentError.value(parentId, 'parentId', 'invalid parent');
        }
      }
      final all = await _database.select(_database.ledgerCategories).get();
      final duplicate = all
          .where(
            (item) =>
                item.transactionType == type.name &&
                item.parentId == parentId &&
                DefaultLedgerNames.categoryMatches(
                  LedgerCategory(
                    id: item.id,
                    name: item.name,
                    parentId: item.parentId,
                  ),
                  normalized,
                ),
          )
          .firstOrNull;
      if (duplicate != null) {
        if (!duplicate.isArchived) {
          throw StateError('A category with this name already exists');
        }
        await (_database.update(
          _database.ledgerCategories,
        )..where((table) => table.id.equals(duplicate.id))).write(
          LedgerCategoriesCompanion(
            isArchived: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      }
      final siblings = all.where(
        (item) =>
            item.transactionType == type.name && item.parentId == parentId,
      );
      final nextOrder =
          siblings.fold<int>(
            parentId == null
                ? (type == LedgerTransactionType.expense ? -100 : 900)
                : parent!.sortOrder,
            (maximum, item) => math.max(maximum, item.sortOrder),
          ) +
          1;
      final now = DateTime.now();
      final id = _uuid.v4();
      await _database
          .into(_database.ledgerCategories)
          .insert(
            LedgerCategoriesCompanion.insert(
              id: id,
              name: normalized,
              transactionType: Value(type.name),
              parentId: Value(parentId),
              sortOrder: Value(nextOrder),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (parentId == null) {
        await _database
            .into(_database.ledgerCategories)
            .insert(
              LedgerCategoriesCompanion.insert(
                id: _uuid.v4(),
                name: '其他',
                transactionType: Value(type.name),
                parentId: Value(id),
                sortOrder: Value(nextOrder + 1),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> renameCategory({
    required String id,
    required String name,
  }) async {
    final normalized = _validatedCategoryName(name);
    final category = await (_database.select(
      _database.ledgerCategories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (category == null || category.isArchived) {
      throw ArgumentError.value(id, 'id', 'category not found');
    }
    if (DefaultLedgerNames.isProtectedOther(
      LedgerCategory(
        id: category.id,
        name: category.name,
        parentId: category.parentId,
      ),
    )) {
      throw const TransactionRuleException(
        TransactionRuleError.fixedOtherCategory,
      );
    }
    final siblings =
        await (_database.select(_database.ledgerCategories)..where(
              (table) =>
                  table.transactionType.equals(category.transactionType) &
                  (category.parentId == null
                      ? table.parentId.isNull()
                      : table.parentId.equals(category.parentId!)) &
                  table.id.equals(id).not(),
            ))
            .get();
    final duplicate = siblings
        .where(
          (item) => DefaultLedgerNames.categoryMatches(
            LedgerCategory(
              id: item.id,
              name: item.name,
              parentId: item.parentId,
            ),
            normalized,
          ),
        )
        .firstOrNull;
    if (duplicate != null) {
      throw StateError('A category with this name already exists');
    }
    await (_database.update(
      _database.ledgerCategories,
    )..where((table) => table.id.equals(id))).write(
      LedgerCategoriesCompanion(
        name: Value(normalized),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> archiveCategory(String id) async {
    await _database.transaction(() async {
      final category = await (_database.select(
        _database.ledgerCategories,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (category == null || category.isArchived) {
        throw ArgumentError.value(id, 'id', 'category not found');
      }
      if (DefaultLedgerNames.isProtectedOther(
        LedgerCategory(
          id: category.id,
          name: category.name,
          parentId: category.parentId,
        ),
      )) {
        throw const TransactionRuleException(
          TransactionRuleError.otherCategoryRequired,
        );
      }
      final now = DateTime.now();
      await (_database.update(_database.ledgerCategories)..where(
            (table) =>
                table.id.equals(id) |
                (category.parentId == null
                    ? table.parentId.equals(id)
                    : const Constant(false)),
          ))
          .write(
            LedgerCategoriesCompanion(
              isArchived: const Value(true),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> moveCategory(String id, {required bool moveUp}) async {
    await _database.transaction(() async {
      final category = await (_database.select(
        _database.ledgerCategories,
      )..where((table) => table.id.equals(id))).getSingleOrNull();
      if (category == null || category.isArchived) {
        throw ArgumentError.value(id, 'id', 'category not found');
      }
      if (_isOtherCategoryRow(category)) return;
      final query = _database.select(_database.ledgerCategories)
        ..where(
          (table) =>
              table.transactionType.equals(category.transactionType) &
              table.isArchived.equals(false) &
              (category.parentId == null
                  ? table.parentId.isNull()
                  : table.parentId.equals(category.parentId!)),
        )
        ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
      final siblings = await query.get()
        ..sort(_compareCategoryRows);
      final index = siblings.indexWhere((item) => item.id == id);
      final targetIndex = index + (moveUp ? -1 : 1);
      if (index < 0 || targetIndex < 0 || targetIndex >= siblings.length) {
        return;
      }
      final other = siblings[targetIndex];
      if (_isOtherCategoryRow(other)) return;
      final now = DateTime.now();
      await (_database.update(
        _database.ledgerCategories,
      )..where((table) => table.id.equals(category.id))).write(
        LedgerCategoriesCompanion(
          sortOrder: Value(other.sortOrder),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(
        _database.ledgerCategories,
      )..where((table) => table.id.equals(other.id))).write(
        LedgerCategoriesCompanion(
          sortOrder: Value(category.sortOrder),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> restoreDefaultCategories() async {
    final now = DateTime.now();
    await _database.transaction(() async {
      for (final item in _defaultCategorySpecs) {
        final existing = await (_database.select(
          _database.ledgerCategories,
        )..where((table) => table.id.equals(item.id))).getSingleOrNull();
        if (existing == null) {
          await _database
              .into(_database.ledgerCategories)
              .insert(
                LedgerCategoriesCompanion.insert(
                  id: item.id,
                  name: item.name,
                  transactionType: Value(item.type),
                  parentId: Value(item.parentId),
                  sortOrder: Value(item.order),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        } else if (existing.isArchived) {
          await (_database.update(
            _database.ledgerCategories,
          )..where((table) => table.id.equals(item.id))).write(
            LedgerCategoriesCompanion(
              isArchived: const Value(false),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  @override
  Future<String> createFullBackup() async {
    final accounts = await _database.select(_database.ledgerAccounts).get();
    final categories = await _database.select(_database.ledgerCategories).get();
    final entries = await _database.select(_database.ledgerEntries).get();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'ledgerpro_full_backup',
      'backup_version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'accounts': [for (final item in accounts) _backupAccount(item)],
      'categories': [for (final item in categories) _backupCategory(item)],
      'entries': [for (final item in entries) _backupEntry(item)],
    });
  }

  @override
  LedgerBackupPreview inspectFullBackup(String source) {
    final payload = _parseBackup(source);
    final entries = payload.entries;
    return LedgerBackupPreview(
      createdAt: payload.createdAt,
      accountCount: payload.accounts.length,
      categoryCount: payload.categories.length,
      entryCount: entries.length,
      deletedEntryCount: entries
          .where((item) => _requiredBool(item, 'is_deleted'))
          .length,
    );
  }

  @override
  Future<void> restoreFullBackup(
    String source, {
    required BackupRestoreMode mode,
  }) async {
    final payload = _parseBackup(source);
    await _database.transaction(() async {
      if (mode == BackupRestoreMode.replace) {
        await _database.delete(_database.ledgerEntries).go();
        await _database.delete(_database.ledgerCategories).go();
        await _database.delete(_database.ledgerAccounts).go();
      }

      for (final raw in payload.accounts) {
        await _database
            .into(_database.ledgerAccounts)
            .insertOnConflictUpdate(
              LedgerAccountsCompanion.insert(
                id: _requiredString(raw, 'id'),
                name: _requiredString(raw, 'name'),
                kind: _requiredEnum(
                  raw,
                  'kind',
                  AccountKind.values.map((e) => e.name),
                ),
                currencyCode: Value(_requiredString(raw, 'currency_code')),
                openingBalanceMinor: Value(
                  _requiredInt(raw, 'opening_balance_minor'),
                ),
                sortOrder: Value(_requiredInt(raw, 'sort_order')),
                isArchived: Value(_requiredBool(raw, 'is_archived')),
                createdAt: _requiredDate(raw, 'created_at'),
                updatedAt: _requiredDate(raw, 'updated_at'),
              ),
            );
      }

      final categories = [...payload.categories]
        ..sort((a, b) {
          final aParent = a['parent_id'] == null ? 0 : 1;
          final bParent = b['parent_id'] == null ? 0 : 1;
          return aParent.compareTo(bParent);
        });
      for (final raw in categories) {
        await _database
            .into(_database.ledgerCategories)
            .insertOnConflictUpdate(
              LedgerCategoriesCompanion.insert(
                id: _requiredString(raw, 'id'),
                name: _requiredString(raw, 'name'),
                transactionType: Value(
                  _requiredEnum(
                    raw,
                    'transaction_type',
                    LedgerTransactionType.values.map((e) => e.name),
                  ),
                ),
                parentId: Value(_nullableString(raw, 'parent_id')),
                sortOrder: Value(_requiredInt(raw, 'sort_order')),
                isArchived: Value(_requiredBool(raw, 'is_archived')),
                createdAt: _requiredDate(raw, 'created_at'),
                updatedAt: _requiredDate(raw, 'updated_at'),
              ),
            );
      }

      for (final raw in payload.entries) {
        await _database
            .into(_database.ledgerEntries)
            .insertOnConflictUpdate(
              LedgerEntriesCompanion.insert(
                id: _requiredString(raw, 'id'),
                transactionType: _requiredEnum(
                  raw,
                  'transaction_type',
                  LedgerTransactionType.values.map((e) => e.name),
                ),
                amountMinor: _requiredInt(raw, 'amount_minor'),
                currencyCode: Value(_requiredString(raw, 'currency_code')),
                occurredAt: _requiredDate(raw, 'occurred_at'),
                timezoneOffsetMinutes: _requiredInt(
                  raw,
                  'timezone_offset_minutes',
                ),
                categoryId: _requiredString(raw, 'category_id'),
                accountId: _requiredString(raw, 'account_id'),
                targetAccountId: Value(
                  _nullableString(raw, 'target_account_id'),
                ),
                note: Value(_requiredString(raw, 'note')),
                createdAt: _requiredDate(raw, 'created_at'),
                updatedAt: _requiredDate(raw, 'updated_at'),
                isDeleted: Value(_requiredBool(raw, 'is_deleted')),
              ),
            );
      }
    });
  }

  @override
  Future<void> resetLedgerData() => _database.resetLedgerData();

  @override
  Future<void> resetToFactoryDefaults() => _database.resetToFactoryDefaults();
}

Map<String, Object?> _backupAccount(AccountRow item) => {
  'id': item.id,
  'name': item.name,
  'kind': item.kind,
  'currency_code': item.currencyCode,
  'opening_balance_minor': item.openingBalanceMinor,
  'sort_order': item.sortOrder,
  'is_archived': item.isArchived,
  'created_at': item.createdAt.toIso8601String(),
  'updated_at': item.updatedAt.toIso8601String(),
};

Map<String, Object?> _backupCategory(CategoryRow item) => {
  'id': item.id,
  'name': item.name,
  'transaction_type': item.transactionType,
  'parent_id': item.parentId,
  'sort_order': item.sortOrder,
  'is_archived': item.isArchived,
  'created_at': item.createdAt.toIso8601String(),
  'updated_at': item.updatedAt.toIso8601String(),
};

Map<String, Object?> _backupEntry(EntryRow item) => {
  'id': item.id,
  'transaction_type': item.transactionType,
  'amount_minor': item.amountMinor,
  'currency_code': item.currencyCode,
  'occurred_at': item.occurredAt.toIso8601String(),
  'timezone_offset_minutes': item.timezoneOffsetMinutes,
  'category_id': item.categoryId,
  'account_id': item.accountId,
  'target_account_id': item.targetAccountId,
  'note': item.note,
  'created_at': item.createdAt.toIso8601String(),
  'updated_at': item.updatedAt.toIso8601String(),
  'is_deleted': item.isDeleted,
};

({
  DateTime createdAt,
  List<Map<String, dynamic>> accounts,
  List<Map<String, dynamic>> categories,
  List<Map<String, dynamic>> entries,
})
_parseBackup(String source) {
  dynamic decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw LedgerBackupException('备份 JSON 格式错误：${error.message}');
  }
  if (decoded is! Map<String, dynamic> ||
      decoded['format'] != 'ledgerpro_full_backup' ||
      decoded['backup_version'] != 1) {
    throw const LedgerBackupException('这不是受支持的 Summa 完整备份');
  }
  final createdAt = DateTime.tryParse(decoded['created_at']?.toString() ?? '');
  if (createdAt == null) throw const LedgerBackupException('备份时间无效');
  return (
    createdAt: createdAt,
    accounts: _requiredObjectList(decoded, 'accounts'),
    categories: _requiredObjectList(decoded, 'categories'),
    entries: _requiredObjectList(decoded, 'entries'),
  );
}

List<Map<String, dynamic>> _requiredObjectList(
  Map<String, dynamic> source,
  String key,
) {
  final value = source[key];
  if (value is! List) throw LedgerBackupException('备份缺少 $key 列表');
  return [
    for (final item in value)
      if (item is Map<String, dynamic>)
        item
      else
        throw LedgerBackupException('$key 中包含无效项目'),
  ];
}

String _requiredString(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! String) throw LedgerBackupException('字段 $key 必须是字符串');
  return value;
}

String? _nullableString(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is! String) throw LedgerBackupException('字段 $key 必须是字符串或 null');
  return value;
}

int _requiredInt(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! int) throw LedgerBackupException('字段 $key 必须是整数');
  return value;
}

bool _requiredBool(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is! bool) throw LedgerBackupException('字段 $key 必须是布尔值');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> source, String key) {
  final value = DateTime.tryParse(_requiredString(source, key));
  if (value == null) throw LedgerBackupException('字段 $key 不是有效时间');
  return value;
}

String _requiredEnum(
  Map<String, dynamic> source,
  String key,
  Iterable<String> allowed,
) {
  final value = _requiredString(source, key);
  if (!allowed.contains(value)) {
    throw LedgerBackupException('字段 $key 的值不受支持：$value');
  }
  return value;
}

String _validatedCategoryName(String name) {
  final normalized = name.trim();
  if (normalized.isEmpty ||
      normalized.length > 20 ||
      normalized.contains('/')) {
    throw ArgumentError.value(name, 'name', 'must be 1-20 chars without /');
  }
  return normalized;
}

bool _isOtherCategoryRow(CategoryRow row) => DefaultLedgerNames.isOtherCategory(
  LedgerCategory(id: row.id, name: row.name, parentId: row.parentId),
);

int _compareCategoryRows(CategoryRow left, CategoryRow right) {
  final leftIsOther = _isOtherCategoryRow(left);
  final rightIsOther = _isOtherCategoryRow(right);
  if (leftIsOther != rightIsOther) return leftIsOther ? 1 : -1;
  return left.sortOrder.compareTo(right.sortOrder);
}

List<({String id, String name, String type, String? parentId, int order})>
get _defaultCategorySpecs {
  final result =
      <({String id, String name, String type, String? parentId, int order})>[];
  void addGroups(String type, int base, Map<String, List<String>> groups) {
    var parentIndex = 0;
    for (final group in groups.entries) {
      final parentId = '$type-parent-$parentIndex';
      result.add((
        id: parentId,
        name: group.key,
        type: type,
        parentId: null,
        order: base + parentIndex * 100,
      ));
      for (var childIndex = 0; childIndex < group.value.length; childIndex++) {
        result.add((
          id: '$parentId-child-$childIndex',
          name: group.value[childIndex],
          type: type,
          parentId: parentId,
          order: base + parentIndex * 100 + childIndex,
        ));
      }
      parentIndex++;
    }
  }

  addGroups('expense', 0, const {
    '饮食': ['早餐', '午餐', '晚餐', '零食饮料', '食材', '其他'],
    '交通': ['公交地铁', '网约车', '骑行', '长途交通', '其他'],
    '日用': ['生活用品', '衣物', '数码', '医疗健康', '其他'],
    '娱乐': ['游戏', '影音', '社交', '旅行', '其他'],
    '其他': ['未分类'],
  });
  addGroups('income', 1000, const {
    '劳动所得': ['工资', '兼职', '其他'],
    '家庭支持': ['生活费', '亲属赠予', '采购结余', '其他'],
    '退款报销': ['退款', '报销', '其他'],
    '其他收入': ['礼金', '投资收益', '未分类'],
  });
  return result;
}

Map<String, int> _requiredImportOpeningBalances(
  List<LedgerImportDraft> drafts,
) {
  final running = <String, int>{};
  final minimum = <String, int>{};

  void change(String? id, int delta) {
    if (id == null || !id.startsWith('__new__:')) return;
    final next = (running[id] ?? 0) + delta;
    running[id] = next;
    minimum[id] = math.min(minimum[id] ?? 0, next);
  }

  for (final draft in drafts) {
    switch (draft.type) {
      case LedgerTransactionType.expense:
        change(
          draft.accountId,
          draft.accountKind == AccountKind.creditLine
              ? draft.amountMinor
              : -draft.amountMinor,
        );
      case LedgerTransactionType.income:
        change(
          draft.accountId,
          draft.accountKind == AccountKind.creditLine
              ? -draft.amountMinor
              : draft.amountMinor,
        );
      case LedgerTransactionType.borrowing:
        change(draft.accountId, draft.amountMinor);
        change(draft.targetAccountId, draft.amountMinor);
      case LedgerTransactionType.transfer:
        change(draft.accountId, -draft.amountMinor);
        change(draft.targetAccountId, draft.amountMinor);
      case LedgerTransactionType.repayment:
        change(draft.accountId, -draft.amountMinor);
        change(draft.targetAccountId, -draft.amountMinor);
    }
  }
  return {
    for (final entry in minimum.entries) entry.key: math.max(0, -entry.value),
  };
}
