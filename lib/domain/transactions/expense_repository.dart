import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

enum TransactionRuleError {
  insufficientBalance,
  overpayment,
  invalidPaymentSplit,
  refundLimitExceeded,
  linkedRefunds,
  archivedPostingAccount,
  invalidTransferSettlement,
  currencyMismatch,
  fixedOtherCategory,
  otherCategoryRequired,
}

class TransactionRuleException implements Exception {
  const TransactionRuleException(
    this.error, {
    this.accountId,
    this.accountName,
    this.amountMinor,
    this.currencyCode = defaultCurrency,
  });

  final TransactionRuleError error;
  final String? accountId;
  final String? accountName;
  final int? amountMinor;
  final String currencyCode;

  @override
  String toString() => error.name;
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
    List<AccountPayment>? payments,
    TransferSettlement? settlement,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
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
    List<AccountPayment>? payments,
    TransferSettlement? settlement,
    required String note,
  });

  Future<void> postTransaction(String id);

  Future<void> saveRefund({
    String? id,
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
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
    String currencyCode = defaultCurrency,
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

  Stream<ValuationSettings> watchValuationSettings();

  Future<void> setValuationBaseCurrency(String baseCurrency);

  Future<void> saveValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
    required String rate,
  });

  Future<void> removeValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
  });

  Future<String> createFullBackup();

  LedgerBackupPreview inspectFullBackup(String source);

  Future<void> restoreFullBackup(
    String source, {
    required BackupRestoreMode mode,
  });

  Future<void> resetLedgerData();

  Future<void> resetToFactoryDefaults();
}
