import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/cash_forecast.dart';
import 'package:summa/domain/analytics/ledger_history.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

enum TransactionRuleError {
  insufficientBalance,
  insufficientAllowance,
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

  Stream<LedgerHistoryInputs> watchLedgerHistoryInputs();

  Stream<CashForecastInputs> watchCashForecastInputs();

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
    required List<ImportRuleCondition> conditions,
    ImportRuleMode mode = ImportRuleMode.all,
    required String categoryId,
    required int priority,
    required bool enabled,
  });

  Future<List<CsvRuleTrialRow>> previewImportRules(
    CsvImportFile file, {
    ImportCategoryRule? draft,
  });

  Future<void> deleteImportRule(String id);

  Stream<List<SpendingPlan>> watchSpendingPlans();

  Future<void> addSpendingPlan(SpendingPlanDraft draft);

  Future<void> setSpendingPlanLimit(String id, SpendingPlanLimit limit);

  Future<void> setSpendingPlanArchived(String id, bool archived);

  Stream<List<RecurringPlan>> watchRecurringPlans();

  Future<void> addRecurringPlan(RecurringPlanDraft draft);

  Future<void> setRecurringPlanPaused(String id, bool paused);

  Future<void> setRecurringPlanExpectedAmount(String id, int amountMinor);

  Future<void> confirmRecurringOccurrence(
    String id,
    int expectedIndex, {
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
  });

  Future<void> linkRecurringOccurrence(
    String id,
    int expectedIndex,
    String entryId,
  );

  Stream<List<DebtContract>> watchDebtContracts();

  Future<void> addDebtContract(DebtContractDraft draft);

  Future<void> linkDebtSettlement(
    String accountId,
    String entryId,
    DebtLinkKind kind,
  );

  Future<void> unlinkDebtSettlement(String linkId);

  Stream<List<SavingsAccountAllocation>> watchSavingsAllocations();

  Future<void> addSavingsGoal(SavingsGoalDraft draft);

  Future<void> updateSavingsGoal(String id, SavingsGoalDraft draft);

  Future<void> changeSavingsAllocation(
    String id,
    int changeMinor, {
    required String note,
  });

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
