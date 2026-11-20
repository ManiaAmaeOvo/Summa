import 'dart:math' as math;
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/transactions/ledger_posting.dart';
import 'package:summa/domain/defaults/default_ledger_names.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';
import 'package:uuid/uuid.dart';

import 'drift_csv_import_store.dart';
import 'drift_debt_contract_store.dart';
import 'drift_import_rule_store.dart';
import 'drift_reconciliation_store.dart';
import 'drift_recurring_plan_store.dart';
import 'drift_spending_plan_store.dart';
import 'drift_valuation_store.dart';

const _backupFormat = 'summa_full_backup';
const _legacyBackupFormat = 'ledgerpro_full_backup';

class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this._database)
    : _valuation = DriftValuationStore(_database),
      _reconciliation = DriftReconciliationStore(_database),
      _csv = DriftCsvImportStore(_database),
      _importRules = DriftImportRuleStore(_database),
      _spendingPlans = DriftSpendingPlanStore(_database),
      _recurringPlans = DriftRecurringPlanStore(_database),
      _debtContracts = DriftDebtContractStore(_database);

  final AppDatabase _database;
  final DriftValuationStore _valuation;
  final DriftReconciliationStore _reconciliation;
  final DriftCsvImportStore _csv;
  final DriftImportRuleStore _importRules;
  final DriftSpendingPlanStore _spendingPlans;
  final DriftRecurringPlanStore _recurringPlans;
  final DriftDebtContractStore _debtContracts;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<LedgerAccount>> watchAccounts() {
    final query = _database.select(_database.ledgerAccounts)
      ..where(
        (table) =>
            table.isArchived.equals(false) &
            table.kind.equals(AccountKind.familyDirect.name).not(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => LedgerAccount(
              id: row.id,
              name: row.name,
              kind: AccountKind.values.byName(row.kind),
              currencyCode: row.currencyCode,
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
              currencyCode: row.read<String>('currency_code'),
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
              _database.balanceCheckpoints,
              _database.balanceCheckpoints.adjustmentId.equalsExp(entry.id),
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

    return query.watch().asyncMap((rows) async {
      final transactions = <String, List<TypedResult>>{};
      for (final row in rows) {
        (transactions[row.readTable(entry).id] ??= []).add(row);
      }
      final terms = {
        for (final group in transactions.entries)
          if (group.value.first.readTable(entry).termsJson case final json?)
            group.key: _decodeTerms(json),
      };
      final reversedIds = {
        for (final detail in terms.values) ?detail.reversalOfId,
      };
      final allocationIds = {
        for (final detail in terms.values) ...[
          for (final part in detail.categories) part.categoryId,
          if (detail.feeMinor != 0) financialFeeCategoryId,
          if (detail.interestMinor != 0) financialInterestCategoryId,
        ],
      };
      final labels = allocationIds.isEmpty
          ? const <
              String,
              ({String parentId, String parentName, String name})
            >{}
          : await _allocationLabels(allocationIds);
      return [
        for (final group in transactions.entries)
          _ledgerRecord(
            group.value,
            terms[group.key] ?? const TransactionTerms(),
            reversedIds.contains(group.key),
            labels,
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

  Future<Map<String, ({String parentId, String parentName, String name})>>
  _allocationLabels(Set<String> ids) async {
    final category = _database.ledgerCategories;
    final parent = _database.alias(category, 'allocation_parent');
    final query = _database.select(category).join([
      innerJoin(parent, parent.id.equalsExp(category.parentId)),
    ])..where(category.id.isIn(ids));
    return {
      for (final row in await query.get())
        row.readTable(category).id: (
          parentId: row.readTable(parent).id,
          parentName: row.readTable(parent).name,
          name: row.readTable(category).name,
        ),
    };
  }

  LedgerRecord _ledgerRecord(
    List<TypedResult> legs,
    TransactionTerms terms,
    bool hasReversal,
    Map<String, ({String parentId, String parentName, String name})> labels,
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
            currencyCode: posting.currencyCode,
            needsReview: posting.needsReview,
          ),
        );
      }
    }
    return LedgerRecord(
      id: item.id,
      type: LedgerTransactionType.values.byName(item.transactionType),
      amountMinor: item.amountMinor,
      currencyCode: item.currencyCode,
      settlement: _entrySettlement(item),
      terms: terms,
      hasReversal: hasReversal,
      isReconciliationAdjustment:
          row.readTableOrNull(_database.balanceCheckpoints) != null,
      allocationLabels: {
        for (final category in terms.categories)
          category.categoryId: ?labels[category.categoryId],
        if (terms.feeMinor > 0)
          financialFeeCategoryId: ?labels[financialFeeCategoryId],
        if (terms.interestMinor > 0)
          financialInterestCategoryId: ?labels[financialInterestCategoryId],
      },
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
    TransferSettlement? settlement,
    TransactionTerms terms = const TransactionTerms(),
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
    settlement: settlement,
    terms: terms,
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
    TransferSettlement? settlement,
    TransactionTerms? terms,
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
    settlement: settlement,
    terms: terms,
    status: LedgerPostingStatus.posted,
    note: note,
  );

  Future<void> _saveTransaction({
    String? id,
    String? newEntryId,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    required String? targetAccountId,
    required String? categoryId,
    required List<AccountPayment>? payments,
    TransferSettlement? settlement,
    String? requiredCurrency,
    TransactionTerms? terms,
    required LedgerPostingStatus status,
    required String note,
  }) => _database.transaction(() async {
    final previous = id == null ? null : await _activeEntry(id);
    if (type == LedgerTransactionType.adjustment ||
        terms?.reversalOfId != null) {
      throw ArgumentError('Use the balance or reversal command');
    }
    if (previous != null) {
      await _requireEditable(previous);
      if (previous.refundOfId != null) {
        throw ArgumentError('Use saveRefund to edit a refund');
      }
      await _requireNoActiveRefunds(previous.id);
    }
    final effectiveStatus = previous == null
        ? status
        : LedgerPostingStatus.values.byName(previous.status);
    final actualTerms = terms ?? _decodeTerms(previous?.termsJson);
    final savedPayments =
        type == LedgerTransactionType.expense &&
            previous?.transactionType == LedgerTransactionType.expense.name &&
            payments == null
        ? await _expensePayments(previous!.id)
        : const <AccountPayment>[];
    final preservedSettlement =
        previous != null &&
            type == LedgerTransactionType.transfer &&
            previous.amountMinor == amountMinor &&
            previous.accountId == accountId &&
            previous.targetAccountId == targetAccountId
        ? _entrySettlement(previous)
        : null;
    final actualSettlement = settlement ?? preservedSettlement;
    final validation = await _validateTransaction(
      type: type,
      amountMinor: amountMinor,
      categoryId: categoryId,
      accountId: accountId,
      targetAccountId: targetAccountId,
      status: effectiveStatus,
      previous: previous,
      settlement: actualSettlement,
      requiredCurrency: requiredCurrency,
      terms: actualTerms,
      payments: payments ?? (savedPayments.length > 1 ? savedPayments : null),
    );
    await _writeEntry(
      previous: previous,
      entryId: newEntryId,
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: validation.categoryId,
      currencyCode: validation.currencyCode,
      settlement: actualSettlement,
      terms: actualTerms,
      accountId: accountId,
      targetAccountId: targetAccountId,
      status: effectiveStatus,
      note: note,
      postings: validation.postings,
    );
  });

  Future<void> _writeEntry({
    EntryRow? previous,
    String? entryId,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String currencyCode,
    required String accountId,
    String? targetAccountId,
    String? refundOfId,
    TransferSettlement? settlement,
    TransactionTerms terms = const TransactionTerms(),
    required LedgerPostingStatus status,
    required String note,
    required List<PostingLeg> postings,
  }) async {
    final now = DateTime.now();
    final id = previous?.id ?? entryId ?? _uuid.v4();
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
            settlementAmountMinor: Value(settlement?.amountMinor),
            settlementCurrencyCode: Value(settlement?.currencyCode),
            quotedExchangeRate: Value(settlement?.quotedRate),
            termsJson: Value(terms.isEmpty ? null : jsonEncode(terms.toJson())),
            status: Value(status.name),
            note: Value(note.trim()),
            createdAt: previous?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    await _replacePostings(id, postings);
    final receivableIds = {
      ..._receivableAccounts(type, accountId, targetAccountId, terms),
      if (previous != null) ..._entryReceivableAccounts(previous),
    };
    if (receivableIds.isNotEmpty) {
      await _checkReceivableBalances(accountIds: receivableIds);
    }
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
      if (leg.debitMinor < 0) AccountPayment(leg.accountId!, -leg.debitMinor),
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
    final entry = await _activeEntry(id);
    await _requireEditable(entry);
    await _requireIndependentAdjustment(entry);
    await _requireNoActiveRefunds(id);
    await _softDeleteEntry(entry, DateTime.now());
  });

  Future<void> _softDeleteEntry(EntryRow entry, DateTime at) async {
    await (_database.update(
      _database.ledgerEntries,
    )..where((table) => table.id.equals(entry.id))).write(
      LedgerEntriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(at),
      ),
    );
    final receivableIds = _entryReceivableAccounts(entry);
    if (receivableIds.isNotEmpty) {
      await _checkReceivableBalances(accountIds: receivableIds);
    }
  }

  Future<void> _requireIndependentAdjustment(EntryRow entry) async {
    if (entry.transactionType == LedgerTransactionType.adjustment.name &&
        await _reconciliation.ownsAdjustment(entry.id)) {
      throw const TransactionRuleException(
        TransactionRuleError.linkedCheckpoint,
      );
    }
  }

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
        settlement: _entrySettlement(entry),
        terms: _decodeTerms(entry.termsJson),
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
    final receivableIds = _entryReceivableAccounts(entry);
    if (receivableIds.isNotEmpty) {
      await _checkReceivableBalances(accountIds: receivableIds);
    }
  });

  Future<void> _requireEditable(EntryRow entry) async {
    if (_decodeTerms(entry.termsJson).reversalOfId != null ||
        await _hasActiveReversal(entry.id)) {
      throw const TransactionRuleException(TransactionRuleError.linkedReversal);
    }
  }

  Future<String?> _activeReversalId(String id) async {
    final row = await _database
        .customSelect(
          """
        SELECT id FROM ledger_entries
        WHERE is_deleted = 0 AND json_extract(terms_json, '\$.reversal_of_id') = ?
        LIMIT 1
      """,
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row?.read<String>('id');
  }

  Future<bool> _hasActiveReversal(String id) async =>
      await _activeReversalId(id) != null;

  @override
  Future<void> reverseTransaction(String id, {required DateTime occurredAt}) =>
      _database.transaction(() async {
        final original = await _activeEntry(id);
        await _requireIndependentAdjustment(original);
        final terms = _decodeTerms(original.termsJson);
        if (await _hasActiveReversal(id)) return;
        await _requireNoActiveRefunds(id);
        if (original.status != LedgerPostingStatus.posted.name ||
            original.refundOfId != null ||
            terms.reversalOfId != null ||
            occurredAt.isBefore(original.occurredAt)) {
          throw const TransactionRuleException(
            TransactionRuleError.invalidTransactionDetails,
          );
        }
        final legs = await _allPostings(id);
        if (legs.isEmpty || legs.any((leg) => leg.needsReview)) {
          throw const TransactionRuleException(
            TransactionRuleError.invalidTransactionDetails,
          );
        }
        for (final leg in legs) {
          final accountId = leg.accountId;
          if (accountId == null || leg.debitMinor == 0) continue;
          final account = await (_database.select(
            _database.ledgerAccounts,
          )..where((row) => row.id.equals(accountId))).getSingle();
          final kind = AccountKind.values.byName(account.kind);
          if (kind.isPersonalCash || kind == AccountKind.entrustedFunds) {
            await _requireAvailableBalance(
              accountId: accountId,
              accountName: account.name,
              currencyCode: account.currencyCode,
              requiredMinor: leg.debitMinor,
            );
          }
        }
        await _writeEntry(
          type: LedgerTransactionType.values.byName(original.transactionType),
          amountMinor: original.amountMinor,
          occurredAt: occurredAt,
          categoryId: original.categoryId,
          currencyCode: original.currencyCode,
          accountId: original.accountId,
          targetAccountId: original.targetAccountId,
          settlement: _entrySettlement(original),
          terms: TransactionTerms.fromJson({
            ...terms.toJson(),
            'reversal_of_id': id,
          }),
          status: LedgerPostingStatus.posted,
          note: '',
          postings: [for (final leg in legs) oppositePosting(_postingLeg(leg))],
        );
      });

  Future<List<PostingRow>> _allPostings(String id) =>
      (_database.select(_database.ledgerPostings)
            ..where((row) => row.transactionId.equals(id))
            ..orderBy([(row) => OrderingTerm.asc(row.position)]))
          .get();

  @override
  Stream<List<BalanceCheckpoint>> watchBalanceCheckpoints(String accountId) =>
      _reconciliation.watch(accountId);

  @override
  Future<void> saveBalanceCheckpoint({
    required String accountId,
    required DateTime observedAt,
    required int actualMinor,
    required String note,
  }) => _database.transaction(() async {
    final now = DateTime.now();
    if (actualMinor < 0 || observedAt.isAfter(now)) {
      throw const ReconciliationException(ReconciliationError.unavailable);
    }
    final snapshot = await _checkpointBalance(accountId, observedAt);
    await _reconciliation.insert(
      CheckpointRow(
        id: _uuid.v4(),
        accountId: accountId,
        observedAt: observedAt,
        currencyCode: snapshot.read<String>('currency_code'),
        actualMinor: actualMinor,
        recordedBookMinor: snapshot.read<int>('current_balance'),
        note: note.trim(),
        createdAt: now,
      ),
    );
  });

  @override
  Future<void> adjustBalanceCheckpoint(
    String id, {
    required int expectedBookMinor,
  }) => _database.transaction(() async {
    final checkpoint = await _reconciliation.read(id);
    if (checkpoint == null ||
        checkpoint.voidedAt != null ||
        checkpoint.adjustmentId != null) {
      throw const ReconciliationException(ReconciliationError.unavailable);
    }
    final snapshot = await _checkpointBalance(
      checkpoint.accountId,
      checkpoint.observedAt,
    );
    final book = snapshot.read<int>('current_balance');
    if (book != expectedBookMinor) {
      throw const ReconciliationException(ReconciliationError.changed);
    }
    if (checkpoint.actualMinor == book) return;
    final entryId = _uuid.v4();
    await _writeBalanceAdjustment(
      snapshot: snapshot,
      amountMinor: checkpoint.actualMinor,
      occurredAt: checkpoint.observedAt,
      note: checkpoint.note,
      entryId: entryId,
    );
    await _reconciliation.setAdjustment(id, entryId, book);
  });

  @override
  Future<void> voidBalanceCheckpoint(String id) =>
      _database.transaction(() async {
        final checkpoint = await _reconciliation.read(id);
        if (checkpoint == null || checkpoint.voidedAt != null) return;
        final now = DateTime.now();
        if (checkpoint.adjustmentId case final adjustmentId?) {
          await _softDeleteEntry(await _activeEntry(adjustmentId), now);
        }
        await _reconciliation.voidCheckpoint(id, now);
      });

  Future<QueryRow> _checkpointBalance(
    String accountId,
    DateTime observedAt,
  ) async {
    final snapshot = await _balanceQuery(
      accountId: accountId,
      asOf: observedAt,
    ).getSingleOrNull();
    if (snapshot == null ||
        snapshot.read<bool>('is_archived') ||
        snapshot.read<String>('kind') == AccountKind.familyDirect.name) {
      throw const ReconciliationException(ReconciliationError.unavailable);
    }
    return snapshot;
  }

  @override
  Future<void> recordBalanceAdjustment({
    required String accountId,
    required int amountMinor,
    required String note,
  }) => _database.transaction(() async {
    if (amountMinor < 0) throw ArgumentError.value(amountMinor, 'amountMinor');
    final snapshot = await _balanceQuery(accountId: accountId).getSingle();
    if (snapshot.read<String>('kind') == AccountKind.familyDirect.name) {
      throw ArgumentError.value(accountId);
    }
    await _writeBalanceAdjustment(
      snapshot: snapshot,
      amountMinor: amountMinor,
      occurredAt: DateTime.now(),
      note: note,
    );
  });

  Future<void> _writeBalanceAdjustment({
    required QueryRow snapshot,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    String? entryId,
  }) async {
    final accountId = snapshot.read<String>('id');
    final kind = AccountKind.values.byName(snapshot.read<String>('kind'));
    final currency = snapshot.read<String>('currency_code');
    final difference =
        BigInt.from(amountMinor) -
        BigInt.from(snapshot.read<int>('current_balance'));
    final debit = kind.isLiability ? -difference : difference;
    if (debit == BigInt.zero) return;
    if (debit.abs() > BigInt.from(0x7fffffffffffffff)) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransactionDetails,
      );
    }
    final adjustment = debit.toInt();
    await _ensureSystemCategories(adjustment: true);
    await _writeEntry(
      entryId: entryId,
      type: LedgerTransactionType.adjustment,
      amountMinor: adjustment,
      occurredAt: occurredAt,
      categoryId: _adjustmentCategory,
      currencyCode: currency,
      accountId: accountId,
      status: LedgerPostingStatus.posted,
      note: note,
      postings: transactionPostings(
        type: LedgerTransactionType.adjustment,
        amountMinor: adjustment,
        currencyCode: currency,
        accountId: accountId,
      ),
    );
  }

  Future<void> _validateAllocationCategories(TransactionTerms terms) async {
    if (terms.feeMinor + terms.interestMinor > 0) {
      await _ensureSystemCategories(adjustment: false);
    }
    final ids = terms.categories.map((part) => part.categoryId).toSet();
    if (ids.isEmpty) return;
    final found =
        await (_database.select(_database.ledgerCategories)..where(
              (row) =>
                  row.id.isIn(ids) &
                  row.parentId.isNotNull() &
                  row.transactionType.equals(
                    LedgerTransactionType.expense.name,
                  ),
            ))
            .get();
    if (found.length != ids.length) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransactionDetails,
      );
    }
  }

  Future<void> _ensureSystemCategories({required bool adjustment}) async {
    final now = DateTime.now();
    final categories = adjustment
        ? [
            (_adjustmentParent, '余额调整', null),
            (_adjustmentCategory, '余额调整', _adjustmentParent),
          ]
        : [
            (financialChargesCategoryId, '金融费用', null),
            (financialFeeCategoryId, '手续费', financialChargesCategoryId),
            (financialInterestCategoryId, '利息', financialChargesCategoryId),
          ];
    await _database.batch((batch) {
      batch.insertAll(_database.ledgerCategories, [
        for (final (id, name, parent) in categories)
          LedgerCategoriesCompanion.insert(
            id: id,
            name: name,
            parentId: Value(parent),
            transactionType: Value(adjustment ? 'adjustment' : 'expense'),
            sortOrder: const Value(9000),
            createdAt: now,
            updatedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  @override
  Future<void> saveFamilyExpense({
    String? id,
    required int amountMinor,
    required String currencyCode,
    required DateTime occurredAt,
    required String categoryId,
    required String note,
    List<CategoryAmount> categories = const [],
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => _database.transaction(() async {
    if (!currencyMinorDigits.containsKey(currencyCode)) {
      throw const TransactionRuleException(
        TransactionRuleError.currencyMismatch,
      );
    }
    final accountId = _familyAccountId(currencyCode);
    final now = DateTime.now();
    await _database
        .into(_database.ledgerAccounts)
        .insert(
          LedgerAccountsCompanion.insert(
            id: accountId,
            name: '家庭直接承担',
            kind: AccountKind.familyDirect.name,
            currencyCode: Value(currencyCode),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final account = await (_database.select(
      _database.ledgerAccounts,
    )..where((table) => table.id.equals(accountId))).getSingle();
    if (account.kind != AccountKind.familyDirect.name ||
        account.currencyCode != currencyCode) {
      throw StateError('The reserved family funding account is in use');
    }
    await _saveTransaction(
      id: id,
      type: LedgerTransactionType.expense,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: accountId,
      targetAccountId: null,
      categoryId: categoryId,
      payments: [AccountPayment(accountId, amountMinor)],
      requiredCurrency: currencyCode,
      terms: TransactionTerms(categories: categories),
      status: status,
      note: note,
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
    int? advanceCancellationMinor,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => _database.transaction(() async {
    final previous = id == null ? null : await _activeEntry(id);
    if (previous != null && previous.refundOfId != originalId) {
      throw ArgumentError('A refund must retain its original purchase');
    }
    if (previous != null) await _requireEditable(previous);
    final original = await _validateRefund(
      originalId: originalId,
      accountId: accountId,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      excludingId: id,
    );
    final terms = await _refundTerms(
      original,
      amountMinor,
      excludingId: id,
      advanceCancellationMinor: advanceCancellationMinor,
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
      terms: terms,
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
        terms: terms,
      ),
    );
  });

  Future<List<EntryRow>> _refunds(String id, {String? excludingId}) =>
      (_database.select(_database.ledgerEntries)..where(
            (row) =>
                row.refundOfId.equals(id) &
                row.isDeleted.equals(false) &
                (excludingId == null
                    ? const Constant(true)
                    : row.id.equals(excludingId).not()),
          ))
          .get();

  Future<TransactionTerms> _refundTerms(
    EntryRow original,
    int amountMinor, {
    String? excludingId,
    int? advanceCancellationMinor,
    TransactionTerms? existing,
  }) async {
    final purchase = _decodeTerms(original.termsJson);
    var outstandingAdvance = purchase.advance?.amountMinor ?? 0;
    final outstanding = <String, int>{
      if (purchase.categories.isEmpty)
        original.categoryId: original.amountMinor - outstandingAdvance
      else
        for (final part in purchase.categories)
          part.categoryId: part.amountMinor,
    };
    List<CategoryAmount> portions(TransactionTerms terms, int amount) {
      if (terms.categories.isNotEmpty) return terms.categories;
      final spent = amount - (terms.advance?.amountMinor ?? 0);
      return spent == 0
          ? const []
          : [(categoryId: original.categoryId, amountMinor: spent)];
    }

    for (final refund in await _refunds(
      original.id,
      excludingId: excludingId,
    )) {
      final prior = _decodeTerms(refund.termsJson);
      outstandingAdvance -= prior.advance?.amountMinor ?? 0;
      for (final part in portions(prior, refund.amountMinor)) {
        outstanding.update(
          part.categoryId,
          (value) => value - part.amountMinor,
          ifAbsent: () => -part.amountMinor,
        );
      }
    }
    if (existing != null) {
      final advance = existing.advance;
      if (outstandingAdvance < (advance?.amountMinor ?? 0) ||
          (advance != null &&
              advance.accountId != purchase.advance?.accountId) ||
          portions(existing, amountMinor).any(
            (part) => (outstanding[part.categoryId] ?? 0) < part.amountMinor,
          )) {
        throw const LedgerBackupException('备份退款超过原分类或垫付账面金额');
      }
      return existing;
    }
    final outstandingSpending = outstanding.values.fold(
      0,
      (sum, value) => sum + value,
    );
    final excess = amountMinor - outstandingSpending;
    final cancelled = advanceCancellationMinor ?? (excess > 0 ? excess : 0);
    if (cancelled < 0 ||
        cancelled > amountMinor ||
        cancelled > outstandingAdvance ||
        amountMinor - cancelled > outstandingSpending) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransactionDetails,
      );
    }
    var remaining = amountMinor - cancelled;
    final parts = <CategoryAmount>[];
    for (final part in outstanding.entries) {
      if (remaining == 0) break;
      if (part.value <= 0) continue;
      final portion = part.value < remaining ? part.value : remaining;
      parts.add((categoryId: part.key, amountMinor: portion));
      remaining -= portion;
    }
    return TransactionTerms(
      categories: purchase.categories.isEmpty ? const [] : parts,
      advance: cancelled == 0
          ? null
          : AccountPayment(purchase.advance!.accountId, cancelled),
    );
  }

  Future<EntryRow> _validateRefund({
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String? excludingId,
  }) async {
    final original = await _activeEntry(originalId);
    if (await _hasActiveReversal(originalId) ||
        _decodeTerms(original.termsJson).reversalOfId != null ||
        amountMinor <= 0 ||
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
        currencyCode: original.currencyCode,
      );
    }
    return original;
  }

  @override
  Stream<List<ImportCategoryRule>> watchImportRules() => _importRules.watch();

  @override
  Future<void> saveImportRule({
    String? id,
    required ImportRuleField field,
    required String keyword,
    required String categoryId,
    required int priority,
    required bool enabled,
  }) => _database.transaction(
    () => _importRules.save(
      ImportCategoryRule(
        id: id ?? _uuid.v4(),
        field: field,
        keyword: keyword,
        categoryId: categoryId,
        priority: priority,
        enabled: enabled,
      ),
    ),
  );

  @override
  Future<void> deleteImportRule(String id) => _importRules.delete(id);

  @override
  Stream<List<SpendingPlan>> watchSpendingPlans() => _spendingPlans.watch();

  @override
  Future<void> addSpendingPlan(SpendingPlanDraft draft) =>
      _database.transaction(() => _spendingPlans.add(_uuid.v4(), draft));

  @override
  Future<void> setSpendingPlanLimit(String id, SpendingPlanLimit limit) =>
      _database.transaction(
        () => _spendingPlans.setLimit(id, _uuid.v4(), limit),
      );

  @override
  Future<void> setSpendingPlanArchived(String id, bool archived) =>
      _database.transaction(() => _spendingPlans.setArchived(id, archived));

  @override
  Stream<List<DebtContract>> watchDebtContracts() =>
      _debtContracts.watch(_balanceQuery(contractsOnly: true));

  @override
  Future<void> addDebtContract(DebtContractDraft draft) =>
      _database.transaction(() => _debtContracts.add(draft));

  @override
  Future<void> linkDebtSettlement(
    String accountId,
    String entryId,
    DebtLinkKind kind,
  ) => _database.transaction(() async {
    final contract = await _debtContracts.byAccount(accountId);
    if (contract == null) {
      throw const DebtContractException(DebtContractError.unavailable);
    }
    final entry = await (_database.select(
      _database.ledgerEntries,
    )..where((row) => row.id.equals(entryId))).getSingleOrNull();
    if (entry == null ||
        entry.isDeleted ||
        entry.refundOfId != null ||
        entry.status != LedgerPostingStatus.posted.name ||
        entry.currencyCode != contract.currency ||
        await _hasActiveReversal(entryId)) {
      throw const DebtContractException(DebtContractError.ineligible);
    }
    final terms = _decodeTerms(entry.termsJson);
    final postings = await _accountPostings(entryId);
    if (terms.reversalOfId != null || postings.any((row) => row.needsReview)) {
      throw const DebtContractException(DebtContractError.ineligible);
    }
    final debit =
        postings
            .where(
              (row) =>
                  row.accountId == accountId &&
                  row.currencyCode == contract.currency,
            )
            .firstOrNull
            ?.debitMinor ??
        0;
    bool personalCash = false;
    if (kind == DebtLinkKind.interest) {
      final account = await (_database.select(
        _database.ledgerAccounts,
      )..where((row) => row.id.equals(entry.accountId))).getSingle();
      personalCash =
          AccountKind.values.byName(account.kind).isPersonalCash &&
          postings.any(
            (row) =>
                row.accountId == account.id &&
                row.currencyCode == contract.currency &&
                row.debitMinor > 0,
          );
    }
    if (debtPaymentAmounts(
          DebtDirection.values.byName(contract.direction),
          kind,
          type: LedgerTransactionType.values.byName(entry.transactionType),
          debitMinor: debit,
          amountMinor: entry.amountMinor,
          interestMinor: terms.interestMinor,
          feeMinor: terms.feeMinor,
          incomeToPersonalCash: personalCash,
        ) ==
        null) {
      throw const DebtContractException(DebtContractError.ineligible);
    }
    await _debtContracts.link(_uuid.v4(), accountId, entryId, kind);
  });

  @override
  Future<void> unlinkDebtSettlement(String linkId) =>
      _debtContracts.unlink(linkId);

  @override
  Stream<List<RecurringPlan>> watchRecurringPlans() => _recurringPlans.watch();

  @override
  Future<void> addRecurringPlan(RecurringPlanDraft draft) =>
      _database.transaction(() => _recurringPlans.add(_uuid.v4(), draft));

  @override
  Future<void> setRecurringPlanPaused(String id, bool paused) =>
      _recurringPlans.setPaused(id, paused);

  @override
  Future<void> setRecurringPlanExpectedAmount(String id, int amountMinor) =>
      _recurringPlans.setExpectedAmount(id, amountMinor);

  @override
  Future<void> confirmRecurringOccurrence(
    String id,
    int expectedIndex, {
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
  }) => _database.transaction(() async {
    final plan = await _recurringPlans.requireOpenCycle(id, expectedIndex);
    if (amountMinor <= 0 || occurredAt.isAfter(DateTime.now())) {
      throw const RecurringPlanException(RecurringPlanError.invalid);
    }
    final entryId = _uuid.v4();
    await _saveTransaction(
      newEntryId: entryId,
      type: plan.kind.transactionType,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: plan.accountId,
      categoryId: plan.categoryId,
      targetAccountId: null,
      payments: null,
      requiredCurrency: plan.currency,
      status: LedgerPostingStatus.posted,
      note: note,
    );
    await _recurringPlans.record(
      id,
      expectedIndex,
      entryId,
      plan.expectedMinor,
    );
  });

  @override
  Future<void> linkRecurringOccurrence(
    String id,
    int expectedIndex,
    String entryId,
  ) => _database.transaction(() async {
    final plan = await _recurringPlans.requireOpenCycle(id, expectedIndex);
    final entry = await (_database.select(
      _database.ledgerEntries,
    )..where((row) => row.id.equals(entryId))).getSingleOrNull();
    if (entry == null ||
        entry.isDeleted ||
        entry.status != LedgerPostingStatus.posted.name ||
        entry.transactionType != plan.kind.transactionType.name ||
        entry.currencyCode != plan.currency ||
        entry.refundOfId != null ||
        _decodeTerms(entry.termsJson).reversalOfId != null ||
        entry.occurredAt.isAfter(DateTime.now()) ||
        await _hasActiveReversal(entryId)) {
      throw const RecurringPlanException(RecurringPlanError.ineligible);
    }
    final postings = await _accountPostings(entryId);
    if (postings.any((posting) => posting.needsReview) ||
        !postings.any(
          (posting) =>
              posting.accountId == plan.accountId &&
              posting.currencyCode == plan.currency,
        )) {
      throw const RecurringPlanException(RecurringPlanError.ineligible);
    }
    await _recurringPlans.record(
      id,
      expectedIndex,
      entryId,
      plan.expectedMinor,
    );
  });

  @override
  Future<List<CsvReviewRow>> previewCsvImport(
    CsvImportFile file, {
    Map<int, CsvMapping> mappings = const {},
  }) => _database.transaction(
    () async => _csv.review(file, mappings, await _importRules.read()),
  );

  @override
  Stream<List<CsvBatchSummary>> watchCsvBatches() => _csv.watchBatches();

  @override
  Future<List<CsvBatchItem>> readCsvBatchItems(String id) => _csv.items(id);

  @override
  Future<CsvImportResult> commitCsvImport(
    CsvImportFile file,
    List<CsvSelection> selections,
  ) => _database.transaction(() async {
    final choices = {for (final choice in selections) choice.number: choice};
    if (choices.isEmpty || choices.length != selections.length) {
      throw const CsvBatchException(CsvBatchError.reviewChanged);
    }
    final preview = await _csv.review(file, {
      for (final choice in selections) choice.number: choice.mapping,
    }, const []);
    final chosen = preview
        .where((item) => choices.containsKey(item.row.number))
        .toList();
    if (chosen.length != choices.length) {
      throw const CsvBatchException(CsvBatchError.reviewChanged);
    }
    final matchedIds = <String>{};
    for (final item in chosen) {
      final choice = choices[item.row.number]!;
      final matchId = choice.matchId;
      final reviewedIds = choice.reviewedMatchIds;
      final canAdd =
          item.state == CsvReviewState.ready && reviewedIds == null ||
          item.state == CsvReviewState.similar &&
              reviewedIds != null &&
              reviewedIds.length == item.matches.length &&
              item.matches.every(
                (candidate) => reviewedIds.contains(candidate.id),
              );
      final movement = item.row.movement;
      if (matchId != null &&
          item.state == CsvReviewState.similar &&
          item.matches.any(
            (candidate) => candidate.id == matchId && candidate.canLink,
          ) &&
          matchedIds.add(matchId)) {
        continue;
      }
      if (matchId != null ||
          !canAdd ||
          movement == null ||
          item.mapping != choice.mapping ||
          (csvNeedsCategory(movement.type) &&
              item.mapping.categoryId == null)) {
        throw CsvBatchException(
          CsvBatchError.reviewChanged,
          line: item.row.line,
        );
      }
    }
    chosen.sort((a, b) {
      final chronological = a.row.movement!.occurredAt.compareTo(
        b.row.movement!.occurredAt,
      );
      return chronological != 0
          ? chronological
          : a.row.number.compareTo(b.row.number);
    });
    final batchId = _uuid.v4();
    final fileName = file.name.trim();
    await _csv.insertBatch(
      CsvBatchRecord(
        id: batchId,
        name: fileName.isEmpty ? 'CSV' : fileName,
        fingerprint: file.fingerprint,
        createdAt: DateTime.now(),
      ),
    );
    for (final item in chosen) {
      final row = item.row;
      final matchId = choices[row.number]!.matchId;
      final entryId = matchId ?? _uuid.v4();
      String? snapshot;
      if (matchId == null) {
        final movement = row.movement!;
        try {
          await _saveTransaction(
            newEntryId: entryId,
            type: movement.type,
            amountMinor: movement.amountMinor,
            occurredAt: movement.occurredAt,
            accountId: item.mapping.accountId!,
            targetAccountId: item.mapping.targetId,
            categoryId: item.mapping.categoryId,
            note: movement.note,
            requiredCurrency: movement.currency,
            payments: null,
            status: LedgerPostingStatus.posted,
          );
        } on TransactionRuleException catch (error) {
          throw CsvPostingException(row.line, error);
        } on ArgumentError catch (error) {
          throw CsvPostingException(row.line, error);
        }
        snapshot = await _csvSnapshot(await _activeEntry(entryId));
      }
      await _csv.insertRow(
        CsvImportRecord(
          batchId: batchId,
          rowNumber: row.number,
          line: row.line,
          fileRowKey: file.rowKey(row),
          sourceKey: row.sourceKey,
          signature: row.signature!,
          rawJson: csvRawCellsJson(row.raw),
          entryId: entryId,
          snapshot: snapshot,
          active: true,
        ),
      );
    }
    return (
      batchId: batchId,
      added: chosen.length - matchedIds.length,
      matched: matchedIds.length,
    );
  });

  @override
  Future<void> undoCsvImport(String id) => _database.transaction(() async {
    final batch = await _csv.readBatch(id);
    if (batch == null) throw const CsvBatchException(CsvBatchError.unavailable);
    if (batch.undoneAt != null) return;
    final entries = <EntryRow>[];
    for (final row in await _csv.readRows(id)) {
      final saved = row.snapshot;
      if (saved == null) continue;
      final entry = await (_database.select(
        _database.ledgerEntries,
      )..where((entry) => entry.id.equals(row.entryId))).getSingleOrNull();
      if (entry == null ||
          entry.isDeleted ||
          saved != await _csvSnapshot(entry)) {
        throw CsvBatchException(CsvBatchError.modified, line: row.line);
      }
      if (await _hasActiveRefunds(entry.id) ||
          await _hasActiveReversal(entry.id) ||
          await _csv.hasOtherLink(entry.id, id)) {
        throw CsvBatchException(CsvBatchError.linked, line: row.line);
      }
      entries.add(entry);
    }
    await _checkCsvUndoBalances(entries);
    final now = DateTime.now();
    for (final entry in entries) {
      await _softDeleteEntry(entry, now);
    }
    await _csv.markUndone(id, now);
  });

  Future<void> _checkCsvUndoBalances(List<EntryRow> entries) async {
    final changes = <String, BigInt>{};
    for (final entry in entries) {
      for (final leg in await _accountPostings(entry.id)) {
        final accountId = leg.accountId!;
        changes.update(
          accountId,
          (sum) => sum + BigInt.from(leg.debitMinor),
          ifAbsent: () => BigInt.from(leg.debitMinor),
        );
      }
    }
    if (changes.isEmpty) return;
    final accounts = await (_database.select(
      _database.ledgerAccounts,
    )..where((row) => row.id.isIn(changes.keys))).get();
    for (final account in accounts) {
      final kind = AccountKind.values.byName(account.kind);
      final change = kind.isLiability
          ? changes[account.id]!
          : -changes[account.id]!;
      if (!change.isNegative) continue;
      if (BigInt.from(await _currentBalance(account.id)) + change <
          BigInt.zero) {
        throw const CsvBatchException(CsvBatchError.linked);
      }
    }
  }

  Future<String> _csvSnapshot(EntryRow entry) async {
    final snapshot = _backupEntry(entry, await _allPostings(entry.id));
    // Backup ISO strings may be written in different device time zones.
    snapshot['occurred_at'] = entry.occurredAt.millisecondsSinceEpoch;
    snapshot['created_at'] = entry.createdAt.millisecondsSinceEpoch;
    snapshot['updated_at'] = entry.updatedAt.millisecondsSinceEpoch;
    return csvDigest(snapshot);
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
        await _saveTransaction(
          type: draft.type,
          requiredCurrency: defaultCurrency,
          status: LedgerPostingStatus.posted,
          payments: null,
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
    TransferSettlement? settlement,
    String? requiredCurrency,
    TransactionTerms terms = const TransactionTerms(),
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be positive');
    }
    final resolvedCategoryId = switch (type) {
      _ when type.isReceivableFlow => 'flow-${type.name}',
      LedgerTransactionType.borrowing => 'flow-borrowing',
      LedgerTransactionType.repayment => 'flow-repayment',
      LedgerTransactionType.transfer => 'flow-transfer',
      _ => categoryId,
    };
    if (resolvedCategoryId == null) {
      throw ArgumentError.notNull('categoryId');
    }
    final categoryQuery = _database.select(_database.ledgerCategories)
      ..where((table) => table.id.equals(resolvedCategoryId));
    var category = await categoryQuery.getSingleOrNull();
    if (category == null && type == LedgerTransactionType.transfer) {
      // A complete legacy snapshot can contain only the categories it used.
      await _database.ensureTransferCategory();
      category = await categoryQuery.getSingleOrNull();
    }
    if (category == null && type.isReceivableFlow) {
      await _database.ensureReceivableCategories();
      category = await categoryQuery.getSingleOrNull();
    }
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
      ?terms.advance?.accountId,
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
    if ((requiredCurrency != null &&
            requiredCurrency != account.currencyCode) ||
        (previous != null && previous.currencyCode != account.currencyCode) ||
        allocations.any(
          (payment) =>
              accounts[payment.accountId]!.currencyCode != account.currencyCode,
        )) {
      throw const TransactionRuleException(
        TransactionRuleError.currencyMismatch,
      );
    }
    if (!_validTransferSettlement(
      type,
      account.currencyCode,
      target?.currencyCode,
      settlement,
    )) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransferSettlement,
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
    if (!_validAccountFlow(type, accountKind, targetKind, terms) ||
        !_validFundingAccounts(
          allocations.map(
            (payment) =>
                AccountKind.values.byName(accounts[payment.accountId]!.kind),
          ),
        )) {
      if (terms.isEmpty) {
        throw ArgumentError('The accounts do not match the transaction type');
      }
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransactionDetails,
      );
    }
    if (!_validTerms(
      type,
      amountMinor,
      account.currencyCode,
      resolvedCategoryId,
      allocations,
      accounts,
      terms,
    )) {
      throw const TransactionRuleException(
        TransactionRuleError.invalidTransactionDetails,
      );
    }
    await _validateAllocationCategories(terms);
    Future<void> requireFunds(AccountRow source, int amount) =>
        _requireAvailableBalance(
          accountId: source.id,
          accountName: source.name,
          currencyCode: source.currencyCode,
          requiredMinor: amount,
          excludingEntryId: previous?.id,
        );
    Future<void> requireDebt(AccountRow debt) => _requireOutstandingLiability(
      accountId: debt.id,
      accountName: debt.name,
      currencyCode: debt.currencyCode,
      requiredMinor: amountMinor,
      excludingEntryId: previous?.id,
    );

    switch (type) {
      case LedgerTransactionType.expense:
        if (posting) {
          for (final payment in allocations) {
            final source = accounts[payment.accountId]!;
            final kind = AccountKind.values.byName(source.kind);
            if (!kind.isLiability && kind != AccountKind.familyDirect) {
              await requireFunds(source, payment.amountMinor);
            }
          }
        }
      case LedgerTransactionType.income:
        if (posting && accountKind.isLiability) await requireDebt(account);
      case LedgerTransactionType.borrowing:
        break;
      case LedgerTransactionType.transfer:
        if (posting) await requireFunds(account, amountMinor + terms.feeMinor);
      case LedgerTransactionType.lending:
      case LedgerTransactionType.advance:
        if (posting) await requireFunds(account, amountMinor);
      case LedgerTransactionType.repayment:
        if (posting) {
          if (terms.externalDebtPayment) {
            await requireDebt(account);
          } else {
            await requireFunds(
              account,
              amountMinor + terms.feeMinor + terms.interestMinor,
            );
            await requireDebt(target!);
          }
        }
      case LedgerTransactionType.adjustment:
      case LedgerTransactionType.collection:
      case LedgerTransactionType.reimbursement:
        // The completed ledger is checked chronologically after the write.
        break;
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
        settlement: settlement,
        isCreditIncome:
            type == LedgerTransactionType.income && accountKind.isLiability,
        terms: terms,
      ),
    );
  }

  Future<void> _checkReceivableBalances({Set<String>? accountIds}) async {
    if (accountIds != null && accountIds.isEmpty) return;
    final filter = accountIds == null
        ? ''
        : "AND a.id IN (${List.filled(accountIds.length, '?').join(', ')})";
    final violation = await _database
        .customSelect(
          """
      WITH movements AS (
        SELECT p.account_id, e.occurred_at, SUM(p.debit_minor) AS change
        FROM ledger_postings AS p
        JOIN ledger_entries AS e ON e.id = p.transaction_id
        JOIN ledger_accounts AS a ON a.id = p.account_id
        WHERE a.kind = 'receivable' AND e.status = 'posted' AND e.is_deleted = 0
          AND p.currency_code = a.currency_code
          $filter
        GROUP BY p.account_id, e.occurred_at
      ), running AS (
        SELECT account_id, SUM(change) OVER (
          PARTITION BY account_id ORDER BY occurred_at
        ) AS balance_change
        FROM movements
      )
      SELECT a.id, a.name, a.currency_code
      FROM ledger_accounts AS a
      WHERE a.kind = 'receivable'
        AND (a.opening_balance_minor < 0 OR a.opening_balance_minor + COALESCE((
          SELECT MIN(balance_change) FROM running WHERE account_id = a.id
        ), 0) < 0)
        $filter
      LIMIT 1
      """,
          variables: [
            if (accountIds != null) ...accountIds.map(Variable.withString),
            if (accountIds != null) ...accountIds.map(Variable.withString),
          ],
        )
        .getSingleOrNull();
    if (violation != null) {
      throw TransactionRuleException(
        TransactionRuleError.receivableBalanceExceeded,
        accountId: violation.read<String>('id'),
        accountName: violation.read<String>('name'),
        currencyCode: violation.read<String>('currency_code'),
      );
    }
  }

  Future<void> _requireAvailableBalance({
    required String accountId,
    required String accountName,
    required String currencyCode,
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
        currencyCode: currencyCode,
        amountMinor: available,
      );
    }
  }

  Future<void> _requireOutstandingLiability({
    required String accountId,
    required String accountName,
    required String currencyCode,
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
        currencyCode: currencyCode,
        amountMinor: outstanding,
      );
    }
  }

  Selectable<QueryRow> _balanceQuery({
    String? accountId,
    String? excludingEntryId,
    DateTime? asOf,
    bool contractsOnly = false,
  }) {
    final postingAccount = accountId == null ? '' : 'AND leg.account_id = ?';
    final exclusion = excludingEntryId == null
        ? ''
        : 'AND leg.transaction_id != ?';
    final cutoff = asOf == null ? '' : 'AND entry.occurred_at <= ?';
    final selection = accountId != null
        ? 'a.id = ?'
        : contractsOnly
        ? 'a.id IN (SELECT account_id FROM debt_contracts)'
        : "a.is_archived = 0 AND a.kind <> 'familyDirect'";
    return _database.customSelect(
      """
      SELECT a.id, a.name, a.kind, a.currency_code, a.opening_balance_minor, a.is_archived,
        a.opening_balance_minor + COALESCE(p.net_debit, 0) *
          CASE WHEN a.kind IN ('creditLine', 'thirdPartyPayable') THEN -1 ELSE 1 END AS current_balance
      FROM ledger_accounts AS a
      LEFT JOIN (
        SELECT leg.account_id, leg.currency_code, SUM(leg.debit_minor) AS net_debit
        FROM ledger_postings AS leg
        JOIN ledger_entries AS entry ON entry.id = leg.transaction_id
        WHERE leg.account_id IS NOT NULL
          AND entry.status = 'posted' AND entry.is_deleted = 0
          $postingAccount $exclusion $cutoff
        GROUP BY leg.account_id, leg.currency_code
      ) AS p ON p.account_id = a.id AND p.currency_code = a.currency_code
      WHERE $selection
      ORDER BY a.sort_order
      """,
      variables: [
        if (accountId != null) Variable.withString(accountId),
        if (excludingEntryId != null) Variable.withString(excludingEntryId),
        if (asOf != null) Variable.withDateTime(asOf),
        if (accountId != null) Variable.withString(accountId),
      ],
      readsFrom: {
        _database.ledgerAccounts,
        _database.ledgerEntries,
        _database.ledgerPostings,
        if (contractsOnly) _database.debtContracts,
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
      if (snapshot.read<String>('kind') == AccountKind.familyDirect.name) {
        throw ArgumentError('A family funding account has no editable balance');
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
      if (snapshot.read<String>('kind') == AccountKind.receivable.name) {
        await _checkReceivableBalances(accountIds: {accountId});
      }
    });
  }

  @override
  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    required int currentBalanceMinor,
    String currencyCode = defaultCurrency,
  }) async {
    if (kind == AccountKind.familyDirect) {
      throw ArgumentError('Family funding accounts are managed by the ledger');
    }
    final normalizedName = name.trim();
    final currency = currencyCode.trim().toUpperCase();
    if (!currencyMinorDigits.containsKey(currency)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'unsupported currency',
      );
    }
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
            currencyCode: Value(currency),
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
              (table) =>
                  table.id.equals(id) &
                  table.isArchived.equals(false) &
                  table.kind.equals(AccountKind.familyDirect.name).not(),
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
  Stream<ValuationSettings> watchValuationSettings() =>
      _valuation.watchSettings();

  @override
  Future<void> setValuationBaseCurrency(String baseCurrency) =>
      _valuation.setBaseCurrency(baseCurrency);

  @override
  Future<void> saveValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
    required String rate,
  }) => _valuation.saveRate(
    sourceCurrency: sourceCurrency,
    baseCurrency: baseCurrency,
    rate: rate,
  );

  @override
  Future<void> removeValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
  }) => _valuation.removeRate(
    sourceCurrency: sourceCurrency,
    baseCurrency: baseCurrency,
  );

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
    final valuation = await _valuation.readSettings();
    return const JsonEncoder.withIndent('  ').convert({
      'format': _backupFormat,
      'backup_version': 12,
      'debt_contracts': await _debtContracts.backup(),
      'recurring_plans': await _recurringPlans.backup(),
      'spending_plans': await _spendingPlans.backup(),
      'import_category_rules': await _importRules.backup(),
      'csv_import': await _csv.backup(),
      'balance_checkpoints': await _reconciliation.backup(),
      'valuation': {
        'base_currency': valuation.baseCurrency,
        'rates': [
          for (final item in valuation.rates)
            {
              'base_currency': item.baseCurrency,
              'source_currency': item.sourceCurrency,
              'rate': item.rate,
              'updated_at': item.updatedAt.toUtc().toIso8601String(),
            },
        ],
      },
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
      checkpointCount: payload.checkpoints.length,
      importBatchCount: payload.csvBatches.length,
      spendingPlanCount: payload.spendingPlans.length,
      recurringPlanCount: payload.recurringPlans.length,
      debtContractCount: payload.debtContracts.length,
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
        await _database.delete(_database.csvImportBatches).go();
        await _database.delete(_database.balanceCheckpoints).go();
        await _database.delete(_database.recurringPlans).go();
        await _database.delete(_database.debtContracts).go();
        await _database.delete(_database.ledgerEntries).go();
        await _database.delete(_database.importCategoryRules).go();
        await _database.delete(_database.spendingPlans).go();
        await _database.delete(_database.ledgerCategories).go();
        await _database.delete(_database.ledgerAccounts).go();
      }

      for (final raw in payload.accounts) {
        final id = _requiredString(raw, 'id');
        final kind = AccountKind.values.byName(
          _requiredEnum(
            raw,
            'kind',
            AccountKind.values.map((item) => item.name),
          ),
        );
        final code = _requiredString(raw, 'currency_code');
        final opening = _requiredInt(raw, 'opening_balance_minor');
        final archived = _requiredBool(raw, 'is_archived');
        if ((payload.version < 5 && kind.isAdvancedFunding) ||
            (payload.version < 6 && kind.isNewAssetKind) ||
            (kind == AccountKind.familyDirect &&
                (id != _familyAccountId(code) ||
                    !currencyMinorDigits.containsKey(code) ||
                    opening != 0 ||
                    archived))) {
          throw const LedgerBackupException('备份资金归属账户无效');
        }
        if (mode == BackupRestoreMode.merge) {
          final old = await (_database.select(
            _database.ledgerAccounts,
          )..where((table) => table.id.equals(id))).getSingleOrNull();
          if (old != null &&
              (old.currencyCode != code || old.kind != kind.name) &&
              await _reconciliation.hasCheckpoints(id)) {
            throw const LedgerBackupException('备份与余额检查点的账户类型或币种冲突');
          }
          if (old != null &&
              old.kind != kind.name &&
              (kind.isAdvancedFunding ||
                  kind.isNewAssetKind ||
                  AccountKind.values.byName(old.kind).isAdvancedFunding ||
                  AccountKind.values.byName(old.kind).isNewAssetKind)) {
            throw const LedgerBackupException('备份与已有资金归属账户冲突');
          }
        }
        await _database
            .into(_database.ledgerAccounts)
            .insertOnConflictUpdate(
              LedgerAccountsCompanion.insert(
                id: id,
                name: _requiredString(raw, 'name'),
                kind: kind.name,
                currencyCode: Value(code),
                openingBalanceMinor: Value(opening),
                sortOrder: Value(_requiredInt(raw, 'sort_order')),
                isArchived: Value(archived),
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
        if (payload.version < 6 && mode == BackupRestoreMode.merge) {
          await _guardLegacyMerge(entry.id, payload.version);
        }
        if (_decodeTerms(entry.termsJson).reversalOfId case final originalId?) {
          final priorId = await _activeReversalId(originalId);
          if (priorId != null && priorId != entry.id) {
            throw const LedgerBackupException('备份含重复冲销记录');
          }
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
      await _reconciliation.restore(payload.checkpoints);
      await _csv.restore(payload.csvBatches, payload.csvRows);
      await _importRules.restore(payload.importRules);
      await _spendingPlans.restore(payload.spendingPlans);
      await _recurringPlans.restore(payload.recurringPlans);
      await _debtContracts.restore(payload.debtContracts);
      try {
        await _checkReceivableBalances();
      } on TransactionRuleException {
        throw const LedgerBackupException('备份会使应收款历史余额为负');
      }
      if (payload.valuation case final valuation?) {
        await _valuation.restore(
          valuation,
          replace: mode == BackupRestoreMode.replace,
        );
      }
    });
  }

  Future<void> _guardLegacyMerge(String id, int version) async {
    final entries = _database.ledgerEntries;
    final current = await (_database.select(
      entries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (current != null &&
        (current.termsJson != null ||
            current.transactionType == LedgerTransactionType.adjustment.name ||
            await _hasActiveReversal(id))) {
      throw const LedgerBackupException('旧备份与已有财务明细或冲销记录冲突');
    }
    if (version < 5 &&
        current != null &&
        (_isReceivableEntry(current) ||
            await _hasAdvancedFundingPostings(id))) {
      throw const LedgerBackupException('旧备份与已有资金归属或应收款交易冲突');
    }
    if (version < 3 && current?.settlementAmountMinor != null) {
      throw const LedgerBackupException('旧备份与已有跨币种转账冲突');
    }
    if (version == 1 &&
        current != null &&
        (current.status == LedgerPostingStatus.pending.name ||
            current.refundOfId != null ||
            (current.transactionType == LedgerTransactionType.expense.name &&
                ((await _accountPostings(id)).length > 1 ||
                    await _hasActiveRefunds(id))))) {
      throw const LedgerBackupException('旧备份与已有拆分、待入账或退款交易冲突');
    }
  }

  Future<bool> _hasAdvancedFundingPostings(String id) async {
    final row = await _database
        .customSelect(
          """
      SELECT 1
      FROM ledger_postings AS p
      JOIN ledger_accounts AS a ON a.id = p.account_id
      WHERE p.transaction_id = ? AND a.kind IN ('receivable', 'thirdPartyPayable', 'familyDirect')
      LIMIT 1
      """,
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row != null;
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
    final entries = _database.ledgerEntries;
    final detailed =
        await (_database.select(entries)..where(
              (row) =>
                  row.termsJson.isNotNull() |
                  row.transactionType.equals('adjustment'),
            ))
            .get();
    for (final entry in detailed) {
      final terms = _decodeTerms(entry.termsJson);
      try {
        await _validateAllocationCategories(terms);
      } on TransactionRuleException {
        throw const LedgerBackupException('备份消费拆分分类无效');
      }
      if (terms.reversalOfId case final originalId?) {
        final original = await (_database.select(
          entries,
        )..where((row) => row.id.equals(originalId))).getSingleOrNull();
        if (original == null ||
            original.isDeleted ||
            entry.isDeleted ||
            original.refundOfId != null ||
            entry.refundOfId != null ||
            original.status != 'posted' ||
            entry.status != 'posted' ||
            entry.occurredAt.isBefore(original.occurredAt) ||
            original.transactionType != entry.transactionType ||
            original.amountMinor != entry.amountMinor ||
            original.currencyCode != entry.currencyCode ||
            original.categoryId != entry.categoryId ||
            original.accountId != entry.accountId ||
            original.targetAccountId != entry.targetAccountId ||
            original.settlementAmountMinor != entry.settlementAmountMinor ||
            original.settlementCurrencyCode != entry.settlementCurrencyCode ||
            original.quotedExchangeRate != entry.quotedExchangeRate ||
            _decodeTerms(original.termsJson).reversalOfId != null ||
            jsonEncode({
                  ..._decodeTerms(original.termsJson).toJson(),
                  'reversal_of_id': originalId,
                }) !=
                jsonEncode(terms.toJson())) {
          throw const LedgerBackupException('备份冲销记录与原交易不一致');
        }
        final originalLegs = await _allPostings(originalId);
        final reversals = await _allPostings(entry.id);
        if (originalLegs.length != reversals.length ||
            originalLegs.indexed.any(
              (leg) =>
                  oppositePosting(_postingLeg(leg.$2)) !=
                  _postingLeg(reversals[leg.$1]),
            )) {
          throw const LedgerBackupException('备份冲销分录与原交易不一致');
        }
      }
    }
    final refunds =
        await (_database.select(entries)..where(
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
        await _refundTerms(
          original,
          refund.amountMinor,
          excludingId: refund.id,
          existing: _decodeTerms(refund.termsJson),
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

String _familyAccountId(String currency) => 'system-family-direct-$currency';

bool _isReceivableEntry(EntryRow? entry) =>
    entry != null &&
    LedgerTransactionType.values.byName(entry.transactionType).isReceivableFlow;

const _adjustmentParent = 'adjustment-root';
const _adjustmentCategory = 'adjustment-balance';

TransactionTerms _decodeTerms(String? json) => json == null
    ? const TransactionTerms()
    : TransactionTerms.fromJson(jsonDecode(json) as Map<String, dynamic>);

Set<String> _receivableAccounts(
  LedgerTransactionType type,
  String accountId,
  String? targetAccountId,
  TransactionTerms terms,
) => {
  if (type.isReceivableFlow || type == LedgerTransactionType.adjustment)
    accountId,
  if (type.isReceivableFlow && targetAccountId != null) targetAccountId,
  ?terms.advance?.accountId,
};

Set<String> _entryReceivableAccounts(EntryRow entry) => _receivableAccounts(
  LedgerTransactionType.values.byName(entry.transactionType),
  entry.accountId,
  entry.targetAccountId,
  _decodeTerms(entry.termsJson),
);

bool _validTerms(
  LedgerTransactionType type,
  int amount,
  String currency,
  String categoryId,
  List<AccountPayment> payments,
  Map<String, AccountRow> accounts,
  TransactionTerms terms, {
  bool isRefund = false,
}) {
  if (type == LedgerTransactionType.adjustment) {
    return amount != 0 &&
        amount != -0x7fffffffffffffff - 1 &&
        (terms.isEmpty ||
            terms.toJson().length == 1 && terms.reversalOfId != null);
  }
  if (amount <= 0) return false;
  final price = terms.originalPrice;
  final advance = terms.advance;
  if (price != null &&
      (type != LedgerTransactionType.expense ||
          isRefund ||
          price.amountMinor <= 0 ||
          price.currencyCode == currency ||
          !currencyMinorDigits.containsKey(currency) ||
          !currencyMinorDigits.containsKey(price.currencyCode) ||
          (price.quotedRate != null &&
              !isValidExchangeQuote(price.quotedRate!)))) {
    return false;
  }
  if (advance != null &&
      (type != LedgerTransactionType.expense ||
          advance.amountMinor <= 0 ||
          (isRefund
              ? advance.amountMinor > amount
              : advance.amountMinor >= amount) ||
          accounts[advance.accountId]?.kind != AccountKind.receivable.name ||
          accounts[advance.accountId]?.currencyCode != currency ||
          payments.any(
            (payment) => !AccountKind.values
                .byName(accounts[payment.accountId]!.kind)
                .isPersonalCash,
          ))) {
    return false;
  }
  if (terms.categories.isNotEmpty) {
    if (type != LedgerTransactionType.expense ||
        (!isRefund && terms.categories.first.categoryId != categoryId)) {
      return false;
    }
    final ids = <String>{};
    var remaining = amount - (advance?.amountMinor ?? 0);
    for (final part in terms.categories) {
      if (!ids.add(part.categoryId) ||
          part.amountMinor <= 0 ||
          part.amountMinor > remaining) {
        return false;
      }
      remaining -= part.amountMinor;
    }
    if (remaining != 0) return false;
  }
  if (terms.externalDebtPayment && type != LedgerTransactionType.repayment) {
    return false;
  }
  final fee = terms.feeMinor;
  final interest = terms.interestMinor;
  if (fee < 0 ||
      interest < 0 ||
      (fee > 0 &&
          type != LedgerTransactionType.transfer &&
          type != LedgerTransactionType.repayment) ||
      (interest > 0 && type != LedgerTransactionType.repayment) ||
      (terms.externalDebtPayment && (fee != 0 || interest != 0))) {
    return false;
  }
  return BigInt.from(amount) + BigInt.from(fee) + BigInt.from(interest) <=
      BigInt.from(0x7fffffffffffffff);
}

bool _validFundingAccounts(Iterable<AccountKind> allocations) =>
    allocations.every((kind) => kind != AccountKind.receivable) &&
    (!allocations.contains(AccountKind.familyDirect) ||
        allocations.length == 1);

bool _validAccountFlow(
  LedgerTransactionType type,
  AccountKind source,
  AccountKind? target, [
  TransactionTerms terms = const TransactionTerms(),
]) {
  bool isTransferAccount(AccountKind? kind) =>
      kind?.isPersonalCash == true || kind == AccountKind.entrustedFunds;
  return switch (type) {
    LedgerTransactionType.expense =>
      target == null && source != AccountKind.receivable,
    LedgerTransactionType.income =>
      target == null &&
          source != AccountKind.receivable &&
          source != AccountKind.familyDirect &&
          source != AccountKind.thirdPartyPayable,
    LedgerTransactionType.borrowing =>
      source.isLiability && target?.isPersonalCash == true,
    LedgerTransactionType.repayment =>
      terms.externalDebtPayment
          ? source.isLiability && target == null
          : isTransferAccount(source) && target?.isLiability == true,
    LedgerTransactionType.adjustment =>
      source != AccountKind.familyDirect && target == null,
    LedgerTransactionType.transfer =>
      (isTransferAccount(source) || source == AccountKind.prepaid) &&
          (isTransferAccount(target) || target == AccountKind.prepaid),
    LedgerTransactionType.lending || LedgerTransactionType.advance =>
      source.isPersonalCash && target == AccountKind.receivable,
    LedgerTransactionType.collection || LedgerTransactionType.reimbursement =>
      source == AccountKind.receivable && target?.isPersonalCash == true,
  };
}

TransferSettlement? _entrySettlement(EntryRow entry) {
  final amount = entry.settlementAmountMinor;
  final currency = entry.settlementCurrencyCode;
  if (amount == null || currency == null) return null;
  return TransferSettlement(
    amountMinor: amount,
    currencyCode: currency,
    quotedRate: entry.quotedExchangeRate,
  );
}

bool _validTransferSettlement(
  LedgerTransactionType type,
  String source,
  String? target,
  TransferSettlement? settlement,
) {
  if (target == null || target == source) return settlement == null;
  final quote = settlement?.quotedRate;
  return type == LedgerTransactionType.transfer &&
      settlement != null &&
      settlement.amountMinor > 0 &&
      settlement.currencyCode == target &&
      currencyMinorDigits.containsKey(source) &&
      currencyMinorDigits.containsKey(target) &&
      (quote == null || isValidExchangeQuote(quote));
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
  'occurred_at': item.occurredAt.toUtc().toIso8601String(),
  'timezone_offset_minutes': item.timezoneOffsetMinutes,
  'category_id': item.categoryId,
  'account_id': item.accountId,
  'target_account_id': item.targetAccountId,
  'note': item.note,
  'created_at': item.createdAt.toUtc().toIso8601String(),
  'updated_at': item.updatedAt.toUtc().toIso8601String(),
  'is_deleted': item.isDeleted,
  'status': item.status,
  'refund_of_id': item.refundOfId,
  if (item.settlementAmountMinor != null)
    'settlement_amount_minor': item.settlementAmountMinor,
  if (item.settlementCurrencyCode != null)
    'settlement_currency_code': item.settlementCurrencyCode,
  if (item.quotedExchangeRate != null)
    'quoted_exchange_rate': item.quotedExchangeRate,
  if (item.termsJson case final terms?) 'financial_details': jsonDecode(terms),
  'postings': [for (final posting in postings) _backupPosting(posting)],
};

EntryRow _restoreEntry(Map<String, dynamic> raw, int version) {
  final id = _requiredString(raw, 'id');
  final original = version >= 2 ? _nullableString(raw, 'refund_of_id') : null;
  final type = _requiredEnum(
    raw,
    'transaction_type',
    LedgerTransactionType.values.map((type) => type.name),
  );
  if (version < 5 &&
      LedgerTransactionType.values.byName(type).isReceivableFlow) {
    throw const LedgerBackupException('旧备份不能包含应收款交易');
  }
  if (original != null &&
      (id == original || type != LedgerTransactionType.expense.name)) {
    throw const LedgerBackupException('备份退款关联无效');
  }
  final detail = raw['financial_details'];
  String? termsJson;
  if (type == LedgerTransactionType.adjustment.name &&
      (raw['status'] != LedgerPostingStatus.posted.name ||
          raw['category_id'] != _adjustmentCategory)) {
    throw const LedgerBackupException('备份财务明细中的余额调整无效');
  }
  if (detail != null || type == LedgerTransactionType.adjustment.name) {
    if (version < 6) throw const LedgerBackupException('旧备份不能包含财务明细');
    if (detail != null) {
      try {
        final terms = TransactionTerms.fromJson(detail as Map<String, dynamic>);
        if (terms.isEmpty) {
          throw const FormatException('Empty financial details');
        }
        termsJson = jsonEncode(terms.toJson());
      } on Object {
        throw const LedgerBackupException('备份财务明细无效');
      }
    }
  }
  final amount = raw['settlement_amount_minor'];
  final currency = _nullableString(raw, 'settlement_currency_code');
  final quote = _nullableString(raw, 'quoted_exchange_rate');
  if (amount != null || currency != null || quote != null) {
    if (version < 3 ||
        type != LedgerTransactionType.transfer.name ||
        amount is! int ||
        amount <= 0 ||
        currency == null ||
        (quote != null && !isValidExchangeQuote(quote))) {
      throw const LedgerBackupException('备份的跨币种结算信息无效');
    }
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
    status: version >= 2
        ? _requiredEnum(
            raw,
            'status',
            LedgerPostingStatus.values.map((status) => status.name),
          )
        : LedgerPostingStatus.posted.name,
    refundOfId: original,
    settlementAmountMinor: amount as int?,
    settlementCurrencyCode: currency,
    quotedExchangeRate: quote,
    termsJson: termsJson,
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
  final terms = _decodeTerms(entry.termsJson);
  final settlement = _entrySettlement(entry);
  // Older rows may have unknown settlement semantics. Preserve their exact
  // per-currency account effects when restoring a full backup.
  if (!isRefund &&
      type != LedgerTransactionType.adjustment &&
      terms.isEmpty &&
      settlement == null &&
      entry.status == LedgerPostingStatus.posted.name &&
      postings.every((leg) => leg.needsReview)) {
    return postings;
  }

  final payments = type == LedgerTransactionType.expense && !isRefund
      ? [
          for (final leg in accountLegs)
            if (leg.accountId != terms.advance?.accountId)
              AccountPayment(
                leg.accountId!,
                terms.reversalOfId == null ? -leg.debitMinor : leg.debitMinor,
              ),
        ]
      : const <AccountPayment>[];
  final hasTarget =
      type != LedgerTransactionType.expense &&
      type != LedgerTransactionType.income &&
      type != LedgerTransactionType.adjustment &&
      !terms.externalDebtPayment;
  final source = accounts[entry.accountId]!;
  final target = accounts[entry.targetAccountId];
  final sourceKind = AccountKind.values.byName(source.kind);
  final targetKind = target == null
      ? null
      : AccountKind.values.byName(target.kind);
  final validAccounts =
      _validAccountFlow(type, sourceKind, targetKind, terms) &&
      _validFundingAccounts(
        payments.map(
          (payment) =>
              AccountKind.values.byName(accounts[payment.accountId]!.kind),
        ),
      );
  if (!_validTerms(
        type,
        entry.amountMinor,
        entry.currencyCode,
        entry.categoryId,
        payments,
        accounts,
        terms,
        isRefund: isRefund,
      ) ||
      !validAccounts ||
      source.currencyCode != entry.currencyCode ||
      !_validTransferSettlement(
        type,
        source.currencyCode,
        target?.currencyCode,
        settlement,
      ) ||
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
    settlement: settlement,
    isCreditIncome:
        type == LedgerTransactionType.income && sourceKind.isLiability,
    terms: terms,
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
  ValuationSettings? valuation,
  List<Map<String, dynamic>> accounts,
  List<Map<String, dynamic>> categories,
  List<Map<String, dynamic>> entries,
  List<Map<String, dynamic>> checkpoints,
  List<Map<String, dynamic>> csvBatches,
  List<Map<String, dynamic>> csvRows,
  List<Map<String, dynamic>> importRules,
  List<Map<String, dynamic>> spendingPlans,
  List<Map<String, dynamic>> recurringPlans,
  List<Map<String, dynamic>> debtContracts,
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
      !(format == _backupFormat && (version >= 1 && version <= 12) ||
          format == _legacyBackupFormat && version == 1)) {
    throw const LedgerBackupException('这不是受支持的 Summa 完整备份');
  }
  final createdAt = DateTime.tryParse(decoded['created_at']?.toString() ?? '');
  if (createdAt == null) throw const LedgerBackupException('备份时间无效');
  final csv = decoded['csv_import'];
  if (version >= 8 && csv is! Map<String, dynamic>) {
    throw const LedgerBackupException('备份缺少 CSV 导入批次');
  }
  final csvData = version >= 8 ? csv as Map<String, dynamic> : null;
  return (
    createdAt: createdAt,
    version: version,
    valuation: version >= 4 ? _restoreValuation(decoded['valuation']) : null,
    accounts: _requiredObjectList(decoded, 'accounts'),
    categories: _requiredObjectList(decoded, 'categories'),
    entries: _requiredObjectList(decoded, 'entries'),
    debtContracts: version >= 12
        ? _requiredObjectList(decoded, 'debt_contracts')
        : const [],
    recurringPlans: version >= 11
        ? _requiredObjectList(decoded, 'recurring_plans')
        : const [],
    spendingPlans: version >= 10
        ? _requiredObjectList(decoded, 'spending_plans')
        : const [],
    importRules: version >= 9
        ? _requiredObjectList(decoded, 'import_category_rules')
        : const [],
    csvBatches: csvData == null
        ? const []
        : _requiredObjectList(csvData, 'batches'),
    csvRows: csvData == null ? const [] : _requiredObjectList(csvData, 'rows'),
    checkpoints: version >= 7
        ? _requiredObjectList(decoded, 'balance_checkpoints')
        : const [],
  );
}

ValuationSettings _restoreValuation(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw const LedgerBackupException('备份估值设置无效');
  }
  final base = _requiredString(data, 'base_currency');
  if (!isValuationCurrency(base)) {
    throw const LedgerBackupException('备份估值基准币种不受支持');
  }
  final pairs = <(String, String)>{};
  final rates = <ValuationRate>[];
  for (final raw in _requiredObjectList(data, 'rates')) {
    final sourceCurrency = _requiredString(raw, 'source_currency');
    final baseCurrency = _requiredString(raw, 'base_currency');
    final value = _requiredString(raw, 'rate');
    if (!isValidValuationRate(
          sourceCurrency: sourceCurrency,
          baseCurrency: baseCurrency,
          rate: value,
        ) ||
        !pairs.add((baseCurrency, sourceCurrency))) {
      throw const LedgerBackupException('备份估值汇率无效或重复');
    }
    rates.add(
      ValuationRate(
        sourceCurrency: sourceCurrency,
        baseCurrency: baseCurrency,
        rate: value,
        updatedAt: _requiredDate(raw, 'updated_at'),
      ),
    );
  }
  return ValuationSettings(baseCurrency: base, rates: rates);
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
      case LedgerTransactionType.lending:
      case LedgerTransactionType.advance:
      case LedgerTransactionType.collection:
      case LedgerTransactionType.reimbursement:
      case LedgerTransactionType.adjustment:
        throw const LedgerImportException('财务分录请通过完整备份恢复');
    }
  }
  return {
    for (final entry in minimum.entries) entry.key: math.max(0, -entry.value),
  };
}
