import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
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
  receivableBalanceExceeded,
  invalidTransactionDetails,
  linkedReversal,
  linkedCheckpoint,
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
    TransactionTerms terms = const TransactionTerms(),
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
    TransactionTerms? terms,
    required String note,
  });

  Future<void> postTransaction(String id);

  Future<void> reverseTransaction(String id, {required DateTime occurredAt});

  Stream<List<BalanceCheckpoint>> watchBalanceCheckpoints(String accountId);

  Future<void> saveBalanceCheckpoint({
    required String accountId,
    required DateTime observedAt,
    required int actualMinor,
    required String note,
  });

  Future<void> adjustBalanceCheckpoint(
    String id, {
    required int expectedBookMinor,
  });

  Future<void> voidBalanceCheckpoint(String id);

  Future<void> recordBalanceAdjustment({
    required String accountId,
    required int amountMinor,
    required String note,
  });

  Future<void> saveFamilyExpense({
    String? id,
    required int amountMinor,
    required String currencyCode,
    required DateTime occurredAt,
    required String categoryId,
    required String note,
    List<CategoryAmount> categories = const [],
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  });

  Future<void> saveRefund({
    String? id,
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    int? advanceCancellationMinor,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  });

  Future<void> importTransactions(List<LedgerImportDraft> drafts);

  Stream<List<ImportCategoryRule>> watchImportRules();

  Future<void> saveImportRule({
    String? id,
    required ImportRuleField field,
    required String keyword,
    required String categoryId,
    required int priority,
    required bool enabled,
  });

  Future<void> deleteImportRule(String id);

  Future<List<CsvReviewRow>> previewCsvImport(
    CsvImportFile file, {
    Map<int, CsvMapping> mappings = const {},
  });

  Future<CsvImportResult> commitCsvImport(
    CsvImportFile file,
    List<CsvSelection> selections,
  );

  Stream<List<CsvBatchSummary>> watchCsvBatches();

  Future<List<CsvBatchItem>> readCsvBatchItems(String id);

  Future<void> undoCsvImport(String id);

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
