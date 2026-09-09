import 'package:ledger_pro/data/backup/local_backup_store.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';

class AutoBackupExpenseRepository implements ExpenseRepository {
  AutoBackupExpenseRepository(this._delegate, this._backupStore);

  final ExpenseRepository _delegate;
  final LocalBackupStore _backupStore;

  Future<void> _mutate(Future<void> Function() action) async {
    final path = await _backupStore.beginAutomaticBackup(
      await _delegate.createFullBackup(),
    );
    try {
      await action();
    } catch (_) {
      await _backupStore.rollBackAutomaticBackup(path);
      rethrow;
    }
    try {
      await _backupStore.commitAutomaticBackup(path);
    } catch (_) {
      // The ledger edit already succeeded; rotation maintenance must not make
      // the caller believe that the edit failed.
    }
  }

  @override
  Stream<List<LedgerRecord>> watchTransactions() =>
      _delegate.watchTransactions();

  @override
  Stream<List<LedgerAccount>> watchAccounts() => _delegate.watchAccounts();

  @override
  Stream<List<AccountBalance>> watchAccountBalances() =>
      _delegate.watchAccountBalances();

  @override
  Stream<List<LedgerCategory>> watchExpenseCategories() =>
      _delegate.watchExpenseCategories();

  @override
  Stream<List<LedgerCategory>> watchIncomeCategories() =>
      _delegate.watchIncomeCategories();

  @override
  Future<void> addExpense({
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) => _mutate(
    () => _delegate.addExpense(
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    ),
  );

  @override
  Future<void> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) => _mutate(
    () => _delegate.updateExpense(
      id: id,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    ),
  );

  @override
  Future<void> deleteTransaction(String id) =>
      _mutate(() => _delegate.deleteTransaction(id));

  @override
  Future<void> addTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  }) => _mutate(
    () => _delegate.addTransaction(
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: accountId,
      targetAccountId: targetAccountId,
      categoryId: categoryId,
      note: note,
    ),
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
    required String note,
  }) => _mutate(
    () => _delegate.updateTransaction(
      id: id,
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: accountId,
      targetAccountId: targetAccountId,
      categoryId: categoryId,
      note: note,
    ),
  );

  @override
  Future<void> importTransactions(List<LedgerImportDraft> drafts) =>
      drafts.isEmpty
      ? Future.value()
      : _mutate(() => _delegate.importTransactions(drafts));

  @override
  Future<void> setCurrentBalance({
    required String accountId,
    required int amountMinor,
  }) => _mutate(
    () => _delegate.setCurrentBalance(
      accountId: accountId,
      amountMinor: amountMinor,
    ),
  );

  @override
  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    required int currentBalanceMinor,
  }) => _mutate(
    () => _delegate.addAccount(
      name: name,
      kind: kind,
      currentBalanceMinor: currentBalanceMinor,
    ),
  );

  @override
  Future<void> archiveAccount(String id) =>
      _mutate(() => _delegate.archiveAccount(id));

  @override
  Future<void> restoreDefaultAccounts() =>
      _mutate(_delegate.restoreDefaultAccounts);

  @override
  Future<void> addCategory({
    required LedgerTransactionType type,
    required String name,
    String? parentId,
  }) => _mutate(
    () => _delegate.addCategory(type: type, name: name, parentId: parentId),
  );

  @override
  Future<void> renameCategory({required String id, required String name}) =>
      _mutate(() => _delegate.renameCategory(id: id, name: name));

  @override
  Future<void> archiveCategory(String id) =>
      _mutate(() => _delegate.archiveCategory(id));

  @override
  Future<void> moveCategory(String id, {required bool moveUp}) =>
      _mutate(() => _delegate.moveCategory(id, moveUp: moveUp));

  @override
  Future<void> restoreDefaultCategories() =>
      _mutate(_delegate.restoreDefaultCategories);

  @override
  Future<String> createFullBackup() => _delegate.createFullBackup();

  @override
  LedgerBackupPreview inspectFullBackup(String source) =>
      _delegate.inspectFullBackup(source);

  @override
  Future<void> restoreFullBackup(
    String source, {
    required BackupRestoreMode mode,
  }) => _mutate(() => _delegate.restoreFullBackup(source, mode: mode));

  @override
  Future<void> resetLedgerData() => _mutate(_delegate.resetLedgerData);

  @override
  Future<void> resetToFactoryDefaults() =>
      _mutate(_delegate.resetToFactoryDefaults);
}
