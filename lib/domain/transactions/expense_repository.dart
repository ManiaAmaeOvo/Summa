import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

class TransactionRuleException implements Exception {
  const TransactionRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ExpenseRepository {
  Stream<List<LedgerRecord>> watchTransactions();

  Stream<List<LedgerAccount>> watchAccounts();

  Stream<List<AccountBalance>> watchAccountBalances();

  Stream<List<LedgerCategory>> watchExpenseCategories();

  Stream<List<LedgerCategory>> watchIncomeCategories();

  Future<void> addExpense({
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  });

  Future<void> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  });

  Future<void> deleteTransaction(String id);

  Future<void> addTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  });

  Future<void> updateTransaction({
    required String id,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    required String note,
  });

  Future<void> importTransactions(List<LedgerImportDraft> drafts);

  Future<void> setCurrentBalance({
    required String accountId,
    required int amountMinor,
  });

  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    required int currentBalanceMinor,
  });

  Future<void> archiveAccount(String id);

  Future<void> restoreDefaultAccounts();

  Future<void> addCategory({
    required LedgerTransactionType type,
    required String name,
    String? parentId,
  });

  Future<void> renameCategory({required String id, required String name});

  Future<void> archiveCategory(String id);

  Future<void> moveCategory(String id, {required bool moveUp});

  Future<void> restoreDefaultCategories();

  Future<String> createFullBackup();

  LedgerBackupPreview inspectFullBackup(String source);

  Future<void> restoreFullBackup(
    String source, {
    required BackupRestoreMode mode,
  });

  Future<void> resetLedgerData();

  Future<void> resetToFactoryDefaults();
}
