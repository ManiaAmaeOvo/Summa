import 'dart:math' as math;
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/transactions/ledger_posting.dart';
import 'package:summa/domain/defaults/default_ledger_names.dart';
import 'package:uuid/uuid.dart';

const _backupFormat = 'summa_full_backup';
const _legacyBackupFormat = 'ledgerpro_full_backup';

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
    final query = _balanceQuery();
    return query.watch().map(
      (rows) => rows
          .map((row) {
            final kind = AccountKind.values.byName(row.read<String>('kind'));
            final opening = row.read<int>('opening_balance_minor');
            return AccountBalance(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              kind: kind,
              openingBalanceMinor: opening,
              currentBalanceMinor: row.read<int>('current_balance'),
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
    final postings = _database.ledgerPostings;
    final postingAccount = _database.alias(account, 'posting_account');
    final query =
        _database.select(entry).join([
            innerJoin(child, child.id.equalsExp(entry.categoryId)),
            innerJoin(parent, parent.id.equalsExp(child.parentId)),
            innerJoin(account, account.id.equalsExp(entry.accountId)),
            leftOuterJoin(
              targetAccount,
              targetAccount.id.equalsExp(entry.targetAccountId),
            ),
            leftOuterJoin(
              postings,
              postings.transactionId.equalsExp(entry.id) &
                  postings.accountId.isNotNull(),
            ),
            leftOuterJoin(
              postingAccount,
              postingAccount.id.equalsExp(postings.accountId),
            ),
          ])
          ..where(entry.isDeleted.equals(false))
          ..orderBy([
            OrderingTerm.desc(entry.occurredAt),
            OrderingTerm.desc(entry.id),
            OrderingTerm.asc(postings.position),
          ]);

    return query.watch().map((rows) {
      final transactions = <String, List<TypedResult>>{};
      for (final row in rows) {
        (transactions[row.readTable(entry).id] ??= []).add(row);
      }
      return [
        for (final legs in transactions.values)
          _ledgerRecord(
            legs,
            entry,
            parent,
            child,
            account,
            targetAccount,
            postingAccount,
            postings,
          ),
      ];
    });
  }

  LedgerRecord _ledgerRecord(
    List<TypedResult> legs,
    $LedgerEntriesTable entry,
    $LedgerCategoriesTable parent,
    $LedgerCategoriesTable child,
    $LedgerAccountsTable account,
    $LedgerAccountsTable targetAccount,
    $LedgerAccountsTable postingAccount,
    $LedgerPostingsTable postings,
  ) {
    final row = legs.first;
    final item = row.readTable(entry);
    final target = row.readTableOrNull(targetAccount);
    final accountPostings = <AccountPosting>[];
    for (final leg in legs) {
      final posting = leg.readTableOrNull(postings);
      final destination = leg.readTableOrNull(postingAccount);
      if (posting != null && destination != null) {
        accountPostings.add(
          AccountPosting(
            accountId: destination.id,
            accountName: destination.name,
            accountKind: destination.kind,
            debitMinor: posting.debitMinor,
            needsReview: posting.needsReview,
          ),
        );
      }
    }
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
      status: LedgerPostingStatus.values.byName(item.status),
      refundOfId: item.refundOfId,
      accountPostings: List.unmodifiable(accountPostings),
      note: item.note,
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
    List<AccountPayment>? payments,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
    required String note,
  }) => _saveTransaction(
    type: type,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    accountId: accountId,
    targetAccountId: targetAccountId,
    categoryId: categoryId,
    payments: payments,
    status: status,
    note: note,
  );

  @override
  Future<void> updateTransaction({
    required String id,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    List<AccountPayment>? payments,
    required String note,
  }) => _saveTransaction(
    id: id,
    type: type,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    accountId: accountId,
    targetAccountId: targetAccountId,
    categoryId: categoryId,
    payments: payments,
    status: LedgerPostingStatus.posted,
    note: note,
  );

  Future<void> _saveTransaction({
    String? id,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    required String? targetAccountId,
    required String? categoryId,
    required List<AccountPayment>? payments,
    required LedgerPostingStatus status,
    required String note,
  }) => _database.transaction(() async {
    final previous = id == null ? null : await _activeEntry(id);
    if (previous != null) {
      if (previous.refundOfId != null) {
        throw ArgumentError('Use saveRefund to edit a refund');
      }
      await _requireNoActiveRefunds(previous.id);
    }
    final effectiveStatus = previous == null
        ? status
        : LedgerPostingStatus.values.byName(previous.status);
    final savedPayments =
        type == LedgerTransactionType.expense &&
            previous?.transactionType == LedgerTransactionType.expense.name &&
            payments == null
        ? await _expensePayments(previous!.id)
        : const <AccountPayment>[];
    final validation = await _validateTransaction(
      type: type,
      amountMinor: amountMinor,
      categoryId: categoryId,
      accountId: accountId,
      targetAccountId: targetAccountId,
      status: effectiveStatus,
      previous: previous,
      payments: payments ?? (savedPayments.length > 1 ? savedPayments : null),
    );
    await _writeEntry(
      previous: previous,
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: validation.categoryId,
      currencyCode: validation.currencyCode,
      accountId: accountId,
      targetAccountId: targetAccountId,
      status: effectiveStatus,
      note: note,
      postings: validation.postings,
    );
  });

  Future<void> _writeEntry({
    EntryRow? previous,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String currencyCode,
    required String accountId,
    String? targetAccountId,
    String? refundOfId,
    required LedgerPostingStatus status,
    required String note,
    required List<PostingLeg> postings,
  }) async {
    final now = DateTime.now();
    final id = previous?.id ?? _uuid.v4();
    await _database
        .into(_database.ledgerEntries)
        .insertOnConflictUpdate(
          LedgerEntriesCompanion.insert(
            id: id,
            transactionType: type.name,
            amountMinor: amountMinor,
            occurredAt: occurredAt,
            timezoneOffsetMinutes: occurredAt.timeZoneOffset.inMinutes,
            categoryId: categoryId,
            currencyCode: Value(currencyCode),
            accountId: accountId,
            targetAccountId: Value(targetAccountId),
            refundOfId: Value(refundOfId),
            status: Value(status.name),
            note: Value(note.trim()),
            createdAt: previous?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    await _replacePostings(id, postings);
  }

  Future<void> _replacePostings(String id, List<PostingLeg> postings) async {
    await (_database.delete(
      _database.ledgerPostings,
    )..where((table) => table.transactionId.equals(id))).go();
    await _database.batch(
      (batch) => batch.insertAll(_database.ledgerPostings, [
        for (final (position, posting) in postings.indexed)
          LedgerPostingsCompanion.insert(
            transactionId: id,
            position: position,
            accountId: Value(posting.accountId),
            currencyCode: posting.currencyCode,
            debitMinor: posting.debitMinor,
            role: posting.role.name,
            needsReview: Value(posting.needsReview),
          ),
      ]),
    );
  }

  Future<EntryRow> _activeEntry(String id) async {
    final row =
        await (_database.select(_database.ledgerEntries)..where(
              (table) => table.id.equals(id) & table.isDeleted.equals(false),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw ArgumentError.value(id, 'id', 'transaction not found');
    }
    return row;
  }

  Future<List<PostingRow>> _accountPostings(String id) =>
      (_database.select(_database.ledgerPostings)
            ..where(
              (table) =>
                  table.transactionId.equals(id) & table.accountId.isNotNull(),
            )
            ..orderBy([(table) => OrderingTerm.asc(table.position)]))
          .get();

  Future<List<AccountPayment>> _expensePayments(String id) async => [
    for (final leg in await _accountPostings(id))
      AccountPayment(leg.accountId!, -leg.debitMinor),
  ];

  Future<void> _requireNoActiveRefunds(String id) async {
    if (await _hasActiveRefunds(id)) {
      throw const TransactionRuleException(TransactionRuleError.linkedRefunds);
    }
  }

  Future<bool> _hasActiveRefunds(String id) async {
    final refund =
        await (_database.select(_database.ledgerEntries)
              ..where(
                (table) =>
                    table.refundOfId.equals(id) & table.isDeleted.equals(false),
              )
              ..limit(1))
            .getSingleOrNull();
    return refund != null;
  }

  @override
  Future<void> deleteTransaction(String id) => _database.transaction(() async {
    await _activeEntry(id);
    await _requireNoActiveRefunds(id);
    await (_database.update(
      _database.ledgerEntries,
    )..where((table) => table.id.equals(id))).write(
      LedgerEntriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  @override
  Future<void> postTransaction(String id) => _database.transaction(() async {
    final entry = await _activeEntry(id);
    if (entry.status == LedgerPostingStatus.posted.name) return;

    final type = LedgerTransactionType.values.byName(entry.transactionType);
    final originalId = entry.refundOfId;
    if (originalId == null) {
      await _validateTransaction(
        type: type,
        amountMinor: entry.amountMinor,
        categoryId: entry.categoryId,
        accountId: entry.accountId,
        targetAccountId: entry.targetAccountId,
        previous: entry,
        status: LedgerPostingStatus.posted,
        payments: type == LedgerTransactionType.expense
            ? await _expensePayments(id)
            : null,
      );
    } else {
      await _validateRefund(
        originalId: originalId,
        accountId: entry.accountId,
        amountMinor: entry.amountMinor,
        occurredAt: entry.occurredAt,
        excludingId: id,
      );
    }

    await (_database.update(
      _database.ledgerEntries,
    )..where((table) => table.id.equals(id))).write(
      LedgerEntriesCompanion(
        status: Value(LedgerPostingStatus.posted.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  @override
  Future<void> saveRefund({
    String? id,
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => _database.transaction(() async {
    final previous = id == null ? null : await _activeEntry(id);
    if (previous != null && previous.refundOfId != originalId) {
      throw ArgumentError('A refund must retain its original purchase');
    }
    final original = await _validateRefund(
      originalId: originalId,
      accountId: accountId,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      excludingId: id,
    );
    await _writeEntry(
      previous: previous,
      type: LedgerTransactionType.expense,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: original.categoryId,
      currencyCode: original.currencyCode,
      accountId: accountId,
      refundOfId: original.id,
      status: previous == null
          ? status
          : LedgerPostingStatus.values.byName(previous.status),
      note: note,
      postings: transactionPostings(
        type: LedgerTransactionType.expense,
        amountMinor: amountMinor,
        currencyCode: original.currencyCode,
        accountId: accountId,
        isRefund: true,
      ),
    );
  });

  Future<EntryRow> _validateRefund({
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String? excludingId,
  }) async {
    final original = await _activeEntry(originalId);
    if (amountMinor <= 0 ||
        original.transactionType != LedgerTransactionType.expense.name ||
        original.status != LedgerPostingStatus.posted.name ||
        original.refundOfId != null ||
        occurredAt.isBefore(original.occurredAt)) {
      throw ArgumentError(
        'A refund requires a positive amount and an earlier posted purchase',
      );
    }
    final legs = await _accountPostings(originalId);
    final paid = legs.where((leg) => leg.accountId == accountId).singleOrNull;
    if (paid == null ||
        paid.debitMinor >= 0 ||
        legs.any((leg) => leg.needsReview)) {
      throw ArgumentError(
        'Refund account must have a verified payment on the original purchase',
      );
    }

    final refunds =
        await (_database.select(_database.ledgerEntries)..where(
              (table) =>
                  table.refundOfId.equals(originalId) &
                  table.accountId.equals(accountId) &
                  table.isDeleted.equals(false) &
                  (excludingId == null
                      ? const Constant(true)
                      : table.id.equals(excludingId).not()),
            ))
            .get();
    final available = refunds.fold(
      -paid.debitMinor,
      (amount, refund) => amount - refund.amountMinor,
    );
    if (amountMinor > available) {
      throw TransactionRuleException(
        TransactionRuleError.refundLimitExceeded,
        amountMinor: available,
      );
    }
    return original;
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

  Future<({String categoryId, String currencyCode, List<PostingLeg> postings})>
  _validateTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required String? categoryId,
    required String accountId,
    required String? targetAccountId,
    required LedgerPostingStatus status,
    EntryRow? previous,
    List<AccountPayment>? payments,
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

    final allocations = type == LedgerTransactionType.expense
        ? payments ?? [AccountPayment(accountId, amountMinor)]
        : const <AccountPayment>[];
    if (type == LedgerTransactionType.expense
        ? allocations.isEmpty ||
              allocations.first.accountId != accountId ||
              !isValidPaymentSplit(allocations, amountMinor)
        : payments != null && payments.isNotEmpty) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidPaymentSplit,
      );
    }
    if (accountId == targetAccountId) {
      throw ArgumentError('source and target accounts must differ');
    }
    final ids = {
      accountId,
      ?targetAccountId,
      for (final payment in allocations) payment.accountId,
    };
    final accounts = {
      for (final row in await (_database.select(
        _database.ledgerAccounts,
      )..where((table) => table.id.isIn(ids))).get())
        row.id: row,
    };
    if (accounts.length != ids.length) {
      throw ArgumentError('A transaction account no longer exists');
    }
    final account = accounts[accountId]!;
    final target = accounts[targetAccountId];
    if (accounts.values.any(
          (row) => row.currencyCode != account.currencyCode,
        ) ||
        (previous != null && previous.currencyCode != account.currencyCode)) {
      throw ArgumentError(
        'A cross-currency transaction requires explicit settlement amounts',
      );
    }
    final posting = status == LedgerPostingStatus.posted;
    final originalAccounts =
        previous == null ||
            (posting && previous.status == LedgerPostingStatus.pending.name)
        ? const <String>{}
        : {
            for (final leg in await _accountPostings(previous.id))
              leg.accountId!,
          };
    if (accounts.values.any(
      (row) => row.isArchived && !originalAccounts.contains(row.id),
    )) {
      throw const TransactionRuleException(
        TransactionRuleError.archivedPostingAccount,
      );
    }

    final accountKind = AccountKind.values.byName(account.kind);
    final targetKind = target == null
        ? null
        : AccountKind.values.byName(target.kind);
    Future<void> requireFunds(AccountRow source, int amount) =>
        _requireAvailableBalance(
          accountId: source.id,
          accountName: source.name,
          requiredMinor: amount,
          excludingEntryId: previous?.id,
        );
    Future<void> requireDebt(AccountRow debt) => _requireOutstandingLiability(
      accountId: debt.id,
      accountName: debt.name,
      requiredMinor: amountMinor,
      excludingEntryId: previous?.id,
    );

    switch (type) {
      case LedgerTransactionType.expense:
        if (target != null) {
          throw ArgumentError('expense and income have no target account');
        }
        if (posting) {
          for (final payment in allocations) {
            final source = accounts[payment.accountId]!;
            if (source.kind != AccountKind.creditLine.name) {
              await requireFunds(source, payment.amountMinor);
            }
          }
        }
      case LedgerTransactionType.income:
        if (target != null) {
          throw ArgumentError('expense and income have no target account');
        }
        if (posting && accountKind == AccountKind.creditLine) {
          await requireDebt(account);
        }
      case LedgerTransactionType.borrowing:
        if (accountKind != AccountKind.creditLine ||
            targetKind == null ||
            targetKind == AccountKind.creditLine ||
            targetKind == AccountKind.entrustedFunds) {
          throw ArgumentError('borrowing requires liability to personal asset');
        }
      case LedgerTransactionType.transfer:
        if (accountKind == AccountKind.creditLine ||
            targetKind == null ||
            targetKind == AccountKind.creditLine) {
          throw ArgumentError('transfer requires two non-liability accounts');
        }
        if (posting) await requireFunds(account, amountMinor);
      case LedgerTransactionType.repayment:
        if (accountKind == AccountKind.creditLine ||
            targetKind != AccountKind.creditLine) {
          throw ArgumentError(
            'repayment requires a non-liability account to liability',
          );
        }
        if (posting) {
          await requireFunds(account, amountMinor);
          await requireDebt(target!);
        }
    }
    return (
      categoryId: resolvedCategoryId,
      currencyCode: account.currencyCode,
      postings: transactionPostings(
        type: type,
        amountMinor: amountMinor,
        currencyCode: account.currencyCode,
        accountId: accountId,
        targetAccountId: targetAccountId,
        payments: allocations,
        isCreditIncome:
            type == LedgerTransactionType.income &&
            accountKind == AccountKind.creditLine,
      ),
    );
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

  Selectable<QueryRow> _balanceQuery({
    String? accountId,
    String? excludingEntryId,
  }) {
    final postingAccount = accountId == null ? '' : 'AND leg.account_id = ?';
    final exclusion = excludingEntryId == null
        ? ''
        : 'AND leg.transaction_id != ?';
    final selection = accountId == null ? 'a.is_archived = 0' : 'a.id = ?';
    return _database.customSelect(
      """
      SELECT a.id, a.name, a.kind, a.opening_balance_minor,
        a.opening_balance_minor + COALESCE(p.net_debit, 0) *
          CASE WHEN a.kind = 'creditLine' THEN -1 ELSE 1 END AS current_balance
      FROM ledger_accounts AS a
      LEFT JOIN (
        SELECT leg.account_id, leg.currency_code, SUM(leg.debit_minor) AS net_debit
        FROM ledger_postings AS leg
        JOIN ledger_entries AS entry ON entry.id = leg.transaction_id
        WHERE leg.account_id IS NOT NULL
          AND entry.status = 'posted' AND entry.is_deleted = 0
          $postingAccount $exclusion
        GROUP BY leg.account_id, leg.currency_code
      ) AS p ON p.account_id = a.id AND p.currency_code = a.currency_code
      WHERE $selection
      ORDER BY a.sort_order
      """,
      variables: [
        if (accountId != null) Variable.withString(accountId),
        if (excludingEntryId != null) Variable.withString(excludingEntryId),
        if (accountId != null) Variable.withString(accountId),
      ],
      readsFrom: {
        _database.ledgerAccounts,
        _database.ledgerEntries,
        _database.ledgerPostings,
      },
    );
  }

  Future<int> _currentBalance(
    String accountId, {
    String? excludingEntryId,
  }) async {
    final row = await _balanceQuery(
      accountId: accountId,
      excludingEntryId: excludingEntryId,
    ).getSingle();
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
    await _database.transaction(() async {
      final snapshot = await _balanceQuery(accountId: accountId)
          .getSingleOrNull();
      if (snapshot == null) {
        throw ArgumentError.value(accountId, 'accountId', 'account not found');
      }
      final difference = amountMinor - snapshot.read<int>('current_balance');
      final opening = snapshot.read<int>('opening_balance_minor');
      await (_database.update(
        _database.ledgerAccounts,
      )..where((table) => table.id.equals(accountId))).write(
        LedgerAccountsCompanion(
          openingBalanceMinor: Value(opening + difference),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
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
  Future<String> createFullBackup() => _database.transaction(() async {
    final accounts = await _database.select(_database.ledgerAccounts).get();
    final categories = await _database.select(_database.ledgerCategories).get();
    final entries = await _database.select(_database.ledgerEntries).get();
    final postings = <String, List<PostingRow>>{};
    final orderedPostings = await (_database.select(
      _database.ledgerPostings,
    )..orderBy([(table) => OrderingTerm.asc(table.position)])).get();
    for (final posting in orderedPostings) {
      (postings[posting.transactionId] ??= []).add(posting);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': _backupFormat,
      'backup_version': 2,
      'schema_version': _database.schemaVersion,
      'created_at': DateTime.now().toIso8601String(),
      'accounts': [for (final item in accounts) _backupAccount(item)],
      'categories': [for (final item in categories) _backupCategory(item)],
      'entries': [
        for (final entry in entries)
          _backupEntry(entry, postings[entry.id] ?? const []),
      ],
    });
  });

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

      final knownAccounts = {
        for (final account
            in await _database.select(_database.ledgerAccounts).get())
          account.id: account,
      };
      final entries = {
        for (final raw in payload.entries)
          _restoreEntry(raw, payload.version): raw,
      };
      if (entries.keys.map((entry) => entry.id).toSet().length !=
          payload.entries.length) {
        throw const LedgerBackupException('备份含重复交易 ID');
      }

      // Insert purchases before their refunds, even if the file order differs.
      final ordered = [...entries.keys]
        ..sort(
          (a, b) => (a.refundOfId == null ? 0 : 1).compareTo(
            b.refundOfId == null ? 0 : 1,
          ),
        );
      final legacyReviews = <String, List<PostingLeg>>{};
      for (final entry in ordered) {
        if (payload.version == 1 && mode == BackupRestoreMode.merge) {
          await _guardLegacyMerge(entry.id);
        }
        await _database
            .into(_database.ledgerEntries)
            .insertOnConflictUpdate(entry);
        final postings = payload.version == 1
            ? const <PostingLeg>[]
            : _restorePostings(entries[entry]!, entry, knownAccounts);
        final legacyReview =
            postings.isNotEmpty &&
            entry.status == LedgerPostingStatus.posted.name &&
            entry.refundOfId == null &&
            postings.every((posting) => posting.needsReview);
        if (legacyReview) legacyReviews[entry.id] = postings;
        await _replacePostings(entry.id, legacyReview ? const [] : postings);
      }
      if (payload.version == 1 || legacyReviews.isNotEmpty) {
        await _database.backfillLegacyPostings();
      }
      for (final item in legacyReviews.entries) {
        final derived =
            await (_database.select(_database.ledgerPostings)
                  ..where((row) => row.transactionId.equals(item.key))
                  ..orderBy([(row) => OrderingTerm.asc(row.position)]))
                .get();
        if (derived.length != item.value.length ||
            derived.indexed.any(
              (row) => _postingLeg(row.$2) != item.value[row.$1],
            )) {
          throw const LedgerBackupException('备份历史分录与原交易不一致');
        }
      }
      await _validateRestoredLedger();
    });
  }

  Future<void> _guardLegacyMerge(String id) async {
    final entries = _database.ledgerEntries;
    final current = await (_database.select(
      entries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (current != null &&
        (current.status == LedgerPostingStatus.pending.name ||
            current.refundOfId != null ||
            (current.transactionType == LedgerTransactionType.expense.name &&
                ((await _accountPostings(id)).length > 1 ||
                    await _hasActiveRefunds(id))))) {
      throw const LedgerBackupException('旧备份与已有拆分、待入账或退款交易冲突');
    }
  }

  Future<void> _validateRestoredLedger() async {
    final mismatch = await _database.customSelect('''
      SELECT 1
      FROM ledger_postings AS p
      JOIN ledger_accounts AS a ON a.id = p.account_id
      WHERE p.currency_code <> a.currency_code
      LIMIT 1
    ''').getSingleOrNull();
    if (mismatch != null) {
      throw const LedgerBackupException('备份与已有账户分录币种冲突');
    }
    final refunds =
        await (_database.select(_database.ledgerEntries)..where(
              (table) =>
                  table.refundOfId.isNotNull() & table.isDeleted.equals(false),
            ))
            .get();
    for (final refund in refunds) {
      try {
        final original = await _validateRefund(
          originalId: refund.refundOfId!,
          accountId: refund.accountId,
          amountMinor: refund.amountMinor,
          occurredAt: refund.occurredAt,
          excludingId: refund.id,
        );
        if (refund.currencyCode != original.currencyCode ||
            refund.categoryId != original.categoryId) {
          throw const LedgerBackupException('备份退款与原交易的币种或分类不一致');
        }
      } on ArgumentError {
        throw const LedgerBackupException('备份退款没有有效的原交易或付款账户');
      } on TransactionRuleException {
        throw const LedgerBackupException('备份中的累计退款超过原交易金额');
      }
    }
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

Map<String, Object?> _backupEntry(EntryRow item, List<PostingRow> postings) => {
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
  'status': item.status,
  'refund_of_id': item.refundOfId,
  'postings': [for (final posting in postings) _backupPosting(posting)],
};

EntryRow _restoreEntry(Map<String, dynamic> raw, int version) {
  final id = _requiredString(raw, 'id');
  final original = version == 2 ? _nullableString(raw, 'refund_of_id') : null;
  final type = _requiredEnum(
    raw,
    'transaction_type',
    LedgerTransactionType.values.map((type) => type.name),
  );
  if (original != null &&
      (id == original || type != LedgerTransactionType.expense.name)) {
    throw const LedgerBackupException('备份退款关联无效');
  }
  return EntryRow(
    id: id,
    transactionType: type,
    amountMinor: _requiredInt(raw, 'amount_minor'),
    currencyCode: _requiredString(raw, 'currency_code'),
    occurredAt: _requiredDate(raw, 'occurred_at'),
    timezoneOffsetMinutes: _requiredInt(raw, 'timezone_offset_minutes'),
    categoryId: _requiredString(raw, 'category_id'),
    accountId: _requiredString(raw, 'account_id'),
    targetAccountId: _nullableString(raw, 'target_account_id'),
    note: _requiredString(raw, 'note'),
    createdAt: _requiredDate(raw, 'created_at'),
    updatedAt: _requiredDate(raw, 'updated_at'),
    isDeleted: _requiredBool(raw, 'is_deleted'),
    status: version == 2
        ? _requiredEnum(
            raw,
            'status',
            LedgerPostingStatus.values.map((status) => status.name),
          )
        : LedgerPostingStatus.posted.name,
    refundOfId: original,
  );
}

List<PostingLeg> _restorePostings(
  Map<String, dynamic> raw,
  EntryRow entry,
  Map<String, AccountRow> accounts,
) {
  final postings = <PostingLeg>[
    for (final leg in _requiredObjectList(raw, 'postings'))
      (
        accountId: _nullableString(leg, 'account_id'),
        currencyCode: _requiredString(leg, 'currency_code'),
        debitMinor: _requiredInt(leg, 'debit_minor'),
        role: LedgerPostingRole.values.byName(
          _requiredEnum(
            leg,
            'role',
            LedgerPostingRole.values.map((role) => role.name),
          ),
        ),
        needsReview: _requiredBool(leg, 'needs_review'),
      ),
  ];
  final totals = <String, BigInt>{};
  final accountLegs = <PostingLeg>[];
  for (final leg in postings) {
    if (leg.role == LedgerPostingRole.account) {
      if (leg.accountId == null ||
          accounts[leg.accountId]?.currencyCode != leg.currencyCode) {
        throw const LedgerBackupException('备份分录与账户币种不匹配');
      }
      accountLegs.add(leg);
    } else if (leg.accountId != null) {
      throw const LedgerBackupException('备份分录类型与账户不匹配');
    }
    totals.update(
      leg.currencyCode,
      (total) => total + BigInt.from(leg.debitMinor),
      ifAbsent: () => BigInt.from(leg.debitMinor),
    );
  }

  if (accountLegs.isEmpty ||
      accountLegs.first.accountId != entry.accountId ||
      totals.values.any((total) => total != BigInt.zero)) {
    throw const LedgerBackupException('备份分录不平衡或缺少付款账户');
  }

  final type = LedgerTransactionType.values.byName(entry.transactionType);
  final isRefund = entry.refundOfId != null;
  // Older rows may have unknown settlement semantics. Preserve their exact
  // per-currency account effects when restoring a full backup.
  if (!isRefund &&
      entry.status == LedgerPostingStatus.posted.name &&
      postings.every((leg) => leg.needsReview)) {
    return postings;
  }

  final payments = type == LedgerTransactionType.expense && !isRefund
      ? [
          for (final leg in accountLegs)
            AccountPayment(leg.accountId!, -leg.debitMinor),
        ]
      : const <AccountPayment>[];
  final hasTarget =
      type != LedgerTransactionType.expense &&
      type != LedgerTransactionType.income;
  final source = accounts[entry.accountId]!;
  final target = accounts[entry.targetAccountId];
  final sourceCredit = source.kind == AccountKind.creditLine.name;
  final targetCredit = target?.kind == AccountKind.creditLine.name;
  final validAccounts = switch (type) {
    LedgerTransactionType.expense ||
    LedgerTransactionType.income => entry.targetAccountId == null,
    LedgerTransactionType.borrowing =>
      sourceCredit &&
          target != null &&
          !targetCredit &&
          target.kind != AccountKind.entrustedFunds.name,
    LedgerTransactionType.repayment => !sourceCredit && targetCredit,
    LedgerTransactionType.transfer =>
      !sourceCredit && target != null && !targetCredit,
  };
  if (entry.amountMinor <= 0 ||
      !validAccounts ||
      (hasTarget && entry.accountId == entry.targetAccountId) ||
      (payments.isNotEmpty &&
          !isValidPaymentSplit(payments, entry.amountMinor))) {
    throw const LedgerBackupException('备份交易账户或金额无效');
  }
  final expected = transactionPostings(
    type: type,
    amountMinor: entry.amountMinor,
    currencyCode: entry.currencyCode,
    accountId: entry.accountId,
    targetAccountId: entry.targetAccountId,
    isRefund: isRefund,
    payments: payments,
    isCreditIncome: type == LedgerTransactionType.income && sourceCredit,
  );
  if (postings.length != expected.length ||
      postings.indexed.any((item) => item.$2 != expected[item.$1])) {
    throw const LedgerBackupException('备份分录与交易不一致');
  }
  return postings;
}

PostingLeg _postingLeg(PostingRow row) => (
  accountId: row.accountId,
  currencyCode: row.currencyCode,
  debitMinor: row.debitMinor,
  role: LedgerPostingRole.values.byName(row.role),
  needsReview: row.needsReview,
);

Map<String, Object?> _backupPosting(PostingRow posting) => {
  'account_id': posting.accountId,
  'currency_code': posting.currencyCode,
  'debit_minor': posting.debitMinor,
  'role': posting.role,
  'needs_review': posting.needsReview,
};

({
  DateTime createdAt,
  int version,
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
  if (decoded is! Map<String, dynamic>) {
    throw const LedgerBackupException('这不是受支持的 Summa 完整备份');
  }
  final version = decoded['backup_version'];
  final format = decoded['format'];
  if (version is! int ||
      !(format == _backupFormat && (version == 1 || version == 2) ||
          format == _legacyBackupFormat && version == 1)) {
    throw const LedgerBackupException('这不是受支持的 Summa 完整备份');
  }
  final createdAt = DateTime.tryParse(decoded['created_at']?.toString() ?? '');
  if (createdAt == null) throw const LedgerBackupException('备份时间无效');
  return (
    createdAt: createdAt,
    version: version,
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
